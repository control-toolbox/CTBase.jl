module TestPathConstraint

using Test: Test
import CTBase.Data: Data, PathConstraint, StateConstraint, ControlConstraint, MixedConstraint
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_path_constraint()
    Test.@testset "PathConstraint Tests" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Construction with all trait combinations
        # ====================================================================

        Test.@testset "Unit: construction and trait extractors" begin
            # StateConstraint, Autonomous, Fixed
            g1 = StateConstraint(x -> x[1]; is_autonomous=true, is_variable=false)
            Test.@test g1 isa Data.PathConstraint
            Test.@test Traits.constraint_kind(g1) === Traits.StateConstraintKind
            Test.@test Traits.time_dependence(g1) === Traits.Autonomous
            Test.@test Traits.variable_dependence(g1) === Traits.Fixed
            Test.@test Traits.is_state_constraint(g1)
            Test.@test !Traits.is_control_constraint(g1)
            Test.@test !Traits.is_mixed_constraint(g1)

            # ControlConstraint, NonAutonomous, NonFixed
            g2 = ControlConstraint(
                (t, u, v) -> u[1] + t + v[1]; is_autonomous=false, is_variable=true
            )
            Test.@test Traits.constraint_kind(g2) === Traits.ControlConstraintKind
            Test.@test Traits.time_dependence(g2) === Traits.NonAutonomous
            Test.@test Traits.variable_dependence(g2) === Traits.NonFixed
            Test.@test Traits.is_control_constraint(g2)

            # MixedConstraint, Autonomous, Fixed
            g3 = MixedConstraint((x, u) -> x[1] + u[1])
            Test.@test Traits.constraint_kind(g3) === Traits.MixedConstraintKind
            Test.@test Traits.is_mixed_constraint(g3)
        end

        # ====================================================================
        # UNIT TESTS - Natural calls, all kinds × trait combos
        # ====================================================================

        Test.@testset "Natural calls - StateConstraint" begin
            Test.@test StateConstraint(x -> 2x[1])([3.0]) == 6.0
            Test.@test StateConstraint((t, x) -> t + x[1]; is_autonomous=false)(1.0, [2.0]) ==
                3.0
            Test.@test StateConstraint((x, v) -> x[1] * v[1]; is_variable=true)(
                [2.0], [5.0]
            ) == 10.0
            Test.@test StateConstraint(
                (t, x, v) -> t + x[1] + v[1]; is_autonomous=false, is_variable=true
            )(
                1.0, [2.0], [3.0]
            ) == 6.0
        end

        Test.@testset "Natural calls - ControlConstraint" begin
            Test.@test ControlConstraint(u -> 2u[1])([3.0]) == 6.0
            Test.@test ControlConstraint((t, u) -> t + u[1]; is_autonomous=false)(
                1.0, [2.0]
            ) == 3.0
            Test.@test ControlConstraint((u, v) -> u[1] * v[1]; is_variable=true)(
                [2.0], [5.0]
            ) == 10.0
        end

        Test.@testset "Natural calls - MixedConstraint" begin
            Test.@test MixedConstraint((x, u) -> x[1] + u[1])([2.0], [3.0]) == 5.0
            Test.@test MixedConstraint(
                (t, x, u) -> t + x[1] + u[1]; is_autonomous=false
            )(
                1.0, [2.0], [3.0]
            ) == 6.0
            Test.@test MixedConstraint(
                (t, x, u, v) -> t + x[1] + u[1] + v[1];
                is_autonomous=false,
                is_variable=true,
            )(
                1.0, [2.0], [3.0], [4.0]
            ) == 10.0
        end

        # ====================================================================
        # UNIT TESTS - Uniform call g(t, x, u, v)
        # ====================================================================

        Test.@testset "Uniform call g(t, x, u, v)" begin
            t, x, u, v = 1.0, [2.0], [3.0], [4.0]

            # State: ignores u
            Test.@test StateConstraint(x -> x[1])(t, x, u, v) == 2.0
            Test.@test StateConstraint((t, x) -> t + x[1]; is_autonomous=false)(
                t, x, u, v
            ) == 3.0
            Test.@test StateConstraint((x, v) -> x[1] + v[1]; is_variable=true)(
                t, x, u, v
            ) == 6.0
            Test.@test StateConstraint(
                (t, x, v) -> t + x[1] + v[1]; is_autonomous=false, is_variable=true
            )(
                t, x, u, v
            ) == 7.0

            # Control: ignores x
            Test.@test ControlConstraint(u -> u[1])(t, x, u, v) == 3.0
            Test.@test ControlConstraint((t, u) -> t + u[1]; is_autonomous=false)(
                t, x, u, v
            ) == 4.0
            Test.@test ControlConstraint((u, v) -> u[1] + v[1]; is_variable=true)(
                t, x, u, v
            ) == 7.0

            # Mixed
            Test.@test MixedConstraint((x, u) -> x[1] + u[1])(t, x, u, v) == 5.0
            Test.@test MixedConstraint((t, x, u) -> t + x[1] + u[1]; is_autonomous=false)(
                t, x, u, v
            ) == 6.0
            Test.@test MixedConstraint((x, u, v) -> x[1] + u[1] + v[1]; is_variable=true)(
                t, x, u, v
            ) == 9.0
            # Mixed NonAut NonFixed: natural == uniform
            Test.@test MixedConstraint(
                (t, x, u, v) -> t + x[1] + u[1] + v[1];
                is_autonomous=false,
                is_variable=true,
            )(
                t, x, u, v
            ) == 10.0
        end

        # ====================================================================
        # UNIT TESTS - Typed constructor
        # ====================================================================

        Test.@testset "Typed constructor" begin
            g = PathConstraint(
                x -> x[1],
                Traits.StateConstraintKind,
                Traits.Autonomous,
                Traits.Fixed,
            )
            Test.@test g isa Data.AbstractPathConstraint
            Test.@test Traits.constraint_kind(g) === Traits.StateConstraintKind
            Test.@test g([5.0]) == 5.0
        end

        # ====================================================================
        # UNIT TESTS - Subtyping
        # ====================================================================

        Test.@testset "Subtyping" begin
            g = StateConstraint(x -> x[1])
            Test.@test g isa Data.AbstractPathConstraint
            Test.@test typeof(g) <: Data.PathConstraint
        end

        # ====================================================================
        # UNIT TESTS - show
        # ====================================================================

        Test.@testset "show" begin
            g = MixedConstraint((x, u) -> x[1] + u[1])
            str = repr(MIME("text/plain"), g)
            Test.@test occursin("PathConstraint: mixed, autonomous, fixed (no variable)", str)
            Test.@test occursin("natural call: g(x, u)", str)
            Test.@test occursin("uniform call: g(t, x, u, v)", str)

            gs = StateConstraint((t, x, v) -> x[1]; is_autonomous=false, is_variable=true)
            strs = repr(MIME("text/plain"), gs)
            Test.@test occursin("PathConstraint: state, non-autonomous, variable", strs)
            Test.@test occursin("natural call: g(t, x, v)", strs)
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_path_constraint() = TestPathConstraint.test_path_constraint()
