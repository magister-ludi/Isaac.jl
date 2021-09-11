module Isaac

export isaac_rand, Isaac32, Isaac64

const RANDSIZL = 8
const RANDSIZ = 1 << RANDSIZL

# Isaac random number generator
mutable struct IsaacRNG{T <: Unsigned}
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

#=
   ------------------------------------------------------------------------------
   Call isaac_rand(r::IsaacRNG{T}) to retrieve a random value of type T
   ------------------------------------------------------------------------------
 =#
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

end # module
