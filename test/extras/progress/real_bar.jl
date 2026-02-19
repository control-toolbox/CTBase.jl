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

# Include TestRunner directly since extension loading isn't working
include(joinpath(@__DIR__, "..", "..", "..", "ext", "TestRunner.jl"))
using .TestRunner: TestRunInfo, _make_default_on_test_done

println("="^60)
println("REAL PROGRESS BAR SIMULATION")
println("="^60)

function simulate_run(total::Int; failures=Int[], skips=Int[])
    println("\n--- $(total) tests ---")
    cb = _make_default_on_test_done(stdout, total)

    for i in 1:total
        status = if i in failures
            :test_failed
        elseif i in skips
            :skipped
        else
            :post_eval
        end
        info = TestRunInfo(
            Symbol("suite/test_file_$(lpad(i, 3)).jl"),
            "/tmp/test_file_$(lpad(i, 3)).jl",
            Symbol("test_$(i)"),
            i,
            total,
            status,
            nothing,
            0.1 + i * 0.05,
        )
        cb(info)
    end
end

# Full-resolution bar (≤ 50) with a failure and a skip
simulate_run(50; failures=[9, 25, 32, 41], skips=[5, 7, 20, 38])

# Compressed bar (> 50) with multiple failures and skips
#simulate_run(60; failures=[7, 18, 35, 52], skips=[5, 22, 45])

println("\n" * "="^60)
println("Done.")
