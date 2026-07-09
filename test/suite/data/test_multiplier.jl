module TestMultiplier

using Test: Test
import CTBase.Data: Data, Multiplier
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_multiplier()
    Test.@testset "Multiplier Tests" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Construction with all trait combinations
        # ====================================================================

        Test.@testset "Unit: construction and trait extractors" begin
            m1 = Multiplier((x, p) -> x[1]; is_autonomous=true, is_variable=false)
            Test.@test m1 isa Data.Multiplier
            Test.@test m1 isa Data.AbstractMultiplier
            Test.@test Traits.time_dependence(m1) === Traits.Autonomous
            Test.@test Traits.variable_dependence(m1) === Traits.Fixed

            m2 = Multiplier(
                (t, x, p, v) -> t + x[1] + p[1] + v[1];
                is_autonomous=false,
                is_variable=true,
            )
            Test.@test Traits.time_dependence(m2) === Traits.NonAutonomous
            Test.@test Traits.variable_dependence(m2) === Traits.NonFixed
        end

        # ====================================================================
        # UNIT TESTS - Natural calls, all trait combos
        # ====================================================================

        Test.@testset "Natural calls" begin
            Test.@test Multiplier((x, p) -> x[1] * p[1])([2.0], [3.0]) == 6.0
            Test.@test Multiplier((t, x, p) -> t + x[1] + p[1]; is_autonomous=false)(
                1.0, [2.0], [3.0]
            ) == 6.0
            Test.@test Multiplier((x, p, v) -> x[1] + p[1] + v[1]; is_variable=true)(
                [2.0], [3.0], [4.0]
            ) == 9.0
            Test.@test Multiplier(
                (t, x, p, v) -> t + x[1] + p[1] + v[1];
                is_autonomous=false,
                is_variable=true,
            )(
                1.0, [2.0], [3.0], [4.0]
            ) == 10.0
        end

        # ====================================================================
        # UNIT TESTS - Uniform call μ(t, x, p, v)
        # ====================================================================

        Test.@testset "Uniform call μ(t, x, p, v)" begin
            t, x, p, v = 1.0, [2.0], [3.0], [4.0]
            Test.@test Multiplier((x, p) -> x[1] + p[1])(t, x, p, v) == 5.0
            Test.@test Multiplier((t, x, p) -> t + x[1] + p[1]; is_autonomous=false)(
                t, x, p, v
            ) == 6.0
            Test.@test Multiplier((x, p, v) -> x[1] + p[1] + v[1]; is_variable=true)(
                t, x, p, v
            ) == 9.0
            # NonAut NonFixed: natural == uniform
            Test.@test Multiplier(
                (t, x, p, v) -> t + x[1] + p[1] + v[1];
                is_autonomous=false,
                is_variable=true,
            )(
                t, x, p, v
            ) == 10.0
        end

        # ====================================================================
        # UNIT TESTS - Typed constructor
        # ====================================================================

        Test.@testset "Typed constructor" begin
            m = Multiplier((x, p) -> x[1], Traits.Autonomous, Traits.Fixed)
            Test.@test m isa Data.AbstractMultiplier
            Test.@test m([5.0], [0.0]) == 5.0
        end

        # ====================================================================
        # UNIT TESTS - show
        # ====================================================================

        Test.@testset "show" begin
            m = Multiplier((x, p) -> x[1])
            str = repr(MIME("text/plain"), m)
            Test.@test occursin("Multiplier: autonomous, fixed (no variable)", str)
            Test.@test occursin("natural call: μ(x, p)", str)
            Test.@test occursin("uniform call: μ(t, x, p, v)", str)

            m2 = Multiplier((t, x, p) -> x[1]; is_autonomous=false)
            str2 = repr(MIME("text/plain"), m2)
            Test.@test occursin("Multiplier: non-autonomous, fixed (no variable)", str2)
            Test.@test occursin("natural call: μ(t, x, p)", str2)
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_multiplier() = TestMultiplier.test_multiplier()
