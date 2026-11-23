"""
Unit, contract and error tests for `ConstrainedPseudoHamiltonian` (the pseudo-Hamiltonian
of the maximum principle with the multiplier as an explicit argument) and
`freeze_multiplier`.
"""

module TestConstrainedPseudoHamiltonian

using Test: Test
using CTBase: Data
using CTBase: Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fixtures (module top-level)
# ==============================================================================

# H(x,p,u,μ) = p·u − x² + μ·(x − 0.1): the order-one state-constraint example of the
# OptimalControl docs (x ≥ 0.1 adjoined as μ·g with g = x − 0.1 ≥ 0).
h_aut_fixed(x, p, u, μ) = p * u - x^2 + μ * (x - 0.1)
h_naut_fixed(t, x, p, u, μ) = t * p * u + μ * x
h_aut_var(x, p, u, μ, v) = p * u + μ * v
h_naut_var(t, x, p, u, μ, v) = t + sum(x .* p) + u * sum(μ) + v

# A spy: a constrained pseudo-Hamiltonian function that records the arguments it receives
# (used to check what freeze_multiplier forwards).
mutable struct SpyH <: Function
    last::Any
    calls::Int
end
SpyH() = SpyH(nothing, 0)
function (s::SpyH)(args...)
    s.last = args
    s.calls += 1
    return 0.0
end

function test_constrained_pseudo_hamiltonian()
    Test.@testset "ConstrainedPseudoHamiltonian Tests" verbose = VERBOSE showtiming =
        SHOWTIMING begin

        # ======================================================================
        # UNIT — construction and traits
        # ======================================================================

        Test.@testset "Unit: keyword constructor sets the traits" begin
            for (aut, var, TD, VD) in (
                (true, false, Traits.Autonomous, Traits.Fixed),
                (false, false, Traits.NonAutonomous, Traits.Fixed),
                (true, true, Traits.Autonomous, Traits.NonFixed),
                (false, true, Traits.NonAutonomous, Traits.NonFixed),
            )
                H = Data.ConstrainedPseudoHamiltonian(
                    h_aut_fixed; is_autonomous=aut, is_variable=var
                )
                Test.@test Traits.time_dependence(H) === TD
                Test.@test Traits.variable_dependence(H) === VD
            end
        end

        Test.@testset "Unit: default constructor is autonomous and fixed" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_fixed)
            Test.@test Traits.time_dependence(H) === Traits.Autonomous
            Test.@test Traits.variable_dependence(H) === Traits.Fixed
        end

        Test.@testset "Unit: typed constructor" begin
            H = Data.ConstrainedPseudoHamiltonian(
                h_naut_var, Traits.NonAutonomous, Traits.NonFixed
            )
            Test.@test H isa Data.ConstrainedPseudoHamiltonian{
                typeof(h_naut_var),Traits.NonAutonomous,Traits.NonFixed
            }
            Test.@test H.f === h_naut_var
        end

        # ======================================================================
        # UNIT — natural and uniform calls, one per trait combination
        # ======================================================================

        Test.@testset "Unit: calls (Autonomous, Fixed)" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_fixed)
            expected = 2.0 * 0.5 - 1.0^2 + 3.0 * (1.0 - 0.1)
            Test.@test H(1.0, 2.0, 0.5, 3.0) ≈ expected
            Test.@test H(7.0, 1.0, 2.0, 0.5, 3.0, nothing) ≈ expected   # t and v ignored
        end

        Test.@testset "Unit: calls (NonAutonomous, Fixed)" begin
            H = Data.ConstrainedPseudoHamiltonian(h_naut_fixed; is_autonomous=false)
            expected = 2.0 * 3.0 * 4.0 + 5.0 * 1.0
            Test.@test H(2.0, 1.0, 3.0, 4.0, 5.0) ≈ expected
            Test.@test H(2.0, 1.0, 3.0, 4.0, 5.0, nothing) ≈ expected
        end

        Test.@testset "Unit: calls (Autonomous, NonFixed)" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_var; is_variable=true)
            expected = 3.0 * 4.0 + 5.0 * 6.0
            Test.@test H(1.0, 3.0, 4.0, 5.0, 6.0) ≈ expected
            Test.@test H(9.0, 1.0, 3.0, 4.0, 5.0, 6.0) ≈ expected      # t ignored
        end

        Test.@testset "Unit: calls (NonAutonomous, NonFixed), vector x, p and μ" begin
            H = Data.ConstrainedPseudoHamiltonian(
                h_naut_var; is_autonomous=false, is_variable=true
            )
            x, p, μ = [1.0, 2.0], [3.0, 4.0], [0.5, 1.5]
            Test.@test H(1.0, x, p, 2.0, μ, 3.0) ≈ 1.0 + 11.0 + 2.0 * 2.0 + 3.0
        end

        # ======================================================================
        # UNIT — freeze_multiplier
        # ======================================================================

        Test.@testset "Unit: freeze_multiplier returns a PseudoHamiltonian with the traits of H" begin
            for (aut, var) in ((true, false), (false, false), (true, true), (false, true))
                H = Data.ConstrainedPseudoHamiltonian(
                    h_aut_fixed; is_autonomous=aut, is_variable=var
                )
                H̃ = Data.freeze_multiplier(H, 3.0)
                Test.@test H̃ isa Data.PseudoHamiltonian
                Test.@test Traits.time_dependence(H̃) === Traits.time_dependence(H)
                Test.@test Traits.variable_dependence(H̃) === Traits.variable_dependence(H)
            end
        end

        Test.@testset "Unit: freeze_multiplier values, natural and uniform calls" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_fixed)
            H̃ = Data.freeze_multiplier(H, 3.0)
            Test.@test H̃(1.0, 2.0, 0.5) == H(1.0, 2.0, 0.5, 3.0)
            Test.@test H̃(0.0, 1.0, 2.0, 0.5, nothing) == H(1.0, 2.0, 0.5, 3.0)

            Hn = Data.ConstrainedPseudoHamiltonian(h_naut_fixed; is_autonomous=false)
            Test.@test Data.freeze_multiplier(Hn, 5.0)(2.0, 1.0, 3.0, 4.0) ==
                Hn(2.0, 1.0, 3.0, 4.0, 5.0)

            Hv = Data.ConstrainedPseudoHamiltonian(h_aut_var; is_variable=true)
            Test.@test Data.freeze_multiplier(Hv, 5.0)(1.0, 3.0, 4.0, 6.0) ==
                Hv(1.0, 3.0, 4.0, 5.0, 6.0)

            Hnv = Data.ConstrainedPseudoHamiltonian(
                h_naut_var; is_autonomous=false, is_variable=true
            )
            x, p, μ = [1.0, 2.0], [3.0, 4.0], [0.5, 1.5]
            Test.@test Data.freeze_multiplier(Hnv, μ)(1.0, x, p, 2.0, 3.0) ==
                Hnv(1.0, x, p, 2.0, μ, 3.0)
        end

        Test.@testset "Unit: freeze_multiplier forwards the arguments unchanged (spy)" begin
            spy = SpyH()
            H = Data.ConstrainedPseudoHamiltonian(
                spy; is_autonomous=false, is_variable=true
            )
            x, p, u, μ = [1.0, 2.0], [3.0, 4.0], 0.5, [7.0, 8.0]
            Data.freeze_multiplier(H, μ)(2.0, x, p, u, 9.0)
            Test.@test spy.calls == 1
            Test.@test spy.last == (2.0, x, p, u, μ, 9.0)
            Test.@test spy.last[5] === μ                     # the same object, not a copy

            spy1 = SpyH()
            H1 = Data.ConstrainedPseudoHamiltonian(spy1)
            Data.freeze_multiplier(H1, 2.0)(1.0, 3.0, 0.5)   # 1-D: scalars stay scalars
            Test.@test spy1.last == (1.0, 3.0, 0.5, 2.0)
        end

        # ======================================================================
        # UNIT — display
        # ======================================================================

        Test.@testset "Unit: Base.show" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_fixed)
            s = sprint(show, H)
            Test.@test occursin("ConstrainedPseudoHamiltonian: autonomous", s)
            Test.@test occursin("natural call: H(x, p, u, μ)", s)
            Test.@test occursin("uniform call: H(t, x, p, u, μ, v)", s)
            Test.@test sprint(show, MIME"text/plain"(), H) == s

            Hnv = Data.ConstrainedPseudoHamiltonian(
                h_naut_var; is_autonomous=false, is_variable=true
            )
            Test.@test occursin("natural call: H(t, x, p, u, μ, v)", sprint(show, Hnv))
        end

        # ======================================================================
        # CONTRACT — abstract type and traits
        # ======================================================================

        Test.@testset "Contract: subtype of AbstractConstrainedPseudoHamiltonian, not of AbstractPseudoHamiltonian" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_fixed)
            Test.@test isabstracttype(Data.AbstractConstrainedPseudoHamiltonian)
            Test.@test H isa Data.AbstractConstrainedPseudoHamiltonian
            Test.@test !(H isa Data.AbstractPseudoHamiltonian)
            Test.@test Traits.dynamics_trait(H) === Traits.HamiltonianDynamics
            Test.@test Traits.has_time_dependence_trait(H) === true
            Test.@test Traits.has_variable_dependence_trait(H) === true
        end

        # ======================================================================
        # UNIT — type stability
        # ======================================================================

        Test.@testset "Unit: calls are type-stable" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_fixed)
            Test.@test (Test.@inferred H(1.0, 2.0, 0.5, 3.0)) isa Float64
            Test.@test (Test.@inferred H(0.0, 1.0, 2.0, 0.5, 3.0, nothing)) isa Float64
            H̃ = Data.freeze_multiplier(H, 3.0)
            Test.@test (Test.@inferred H̃(1.0, 2.0, 0.5)) isa Float64
            Test.@test (Test.@inferred H̃(0.0, 1.0, 2.0, 0.5, nothing)) isa Float64
        end

        # ======================================================================
        # ERROR — wrong arity
        # ======================================================================

        Test.@testset "Error: a call with the arity of another trait combination" begin
            H = Data.ConstrainedPseudoHamiltonian(h_aut_fixed)
            Test.@test_throws MethodError H(1.0, 2.0, 0.5)                  # μ missing
            H̃ = Data.freeze_multiplier(H, 3.0)
            Test.@test_throws MethodError H̃(1.0, 2.0, 0.5, 3.0)            # μ already frozen
        end
    end
end

end # module TestConstrainedPseudoHamiltonian

# CRITICAL: Redefine in outer scope for TestRunner
function test_constrained_pseudo_hamiltonian()
    return TestConstrainedPseudoHamiltonian.test_constrained_pseudo_hamiltonian()
end
