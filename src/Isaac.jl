module Isaac

export isaac_rand, Isaac32, Isaac64

using Random: Random, AbstractRNG, Sampler, SamplerType

import Random: rand, seed!

const RANDSIZL = 8
const RANDSIZ = 1 << RANDSIZL

# Isaac random number generator
mutable struct IsaacRNG{T <: Unsigned} <: AbstractRNG
    randrsl::Vector{T}
    randmem::Vector{T}
    randcnt::T
    randa::T
    randb::T
    randc::T
    function IsaacRNG{T}(s::String = "") where {T}
        r = new(Vector{T}(undef, RANDSIZ), Vector{T}(undef, RANDSIZ))
        randinit(r, s)
        return r
    end
end

Base.show(io::IO, rng::IsaacRNG{T}) where {T} =
    print(io, IsaacRNG, "{", T, "}(hash=0x",string(hash(rng), base=16), ")")

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

const Isaac32 = IsaacRNG{UInt32}
const Isaac64 = IsaacRNG{UInt64}

include("isaac32.jl")
include("isaac64.jl")
include("rng_compat.jl")

end # module
