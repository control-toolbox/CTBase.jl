try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Add CTBase in development mode
if !haskey(Pkg.project().dependencies, "CTBase")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTBase
using Test

# ============================================================================
# Exploration: how does Test.get_testset() / anynonpass behave?
# ============================================================================

# Helper functions
function fake_test_with_failure()
    @testset "Fake test" begin
        @test 1 == 1
        @test 1 == 0  # fail
        @test 2 == 2
    end
end

function fake_test_passing()
    @testset "Fake passing" begin
        @test 1 == 1
        @test 2 == 2
    end
end

# Recursive failure detection
function _has_failures(ts::Test.DefaultTestSet)
    ts.anynonpass && return true
    for r in ts.results
        if r isa Test.DefaultTestSet
            _has_failures(r) && return true
        elseif r isa Test.Fail || r isa Test.Error
            return true
        end
    end
    return false
end

# ============================================================================
# EXPLORATION 1: anynonpass + results inspection after eval
# ============================================================================
println("=" ^ 60)
println("EXPLORATION 1: anynonpass + results after eval")
println("=" ^ 60)

try
    @testset "expl1" begin
        @testset "spec_fail" begin
            fake_test_with_failure()
            ts = Test.get_testset()
            println("  [FAIL] anynonpass: $(ts.anynonpass)")
            println("  [FAIL] results count: $(length(ts.results))")
            for (i, r) in enumerate(ts.results)
                if r isa Test.DefaultTestSet
                    println("    result[$i]: desc=$(r.description), anynonpass=$(r.anynonpass), n_passed=$(r.n_passed), results=$(length(r.results))")
                    for (j, rr) in enumerate(r.results)
                        println("      result[$i][$j]: $(typeof(rr))")
                    end
                else
                    println("    result[$i]: $(typeof(r))")
                end
            end
            println("  [FAIL] _has_failures: $(_has_failures(ts))")
        end

        @testset "spec_pass" begin
            fake_test_passing()
            ts = Test.get_testset()
            println("  [PASS] anynonpass: $(ts.anynonpass)")
            println("  [PASS] results count: $(length(ts.results))")
            for (i, r) in enumerate(ts.results)
                if r isa Test.DefaultTestSet
                    println("    result[$i]: desc=$(r.description), anynonpass=$(r.anynonpass), n_passed=$(r.n_passed), results=$(length(r.results))")
                else
                    println("    result[$i]: $(typeof(r))")
                end
            end
            println("  [PASS] _has_failures: $(_has_failures(ts))")
        end
    end
catch e
    println("  (testset threw: $(typeof(e)))")
end

# ============================================================================
# EXPLORATION 2: count Fail/Error types directly in results
# ============================================================================
println()
println("=" ^ 60)
println("EXPLORATION 2: count Fail/Error in results tree")
println("=" ^ 60)

function _count_failures(ts::Test.DefaultTestSet)
    count = 0
    for r in ts.results
        if r isa Test.DefaultTestSet
            count += _count_failures(r)
        elseif r isa Test.Fail || r isa Test.Error
            count += 1
        end
    end
    return count
end

try
    @testset "expl2" begin
        @testset "fail_case" begin
            fake_test_with_failure()
            ts = Test.get_testset()
            println("  [FAIL] _count_failures: $(_count_failures(ts))")
            println("  [FAIL] _has_failures: $(_has_failures(ts))")
        end

        @testset "pass_case" begin
            fake_test_passing()
            ts = Test.get_testset()
            println("  [PASS] _count_failures: $(_count_failures(ts))")
            println("  [PASS] _has_failures: $(_has_failures(ts))")
        end
    end
catch e
    println("  (testset threw: $(typeof(e)))")
end

# ============================================================================
# EXPLORATION 3: before/after results count (most robust approach)
# ============================================================================
println()
println("=" ^ 60)
println("EXPLORATION 3: before/after results count")
println("=" ^ 60)

function _has_failures_in_range(ts::Test.DefaultTestSet, from::Int)
    for i in from:length(ts.results)
        r = ts.results[i]
        if r isa Test.DefaultTestSet
            _has_failures(r) && return true
        elseif r isa Test.Fail || r isa Test.Error
            return true
        end
    end
    return false
end

try
    @testset "expl3" begin
        @testset "fail_before_after" begin
            ts = Test.get_testset()
            n_before = length(ts.results)
            println("  [FAIL] results before eval: $n_before")

            fake_test_with_failure()

            n_after = length(ts.results)
            println("  [FAIL] results after eval: $n_after")
            println("  [FAIL] new results: $(n_after - n_before)")
            has_fail = _has_failures_in_range(ts, n_before + 1)
            println("  [FAIL] _has_failures_in_range: $has_fail")
        end

        @testset "pass_before_after" begin
            ts = Test.get_testset()
            n_before = length(ts.results)
            println("  [PASS] results before eval: $n_before")

            fake_test_passing()

            n_after = length(ts.results)
            println("  [PASS] results after eval: $n_after")
            println("  [PASS] new results: $(n_after - n_before)")
            has_fail = _has_failures_in_range(ts, n_before + 1)
            println("  [PASS] _has_failures_in_range: $has_fail")
        end
    end
catch e
    println("  (testset threw: $(typeof(e)))")
end

# ============================================================================
# EXPLORATION 4: without any enclosing @testset (bare _run_single_test)
# ============================================================================
println()
println("=" ^ 60)
println("EXPLORATION 4: no enclosing @testset")
println("=" ^ 60)

try
    ts = Test.get_testset()
    println("  get_testset() outside @testset: $(typeof(ts))")
catch e
    println("  get_testset() outside @testset throws: $(typeof(e))")
end

println()
println("Done.")
