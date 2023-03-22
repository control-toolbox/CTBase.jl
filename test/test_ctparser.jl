#!/usr/bin/env julia
#
# unit test for ctparser.jl
#

# if it is run interactively
if abspath(PROGRAM_FILE) == @__FILE__
    using Test
    include("../src/ctparser.jl")
    using .CtParser
end

# remark: all tests are independant
#         and define unrelated problems
#         (@def enforces this)

function test_ctparser()

@testset verbose = true "ctparser tests" begin

    @testset "parsing OK" begin

        # variables
        @test @def syntax_only=true :(tf, variable)

        # time
        @test @def syntax_only=true :(t ∈ [ t0, tf ], time)

        # control
        @test @def syntax_only=true :(u, control)
        @test @def syntax_only=true :(v[4], control)
        @test @def syntax_only=true :(w ∈ R^3, control)

        # state
        @test @def syntax_only=true :(x ∈ R^3, state)
        @test @def syntax_only=true :(y, state)
        @test @def syntax_only=true :(z[4], state)

        # objective
        @test @def syntax_only=true :(r(t) -> max)

        # alias
        @test @def syntax_only=true :(r = x[1])
        @test @def syntax_only=true :(v = x₂)
        @test @def syntax_only=true :(m = x₃)

        # constraints
        @test @def syntax_only=true begin
            x(t0) == [ r0, v0, m0 ]
            0  ≤ u(t) ≤ 1
            r0 ≤ x(t)[1],          (1)
            0  ≤ x₂(t) ≤ vmax =>   (c2)
            mf ≤ m(t) ≤ m0    =>   (toto)
        end

        # should pass parsing + evaluation
        t0 = 1.1
        ocp = @def begin
            tf, variable
            t ∈ [ t0, tf ], time
            x ∈ R^3, state
            u, control
            v = x₂
            m = x₃
            0  ≤ u(t) ≤ 1
            mf ≤ m(t) ≤ m0    =>   (mass_constraint)
            r(tf) -> max
        end
        @test ocp isa CtParser.fakemodel

    end

    # error testing
    @testset "parsing errors" begin

        @test_throws "@def parsing error" @def syntax_only=true begin
            t ∈ [ t0, tf ], time
            t ∈ [ t0, tf ], time
        end

        @test_throws "@def parsing error" @def syntax_only=true begin
            u, control
            v, control
        end

        @test_throws "@def parsing error" @def syntax_only=true begin
            u, control
            w ∈ R^3, control
        end

        @test_throws "@def parsing error" @def syntax_only=true begin
            u, state
            v, state
        end

        @test_throws "@def parsing error" @def syntax_only=true begin
            u, state
            x ∈ R^3, state
        end

        @test_throws "@def parsing error" @def syntax_only=true begin
            tf, variable
            tf, variable
        end
    end

end

end


# if it is run interactively
if abspath(PROGRAM_FILE) == @__FILE__
    test_ctparser()
end
