"""
Unit, contract and error tests for `ComposedConstrainedHamiltonian`: the Hamiltonian
h(t,x,p,v) = H(t,x,p,u(t,x,p,v),μ(t,x,p,v),v) of a constrained pseudo-Hamiltonian, a
dynamic closed-loop control law and a multiplier.
"""

module TestComposedConstrainedHamiltonian

using Test: Test
using CTBase: Data
using CTBase: Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fixtures (module top-level)
# ==============================================================================

const LB = 0.1

# H(x,p,u,μ) = p·u − x² + μ·(x − lb): order-one state constraint x ≥ lb of the
# OptimalControl docs; on the boundary arc u = 0 and μ = 2x.
h_bd(x, p, u, μ) = p * u - x^2 + μ * (x - LB)
u_bd(x, p) = 0.0
μ_bd(x, p) = 2x

# Spies recording the arguments of the law and of the multiplier, and how many times
# each is called.
mutable struct SpyLaw <: Function
    last::Any
    calls::Int
end
SpyLaw() = SpyLaw(nothing, 0)
function (s::SpyLaw)(args...)
    s.last = args
    s.calls += 1
    return 1.0
end

mutable struct SpyMultiplier <: Function
    last::Any
    calls::Int
end
SpyMultiplier() = SpyMultiplier(nothing, 0)
function (s::SpyMultiplier)(args...)
    s.last = args
    s.calls += 1
    return 2.0
end

function composed_bd()
    return Data.ComposedConstrainedHamiltonian(
        Data.ConstrainedPseudoHamiltonian(h_bd),
        Data.DynClosedLoop(u_bd),
        Data.Multiplier(μ_bd),
    )
end

function test_composed_constrained_hamiltonian()
    Test.@testset "ComposedConstrainedHamiltonian Tests" verbose = VERBOSE showtiming =
        SHOWTIMING begin

        # ======================================================================
        # UNIT — composition value, natural and uniform calls
        # ======================================================================

        Test.@testset "Unit: composition value (Autonomous, Fixed)" begin
            h = composed_bd()
            # h(x,p) = −x² + 2x(x − lb) = x² − 2 lb x
            x, p = 1.5, 2.0
            Test.@test h(x, p) ≈ x^2 - 2LB * x
            Test.@test h(0.0, x, p, nothing) ≈ x^2 - 2LB * x               # uniform call
            Test.@test h(x, p) == h_bd(x, p, u_bd(x, p), μ_bd(x, p))
        end

        Test.@testset "Unit: on the boundary (g = 0) h equals the unconstrained H̃(u)" begin
            h = composed_bd()
            Test.@test h(LB, 3.0) ≈ 3.0 * u_bd(LB, 3.0) - LB^2
        end

        Test.@testset "Unit: natural call (NonAutonomous, NonFixed), vector μ" begin
            H = Data.ConstrainedPseudoHamiltonian(
                (t, x, p, u, μ, v) -> t * u + sum(μ .* x) + v;
                is_autonomous=false,
                is_variable=true,
            )
            law = Data.DynClosedLoop(
                (t, x, p, v) -> sum(p) * t; is_autonomous=false, is_variable=true
            )
            μ = Data.Multiplier(
                (t, x, p, v) -> v .* p; is_autonomous=false, is_variable=true
            )
            h = Data.ComposedConstrainedHamiltonian(H, law, μ)
            t, x, p, v = 2.0, [1.0, 2.0], [3.0, 4.0], 0.5
            expected = t * (7.0 * t) + sum((v .* p) .* x) + v
            Test.@test h(t, x, p, v) ≈ expected
        end

        # ======================================================================
        # UNIT — getters
        # ======================================================================

        Test.@testset "Unit: getters pseudo_hamiltonian / control_law / multiplier" begin
            H = Data.ConstrainedPseudoHamiltonian(h_bd)
            law = Data.DynClosedLoop(u_bd)
            μ = Data.Multiplier(μ_bd)
            h = Data.ComposedConstrainedHamiltonian(H, law, μ)
            Test.@test Data.pseudo_hamiltonian(h) === H
            Test.@test Data.control_law(h) === law
            Test.@test Data.multiplier(h) === μ
        end

        # ======================================================================
        # UNIT — the law and the multiplier receive (t, x, p, v), once per call (spies)
        # ======================================================================

        Test.@testset "Unit: law and multiplier called once with (t, x, p, v)" begin
            law_spy, μ_spy = SpyLaw(), SpyMultiplier()
            H = Data.ConstrainedPseudoHamiltonian(
                (t, x, p, u, μ, v) -> u + μ; is_autonomous=false, is_variable=true
            )
            h = Data.ComposedConstrainedHamiltonian(
                H,
                Data.DynClosedLoop(law_spy; is_autonomous=false, is_variable=true),
                Data.Multiplier(μ_spy; is_autonomous=false, is_variable=true),
            )
            x, p = [1.0, 2.0], [3.0, 4.0]
            Test.@test h(2.0, x, p, 5.0) == 3.0
            Test.@test law_spy.calls == 1 && μ_spy.calls == 1
            Test.@test law_spy.last == (2.0, x, p, 5.0)
            Test.@test μ_spy.last == (2.0, x, p, 5.0)
        end

        Test.@testset "Unit: an autonomous fixed law and multiplier get their natural arguments" begin
            law_spy, μ_spy = SpyLaw(), SpyMultiplier()
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian((x, p, u, μ) -> u + μ),
                Data.DynClosedLoop(law_spy),
                Data.Multiplier(μ_spy),
            )
            h(1.0, 2.0)                                  # 1-D: scalars stay scalars
            Test.@test law_spy.last == (1.0, 2.0)
            Test.@test μ_spy.last == (1.0, 2.0)
        end

        # ======================================================================
        # UNIT — trait joins over the three inputs (NonAutonomous / NonFixed win)
        # ======================================================================

        Test.@testset "Unit: trait join — all autonomous/fixed ⇒ Autonomous/Fixed" begin
            h = composed_bd()
            Test.@test Traits.time_dependence(h) === Traits.Autonomous
            Test.@test Traits.variable_dependence(h) === Traits.Fixed
        end

        Test.@testset "Unit: trait join — a time-varying multiplier ⇒ NonAutonomous" begin
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(h_bd),
                Data.DynClosedLoop(u_bd),
                Data.Multiplier((t, x, p) -> 2x + t; is_autonomous=false),
            )
            Test.@test Traits.time_dependence(h) === Traits.NonAutonomous
            Test.@test Traits.variable_dependence(h) === Traits.Fixed
            Test.@test h(1.0, 1.5, 2.0) ≈ -1.5^2 + (3.0 + 1.0) * (1.5 - LB)
        end

        Test.@testset "Unit: trait join — a variable law ⇒ NonFixed" begin
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(h_bd),
                Data.DynClosedLoop((x, p, v) -> v; is_variable=true),
                Data.Multiplier(μ_bd),
            )
            Test.@test Traits.time_dependence(h) === Traits.Autonomous
            Test.@test Traits.variable_dependence(h) === Traits.NonFixed
            Test.@test h(1.5, 2.0, 0.5) ≈ 2.0 * 0.5 - 1.5^2 + 3.0 * (1.5 - LB)
        end

        Test.@testset "Unit: trait join — a non-autonomous H ⇒ NonAutonomous" begin
            h = Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(
                    (t, x, p, u, μ) -> t * h_bd(x, p, u, μ); is_autonomous=false
                ),
                Data.DynClosedLoop(u_bd),
                Data.Multiplier(μ_bd),
            )
            Test.@test Traits.time_dependence(h) === Traits.NonAutonomous
            Test.@test h(2.0, 1.5, 2.0) ≈ 2.0 * (1.5^2 - 2LB * 1.5)
        end

        # ======================================================================
        # UNIT — display
        # ======================================================================

        Test.@testset "Unit: Base.show" begin
            h = composed_bd()
            s = sprint(show, h)
            Test.@test occursin("ComposedConstrainedHamiltonian: autonomous", s)
            Test.@test occursin("natural call: h(x, p)", s)
            Test.@test occursin("uniform call: h(t, x, p, v)", s)
            Test.@test sprint(show, MIME"text/plain"(), h) == s
        end

        # ======================================================================
        # CONTRACT — honours the AbstractHamiltonian interface (LSP)
        # ======================================================================

        Test.@testset "Contract: is an AbstractHamiltonian with Hamiltonian dynamics" begin
            h = composed_bd()
            Test.@test h isa Data.AbstractHamiltonian
            Test.@test Traits.dynamics_trait(h) === Traits.HamiltonianDynamics
            Test.@test Traits.has_time_dependence_trait(h) === true
            Test.@test Traits.has_variable_dependence_trait(h) === true
        end

        Test.@testset "Contract: uniform (t,x,p,v) call for every trait combination of the law" begin
            H = Data.ConstrainedPseudoHamiltonian(
                (t, x, p, u, μ, v) -> p * u + μ; is_autonomous=false, is_variable=true
            )
            μ = Data.Multiplier((x, p) -> 1.0)
            laws = (
                Data.DynClosedLoop((x, p) -> -p),
                Data.DynClosedLoop((t, x, p) -> -p; is_autonomous=false),
                Data.DynClosedLoop((x, p, v) -> -p; is_variable=true),
                Data.DynClosedLoop(
                    (t, x, p, v) -> -p; is_autonomous=false, is_variable=true
                ),
            )
            for law in laws
                h = Data.ComposedConstrainedHamiltonian(H, law, μ)
                Test.@test h(0.0, 2.0, 3.0, 4.0) ≈ -9.0 + 1.0
            end
        end

        # ======================================================================
        # UNIT — type stability
        # ======================================================================

        Test.@testset "Unit: calls are type-stable" begin
            h = composed_bd()
            Test.@test (Test.@inferred h(1.5, 2.0)) isa Float64
            Test.@test (Test.@inferred h(0.0, 1.5, 2.0, nothing)) isa Float64
        end

        # ======================================================================
        # ERROR — the constructor rejects what cannot be composed
        # ======================================================================

        Test.@testset "Error: OpenLoop / ClosedLoop laws are rejected" begin
            H = Data.ConstrainedPseudoHamiltonian(h_bd)
            μ = Data.Multiplier(μ_bd)
            Test.@test_throws MethodError Data.ComposedConstrainedHamiltonian(
                H, Data.OpenLoop(t -> 1.0), μ
            )
            Test.@test_throws MethodError Data.ComposedConstrainedHamiltonian(
                H, Data.ClosedLoop(x -> -x), μ
            )
        end

        Test.@testset "Error: a plain function or a PseudoHamiltonian is rejected" begin
            law = Data.DynClosedLoop(u_bd)
            μ = Data.Multiplier(μ_bd)
            Test.@test_throws MethodError Data.ComposedConstrainedHamiltonian(h_bd, law, μ)
            Test.@test_throws MethodError Data.ComposedConstrainedHamiltonian(
                Data.ConstrainedPseudoHamiltonian(h_bd), law, μ_bd
            )
            Test.@test_throws MethodError Data.ComposedConstrainedHamiltonian(
                Data.PseudoHamiltonian((x, p, u) -> p * u), law, μ
            )
        end
    end
end

end # module TestComposedConstrainedHamiltonian

# CRITICAL: Redefine in outer scope for TestRunner
function test_composed_constrained_hamiltonian()
    return TestComposedConstrainedHamiltonian.test_composed_constrained_hamiltonian()
end
