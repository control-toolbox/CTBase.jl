#!/usr/bin/env julia
#
# basic problem using macros
#

# find local CTBase
basename = '/' * joinpath(split(Base.source_path(), '/')[1:(end - 3)])
println(basename)
using Pkg;
Pkg.activate(basename);

using CTBase

tf = 1.0

@def verbose_threshold=80 debug=true begin
    t0, variable
    t ∈ [t0, tf], time
    x ∈ R⁹, state

    a = x₁
    b = x₂
    c = x₃
    d = x₄
    e = x₅
    f = x₆
    g = x₇
    h = x₈
    i = x₉

    0 ≤ a(t) ≤ 1
    0 ≤ b(t) ≤ 1
    0 ≤ c(t) ≤ 1
    0 ≤ d(t) ≤ 1
    0 ≤ e(t) ≤ 1
    0 ≤ f(t) ≤ 1
    0 ≤ g(t) ≤ 1
    0 ≤ h(t) ≤ 1
    0 ≤ i(t) ≤ 1

    v(tf) -> min
end
