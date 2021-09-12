
ind(::Isaac32, mm, x) = mm + (x & ((RANDSIZ - 1) << 2)) >> 2

function rngstep(rng::Isaac32, mix::UInt32, a::UInt32, b::UInt32, mm, m, m2, r)
    x = rng.randmem[m]
    a = (a ⊻ mix) + rng.randmem[m2]
    m2 += 1
    rng.randmem[m] = y = (rng.randmem[ind(rng, mm, x)] + a + b) & 0xffffffff
    m += 1
    rng.randrsl[r] = b = (rng.randmem[ind(rng, mm, y >> RANDSIZL)] + x) & 0xffffffff
    r += 1
    return x, y, a, b, m, m2, r
end

function isaac(rng::Isaac32)
    x = zero(UInt32)
    mm = 1
    r = 1
    a = rng.randa
    rng.randc += 1
    b = rng.randb + rng.randc
    m = mm
    mend = m2 = m + (RANDSIZ >> 1)
    while m < mend
        x, y, a, b, m, m2, r = rngstep(rng, a << 13, a, b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(rng, a >> 6, a, b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(rng, a << 2, a, b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(rng, a >> 16, a, b, mm, m, m2, r)
    end
    m2 = mm
    while m2 < mend
        x, y, a, b, m, m2, r = rngstep(rng, a << 13, a, b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(rng, a >> 6, a, b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(rng, a << 2, a, b, mm, m, m2, r)
        x, y, a, b, m, m2, r = rngstep(rng, a >> 16, a, b, mm, m, m2, r)
    end
    rng.randb = b
    rng.randa = a
end

function mix!(::Isaac32, data)
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

"""
    randinit(rng::IsaacRNG{T}, bytes::AbstractVector{UInt8}) where {T}
Initialise `rng` using the content of `bytes`. If `bytes` is
empty, use a fallback method. Use `sizeof(T) * min(length(bytes) ÷ sizeof(T), 256)`
bytes to initialise.
"""
function randinit(rng::Isaac32, bytes::AbstractVector{UInt8})
    rng.randcnt = rng.randa = rng.randb = rng.randc = 0
    fill!(rng.randmem, 0)
    fill!(rng.randrsl, 0)

    data = fill(0x9e3779b9, 8)  # the golden ratio
    for i = 1:4   # scramble it
        mix!(rng, data)
    end
    if !isempty(bytes)
        len = min(length(bytes) ÷ 4, RANDSIZ)
        io = IOBuffer(bytes[1:(4 * len)])
        for k = 1:len
            rng.randrsl[k] = htol(read(io, UInt32))
        end
        # initialize using the contents of randrsl as the seed
        for i = 1:8:RANDSIZ
            data[1] += rng.randrsl[i]
            data[2] += rng.randrsl[i + 1]
            data[3] += rng.randrsl[i + 2]
            data[4] += rng.randrsl[i + 3]
            data[5] += rng.randrsl[i + 4]
            data[6] += rng.randrsl[i + 5]
            data[7] += rng.randrsl[i + 6]
            data[8] += rng.randrsl[i + 7]
            mix!(rng, data)
            rng.randmem[i] = data[1]
            rng.randmem[i + 1] = data[2]
            rng.randmem[i + 2] = data[3]
            rng.randmem[i + 3] = data[4]
            rng.randmem[i + 4] = data[5]
            rng.randmem[i + 5] = data[6]
            rng.randmem[i + 6] = data[7]
            rng.randmem[i + 7] = data[8]
        end

        # do a second pass to make all of the seed affect all of m
        for i = 1:8:RANDSIZ
            data[1] += rng.randmem[i]
            data[2] += rng.randmem[i + 1]
            data[3] += rng.randmem[i + 2]
            data[4] += rng.randmem[i + 3]
            data[5] += rng.randmem[i + 4]
            data[6] += rng.randmem[i + 5]
            data[7] += rng.randmem[i + 6]
            data[8] += rng.randmem[i + 7]
            mix!(rng, data)
            rng.randmem[i] = data[1]
            rng.randmem[i + 1] = data[2]
            rng.randmem[i + 2] = data[3]
            rng.randmem[i + 3] = data[4]
            rng.randmem[i + 4] = data[5]
            rng.randmem[i + 5] = data[6]
            rng.randmem[i + 6] = data[7]
            rng.randmem[i + 7] = data[8]
        end
    else
        # fill in rng.randmem[] with messy stuff
        for i = 1:8:RANDSIZ
            mix!(rng, data)
            rng.randmem[i] = data[1]
            rng.randmem[i + 1] = data[2]
            rng.randmem[i + 2] = data[3]
            rng.randmem[i + 3] = data[4]
            rng.randmem[i + 4] = data[5]
            rng.randmem[i + 5] = data[6]
            rng.randmem[i + 6] = data[7]
            rng.randmem[i + 7] = data[8]
        end
    end

    isaac(rng)                 # fill in the first set of results
    rng.randcnt = RANDSIZ + 1  # prepare to use the first set of results
end
