"""
Unit and error tests for the `pseudo_variable_gradient` AD contract and extension
(∂H̃/∂v with the control `u` held constant).
"""

module TestPseudoVariableGradient

using Test: Test
import CTBase.Differentiation
import CTBase.Data
import CTBase.Traits
import CTBase.Exceptions
import CTBase.Strategies
using ADTypes: ADTypes
using ForwardDiff: ForwardDiff
using DifferentiationInterface: DifferentiationInterface

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fakes (at module top-level)
# ==============================================================================

struct FakeADBackend <: Differentiation.AbstractADBackend
    options::Strategies.StrategyOptions
end

FakeADBackend() = FakeADBackend(Strategies.StrategyOptions())

struct FakePseudoHamiltonian <:
       Data.AbstractPseudoHamiltonian{Traits.Autonomous,Traits.NonFixed}
    f::Function
end

FakePseudoHamiltonian() = FakePseudoHamiltonian((x, p, u, v) -> 0.0)

function test_pseudo_variable_gradient()
    Test.@testset "PseudoVariableGradient Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ==============================================================================
        # Error — NotImplemented stub
        # ==============================================================================

        Test.@testset "Error: pseudo_variable_gradient stub throws NotImplemented" begin
            backend = FakeADBackend()
            h̃ = FakePseudoHamiltonian()
            try
                Differentiation.pseudo_variable_gradient(
                    backend, h̃, 0.0, [1.0, 2.0], [3.0, 4.0], [5.0, 6.0], 7.0
                )
                Test.@test false
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("pseudo_variable_gradient", err.required_method)
            end
        end

        # ==============================================================================
        # Unit — correctness via DI
        # ==============================================================================

        Test.@testset "Unit: ∂H̃/∂v via DI (Autonomous, NonFixed, scalar v)" begin
            backend = Differentiation.DifferentiationInterface(;
                ad_backend=ADTypes.AutoForwardDiff()
            )
            # H̃(x,p,u,v) = p·x + u² + v²·sum(x) ; ∂H̃/∂v = 2v·sum(x)
            h̃ = Data.PseudoHamiltonian(
                (x, p, u, v) -> sum(x .* p) + sum(u .^ 2) + v^2 * sum(x); is_variable=true
            )
            x = [2.0, 1.0]
            grad_v = Differentiation.pseudo_variable_gradient(
                backend, h̃, 0.0, x, [3.0, 4.0], [5.0, 6.0], 4.0
            )
            Test.@test grad_v ≈ 2 * 4.0 * sum(x) atol = 1e-10
        end

        Test.@testset "Unit: ∂H̃/∂v via DI (NonAutonomous, NonFixed, vector v)" begin
            backend = Differentiation.DifferentiationInterface(;
                ad_backend=ADTypes.AutoForwardDiff()
            )
            # H̃(t,x,p,u,v) = t·(p·x) + v[1]² + 3v[2] ; ∂H̃/∂v = [2v[1], 3]
            h̃ = Data.PseudoHamiltonian(
                (t, x, p, u, v) -> t * sum(x .* p) + v[1]^2 + 3 * v[2];
                is_autonomous=false,
                is_variable=true,
            )
            grad_v = Differentiation.pseudo_variable_gradient(
                backend, h̃, 2.0, [1.0, 2.0], [3.0, 4.0], [5.0], [5.0, 9.0]
            )
            Test.@test grad_v ≈ [2 * 5.0, 3.0] atol = 1e-10
        end

        # ==============================================================================
        # Unit — control `u` is held constant (partial, not total, derivative)
        # ==============================================================================

        Test.@testset "Unit: control u is held constant during ∂/∂v" begin
            backend = Differentiation.DifferentiationInterface(;
                ad_backend=ADTypes.AutoForwardDiff()
            )
            # H̃(x,p,u,v) = u²·v + v³ ; with u fixed ⇒ ∂H̃/∂v = u² + 3v²
            h̃ = Data.PseudoHamiltonian((x, p, u, v) -> u^2 * v + v^3; is_variable=true)
            u = 5.0
            v = 4.0
            grad_v = Differentiation.pseudo_variable_gradient(
                backend, h̃, 0.0, [1.0], [2.0], u, v
            )
            # If u were (incorrectly) allowed to vary with v, the u² term would move.
            Test.@test grad_v ≈ u^2 + 3 * v^2 atol = 1e-10
        end

        # ==============================================================================
        # Export
        # ==============================================================================

        Test.@testset "Export: pseudo_variable_gradient" begin
            Test.@test isdefined(Differentiation, :pseudo_variable_gradient)
        end
    end
end

end # module

test_pseudo_variable_gradient() = TestPseudoVariableGradient.test_pseudo_variable_gradient()
