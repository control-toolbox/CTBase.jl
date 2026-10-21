"""
Unit and integration tests for the CTBaseMooncake extension: the AD inputs of
`CTBase.Differentiation` are materialized for `AutoMooncake` when they are views of host
arrays (CTFlows.jl#448).
"""

module TestMooncakeExtension

using Test: Test
using ForwardDiff: ForwardDiff  # reference backend (AutoForwardDiff)
using Mooncake: Mooncake        # activates CTBaseMooncake and the DI Mooncake extension
using CTBase: CTBase
using CTBase: Data
using CTBase: Differentiation
using ADTypes: ADTypes
using DifferentiationInterface: DifferentiationInterface

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fakes (module top-level)
# ==============================================================================

# H(x, p) = ½‖p‖² + Σ sin xᵢ → ∂H/∂x = cos.(x), ∂H/∂p = p
const FAKE_H = Data.Hamiltonian((x, p) -> sum(abs2, p) / 2 + sum(sin, x))

# H(x, p, v) = ½‖p‖² + v₁ Σ sin xᵢ → ∂H/∂v = [Σ sin xᵢ]
const FAKE_H_V = Data.Hamiltonian(
    (x, p, v) -> sum(abs2, p) / 2 + v[1] * sum(sin, x); is_variable=true
)

# H̃(x, p, u) = p·u - ½‖u‖² + Σ sin xᵢ
const FAKE_H̃ = Data.PseudoHamiltonian(
    (x, p, u) -> sum(p .* u) - sum(abs2, u) / 2 + sum(sin, x)
)

# H̃(x, p, u, v) = p·u + v₁ Σ sin xᵢ
const FAKE_H̃_V = Data.PseudoHamiltonian(
    (x, p, u, v) -> sum(p .* u) + v[1] * sum(sin, x); is_variable=true
)

_fake_scalar(a, c) = sum(sin, a) * sum(c)
_fake_vector(a, c) = sin.(a) .* sum(c)
_fake_sum_sin(z) = sum(sin, z)

const FD = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoForwardDiff())
const MC = Differentiation.DifferentiationInterface(; ad_backend=ADTypes.AutoMooncake())

# views of host arrays, as a Hamiltonian splitter builds them: u = [x; p], w = [v; junk]
const U = [0.3, -0.7, 1.0, 0.5]
const X, P = view(U, 1:2), view(U, 3:4)
const V = view([0.5, 9.0], 1:1)
const UC = view([0.2, 0.1, 9.0], 1:2)

# entry point => arguments after the backend
const CALLS = (
    "hamiltonian_gradient" => (Differentiation.hamiltonian_gradient, (FAKE_H, 0.0, X, P, nothing)),
    "variable_gradient" => (Differentiation.variable_gradient, (FAKE_H_V, 0.0, X, P, V)),
    "pseudo_hamiltonian_gradient" =>
        (Differentiation.pseudo_hamiltonian_gradient, (FAKE_H̃, 0.0, X, P, UC, nothing)),
    "pseudo_hamiltonian_control_gradient" => (
        Differentiation.pseudo_hamiltonian_control_gradient, (FAKE_H̃, 0.0, X, P, UC, nothing)
    ),
    "pseudo_variable_gradient" =>
        (Differentiation.pseudo_variable_gradient, (FAKE_H̃_V, 0.0, X, P, UC, V)),
    "gradient" => (Differentiation.gradient, (_fake_sum_sin, X)),
    "differentiate" => (Differentiation.differentiate, (_fake_scalar, Val(1), X, P)),
    "pushforward" => (Differentiation.pushforward, (_fake_vector, Val(1), X, P, P)),
)

_results(r) = r isa Tuple ? r : (r,)

# ==============================================================================
# Test function
# ==============================================================================

function test_mooncake_extension()
    Test.@testset "Mooncake Extension Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@testset "Extension is loaded" begin
            Test.@test Base.get_extension(CTBase, :CTBaseMooncake) isa Module
        end

        # ======================================================================
        # Unit: the tag of a backend and the materialization hook
        # ======================================================================

        Test.@testset "Unit: _ad_tag" begin
            Test.@test Differentiation._ad_tag(ADTypes.AutoMooncake()) ===
                Differentiation.MooncakeTag
            Test.@test Differentiation._ad_tag(ADTypes.AutoForwardDiff()) ===
                Differentiation.GenericADTag
            Test.@test Differentiation._ad_tag(ADTypes.AutoZygote()) ===
                Differentiation.GenericADTag
        end

        Test.@testset "Unit: _materialize keeps inputs for a generic backend" begin
            Test.@test Differentiation._materialize(Differentiation.GenericADTag, X) === X
            Test.@test Differentiation._materialize(Differentiation.GenericADTag, 1.0) === 1.0
        end

        Test.@testset "Unit: _materialize copies host views for Mooncake" begin
            tag = Differentiation.MooncakeTag
            # vector view
            xm = Differentiation._materialize(tag, X)
            Test.@test xm isa Vector{Float64}
            Test.@test xm == X
            Test.@test parent(X) !== xm   # a copy, not the parent
            # row-block view of a matrix (a batch of columns)
            M = [1.0 2.0; 3.0 4.0; 5.0 6.0; 7.0 8.0]
            Mm = Differentiation._materialize(tag, view(M, 1:2, :))
            Test.@test Mm isa Matrix{Float64}
            Test.@test Mm == M[1:2, :]
            # anything else is left untouched
            vec_ = [1.0, 2.0]
            Test.@test Differentiation._materialize(tag, vec_) === vec_
            Test.@test Differentiation._materialize(tag, 1.0) === 1.0
            Test.@test Differentiation._materialize(tag, nothing) === nothing
        end

        # ======================================================================
        # Integration: every entry point, AutoMooncake on host views
        # ======================================================================

        for (name, (fn, args)) in CALLS
            Test.@testset "Integration: $name on host views" begin
                ref = _results(fn(FD, args...))
                res = _results(fn(MC, args...))
                Test.@test length(res) == length(ref)
                for (r, e) in zip(res, ref)
                    Test.@test r isa AbstractArray   # not a Mooncake.Tangent
                    Test.@test r ≈ e
                    Test.@test -r ≈ -e               # what the Hamiltonian RHS needs
                end
            end
        end

        Test.@testset "Integration: hamiltonian_gradient values" begin
            gx, gp = Differentiation.hamiltonian_gradient(MC, FAKE_H, 0.0, X, P, nothing)
            Test.@test gx ≈ cos.(X)
            Test.@test gp ≈ P
        end

        Test.@testset "Integration: matrix row-block views" begin
            Hm = Data.Hamiltonian((x, p) -> sum(abs2, p) / 2 + sum(sin, x))
            Z = [0.3 0.1; -0.7 0.2; 1.0 -1.0; 0.5 0.4]
            Xm, Pm = view(Z, 1:2, :), view(Z, 3:4, :)
            gx, gp = Differentiation.hamiltonian_gradient(MC, Hm, 0.0, Xm, Pm, nothing)
            Test.@test gx isa Matrix{Float64}
            Test.@test gx ≈ cos.(Xm)
            Test.@test gp ≈ Pm
        end

        Test.@testset "Contract: generic backends still receive the views" begin
            # ForwardDiff is unaffected: same result on a view and on its copy
            gx_view, _ = Differentiation.hamiltonian_gradient(FD, FAKE_H, 0.0, X, P, nothing)
            gx_copy, _ = Differentiation.hamiltonian_gradient(
                FD, FAKE_H, 0.0, copy(X), copy(P), nothing
            )
            Test.@test gx_view == gx_copy
        end
    end
    return nothing
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
function test_mooncake_extension()
    return TestMooncakeExtension.test_mooncake_extension()
end
