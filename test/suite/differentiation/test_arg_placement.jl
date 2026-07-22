"""
Tests for Differentiation.differentiate and Differentiation.pushforward.
"""

module TestArgPlacement

using Test: Test
using ForwardDiff: ForwardDiff  # ensure DI ForwardDiff extension is loaded (AutoForwardDiff backend)
using DifferentiationInterface: DifferentiationInterface   # activates CTBaseDifferentiationInterface extension
import CTBase.Differentiation
import CTBase.Exceptions
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake backend for stub error tests (at module top-level — world-age rule)
# ==============================================================================

struct FakeBackendAP <: Differentiation.AbstractADBackend
    options::Strategies.StrategyOptions
end
FakeBackendAP() = FakeBackendAP(Strategies.StrategyOptions())

# ==============================================================================
# Helper — default backend (AutoForwardDiff via DI)
# ==============================================================================

_default_backend() = Differentiation.DifferentiationInterface()

function test_arg_placement()
    Test.@testset "differentiate/pushforward" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ======================================================================
        # Stub error tests
        # ======================================================================

        Test.@testset "Error: differentiate stub throws NotImplemented" begin
            b = FakeBackendAP()
            f(x) = x^2
            try
                Differentiation.differentiate(b, f, Val(1), 2.0)
                Test.@test false
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("differentiate", err.required_method)
            end
        end

        Test.@testset "Error: pushforward stub throws NotImplemented" begin
            b = FakeBackendAP()
            f(x) = x .^ 2
            try
                Differentiation.pushforward(b, f, Val(1), [1.0, 2.0], [1.0, 0.0])
                Test.@test false
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("pushforward", err.required_method)
            end
        end

        # ======================================================================
        # Differentiation.differentiate — with DI backend
        # ======================================================================

        Test.@testset "differentiate: gradient wrt slot (array active)" begin
            b = _default_backend()
            # H(x, p) = ½‖p‖² + ‖x‖²  →  ∂H/∂x = 2x,  ∂H/∂p = p
            H(x, p) = 0.5 * sum(p .^ 2) + sum(x .^ 2)
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            gx = Differentiation.differentiate(b, H, Val(1), x, p)
            gp = Differentiation.differentiate(b, H, Val(2), p, x)
            Test.@test gx ≈ 2x
            Test.@test gp ≈ p
        end

        Test.@testset "differentiate: derivative wrt slot (scalar active)" begin
            b = _default_backend()
            # f(t, x) = t * x[1]  →  ∂f/∂t = x[1]
            f(t, x) = t * x[1]
            x = [3.0, 4.0]
            t = 2.0
            dt = Differentiation.differentiate(b, f, Val(1), t, x)
            Test.@test dt ≈ x[1]
        end

        Test.@testset "differentiate: 4-arg Hamiltonian (uniform signature)" begin
            b = _default_backend()
            # H(t, x, p, v) = t*v + ½‖p‖² + ‖x‖²
            H(t, x, p, v) = t * v + 0.5 * sum(p .^ 2) + sum(x .^ 2)
            t = 1.0;
            x = [1.0, 2.0];
            p = [3.0, 4.0];
            v = 5.0
            # ∂H/∂x = 2x (slot 2), consts in order t,p,v
            gx = Differentiation.differentiate(b, H, Val(2), x, t, p, v)
            # ∂H/∂p = p (slot 3), consts in order t,x,v
            gp = Differentiation.differentiate(b, H, Val(3), p, t, x, v)
            # ∂H/∂v = t (slot 4, scalar), consts in order t,x,p
            dv = Differentiation.differentiate(b, H, Val(4), v, t, x, p)
            Test.@test gx ≈ 2x
            Test.@test gp ≈ p
            Test.@test dv ≈ t
        end

        # ======================================================================
        # Differentiation.pushforward — with DI backend
        # ======================================================================

        Test.@testset "pushforward: linear vector field (array x)" begin
            b = _default_backend()
            # X(x) = A*x,  J_X = A  →  pushforward(X, x, d) = A*d
            A = [0.0 1.0; -1.0 0.0]
            X(x) = A * x
            x = [1.0, 2.0]
            d = [5.0, 6.0]
            jvp = Differentiation.pushforward(b, X, Val(1), x, d)
            Test.@test jvp ≈ A * d
        end

        Test.@testset "pushforward: scalar function (directional derivative)" begin
            b = _default_backend()
            # f(x) = ‖x‖²,  ∇f = 2x  →  JVP = 2x⋅d
            f(x) = sum(x .^ 2)
            x = [1.0, 2.0]
            d = [3.0, 4.0]
            jvp = Differentiation.pushforward(b, f, Val(1), x, d)
            Test.@test jvp ≈ 2 * sum(x .* d)
        end

        Test.@testset "pushforward: with frozen constant arguments" begin
            b = _default_backend()
            # foo(x, v) = v * x,  active = x (slot 1), const = v
            # JVP: d(v*x)/dx · d = v * d
            foo(x, v) = v .* x
            x = [1.0, 2.0]
            d = [1.0, 0.0]
            v = 3.0
            jvp = Differentiation.pushforward(b, foo, Val(1), x, d, v)
            Test.@test jvp ≈ v .* d
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_arg_placement() = TestArgPlacement.test_arg_placement()
