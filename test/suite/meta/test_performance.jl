module TestPerformance

# ==============================================================================
# Performance contract — deterministic allocation guards
# ==============================================================================
#
# This file asserts the *allocation* invariants of CTBase's hot path: the code
# called repeatedly during a solve (field/Hamiltonian/law/constraint
# evaluation, interpolant evaluation, trait reads, option reads).
#
# Why allocations, and why here:
#   - Type-stability is already guarded by `Test.@inferred` tests next to each
#     function. This file guards the complementary property: a change can keep
#     a call type-stable yet start allocating (a stray `collect`, a boxed
#     closure, an abstract field access). `@inferred` would not catch that.
#   - Allocation counts are DETERMINISTIC — no run-to-run noise, independent of
#     the machine / CI runner. So `== 0` (or `== raw`) is a robust assertion,
#     unlike wall-clock time, which must never be asserted in the suite.
#
# Two invariant classes:
#   1. Zero-overhead wrappers — a wrapper call must allocate exactly what the
#      raw wrapped function does (i.e. the wrapper itself adds nothing). We
#      compare wrapper-vs-raw rather than to a magic constant, so the guard is
#      independent of Julia version / word size.
#   2. Zero-allocation reads — interpolant evaluation, trait accessors, and
#      option reads must allocate nothing at all.
#
# Measured baselines when written (2026-07-12): all four wrappers allocate
# exactly the raw function's result vector (80 B here); all reads are 0 B.
#
# This file is intended as a template for the other control-toolbox packages.
# ==============================================================================

using Test: Test
using BenchmarkTools: BenchmarkTools
import CTBase.Data
import CTBase.Traits
import CTBase.Interpolation
import CTBase.Differentiation

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: raw functions to wrap (never define these inside the test function).
# Each wrapper is compared against the corresponding raw function below.
_vf_raw(x) = -x
_ham_raw(x, p) = sum(x .* p)
_cl_raw(x, p) = x .+ p
_pc_raw(x, u) = x .- u

function test_performance()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Performance contract" begin
        x = [1.0, 2.0]
        p = [3.0, 4.0]
        u = [0.5, 0.5]

        # ======================================================================
        # 1. Zero-overhead wrappers: wrapper allocations == raw allocations
        # ======================================================================
        Test.@testset "Zero-overhead wrappers" begin
            vf = Data.VectorField(_vf_raw; is_inplace=false)
            Test.@test (BenchmarkTools.@ballocated $vf($x)) ==
                (BenchmarkTools.@ballocated _vf_raw($x))

            ham = Data.Hamiltonian(_ham_raw)
            Test.@test (BenchmarkTools.@ballocated $ham($x, $p)) ==
                (BenchmarkTools.@ballocated _ham_raw($x, $p))

            cl = Data.ControlLaw(
                _cl_raw, Traits.DynClosedLoopFeedback, Traits.Autonomous, Traits.Fixed
            )
            Test.@test (BenchmarkTools.@ballocated $cl($x, $p)) ==
                (BenchmarkTools.@ballocated _cl_raw($x, $p))

            g = Data.PathConstraint(
                _pc_raw, Traits.MixedConstraintKind, Traits.Autonomous, Traits.Fixed
            )
            Test.@test (BenchmarkTools.@ballocated $g($x, $u)) ==
                (BenchmarkTools.@ballocated _pc_raw($x, $u))
        end

        # ======================================================================
        # 2. Zero-allocation reads: interpolant eval, trait reads, option reads
        # ======================================================================
        Test.@testset "Zero-allocation reads" begin
            interp_l = Interpolation.ctinterpolate(
                [0.0, 1.0, 2.0, 3.0], [1.0, 2.0, 1.5, 3.0]
            )
            Test.@test (BenchmarkTools.@ballocated $interp_l(1.5)) == 0

            interp_c = Interpolation.ctinterpolate_constant(
                [0.0, 1.0, 2.0, 3.0], [1.0, 2.0, 1.5, 3.0]
            )
            Test.@test (BenchmarkTools.@ballocated $interp_c(1.5)) == 0

            vf = Data.VectorField(_vf_raw; is_inplace=false)
            Test.@test (BenchmarkTools.@ballocated Traits.time_dependence($vf)) == 0
            Test.@test (BenchmarkTools.@ballocated Traits.variable_dependence($vf)) == 0

            cl = Data.ControlLaw(
                _cl_raw, Traits.DynClosedLoopFeedback, Traits.Autonomous, Traits.Fixed
            )
            Test.@test (BenchmarkTools.@ballocated Traits.feedback($cl)) == 0

            backend = Differentiation.DifferentiationInterface()
            Test.@test (BenchmarkTools.@ballocated Differentiation.ad_backend($backend)) ==
                0
        end
    end
    return nothing
end

end # module TestPerformance

# CRITICAL: redefine in outer scope so the test runner can call it
test_performance() = TestPerformance.test_performance()
