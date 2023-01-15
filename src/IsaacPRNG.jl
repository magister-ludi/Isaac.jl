module IsaacPRNG

using Random: Random, AbstractRNG, SamplerType

import Random: rand, seed!, rng_native_52

export isaac_rand, Isaac32, Isaac64

#=
   ------------------------------------------------------------------------------
   Based on ISAAC code
   By Bob Jenkins, 1996, Public Domain
   ------------------------------------------------------------------------------
 =#

const RANDSIZL = 8
const RANDSIZ = 1 << RANDSIZL

mutable struct IsaacRNG{T <: Unsigned} <: AbstractRNG
    randrsl::Vector{T}
    randmem::Vector{T}
    randcnt::T
    randa::T
    randb::T
    randc::T
    function IsaacRNG{T}(bytes::AbstractVector{UInt8}) where {T}
        r = new(Vector{T}(undef, RANDSIZ), Vector{T}(undef, RANDSIZ))
        Random.seed!(r, bytes)
    end
end

IsaacRNG{T}() where {T} = IsaacRNG{T}(UInt8[])

IsaacRNG{T}(s::AbstractString) where {T} = IsaacRNG{T}(transcode(UInt8, s))

Base.show(io::IO, rng::IsaacRNG{T}) where {T} =
    print(io, IsaacRNG, "{", T, "}(hash=0x", string(hash(rng), base = 16), ")")

"""
    isaac_rand(r::IsaacRNG{T})
Return a random value of type T
"""
function isaac_rand(r::IsaacRNG)
    if (r.randcnt -= 1) == 0
        isaac(r)
        r.randcnt = RANDSIZ
    end
    return r.randrsl[r.randcnt]
end

"""
    Isaac32(bytes::AbstractVector{UInt8} = [])
    Isaac32(string::AbstractString = "")
Create an ISAAC generator that produces `UInt32` values
using `bytes` or `string` as the seed.
"""
const Isaac32 = IsaacRNG{UInt32}

"""
    Isaac64()
    Isaac64(seed::AbstractVector{UInt8})
    Isaac64(seed::AbstractString)
Create an ISAAC generator that produces `UInt64` values
using `seed` as the seed.
"""
const Isaac64 = IsaacRNG{UInt64}

include("isaac32.jl")
include("isaac64.jl")
include("rng_compat.jl")

end # module
