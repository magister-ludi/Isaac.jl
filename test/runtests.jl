#!/usr/bin/env julia

using Test
using Isaac

@testset "Compare published results" begin
    data =
        parse.(
            UInt32,
            split(join(readlines("rand32seed.txt"), " "), r"\s+", keepempty = false),
            base = 16,
        )
    rctx = Isaac32("This is <i>not</i> the right mytext.")
    n = 0
    for i = 1:10
        for j = 1:(Isaac.RANDSIZ)
            n += 1
            @test data[n] == isaac_rand(rctx)
        end
    end
end

@testset "Compare 64-bit results" begin
    data =
        parse.(
            UInt64,
            split(join(readlines("rand64seed.txt"), " "), r"\s+", keepempty = false),
            base = 16,
        )
    rctx = Isaac64(
        "Die Würde des Menschen ist unantastbar. Sie zu achten und zu schützen ist Verpflichtung aller staatlichen Gewalt.",
    )
    n = 0
    for i = 1:10
        for j = 1:(Isaac.RANDSIZ)
            n += 1
            @test data[n] == isaac_rand(rctx)
        end
    end
end
