module TestComposedVectorField

using Test: Test
import CTBase.Data: Data
import CTBase.Traits: Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_composed_vector_field()
    Test.@testset "ComposedVectorField Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ── composition value: ClosedLoop and OpenLoop ───────────────────────

        Test.@testset "Unit: ClosedLoop composition g(x) = fc(x, u(x))" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)   # Autonomous, Fixed
            g = Data.ComposedVectorField(fc, Data.ClosedLoop(x -> -x))
            # g(x) = fc(x, -x) = -x - x = -2x
            Test.@test g(3.0) ≈ -6.0                 # natural (x)
            Test.@test g(0.0, 3.0, nothing) ≈ -6.0   # uniform (t,x,v)
        end

        Test.@testset "Unit: OpenLoop composition g(x) = fc(x, u())" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            g = Data.ComposedVectorField(fc, Data.OpenLoop(() -> 2.0))
            # g(x) = fc(x, 2) = -x + 2
            Test.@test g(3.0) ≈ -1.0
        end

        Test.@testset "Unit: getters" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            law = Data.ClosedLoop(x -> -x)
            g = Data.ComposedVectorField(fc, law)
            Test.@test Data.controlled_vector_field(g) === fc
            Test.@test Data.control_law(g) === law
        end

        Test.@testset "Unit: Base.show" begin
            g = Data.ComposedVectorField(
                Data.ControlledVectorField((x, u) -> -x + u), Data.ClosedLoop(x -> -x)
            )
            Test.@test occursin("ComposedVectorField", sprint(show, g))
        end

        # ── trait joins ──────────────────────────────────────────────────────

        Test.@testset "Unit: trait join — both autonomous/fixed" begin
            g = Data.ComposedVectorField(
                Data.ControlledVectorField((x, u) -> -x + u), Data.ClosedLoop(x -> -x)
            )
            Test.@test Traits.time_dependence(g) === Traits.Autonomous
            Test.@test Traits.variable_dependence(g) === Traits.Fixed
        end

        Test.@testset "Unit: trait join — autonomous fc + time-varying law ⇒ NonAutonomous" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            law = Data.ClosedLoop((t, x) -> -x * t; is_autonomous=false)
            g = Data.ComposedVectorField(fc, law)
            Test.@test Traits.time_dependence(g) === Traits.NonAutonomous
            Test.@test Traits.variable_dependence(g) === Traits.Fixed
        end

        Test.@testset "Unit: trait join — variable law ⇒ NonFixed" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            law = Data.ClosedLoop((x, v) -> -x + v; is_variable=true)   # ClosedLoop u(x,v)
            g = Data.ComposedVectorField(fc, law)
            Test.@test Traits.variable_dependence(g) === Traits.NonFixed
            # g(x,v) = fc(x, -x+v) = -x + (-x+v) = -2x + v
            Test.@test g(3.0, 5.0) ≈ -2 * 3.0 + 5.0
        end

        # ── contract: is an out-of-place AbstractVectorField ─────────────────

        Test.@testset "Contract: AbstractVectorField, OutOfPlace, StateDynamics" begin
            g = Data.ComposedVectorField(
                Data.ControlledVectorField((x, u) -> -x + u), Data.ClosedLoop(x -> -x)
            )
            Test.@test g isa Data.AbstractVectorField
            Test.@test Traits.mutability(g) === Traits.OutOfPlace
            Test.@test Traits.dynamics_trait(g) === Traits.StateDynamics
        end

        # ── type stability ───────────────────────────────────────────────────

        Test.@testset "Unit: call is type-stable" begin
            g = Data.ComposedVectorField(
                Data.ControlledVectorField((x, u) -> -x + u), Data.ClosedLoop(x -> -x)
            )
            Test.@test_nowarn Test.@inferred g(3.0)
        end

        # ── error: DynClosedLoop rejected (that is the Hamiltonian path) ──────

        Test.@testset "Error: DynClosedLoop law is rejected" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            Test.@test_throws MethodError Data.ComposedVectorField(
                fc, Data.DynClosedLoop((x, p) -> -p)
            )
        end
    end
end

end # module

test_composed_vector_field() = TestComposedVectorField.test_composed_vector_field()
