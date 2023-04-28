using CTBase
using Test
using Plots

# functions and types that are not exported
const vec2vec  = CTBase.vec2vec
const subs = CTBase.subs
const has = CTBase.has
const replace_call = CTBase.replace_call
const constraint_type = CTBase.constraint_type
const input_line_type = CTBase.input_line_type

#
@testset verbose = true showtiming = true "Base" begin
    for name ∈ (
        :callbacks,
        :ctparser_utils,
        :ctparser,
        :ctparser_constraints,
        :onepass,
        :default,
        :descriptions,
        :exceptions,
        :functions,
        :model,
        :plot,
        :print,
        :utils,
        )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end
