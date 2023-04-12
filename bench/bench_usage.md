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
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 434 evaluations.
 Range (min … max):  234.207 ns … 377.023 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     273.889 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   526.795 ns ±   4.304 μs  ┊ GC (mean ± σ):  2.39% ± 3.06%

  █▅▄▃▃▅▃▃▃▂▁▁                                                  ▁
  ███████████████▇▇▆▆▆▆▄▆▅▄▅▆▃▅▆▁▄▄▃▄▄▃▃▃▅▄▃▅▅▄▄▃▄▄▃▄▃▃▁▁▃▁▄▁▄▃ █
  234 ns        Histogram: log(frequency) by time       3.29 μs <

 Memory estimate: 112 bytes, allocs estimate: 4.
```

```julia
F = Fun_dim_usage_each_call(((t, x, u)->begin
                x + u[1]
            end))
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 446 evaluations.
 Range (min … max):  230.805 ns …  30.361 μs  ┊ GC (min … max): 0.00% … 98.09%
 Time  (median):     270.235 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   422.936 ns ± 841.898 ns  ┊ GC (mean ± σ):  3.64% ±  3.20%

  █▇▅▄▄▃▃▃▄▄▄▃▃▂▂▁▁▁                                            ▂
  ████████████████████▆▇▇▇▇▆▆▆▅▅▅▅▆▆▅▄▄▄▄▄▁▄▅▃▃▄▄▄▃▄▁▁▅▃▁▃▄▄▁▅▃ █
  231 ns        Histogram: log(frequency) by time       2.14 μs <

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
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 442 evaluations.
 Range (min … max):  233.480 ns …  29.591 μs  ┊ GC (min … max): 0.00% … 98.17%
 Time  (median):     277.251 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   413.440 ns ± 737.225 ns  ┊ GC (mean ± σ):  3.33% ±  3.03%

  █▆                                                             
  ██▆▄▄▃▃▃▃▃▃▃▄▄▃▃▃▃▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▁▂▂▁▂▂▂▂▂▂ ▃
  233 ns           Histogram: frequency by time         1.54 μs <

 Memory estimate: 112 bytes, allocs estimate: 4.
```

```julia
F = Fun_dim_usage_a_priori(((t, x, u)->begin
                x + u[1]
            end), 1, 1)
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 438 evaluations.
 Range (min … max):  230.881 ns … 338.430 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     269.755 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   450.559 ns ±   3.683 μs  ┊ GC (mean ± σ):  4.60% ± 3.07%

  █▇▅▄▄▃▃▃▄▄▄▃▃▂▂▁▁                                             ▂
  ████████████████████▇▇▇▇▇▆▆▆▄▆▅▆▅▅▄▅▅▅▄▃▄▄▃▁▃▄▄▄▄▄▄▃▃▃▃▄▄▁▃▄▃ █
  231 ns        Histogram: log(frequency) by time       2.02 μs <

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
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 925 evaluations.
 Range (min … max):  111.246 ns …   9.630 μs  ┊ GC (min … max): 0.00% … 96.12%
 Time  (median):     135.550 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   209.151 ns ± 326.862 ns  ┊ GC (mean ± σ):  3.94% ±  3.42%

  █▇▅▄▄▃▄▅▅▄▃▃▂▂▂▁▁▁                                            ▂
  ███████████████████▇▇▇▇▇▆▆▆▆▇▆▆▄▁▄▅▄▅▁▅▅▄▃▄▁▄▃▄▃▄▁▃▁▁▃▁▄▃▃▄▃▄ █
  111 ns        Histogram: log(frequency) by time       1.15 μs <

 Memory estimate: 64 bytes, allocs estimate: 1.
```

```julia
F = Fun_dim_usage_parametrization{1, 1}(((t, x, u)->begin
                x + u[1]
            end))
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 918 evaluations.
 Range (min … max):  113.780 ns …  20.294 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     137.759 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   206.425 ns ± 381.734 ns  ┊ GC (mean ± σ):  3.02% ± 3.18%

  ██                                                             
  ███▄▄▄▃▃▃▃▃▄▄▄▄▃▃▃▂▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▁▂▂▂▂▂▂▂▂▂▂▂▂▂ ▃
  114 ns           Histogram: frequency by time          761 ns <

 Memory estimate: 64 bytes, allocs estimate: 1.
```

```julia
ϕ(t, x, u) = begin
        x[1] + u[1]
    end
@benchmark ϕ(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 996 evaluations.
 Range (min … max):  24.253 ns …  1.656 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     26.911 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   34.642 ns ± 43.175 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▇█▅▅ ▁▂▂▃▄▄▄▄▄▃▂                                            ▂
  █████████████████████▇▇▆▇▆▆▆▆▅▆▅▅▆▅▅▆▅▅▄▃▅▄▃▄▅▅▄▄▄▄▄▄▄▃▄▄▅▄ █
  24.3 ns      Histogram: log(frequency) by time       105 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

```julia
ψ(t, x, u) = begin
        x + u
    end
@benchmark ψ(t, x[1], u[1])
```

```bash
BenchmarkTools.Trial: 10000 samples with 984 evaluations.
 Range (min … max):  55.941 ns …  4.534 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     61.862 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   80.037 ns ± 99.571 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▇█▆▄▃▂▂▃▃▃▄▃▄▄▃▃▂▂▂▁                                        ▂
  ██████████████████████▇█▇▇▇▇▇▆▆▇▅▆▅▆▆▄▆▅▆▄▅▄▄▅▄▄▅▆▃▄▃▄▄▁▄▄▃ █
  55.9 ns      Histogram: log(frequency) by time       255 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

```julia
θ(t, x, u) = begin
        x + u
    end
@benchmark (θ(t, x, u))[1]
```

```bash
BenchmarkTools.Trial: 10000 samples with 962 evaluations.
 Range (min … max):   83.980 ns …  16.367 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     104.964 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   169.632 ns ± 378.178 ns  ┊ GC (mean ± σ):  4.90% ± 3.49%

  █▅                                                             
  ██▅▄▄▃▃▃▃▃▄▄▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▁▂▂▂▁▂▂▂ ▂
  84 ns            Histogram: frequency by time          783 ns <

 Memory estimate: 64 bytes, allocs estimate: 1.
```

