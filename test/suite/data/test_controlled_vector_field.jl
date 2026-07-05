module TestControlledVectorField

using Test: Test
import CTBase.Data: Data
import CTBase.Traits: Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_controlled_vector_field()
    Test.@testset "ControlledVectorField Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ── construction + traits, all (TD, VD) combinations ─────────────────

        Test.@testset "Unit: construction and traits" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            Test.@test fc isa Data.ControlledVectorField
            Test.@test fc isa Data.AbstractControlledVectorField
            Test.@test Traits.time_dependence(fc) === Traits.Autonomous
            Test.@test Traits.variable_dependence(fc) === Traits.Fixed
            Test.@test Traits.dynamics_trait(fc) === Traits.StateDynamics

            fc2 = Data.ControlledVectorField(
                (t, x, u, v) -> t * x + u + v; is_autonomous=false, is_variable=true
            )
            Test.@test Traits.time_dependence(fc2) === Traits.NonAutonomous
            Test.@test Traits.variable_dependence(fc2) === Traits.NonFixed
        end

        # ── natural + uniform call signatures ────────────────────────────────

        Test.@testset "Unit: natural and uniform calls" begin
            # Autonomous/Fixed: fc(x,u), uniform fc(t,x,u,v)
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            Test.@test fc(3.0, 1.0) ≈ -2.0
            Test.@test fc(0.0, 3.0, 1.0, nothing) ≈ -2.0

            # NonAutonomous/Fixed: fc(t,x,u)
            fct = Data.ControlledVectorField((t, x, u) -> t * x + u; is_autonomous=false)
            Test.@test fct(2.0, 3.0, 1.0) ≈ 7.0
            Test.@test fct(2.0, 3.0, 1.0, nothing) ≈ 7.0   # uniform

            # Autonomous/NonFixed: fc(x,u,v)
            fcv = Data.ControlledVectorField((x, u, v) -> v * x + u; is_variable=true)
            Test.@test fcv(3.0, 1.0, 2.0) ≈ 7.0
            Test.@test fcv(0.0, 3.0, 1.0, 2.0) ≈ 7.0   # uniform

            # NonAutonomous/NonFixed: fc(t,x,u,v) (natural == uniform)
            fctv = Data.ControlledVectorField(
                (t, x, u, v) -> t * v * x + u; is_autonomous=false, is_variable=true
            )
            Test.@test fctv(2.0, 3.0, 1.0, 4.0) ≈ 2 * 4 * 3 + 1
        end

        # ── vector state/control ─────────────────────────────────────────────

        Test.@testset "Unit: vector state and control" begin
            fc = Data.ControlledVectorField((x, u) -> [x[2], u[1]])
            Test.@test fc([1.0, 2.0], [3.0]) ≈ [2.0, 3.0]
        end

        # ── Base.show ────────────────────────────────────────────────────────

        Test.@testset "Unit: Base.show" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            str = sprint(show, fc)
            Test.@test occursin("ControlledVectorField", str)
            Test.@test occursin("fc(x, u)", str)
        end

        # ── type stability of the call ───────────────────────────────────────

        Test.@testset "Unit: call is type-stable" begin
            fc = Data.ControlledVectorField((x, u) -> -x + u)
            Test.@test_nowarn Test.@inferred fc(3.0, 1.0)
        end
    end
end

end # module

test_controlled_vector_field() = TestControlledVectorField.test_controlled_vector_field()
