"""
Unit and error tests for pseudo_hamiltonian_gradient and pseudo_hamiltonian_control_gradient AD contracts and extensions.
"""

module TestPseudoHamiltonianGradient

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
# Fake AD Backend for Testing (at module top-level)
# ==============================================================================

struct FakeADBackend <: Differentiation.AbstractADBackend
    options::Strategies.StrategyOptions
end

FakeADBackend() = FakeADBackend(Strategies.StrategyOptions())

# ==============================================================================
# Fake PseudoHamiltonian for Testing (at module top-level)
# ==============================================================================

struct FakePseudoHamiltonian <:
       Data.AbstractPseudoHamiltonian{Traits.Autonomous,Traits.Fixed}
    f::Function
end

FakePseudoHamiltonian() = FakePseudoHamiltonian((x, p, u) -> 0.0)

function test_pseudo_hamiltonian_gradient()
    Test.@testset "PseudoHamiltonian Gradient Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ==============================================================================
        # Error Tests — NotImplemented stubs
        # ==============================================================================

        Test.@testset "Error: pseudo_hamiltonian_gradient stub throws NotImplemented" begin
            backend = FakeADBackend()
            h̃ = FakePseudoHamiltonian()
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = [5.0, 6.0]
            v = 7.0

            try
                Differentiation.pseudo_hamiltonian_gradient(backend, h̃, t, x, p, u, v)
                Test.@test false
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("pseudo_hamiltonian_gradient", err.required_method)
            end
        end

        Test.@testset "Error: pseudo_hamiltonian_control_gradient stub throws NotImplemented" begin
            backend = FakeADBackend()
            h̃ = FakePseudoHamiltonian()
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = [5.0, 6.0]
            v = 7.0

            try
                Differentiation.pseudo_hamiltonian_control_gradient(backend, h̃, t, x, p, u, v)
                Test.@test false
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("pseudo_hamiltonian_control_gradient", err.required_method)
            end
        end

        # ==============================================================================
        # Unit Tests — pseudo_hamiltonian_gradient via DI
        # ==============================================================================

        Test.@testset "Unit: pseudo_hamiltonian_gradient via DI (Autonomous, Fixed)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            h̃ = Data.PseudoHamiltonian((x, p, u) -> sum(x .* p) + sum(u .^ 2))
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = [5.0, 6.0]
            v = nothing

            grad_x, grad_p = Differentiation.pseudo_hamiltonian_gradient(
                backend, h̃, t, x, p, u, v
            )
            # ∂H̃/∂x = p = [3, 4]
            Test.@test grad_x ≈ [3.0, 4.0]
            # ∂H̃/∂p = x = [1, 2]
            Test.@test grad_p ≈ [1.0, 2.0]
        end

        Test.@testset "Unit: pseudo_hamiltonian_gradient via DI (NonAutonomous, Fixed)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            h̃ = Data.PseudoHamiltonian(
                (t, x, p, u) -> t * sum(x .* p) + sum(u .^ 2);
                is_autonomous=false,
            )
            t = 2.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = [5.0, 6.0]
            v = nothing

            grad_x, grad_p = Differentiation.pseudo_hamiltonian_gradient(
                backend, h̃, t, x, p, u, v
            )
            # ∂H̃/∂x = t*p = [6, 8]
            Test.@test grad_x ≈ [6.0, 8.0]
            # ∂H̃/∂p = t*x = [2, 4]
            Test.@test grad_p ≈ [2.0, 4.0]
        end

        Test.@testset "Unit: pseudo_hamiltonian_gradient via DI (Autonomous, NonFixed)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            h̃ = Data.PseudoHamiltonian(
                (x, p, u, v) -> sum(x .* p) + sum(u .^ 2) + v^2;
                is_variable=true,
            )
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = [5.0, 6.0]
            v = 7.0

            grad_x, grad_p = Differentiation.pseudo_hamiltonian_gradient(
                backend, h̃, t, x, p, u, v
            )
            # ∂H̃/∂x = p = [3, 4]
            Test.@test grad_x ≈ [3.0, 4.0]
            # ∂H̃/∂p = x = [1, 2]
            Test.@test grad_p ≈ [1.0, 2.0]
        end

        # ==============================================================================
        # Unit Tests — pseudo_hamiltonian_control_gradient via DI
        # ==============================================================================

        Test.@testset "Unit: pseudo_hamiltonian_control_gradient via DI (Autonomous, Fixed)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            h̃ = Data.PseudoHamiltonian((x, p, u) -> sum(x .* p) + sum(u .^ 2))
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = [5.0, 6.0]
            v = nothing

            grad_u = Differentiation.pseudo_hamiltonian_control_gradient(
                backend, h̃, t, x, p, u, v
            )
            # ∂H̃/∂u = 2u = [10, 12]
            Test.@test grad_u ≈ [10.0, 12.0]
        end

        Test.@testset "Unit: pseudo_hamiltonian_control_gradient via DI (NonAutonomous, Fixed)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            h̃ = Data.PseudoHamiltonian(
                (t, x, p, u) -> t * sum(x .* p) + sum(u .^ 2);
                is_autonomous=false,
            )
            t = 2.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = [5.0, 6.0]
            v = nothing

            grad_u = Differentiation.pseudo_hamiltonian_control_gradient(
                backend, h̃, t, x, p, u, v
            )
            # ∂H̃/∂u = 2u = [10, 12]
            Test.@test grad_u ≈ [10.0, 12.0]
        end

        Test.@testset "Unit: pseudo_hamiltonian_control_gradient via DI (scalar u)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            h̃ = Data.PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            u = 5.0
            v = nothing

            grad_u = Differentiation.pseudo_hamiltonian_control_gradient(
                backend, h̃, t, x, p, u, v
            )
            # ∂H̃/∂u = 2u = 10
            Test.@test grad_u ≈ 10.0
        end

        # ==============================================================================
        # Export Tests
        # ==============================================================================

        Test.@testset "Export: pseudo_hamiltonian_gradient" begin
            Test.@test isdefined(Differentiation, :pseudo_hamiltonian_gradient)
        end

        Test.@testset "Export: pseudo_hamiltonian_control_gradient" begin
            Test.@test isdefined(Differentiation, :pseudo_hamiltonian_control_gradient)
        end
    end
end

end # module

test_pseudo_hamiltonian_gradient() = TestPseudoHamiltonianGradient.test_pseudo_hamiltonian_gradient()
