using CTBase
using Test
using Plots

# functions and types that are not exported
const vec2vec  = CTBase.vec2vec
const subs = CTBase.subs
const has = CTBase.has
const replace_call = CTBase.replace_call
const constraint_type = CTBase.constraint_type

#
@testset verbose = true showtiming = true "Base" begin
    for name ∈ (
        # :callbacks,
        # :ctparser_utils,
        # #:ctparser,
        # :default,
        # :descriptions,
        # :exceptions,
        # :functions,
        # :model,
        # :plot,
        # :print,
        # :utils,
        :differential_geometry,
        )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end
