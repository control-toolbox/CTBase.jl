---
trigger: performance_critical
---

# Julia Performance and Type Stability Standards

## 🤖 **Agent Directive**

**When applying this rule, explicitly state**: "⚡ **Applying Performance Rule**: [specific performance principle being applied]"

This ensures transparency about which performance standard is being used and why.

---

This document defines performance and type stability standards for the Control Toolbox project. Performance-critical code must follow these guidelines to ensure optimal execution speed and memory efficiency.

## Core Principles

1. **Measure First**: Profile before optimizing
2. **Focus on Hot Paths**: Optimize where it matters (inner loops, critical functions)
3. **Type Stability**: Ensure type-stable code (see `type-stability.md`)
4. **Avoid Premature Optimization**: Optimize only when necessary
5. **Maintain Readability**: Don't sacrifice clarity for marginal gains

## Performance Hierarchy

### Critical (Must Optimize)

- Inner loops (called millions of times)
- Numerical computations in solvers
- Hot paths identified by profiling
- Real-time systems

### Important (Should Optimize)

- Frequently called functions
- Data processing pipelines
- API functions with performance requirements

### Low Priority (Optimize if Easy)

- One-time setup code
- User-facing convenience functions
- Error handling paths
- Debugging utilities

## Profiling

### Using Profile.jl

Profile code to identify bottlenecks:

```julia
using Profile

# Profile a function
@profile my_function(args...)

# View results
Profile.print()

# Clear previous results
Profile.clear()

# Profile with more detail
@profile (for i in 1:1000; my_function(args...); end)
```

### Using ProfileView.jl

Visual profiling for better insights:

```julia
using ProfileView

# Profile and visualize
@profview my_function(args...)

# Profile multiple runs
@profview for i in 1:1000
    my_function(args...)
end
```

### Interpreting Results

Look for:
- **Red bars**: Hot spots (most time spent)
- **Wide bars**: Functions called many times
- **Type instabilities**: Yellow/red warnings
- **Allocations**: Memory allocation hot spots

## Benchmarking

### Using BenchmarkTools.jl

Precise performance measurements:

```julia
using BenchmarkTools

# Basic benchmark
@benchmark my_function($args...)

# Compare implementations
b1 = @benchmark old_implementation($args...)
b2 = @benchmark new_implementation($args...)

# Check improvement
judge(median(b2), median(b1))

# Benchmark suite
suite = BenchmarkGroup()
suite["old"] = @benchmarkable old_implementation($args...)
suite["new"] = @benchmarkable new_implementation($args...)
results = run(suite)
```

### Benchmark Best Practices

**✅ Good - Interpolate variables:**

```julia
x = rand(1000)
@benchmark my_function($x)  # $ interpolates x
```

**❌ Bad - Global variables:**

```julia
x = rand(1000)
@benchmark my_function(x)  # x is global, slower
```

**✅ Good - Warm up before benchmarking:**

```julia
# Warm up (compile)
my_function(args...)

# Then benchmark
@benchmark my_function($args...)
```

## Memory Allocations

### Tracking Allocations

```julia
# Count allocations
allocs = @allocated my_function(args...)
println("Allocated: $allocs bytes")

# Detailed allocation tracking
@time my_function(args...)
# Look at "allocations" in output
```

### Reducing Allocations

**✅ Good - Preallocate buffers:**

```julia
function process_data!(output, input)
    # Modify output in-place
    for i in eachindex(input)
        output[i] = input[i]^2
    end
    return output
end

# Preallocate
output = similar(input)
process_data!(output, input)  # No allocations
```

**❌ Bad - Allocate in loop:**

```julia
function process_data(input)
    output = []  # Allocates
    for x in input
        push!(output, x^2)  # Allocates each iteration
    end
    return output
end
```

**✅ Good - Use views instead of copies:**

```julia
# View (no allocation)
sub = @view matrix[1:10, :]

# Copy (allocates)
sub = matrix[1:10, :]
```

**✅ Good - In-place operations:**

```julia
# In-place (no allocation)
A .= B .+ C

# Allocates new array
A = B .+ C
```

## Type Stability

**See:** `.windsurf/rules/type-stability.md` for comprehensive type stability standards.

### Quick Checks

```julia
# Check type stability
@code_warntype my_function(args...)

# Test type stability
using Test
@test_nowarn @inferred my_function(args...)
```

### Common Issues

**❌ Type-unstable:**

```julia
function process(x)
    if x > 0
        return x
    else
        return nothing  # Union{Int, Nothing}
    end
end
```

**✅ Type-stable:**

```julia
function process(x)
    return x > 0 ? x : 0  # Always Int
end
```

## Common Optimizations

### 1. Avoid Global Variables

**❌ Bad - Global variable:**

```julia
global_counter = 0

function increment()
    global global_counter
    global_counter += 1
end
```

**✅ Good - Use Ref or pass as argument:**

```julia
const COUNTER = Ref(0)

function increment()
    COUNTER[] += 1
end

# Or pass as argument
function increment(counter::Ref{Int})
    counter[] += 1
end
```

### 2. Use @inbounds for Bounds-Checked Loops

**Only when you're certain indices are valid:**

```julia
function sum_array(arr)
    s = zero(eltype(arr))
    @inbounds for i in eachindex(arr)
        s += arr[i]
    end
    return s
end
```

**⚠️ Warning:** `@inbounds` disables bounds checking. Use only when safe.

### 3. Use @simd for Vectorization

```julia
function sum_array(arr)
    s = zero(eltype(arr))
    @simd for i in eachindex(arr)
        s += arr[i]
    end
    return s
end
```

### 4. Avoid String Concatenation in Loops

**❌ Bad - Concatenate in loop:**

```julia
function build_string(n)
    s = ""
    for i in 1:n
        s = s * string(i)  # Allocates each iteration
    end
    return s
end
```

**✅ Good - Use IOBuffer:**

```julia
function build_string(n)
    io = IOBuffer()
    for i in 1:n
        print(io, i)
    end
    return String(take!(io))
end
```

### 5. Use StaticArrays for Small Arrays

```julia
using StaticArrays

# Fast for small arrays (< 100 elements)
v = SVector(1.0, 2.0, 3.0)
m = SMatrix{3,3}(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)

# Operations are allocation-free
result = m * v  # No allocation!
```

### 6. Avoid Type Instabilities in Containers

**❌ Bad - Untyped container:**

```julia
results = []  # Vector{Any}
for i in 1:n
    push!(results, compute(i))
end
```

**✅ Good - Typed container:**

```julia
results = Float64[]  # Vector{Float64}
for i in 1:n
    push!(results, compute(i))
end
```

### 7. Use Multiple Dispatch Effectively

**✅ Good - Specialized methods:**

```julia
# Generic fallback
function process(x)
    # Slow generic implementation
end

# Fast specialized method
function process(x::Float64)
    # Fast implementation for Float64
end
```

## Performance Testing

### Allocation Tests

```julia
using Test

@testset "Allocations" begin
    x = rand(1000)
    
    # Test allocation-free
    allocs = @allocated process!(x)
    @test allocs == 0
    
    # Test bounded allocations
    allocs = @allocated build_model(x)
    @test allocs < 1000  # bytes
end
```

### Benchmark Tests

```julia
using BenchmarkTools, Test

@testset "Performance" begin
    x = rand(1000)
    
    # Test execution time
    b = @benchmark process($x)
    @test median(b.times) < 1_000_000  # < 1ms
    
    # Test allocations
    @test b.allocs == 0
end
```

### Regression Tests

```julia
# Save baseline
baseline = @benchmark my_function($args...)
save("baseline.json", baseline)

# Later, check for regressions
current = @benchmark my_function($args...)
baseline = load("baseline.json")

# Fail if >10% slower
@test median(current.times) < 1.1 * median(baseline.times)
```

## Optimization Workflow

### 1. Identify Bottlenecks

```julia
# Profile the code
@profview my_application()

# Identify hot spots
# - Functions taking most time
# - Functions called most often
# - Type instabilities
```

### 2. Measure Baseline

```julia
# Benchmark before optimization
baseline = @benchmark critical_function($args...)
println("Baseline: ", median(baseline.times))
```

### 3. Optimize

Apply optimizations:
- Fix type instabilities
- Reduce allocations
- Use specialized algorithms
- Parallelize if appropriate

### 4. Measure Improvement

```julia
# Benchmark after optimization
optimized = @benchmark critical_function($args...)
println("Optimized: ", median(optimized.times))

# Compare
improvement = median(baseline.times) / median(optimized.times)
println("Speedup: $(round(improvement, digits=2))x")
```

### 5. Verify Correctness

```julia
# Ensure results are still correct
@test optimized_function(args...) ≈ baseline_function(args...)
```

## When NOT to Optimize

### Premature Optimization

**❌ Don't optimize:**
- Before profiling
- Code that runs once
- Code that's already fast enough
- At the expense of readability

**✅ Do optimize:**
- After profiling identifies bottlenecks
- Inner loops and hot paths
- When performance requirements aren't met
- When optimization maintains clarity

### Readability vs Performance

**Balance is key:**

```julia
# Sometimes clear code is better than fast code
function compute_mean(xs)
    return sum(xs) / length(xs)  # Clear and fast enough
end

# Don't over-optimize
function compute_mean_optimized(xs)
    # Complex, hard to maintain, marginal gain
    s = zero(eltype(xs))
    n = 0
    @inbounds @simd for i in eachindex(xs)
        s += xs[i]
        n += 1
    end
    return s / n
end
```

## Parallelization

### Using Threads

```julia
using Base.Threads

# Parallel loop
function parallel_sum(arr)
    sums = zeros(nthreads())
    @threads for i in eachindex(arr)
        sums[threadid()] += arr[i]
    end
    return sum(sums)
end
```

### Using Distributed

```julia
using Distributed

# Add workers
addprocs(4)

# Parallel map
@everywhere function process(x)
    return x^2
end

results = pmap(process, data)
```

### When to Parallelize

**✅ Good candidates:**
- Independent computations
- Large data sets
- CPU-bound tasks
- Embarrassingly parallel problems

**❌ Poor candidates:**
- Small data sets (overhead dominates)
- I/O-bound tasks
- Tasks with dependencies
- Already fast code

## Quality Checklist

Before finalizing performance optimizations:

- [ ] Profiled to identify bottlenecks
- [ ] Benchmarked baseline performance
- [ ] Optimized critical paths only
- [ ] Verified type stability with `@inferred`
- [ ] Tested allocations are acceptable
- [ ] Verified correctness after optimization
- [ ] Documented performance characteristics
- [ ] Added performance tests
- [ ] Maintained code readability
- [ ] Measured actual improvement

## Tools Reference

### Profiling
- `Profile.jl` - Built-in profiling
- `ProfileView.jl` - Visual profiling
- `PProf.jl` - Google pprof format

### Benchmarking
- `BenchmarkTools.jl` - Precise benchmarking
- `@time` - Quick timing
- `@allocated` - Allocation tracking

### Analysis
- `@code_warntype` - Type stability
- `@code_typed` - Inferred types
- `@code_llvm` - LLVM IR
- `@code_native` - Native assembly

### Optimization
- `StaticArrays.jl` - Fast small arrays
- `LoopVectorization.jl` - SIMD optimization
- `SIMD.jl` - Explicit SIMD

## References

- [Julia Performance Tips](https://docs.julialang.org/en/v1/manual/performance-tips/)
- [Profiling](https://docs.julialang.org/en/v1/manual/profile/)
- [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)

## Related Rules

- `.windsurf/rules/type-stability.md` - Type stability standards (critical for performance)
- `.windsurf/rules/testing.md` - Performance testing standards
- `.windsurf/rules/architecture.md` - Architecture patterns that affect performance
