# IsaacPRNG.jl

## Background

ISAAC (Indirection, Shift, Accumulate, Add, and Count) generates pseudorandom numbers.
The original C reference version was developed by
[Robert J. Jenkins Jr.](https://burtleburtle.net/bob/)
and is available from
the [ISAAC home page](https://burtleburtle.net/bob/rand/isaacafa.html).

How secure is it? See the home page, and pay attention to Jenkins' warning:
> Seeding a random number generator is essentially the same problem as
> encrypting the seed with a block cipher. ISAAC should be initialized
> with the encryption of the seed by some secure cipher.

I am definitely not an expert, but there appears to be no public evidence
(see e.g. [Wikipedia](https://en.wikipedia.org/wiki/ISAAC_(cipher)) that the
cipher has been broken.

## API

Two versions of ISAAC generator are provided:
- __Isaac32__ generates 32-bit unsigned integers
- __Isaac64__ generates 64-bit unsigned integers

The two generators use different algorithms, and will produce different
numbers given the same seed. Both generators are subtypes of `Random.AbstractRNG`
and can be used (I hope) with the same methods provided by [`Random`](https://docs.julialang.org/en/v1/stdlib/Random/#Random-generation-functions) in the Julia
standard library (Thanks to [StableRNGs](https://github.com/JuliaRandom/StableRNGs.jl)
for showing me how to do this).

### Construction

Three construction methods are available for each generator:
- `Isaac32()`, `Isaac64()` are default constructors (equivalent to an empty seed)
- `Isaac32(seed::AbstractVector{UInt8})`, `Isaac64(seed::AbstractVector{UInt8})` use
the items in `seed` to seed the generator
- `Isaac32(seed::AbstractString)`, `Isaac64(seed::AbstractString)` use the bytes in `seed`
to seed the generator

### Methods

- `isaac_rand(rng::Union{Isaac32, Isaac64})` provides underlying access to the next
value generated (either `UInt32` or `UInt64`. This method is not exported.
- `Random.seed!(rng::Union{Isaac32, Isaac64}, seed)` will re-seed `rng` with `seed`.
This is used by the constructors, and `seed` can have the same types as in the constructors.
- `rand(rng::Union{Isaac32, Isaac64}, ::Type{T}, n = (1, ))` where `T` can be any of the
types available to the standard Julia `Random.rand(...)` methods.
- Other methods such as `randn(rng::Union{Isaac32, Isaac64},...)`,
`shuffle(rng::Union{Isaac32, Isaac64},...)` are accessible if `Random` is `use`d
or `import`ed.

## License

Most of the original code is marked as being in the public domain.
This version has been released under the [MIT License](https://mit-license.org/),
which is intended to mean that whatever is working should be accredited to
Robert J. Jenkins Jr. Whatever is broken is probably my fault.
