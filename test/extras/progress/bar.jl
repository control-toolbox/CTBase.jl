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
using .TestRunner: _bar_width, _progress_bar, _format_progress_line, TestRunInfo

# ============================================================================
# Block character samples
# ============================================================================

println("=" ^ 60)
println("BLOCK CHARACTER SAMPLES")
println("=" ^ 60)

blocks = [
    ("█", "Full block (U+2588)"),
    ("▓", "Dark shade (U+2593)"),
    ("▒", "Medium shade (U+2592)"),
    ("░", "Light shade (U+2591)"),
    ("▌", "Left half block (U+258C)"),
    ("▐", "Right half block (U+2590)"),
    ("▍", "Left 3/8 block (U+258D)"),
    ("▎", "Left 1/4 block (U+258E)"),
    ("▏", "Left 1/8 block (U+258F)"),
]

for (ch, desc) in blocks
    println("  $(desc)")
    for w in [5, 10, 15, 20]
        bar = "[" * repeat(ch, w) * "]"
        println("    w=$(lpad(w, 2)): $bar")
    end
    println()
end

# Filled + empty combos
println("--- Filled + empty combos (half-filled, w=20) ---")
combos = [
    ("█", "░"),
    ("▓", "░"),
    ("▌", "░"),
    ("▍", " "),
    ("▎", " "),
    ("█", "·"),
    ("█", "─"),
]

for (filled, empty) in combos
    bar = "[" * repeat(filled, 10) * repeat(empty, 10) * "]"
    println("  $filled + $empty : $bar")
end

println()

# ============================================================================
# Simulate progress bar display for different test counts
# ============================================================================

println("=" ^ 60)
println("PROGRESS BAR VISUAL SIMULATION")
println("=" ^ 60)

function simulate_progress(total_tests::Int)
    println("\n--- $total_tests tests ---")
    
    # Show a few representative progress points
    points = if total_tests <= 20
        collect(1:total_tests)
    elseif total_tests <= 50
        [1, 5, 10, 25, 40, total_tests]
    elseif total_tests <= 100
        [1, 10, 25, 50, 75, total_tests]
    elseif total_tests <= 200
        [1, 20, 50, 100, 150, total_tests]
    else
        [1, 50, 100, 200, 400, total_tests]
    end
    
    for i in points
        if i > total_tests
            continue
        end
        
        # Simulate different statuses
        status = if i == 1
            :post_eval  # success
        elseif i == total_tests
            :test_failed  # failure
        else
            :post_eval  # success
        end
        
        elapsed = 0.1 + (i * 0.05)  # fake elapsed time
        spec = "suite/test_file_$(lpad(i, 3)).jl"
        
        info = TestRunInfo(
            Symbol(spec), 
            "/tmp/$(spec)", 
            Symbol("test_$(i)"),
            i, total_tests, status, nothing, elapsed
        )
        
        buf = IOBuffer()
        _format_progress_line(buf, info)
        line = String(take!(buf))
        println(line)
    end
end

# Simulate different test counts including edge cases
for total in [5, 10, 20, 21, 30, 50, 100, 200, 500]
    simulate_progress(total)
end

println("\n" * "=" ^ 60)
println("Done.")