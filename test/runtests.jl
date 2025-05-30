#
using Aqua
using JET
using JuliaFormatter
using Documenter

#
using CTBase
using Test

#
@testset verbose = true showtiming = true "Base" begin
    for name in (
        :code_quality,
        # :default,
        # :description,
        # :exceptions,
        # :utils,
    )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            println("testing: ", string(name))
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end
