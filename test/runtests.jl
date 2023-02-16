using CTBase
using Test

#
const vec2vec  = CTBase.vec2vec

#
@testset verbose = true showtiming = true "Base" begin
    for name in (
        "utils",
        )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end
