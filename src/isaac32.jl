
#=
   ------------------------------------------------------------------------------
   Based on ISAAC code
   By Bob Jenkins, 1996, Public Domain
   ------------------------------------------------------------------------------
 =#

const RANDSIZL = 8
const RANDSIZ = 1 << RANDSIZL

# context of random number generator
mutable struct Isaac32
    randrsl::Vector{UInt32}  # [RANDSIZ]
    randmem::Vector{UInt32}  # [RANDSIZ]
    randcnt::UInt32
    randa::UInt32
    randb::UInt32
    randc::UInt32
    function Isaac32(s::String = "")
        r = new(Vector{UInt32}(undef, RANDSIZ), Vector{UInt32}(undef, RANDSIZ))
        randinit(r, s)
        return r
    end
end

#=
   ------------------------------------------------------------------------------
   Call rand(/o_ Isaac32 *r _o/) to retrieve a single 32-bit random value
   ------------------------------------------------------------------------------
 =#
function isaac_rand(r::Isaac32)
    if (r.randcnt -= 1) == 0
        isaac(r)
        r.randcnt = RANDSIZ
    end
    return r.randrsl[r.randcnt]
end

ind(mm, x) = mm + (x & ((RANDSIZ - 1) << 2)) >> 2

const counter = Ref(0)

function rngstep(
    ctx::Isaac32,
    mix::UInt32,
    a::UInt32,
    b::UInt32,
    mm,
    m,
    m2,
    r,
    x::UInt32,
)
    x = ctx.randmem[m]
    a = (a ⊻ mix) + ctx.randmem[m2]
    m2 += 1
    ctx.randmem[m] = y = (ctx.randmem[ind(mm, x)] + a + b) & 0xffffffff
    m += 1
    ctx.randrsl[r] = b = (ctx.randmem[ind(mm, y >> RANDSIZL)] + x) & 0xffffffff
    r += 1
    return x, y, a, b, m, m2, r
end

function isaac(ctx::Isaac32)
    x = y = UInt32(0)
    mm = 1
    r = 1
    a = ctx.randa
    ctx.randc += 1
    b = ctx.randb + ctx.randc
    m = mm
    mend = m2 = m + (RANDSIZ ÷ 2)
    while m < mend
        x, y, a, b, m, m2, r = rngstep(ctx, a << 13, a, b, mm, m, m2, r, x)
        x, y, a, b, m, m2, r = rngstep(ctx, a >> 6, a, b, mm, m, m2, r, x)
        x, y, a, b, m, m2, r = rngstep(ctx, a << 2, a, b, mm, m, m2, r, x)
        x, y, a, b, m, m2, r = rngstep(ctx, a >> 16, a, b, mm, m, m2, r, x)
    end
    m2 = mm
    while m2 < mend
        x, y, a, b, m, m2, r = rngstep(ctx, a << 13, a, b, mm, m, m2, r, x)
        x, y, a, b, m, m2, r = rngstep(ctx, a >> 6, a, b, mm, m, m2, r, x)
        x, y, a, b, m, m2, r = rngstep(ctx, a << 2, a, b, mm, m, m2, r, x)
        x, y, a, b, m, m2, r = rngstep(ctx, a >> 16, a, b, mm, m, m2, r, x)
    end
    ctx.randb = b
    ctx.randa = a
end

function mix!(data)
    data[1] ⊻= data[2] << 11
    data[4] += data[1]
    data[2] += data[3]
    data[2] ⊻= data[3] >> 2
    data[5] += data[2]
    data[3] += data[4]
    data[3] ⊻= data[4] << 8
    data[6] += data[3]
    data[4] += data[5]
    data[4] ⊻= data[5] >> 16
    data[7] += data[4]
    data[5] += data[6]
    data[5] ⊻= data[6] << 10
    data[8] += data[5]
    data[6] += data[7]
    data[6] ⊻= data[7] >> 4
    data[1] += data[6]
    data[7] += data[8]
    data[7] ⊻= data[8] << 8
    data[2] += data[7]
    data[8] += data[1]
    data[8] ⊻= data[1] >> 9
    data[3] += data[8]
    data[1] += data[2]
end

# if (flag==TRUE), then use the contents of randrsl[] to initialize mm[].
function randinit(ctx::Isaac32, s::AbstractString)
    ctx.randcnt = ctx.randa = ctx.randb = ctx.randc = 0
    data = fill(0x9e3779b9, 8)  # the golden ratio
    for i = 1:4   # scramble it
        mix!(data)
    end
    if !isempty(s)
        fill!(ctx.randmem, 0)
        fill!(ctx.randrsl, 0)
        bytes = transcode(UInt8, s)
        len = min(length(bytes) ÷ 4, RANDSIZ)
        io = IOBuffer(bytes[1:(4 * len)])
        for k = 1:len
            ctx.randrsl[k] = htol(read(io, UInt32))
        end
        # initialize using the contents of randrsl as the seed
        for i = 1:8:RANDSIZ
            data[1] += ctx.randrsl[i]
            data[2] += ctx.randrsl[i + 1]
            data[3] += ctx.randrsl[i + 2]
            data[4] += ctx.randrsl[i + 3]
            data[5] += ctx.randrsl[i + 4]
            data[6] += ctx.randrsl[i + 5]
            data[7] += ctx.randrsl[i + 6]
            data[8] += ctx.randrsl[i + 7]
            mix!(data)
            ctx.randmem[i] = data[1]
            ctx.randmem[i + 1] = data[2]
            ctx.randmem[i + 2] = data[3]
            ctx.randmem[i + 3] = data[4]
            ctx.randmem[i + 4] = data[5]
            ctx.randmem[i + 5] = data[6]
            ctx.randmem[i + 6] = data[7]
            ctx.randmem[i + 7] = data[8]
        end

        # do a second pass to make all of the seed affect all of m
        for i = 1:8:RANDSIZ
            data[1] += ctx.randmem[i]
            data[2] += ctx.randmem[i + 1]
            data[3] += ctx.randmem[i + 2]
            data[4] += ctx.randmem[i + 3]
            data[5] += ctx.randmem[i + 4]
            data[6] += ctx.randmem[i + 5]
            data[7] += ctx.randmem[i + 6]
            data[8] += ctx.randmem[i + 7]
            mix!(data)
            ctx.randmem[i] = data[1]
            ctx.randmem[i + 1] = data[2]
            ctx.randmem[i + 2] = data[3]
            ctx.randmem[i + 3] = data[4]
            ctx.randmem[i + 4] = data[5]
            ctx.randmem[i + 5] = data[6]
            ctx.randmem[i + 6] = data[7]
            ctx.randmem[i + 7] = data[8]
        end
    else
        # fill in ctx.randmem[] with messy stuff
        for i = 1:8:RANDSIZ
            mix!(data)
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

    isaac(ctx)                 # fill in the first set of results
    ctx.randcnt = RANDSIZ + 1  # prepare to use the first set of results
end
