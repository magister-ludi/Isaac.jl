# Isaac.jl

ISAAC (Indirection, Shift, Accumulate, Add, and Count) generates random numbers.
The original C version was developed by
[Robert J. Jenkins Jr.](https://burtleburtle.net/bob/)
and is available from
the [ISAAC home page](https://burtleburtle.net/bob/rand/isaacafa.html).

How secure is it? See the home page, and pay attention to Jenkins' warning:
> Seeding a random number generator is essentially the same problem as
> encrypting the seed with a block cipher. ISAAC should be initialized
> with the encryption of the seed by some secure cipher.

Most of the original code is marked as being in the public domain.
This version has been released under the [MIT License](https://mit-license.org/),
which is intended to mean that whatever is working should be accredited to
Robert J. Jenkins Jr. Whatever is broken is probably my fault.
