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
BenchmarkTools.Trial: 10000 samples with 492 evaluations.
 Range (min … max):  221.518 ns …  11.205 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     235.602 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   287.003 ns ± 268.401 ns  ┊ GC (mean ± σ):  2.30% ± 3.26%

  █▆▅▆▅▃▁▁▁▁                 ▁▁                                 ▁
  ███████████████▇▇▇▇▇▇█▇▇▇▇█████████▇▇▆▆▆▆▆▆▆▅▆▆▅▆▅▆▅▅▄▄▅▃▃▄▃▃ █
  222 ns        Histogram: log(frequency) by time        780 ns <

 Memory estimate: 112 bytes, allocs estimate: 4.
```

```julia
F = Fun_dim_usage_each_call(((t, x, u)->begin
                x + u[1]
            end))
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 487 evaluations.
 Range (min … max):  219.608 ns …  13.100 μs  ┊ GC (min … max): 0.00% … 96.18%
 Time  (median):     243.357 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   282.687 ns ± 268.154 ns  ┊ GC (mean ± σ):  2.82% ±  3.28%

  █▇▅▆▆▆▄▃▂▂▂▁▁▁▁▁ ▁▁                                           ▂
  ████████████████████████▇▇▇▇▇▇▆▇▇████████▇▇▇▇▆▇▆▅▆▅▅▅▆▅▆▅▆▆▅▅ █
  220 ns        Histogram: log(frequency) by time        664 ns <

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
BenchmarkTools.Trial: 10000 samples with 943 evaluations.
 Range (min … max):  100.929 ns …   7.845 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     113.607 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   154.201 ns ± 217.625 ns  ┊ GC (mean ± σ):  2.17% ± 3.39%

  █▇▆▅▃▃▂▂▂▂▁▁▁▁▁▂▂▃▂▂▁▁                                        ▂
  ██████████████████████████▇▆█▇▇▆▇▆▇▆▆▅▅▆▅▄▄▅▅▅▅▅▄▄▄▃▄▃▃▅▅▅▁▃▃ █
  101 ns        Histogram: log(frequency) by time        590 ns <

 Memory estimate: 64 bytes, allocs estimate: 1.
```

```julia
F = Fun_dim_usage_parametrization{1, 1}(((t, x, u)->begin
                x + u[1]
            end))
@benchmark F(t, x, u)
```

```bash
BenchmarkTools.Trial: 10000 samples with 932 evaluations.
 Range (min … max):  108.153 ns …   9.895 μs  ┊ GC (min … max): 0.00% … 97.64%
 Time  (median):     121.779 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   163.448 ns ± 209.973 ns  ┊ GC (mean ± σ):  2.82% ±  3.41%

  █▇▆▄▃▃▃▂▂▂▂▂▂▂▃▃▃▂▂▁                                          ▂
  ██████████████████████████▇█▇▆▆▆▆▇▅▆▆▄▅▆▅▆▆▅▅▄▅▅▄▅▅▅▄▄▄▃▃▄▁▁▄ █
  108 ns        Histogram: log(frequency) by time        637 ns <

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
 Range (min … max):  23.104 ns … 331.326 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     23.441 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   25.784 ns ±   8.268 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █    ▇   ▁                                                   ▁
  █▇▆█▆█████▅▅▅▄▅▄▄▆▇▆▆▇▇▆▅▆▆▅▆▆▆▆▆▆▇▇▇▇▇▇▇▆▅▃▃▂▂▅▅▄▃▃▅▅▅▄▅▄▃▃ █
  23.1 ns       Histogram: log(frequency) by time      52.7 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

```julia
ψ(t, x, u) = begin
        x + u
    end
@benchmark ψ(t, x[1], u[1])
```

```bash
BenchmarkTools.Trial: 10000 samples with 983 evaluations.
 Range (min … max):  56.845 ns … 624.227 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     57.128 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   65.067 ns ±  20.266 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █▁  ▆▂▁ ▂                                                    ▁
  ███▇█████████▇▆▆▆▆▆▆▆▆▆▆▆▆▆▆▇▇▇▇▆▇█▇▇▇██▇▇▇█▇▆▇▆▆▅▆▆▅▅▅▅▅▅▆▄ █
  56.8 ns       Histogram: log(frequency) by time       130 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

```julia
θ(t, x, u) = begin
        x + u
    end
@benchmark (θ(t, x, u))[1]
```

```bash
BenchmarkTools.Trial: 10000 samples with 965 evaluations.
 Range (min … max):   83.120 ns …   5.867 μs  ┊ GC (min … max): 0.00% … 97.83%
 Time  (median):      94.203 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   123.157 ns ± 151.340 ns  ┊ GC (mean ± σ):  3.19% ±  3.29%

  █▇▇▅▄▃▃▂▂▂▂▁▁▁ ▁▁▁▁▂▂▂▃▂▂▂▁▁                                  ▂
  █████████████████████████████▇▇▇▇▇▆▇▆▇▆▆▆▆▅▆▅▅▆▅▅▅▆▆▅▁▄▅▅▅▃▃▅ █
  83.1 ns       Histogram: log(frequency) by time        408 ns <

 Memory estimate: 64 bytes, allocs estimate: 1.
```

```julia
ξ(t, x, u) = begin
        x + u
    end
a = x[1]
b = u[1]
@benchmark ξ(t, a, b)
```

```bash
BenchmarkTools.Trial: 10000 samples with 996 evaluations.
 Range (min … max):  22.802 ns …  3.982 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     25.470 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   36.790 ns ± 90.791 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █▆▂▃▄▄▃▂▂▁▁▁                                                ▁
  ██████████████████▇▇▇▆▇▆▆▆▅▅▅▅▅▅▄▅▄▅▅▄▄▃▄▅▄▄▄▅▁▄▄▄▁▃▁▁▁▄▃▄▄ █
  22.8 ns      Histogram: log(frequency) by time       182 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

