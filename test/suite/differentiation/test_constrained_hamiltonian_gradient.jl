"""
AD tests for the constrained Hamiltonians: the partial derivatives of the maximum
principle (multiplier and control frozen, through `freeze_multiplier`) against the total
derivative of the composed Hamiltonian (`ComposedConstrainedHamiltonian`), with the
DifferentiationInterface backend and ForwardDiff.
"""

module TestConstrainedHamiltonianGradient

using Test: Test
using CTBase: Differentiation
using CTBase: Data
using ADTypes: ADTypes
using ForwardDiff: ForwardDiff
using DifferentiationInterface: DifferentiationInterface

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fixtures (module top-level)
# ==============================================================================

const LB = 0.1

# Order-one state constraint of the OptimalControl docs, written with a 1-D state
# stored in a vector: H(x,p,u,μ) = p·u − x² + μ·(x − lb); boundary arc u = 0, μ = 2x.
h_bd(x, p, u, μ) = p[1] * u - x[1]^2 + μ * (x[1] - LB)
u_bd(x, p) = 0.0
μ_bd(x, p) = 2 * x[1]

# A control law that is not stationary: H = p·u − u² − x² + μ·(x − lb) with u = p, so
# ∂H/∂u = p − 2u = −p ≠ 0.
h_ns(x, p, u, μ) = p[1] * u - u^2 - x[1]^2 + μ * (x[1] - LB)
u_ns(x, p) = p[1]

# Variable-dependent case: H(x,p,u,μ,v) = p·u + μ·v·x, multiplier μ(x,p,v) = v.
h_var(x, p, u, μ, v) = p[1] * u + μ * v * x[1]
μ_var(x, p, v) = v

backend() = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())

function test_constrained_hamiltonian_gradient()
    Test.@testset "Constrained Hamiltonian Gradient Tests" verbose = VERBOSE showtiming =
        SHOWTIMING begin

        # ======================================================================
        # UNIT — partial derivatives through freeze_multiplier
        # ======================================================================

        Test.@testset "Unit: freeze_multiplier gives ∂H/∂x and ∂H/∂p at fixed u and μ" begin
            H = Data.ConstrainedPseudoHamiltonian(h_bd)
            x, p, u, μ = [1.5], [2.0], 0.3, 4.0
            gx, gp = Differentiation.pseudo_hamiltonian_gradient(
                backend(), Data.freeze_multiplier(H, μ), 0.0, x, p, u, nothing
            )
            Test.@test gx ≈ [-2 * x[1] + μ]          # μ constant: no ∂μ/∂x term
            Test.@test gp ≈ [u]
        end

        Test.@testset "Unit: freeze_multiplier with a vector multiplier" begin
            # H = p·x + μ·g(x), g(x) = (x₁ − 1, x₂²)
            H = Data.ConstrainedPseudoHamiltonian(
                (x, p, u, μ) -> sum(p .* x) + μ[1] * (x[1] - 1) + μ[2] * x[2]^2
            )
            x, p, μ = [2.0, 3.0], [1.0, -1.0], [0.5, 0.25]
            gx, gp = Differentiation.pseudo_hamiltonian_gradient(
                backend(), Data.freeze_multiplier(H, μ), 0.0, x, p, 0.0, nothing
            )
            Test.@test gx ≈ p .+ [μ[1], 2 * μ[2] * x[2]]
            Test.@test gp ≈ x
        end

        Test.@testset "Unit: freeze_multiplier, variable gradient at fixed μ" begin
            H = Data.ConstrainedPseudoHamiltonian(h_var; is_variable=true)
            x, p, u, μ, v = [1.5], [2.0], 0.3, 4.0, 0.7
            gv = Differentiation.pseudo_variable_gradient(
                backend(), Data.freeze_multiplier(H, μ), 0.0, x, p, u, v
            )
            Test.@test gv ≈ μ * x[1]
        end

        # ======================================================================
        # UNIT — total derivative of the composed Hamiltonian
        # ======================================================================

        Test.@testset "Unit: the total derivative adds g·∂μ/∂x" begin
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(h_bd),
                Data.DynClosedLoop(u_bd),
                Data.Multiplier(μ_bd),
            )
            x, p = [1.5], [2.0]
            gx, gp = Differentiation.hamiltonian_gradient(backend(), h, 0.0, x, p, nothing)
            # h(x,p) = x² − 2 lb x  ⇒  dh/dx = 2x − 2lb ; partial ∂H/∂x = −2x + μ = 0
            Test.@test gx ≈ [2 * x[1] - 2LB]
            Test.@test gp ≈ [0.0]

            Hfrozen = Data.freeze_multiplier(
                Data.ConstrainedPseudoHamiltonian(h_bd), μ_bd(x, p)
            )
            px, pp = Differentiation.pseudo_hamiltonian_gradient(
                backend(), Hfrozen, 0.0, x, p, u_bd(x, p), nothing
            )
            Test.@test px ≈ [0.0]
            # the gap is exactly g·∂μ/∂x = (x − lb)·2
            Test.@test gx - px ≈ [(x[1] - LB) * 2]
            Test.@test gp ≈ pp
        end

        Test.@testset "Unit: the total derivative adds ∂H/∂u·∂u/∂p for a non-stationary law" begin
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(h_ns),
                Data.DynClosedLoop(u_ns),
                Data.Multiplier(μ_bd),
            )
            x, p = [1.5], [2.0]
            _, gp = Differentiation.hamiltonian_gradient(backend(), h, 0.0, x, p, nothing)
            Hfrozen = Data.freeze_multiplier(
                Data.ConstrainedPseudoHamiltonian(h_ns), μ_bd(x, p)
            )
            _, pp = Differentiation.pseudo_hamiltonian_gradient(
                backend(), Hfrozen, 0.0, x, p, u_ns(x, p), nothing
            )
            Test.@test pp ≈ [u_ns(x, p)]                       # partial: ∂H/∂p = u
            Test.@test gp - pp ≈ [p[1] - 2 * u_ns(x, p)]       # ∂H/∂u · ∂u/∂p, ∂u/∂p = 1
        end

        Test.@testset "Unit: total variable gradient goes through the multiplier" begin
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(h_var; is_variable=true),
                Data.DynClosedLoop((x, p) -> 0.3),
                Data.Multiplier(μ_var; is_variable=true),
            )
            x, p, v = [1.5], [2.0], 0.7
            gv = Differentiation.variable_gradient(backend(), h, 0.0, x, p, v)
            Test.@test gv ≈ 2 * v * x[1]                       # d/dv (v·v·x)
        end

        # ======================================================================
        # NON-REGRESSION — on the optimal boundary arc both derivatives agree
        # ======================================================================

        Test.@testset "Non-regression: total and partial agree on the boundary arc x = lb" begin
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(h_bd),
                Data.DynClosedLoop(u_bd),
                Data.Multiplier(μ_bd),
            )
            x, p = [LB], [0.0]
            gx, gp = Differentiation.hamiltonian_gradient(backend(), h, 0.0, x, p, nothing)
            Hfrozen = Data.freeze_multiplier(
                Data.ConstrainedPseudoHamiltonian(h_bd), μ_bd(x, p)
            )
            px, pp = Differentiation.pseudo_hamiltonian_gradient(
                backend(), Hfrozen, 0.0, x, p, u_bd(x, p), nothing
            )
            Test.@test gx ≈ px atol = 1e-12
            Test.@test gp ≈ pp atol = 1e-12
            Test.@test gx ≈ [0.0] atol = 1e-12                 # ṗ = 0: p stays 0 on the arc
        end
    end
end

end # module TestConstrainedHamiltonianGradient

# CRITICAL: Redefine in outer scope for TestRunner
function test_constrained_hamiltonian_gradient()
    return TestConstrainedHamiltonianGradient.test_constrained_hamiltonian_gradient()
end
