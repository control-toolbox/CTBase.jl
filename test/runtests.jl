using CTBase
using Test

#
# functions and types that are not exported
const get_priority_print_callbacks = CTBase.get_priority_print_callbacks
const get_priority_stop_callbacks = CTBase.get_priority_stop_callbacks
const vec2vec  = CTBase.vec2vec

#
@testset verbose = true showtiming = true "Base" begin
    for name in (
        "utils",
        "exceptions",
        "callbacks",
        "descriptions",
        "macros",
        "functions",
        )
        @testset "$name" begin
            include("test_$name.jl")
        end
    end
end
