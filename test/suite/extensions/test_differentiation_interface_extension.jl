"""
Unit and integration tests for the CTBaseDifferentiationInterface extension.
"""

module TestDifferentiationInterfaceExtension

import Test
import ForwardDiff  # ensure DI ForwardDiff extension is loaded (AutoForwardDiff backend)
import CTBase: CTBase
import CTBase.Data: Data
import CTBase.Differentiation: Differentiation
import ADTypes
import DifferentiationInterface

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake Hamiltonians for testing (module top-level)
# ==============================================================================

# H(t, x, p) = 0.5*(‖x‖² + ‖p‖²) → ∂H/∂x = x, ∂H/∂p = p
const FAKE_HAMILTONIAN_FIXED = Data.Hamiltonian(
    (x, p) -> 0.5 * (sum(abs2, x) + sum(abs2, p));
    is_autonomous=true, is_variable=false)

# H(t, x, p, v) = 0.5*(‖x‖² + ‖p‖² + ‖v‖²) → ∂H/∂v = v
const FAKE_HAMILTONIAN_NONFIXED = Data.Hamiltonian(
    (x, p, v) -> 0.5 * (sum(abs2, x) + sum(abs2, p) + sum(abs2, v));
    is_autonomous=true, is_variable=true)

# ==============================================================================
# Test function
# ==============================================================================

function test_differentiation_interface_extension()
    Test.@testset "DifferentiationInterface Extension Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        Test.@testset "Integration: hamiltonian_gradient (Fixed)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            v = nothing

            grad_x, grad_p = Differentiation.hamiltonian_gradient(backend, FAKE_HAMILTONIAN_FIXED, t, x, p, v)
            Test.@test grad_x isa AbstractVector
            Test.@test grad_x ≈ x atol=1e-8
            Test.@test grad_p isa AbstractVector
            Test.@test grad_p ≈ p atol=1e-8
        end

        Test.@testset "Integration: variable_gradient (NonFixed)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            v = [5.0, 6.0]

            grad_v = Differentiation.variable_gradient(backend, FAKE_HAMILTONIAN_NONFIXED, t, x, p, v)
            Test.@test grad_v isa AbstractVector
            Test.@test grad_v ≈ v atol=1e-8
        end

        Test.@testset "Integration: gradient (vector input)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            f(x) = sum(x .^ 2)            # ∇f = 2x
            g = Differentiation.gradient(backend, f, [1.0, 2.0])
            Test.@test g isa AbstractVector
            Test.@test g ≈ [2.0, 4.0] atol=1e-8
        end

        Test.@testset "Integration: gradient (scalar overload)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            f(x) = x^3                    # f'(x) = 3x²
            Test.@test Differentiation.gradient(backend, f, 2.0) ≈ 12.0 atol=1e-8
        end

        Test.@testset "Integration: derivative (scalar input)" begin
            backend = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
            g(t) = t^3                    # g'(t) = 3t²
            Test.@test Differentiation.derivative(backend, g, 2.0) ≈ 12.0 atol=1e-8
        end

    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_differentiation_interface_extension() = TestDifferentiationInterfaceExtension.test_differentiation_interface_extension()
