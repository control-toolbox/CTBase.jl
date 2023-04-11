# Benchmarks for bench_usage.jl

```julia
using BenchmarkTools

struct Fun_dim_usage_each_call
    f::Function
end

function (F::Fun_dim_usage_each_call)(t::Real, x::Vector{<:Real}, u::Vector{<:Real}, args...; kwargs...)
    x_ = if length(x) == 1
            (x[1],)
        else
            (x,)
        end
    u_ = if length(u) == 1
            (u[1],)
        else
            (u,)
        end
    y = F.f(t, x_..., u_..., args...; kwargs...)
    return if y isa Real
            [y]
        else
            y
        end
end

t = 1

x = [10]

u = [100]

F = Fun_dim_usage_each_call(((t, x, u)->begin
                x + u
            end))

@benchmark(y = F(t, x, u))
```

```bash
BenchmarkTools.Trial: 10000 samples with 473 evaluations.
 Range (min … max):  225.903 ns …  11.964 μs  ┊ GC (min … max): 0.00% … 97.66%
 Time  (median):     231.386 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   259.082 ns ± 318.048 ns  ┊ GC (mean ± σ):  3.76% ±  3.07%

  █▇▅▃▃▃▂▁▁                                                     ▁
  █████████▇▇▇▆▆▇▆▆▇▆▆▇▆▆▆▆▅▆▆▆▆▅▆▅▅▅▄▅▆▆▆▅▆▆▆▇▇▆▄▅▄▃▄▄▄▄▄▃▂▄▅▆ █
  226 ns        Histogram: log(frequency) by time        544 ns <

 Memory estimate: 112 bytes, allocs estimate: 4.
```

```julia
F = Fun_dim_usage_each_call(((t, x, u)->begin
                x + u[1]
            end))

@benchmark(y = F(t, x, u))
```

```bash
BenchmarkTools.Trial: 10000 samples with 487 evaluations.
 Range (min … max):  223.530 ns …  10.136 μs  ┊ GC (min … max): 0.00% … 95.86%
 Time  (median):     227.337 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   242.282 ns ± 277.727 ns  ┊ GC (mean ± σ):  3.39% ±  2.91%

  ▇█▆▆▅▃▂▁▁▁▁▁                                                  ▂
  ██████████████▇██▇▇▇▆▆▆▆▆▅▆▄▅▆▄▆▆▆▄▆▄▅▁▄▄▄▆▆▄▅▅▆▅▅▅▁▃▅▃▅▁▅▄▄▄ █
  224 ns        Histogram: log(frequency) by time        376 ns <

 Memory estimate: 112 bytes, allocs estimate: 4.
```

```julia
struct Fun_dim_usage_a_priori
    f::Function
    dim_x::Int
    dim_u::Int
end

function (F::Fun_dim_usage_a_priori)(t::Real, x::Vector{<:Real}, u::Vector{<:Real}, args...; kwargs...)
    x_ = if F.dim_x == 1
            (x[1],)
        else
            (x,)
        end
    u_ = if F.dim_u == 1
            (u[1],)
        else
            (u,)
        end
    y = F.f(t, x_..., u_..., args...; kwargs...)
    return if y isa Real
            [y]
        else
            y
        end
end

F = Fun_dim_usage_a_priori(((t, x, u)->begin
                x + u
            end), 1, 1)

@benchmark(y = F(t, x, u))
```

```bash
BenchmarkTools.Trial: 10000 samples with 464 evaluations.
 Range (min … max):  228.675 ns …  12.414 μs  ┊ GC (min … max): 0.00% … 97.30%
 Time  (median):     232.852 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   250.074 ns ± 300.637 ns  ┊ GC (mean ± σ):  3.55% ±  2.92%

  ██▇▆▃▂▁▂▂▁▂▁ ▁                                                ▂
  ██████████████▇▇▇▇▆▆▇▆▅▆▅▆▆▅▅▅▆▆▆▆▆▅▅▅▆▆▆▅▄▄▄▅▅▁▄▃▃▅▄▃▆▅▃▄▄▃▅ █
  229 ns        Histogram: log(frequency) by time        428 ns <

 Memory estimate: 112 bytes, allocs estimate: 4.
```

```julia
F = Fun_dim_usage_a_priori(((t, x, u)->begin
                x + u[1]
            end), 1, 1)

@benchmark(y = F(t, x, u))
```

```bash
BenchmarkTools.Trial: 10000 samples with 464 evaluations.
 Range (min … max):  226.519 ns …  15.069 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     233.976 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   259.531 ns ± 357.388 ns  ┊ GC (mean ± σ):  3.86% ± 3.07%

  █▇▆▅▄▃▂▂▂                                                     ▁
  ██████████▇▆▇▆▆▇▆▆▆▅▆▄▅▅▅▃▆▅▅▃▅▃▅▄▅▄▄▄▄▄▄▅▅▆▄▄▄▅▄▅▅▅▄▅▄▃▄▅▄▅▄ █
  227 ns        Histogram: log(frequency) by time        552 ns <

 Memory estimate: 112 bytes, allocs estimate: 4.
```

```julia
struct Fun_dim_usage_parametrization{dim_x, dim_u}
    f::Function
end

function (F::Fun_dim_usage_parametrization{1, 1})(t::Real, x::Vector{<:Real}, u::Vector{<:Real}, args...; kwargs...)
    return [F.f(t, x[1], u[1], args...; kwargs...)]
end

F = Fun_dim_usage_parametrization{1, 1}(((t, x, u)->begin
                x + u
            end))

@benchmark(y = F(t, x, u))
```

```bash
BenchmarkTools.Trial: 10000 samples with 939 evaluations.
 Range (min … max):  103.938 ns …   8.970 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     111.108 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   152.761 ns ± 281.435 ns  ┊ GC (mean ± σ):  4.04% ± 3.37%

  █▆▅▄▂▂▂▂▁▁▁▁▁▁▁▁▁▁▂▁▁▁                                        ▂
  ████████████████████████▇▇▇▇▇▇▇▇▇▇▆▇▅▅▄▅▅▆▅▅▅▅▆▅▃▄▃▄▄▅▄▅▁▁▄▃▅ █
  104 ns        Histogram: log(frequency) by time        569 ns <

 Memory estimate: 64 bytes, allocs estimate: 1.
```

```julia
F = Fun_dim_usage_parametrization{1, 1}(((t, x, u)->begin
                x + u[1]
            end))

@benchmark(y = F(t, x, u))
```

```bash
BenchmarkTools.Trial: 10000 samples with 935 evaluations.
 Range (min … max):  104.991 ns …   5.553 μs  ┊ GC (min … max): 0.00% … 97.62%
 Time  (median):     109.975 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   118.983 ns ± 150.853 ns  ┊ GC (mean ± σ):  4.14% ±  3.22%

  ▄█▅▆▅▅▄▄▄▃▃▂▂▂▁▁                                              ▂
  █████████████████▇▇▆▆▆▅▆▆▇▆▆▆▆▄▅▆▅▆▅▅▅▅▄▄▅▃▃▆▅▅▄▅▄▅▅▅▁▅▅▅▅▃▃▄ █
  105 ns        Histogram: log(frequency) by time        203 ns <

 Memory estimate: 64 bytes, allocs estimate: 1.
```

