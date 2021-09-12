
ind(::Isaac64, mm, x) = mm + (x & ((RANDSIZ - 1) << 3)) >> 3

function rngstep(ctx::Isaac64, mix::UInt64, b::UInt64, mm, m, m2, r)
    x = ctx.randmem[m]
    a = mix + ctx.randmem[m2]
    m2 += 1
    #@printf("a. %016x %d\n", x, ind(ctx, mm, x))
    ctx.randmem[m] = y = ctx.randmem[ind(ctx, mm, x)] + a + b
    m += 1
    #@printf("b. %16s %d\n", "",  mm + (x & ((RANDSIZ - 1) << 3)) >> 8)
    ctx.randrsl[r] = b = ctx.randmem[ind(ctx, mm, y >> RANDSIZL)] + x
    r += 1
    return x, y, a, b, m, m2, r
end

function isaac(ctx::Isaac64)
    mm = 1
    r = 1
    a = ctx.randa
    ctx.randc += 1
    b = ctx.randb + ctx.randc
    m = mm
    mend = m2 = m + (RANDSIZ >> 1)
    x = y = zero(UInt64)
    while m < mend
        x, y, a, b, m, m2, r = rngstep(ctx, ~(a ⊻ (a << 21)), b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(ctx, a ⊻ (a >> 5), b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(ctx, a ⊻ (a << 12), b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(ctx, a ⊻ (a >> 33), b, mm, m, m2, r)
    end
    m2 = mm
    while m2 < mend
        x, y, a, b, m, m2, r = rngstep(ctx, ~(a ⊻ (a << 21)), b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(ctx, a ⊻ (a >> 5), b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(ctx, a ⊻ (a << 12), b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(ctx, a ⊻ (a >> 33), b, mm, m, m2, r)
    end
    ctx.randb = b
    ctx.randa = a
end

function mix!(::Isaac64, data)
    data[1] -= data[5]
    data[6] ⊻= data[8] >> 9
    data[8] += data[1]
    data[2] -= data[6]
    data[7] ⊻= data[1] << 9
    data[1] += data[2]
    data[3] -= data[7]
    data[8] ⊻= data[2] >> 23
    data[2] += data[3]
    data[4] -= data[8]
    data[1] ⊻= data[3] << 15
    data[3] += data[4]
    data[5] -= data[1]
    data[2] ⊻= data[4] >> 14
    data[4] += data[5]
    data[6] -= data[2]
    data[3] ⊻= data[5] << 20
    data[5] += data[6]
    data[7] -= data[3]
    data[4] ⊻= data[6] >> 17
    data[6] += data[7]
    data[8] -= data[4]
    data[5] ⊻= data[7] << 14
    data[7] += data[8]
end

function randinit(ctx::Isaac64, bytes::AbstractVector{UInt8})
    ctx.randa = ctx.randb = ctx.randc = 0
    fill!(ctx.randmem, 0)
    fill!(ctx.randrsl, 0)
    data = fill(0x9e3779b97f4a7c13, 8)  # the golden ratio
    # scramble it
    for i = 1:4
        mix!(ctx, data)
    end

    if !isempty(bytes)             # use all the information in the seed
        len = min(length(bytes) >> 3, RANDSIZ)
        io = IOBuffer(bytes)
        for k = 1:len
            ctx.randrsl[k] = htol(read(io, UInt64))
        end
    end
    for i = 1:8:RANDSIZ            # fill in randmem[] with messy stuff
        if !isempty(bytes)             # use all the information in the seed
            data[1] += ctx.randrsl[i]
            data[2] += ctx.randrsl[i + 1]
            data[3] += ctx.randrsl[i + 2]
            data[4] += ctx.randrsl[i + 3]
            data[5] += ctx.randrsl[i + 4]
            data[6] += ctx.randrsl[i + 5]
            data[7] += ctx.randrsl[i + 6]
            data[8] += ctx.randrsl[i + 7]
        end

        mix!(ctx, data)
        ctx.randmem[i] = data[1]
        ctx.randmem[i + 1] = data[2]
        ctx.randmem[i + 2] = data[3]
        ctx.randmem[i + 3] = data[4]
        ctx.randmem[i + 4] = data[5]
        ctx.randmem[i + 5] = data[6]
        ctx.randmem[i + 6] = data[7]
        ctx.randmem[i + 7] = data[8]
    end
    if !isempty(bytes) # do a second pass to make all of the seed affect all of ctx.randmem
        for i = 1:8:RANDSIZ
            data[1] += ctx.randmem[i]
            data[2] += ctx.randmem[i + 1]
            data[3] += ctx.randmem[i + 2]
            data[4] += ctx.randmem[i + 3]
            data[5] += ctx.randmem[i + 4]
            data[6] += ctx.randmem[i + 5]
            data[7] += ctx.randmem[i + 6]
            data[8] += ctx.randmem[i + 7]
            mix!(ctx, data)
            ctx.randmem[i] = data[1]
            ctx.randmem[i + 1] = data[2]
            ctx.randmem[i + 2] = data[3]
            ctx.randmem[i + 3] = data[4]
            ctx.randmem[i + 4] = data[5]
            ctx.randmem[i + 5] = data[6]
            ctx.randmem[i + 6] = data[7]
            ctx.randmem[i + 7] = data[8]
        end
    end

    isaac(ctx)          # fill in the first set of results
    ctx.randcnt = RANDSIZ + 1 # prepare to use the first set of results
end
