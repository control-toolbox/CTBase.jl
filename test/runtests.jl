using CTBase
using Test
using Aqua
using JET
using JuliaFormatter
using Documenter

# Macro to check if an expression is type-stable and inferred correctly
macro test_inferred(expr)
    q = quote
        try
            @inferred $expr
            @test true
        catch e
            @test false
            println("Error in @inferred: ", e)
        end
    end
    return esc(q)
end

# Main test set running multiple test suites with verbose output and timing information
@testset verbose = true showtiming = true "Base" begin
    for name in (:code_quality, :default, :description, :exceptions, :utils)
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            println("testing: ", string(name))
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end
