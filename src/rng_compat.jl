
# implementation of AbstractRNG overloading based on
# https://github.com/JuliaRandom/StableRNGs.jl

function seed!(rng::IsaacRNG{T}, seed::AbstractVector{UInt8}) where {T}
    tb = sizeof(T)
    xtra = mod(tb - mod(length(seed), tb), tb)
    seed = [seed; zeros(UInt8, xtra)]
    randinit(rng, seed)
    rng
end

seed!(rng::IsaacRNG, seed::AbstractString) = seed!(rng, transcode(UInt8, seed))

function Base.copy!(dst::IsaacRNG{T}, src::IsaacRNG{T}) where {T}
    dst.randrsl .= src.randrsl
    dst.randmem .= src.randmem
    dst.randcnt = src.randcnt
    dst.randa = src.randa
    dst.randb = src.randb
    dst.randc = src.randc
    dst
end

function Base.copy(src::IsaacRNG{T}) where {T}
    dst = IsaacRNG{T}()
    copy!(dst, src)
end

function Base.:(==)(x::IsaacRNG, y::IsaacRNG)
    all(x.randrsl .== y.randrsl) &&
        all(x.randmem .== y.randmem) &&
        x.randcnt == y.randcnt &&
        x.randa == y.randa &&
        x.randb == y.randb &&
        x.randc == y.randc
end

Base.hash(rng::IsaacRNG{T}, h::UInt) where {T} = hash(
    rng.randrsl,
    hash(
        rng.randmem,
        hash(
            rng.randcnt,
            hash(
                rng.randa,
                hash(rng.randb, hash(rng.randc, 0xaa18734ac002b51c % T ⊻ h)),
            ),
        ),
    ),
)

## Sampling

rand(rng::IsaacRNG{UInt64}, ::SamplerType{UInt64}) = isaac_rand(rng)

rand(rng::IsaacRNG{UInt32}, ::SamplerType{UInt32}) = isaac_rand(rng)

rand(rng::IsaacRNG{UInt32}, ::SamplerType{UInt64}) =
    rand(rng, UInt32) | ((rand(rng, UInt32) % UInt64) << 32)

for T in [Bool, Base.BitInteger64_types...]
    T === UInt64 && continue
    @eval rand(rng::IsaacRNG, ::SamplerType{$T}) = rand(rng, UInt64) % $T
end

rand(rng::IsaacRNG, ::SamplerType{UInt128}) =
    rand(rng, UInt64) | ((rand(rng, UInt64) % UInt128) << 64)

rand(rng::IsaacRNG, ::SamplerType{Int128}) = rand(rng, UInt128) % Int128

rng_native_52(::IsaacRNG) = UInt64
