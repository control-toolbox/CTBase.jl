#!/usr/bin/env julia
#
# test all constraints
#
# ref: https://github.com/control-toolbox/CTBase.jl/issues/9
#


# find local CTBase
basename = '/' * joinpath(split(Base.source_path(), '/')[1:end-3])
println(basename)
using Pkg; Pkg.activate(basename)

using CTBase

t0 = 0.0
tf = 1.0

println("=== initial")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(t0) == x0
    x[2](t0) == x02
    x[2:3](t0) == y0
    x0_b ≤ x(t0) ≤ x0_u
    y0_b ≤ x[2:3](t0) ≤ y0_u
end

println("\n=== final")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(tf) == xf
    xf_b ≤ x(tf) ≤ xf_u
    x[2](tf) == xf2
    x[2:3](tf) == yf
    yf_b ≤ x[2:3](tf) ≤ yf_u
end

println("\n=== boundary")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(tf) - tf*x(t0) == [ 0, 1 ]
    [ 0, 1 ] ≤ x(tf) - tf*x(t0) ≤ [ 1, 3 ]
    x[2](t0)^2 == 1
    1 ≤ x[2](t0)^2 ≤ 2
    x[2](tf)^2 == 1
    1 ≤ x[2](tf)^2 ≤ 2

end

println("\n=== control")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u_b ≤ u(t) ≤ u_u
    u2_b ≤ u[2](t) ≤ u2_u
    v_b ≤ u[2:3](t) ≤ v_u
    u[1](t)^2 + u[2](t)^2 == 1
    1 ≤ u[1](t)^2 + u[2](t)^2 ≤ 2
end

println("\n=== state")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x_b ≤ x(t) ≤ x_u
    x2_b ≤ x[2](t) ≤ x2_u
    y_b ≤ x[2:3](t) ≤ y_u
    x[1:2](t) + x[3:4](t) == [ -1, 1 ]
    [ -1, 1 ] ≤ x[1:2](t) + x[3:4](t) ≤ [ 0, 2 ]
end

println("\n=== mixed")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u[2](t) * x[1:2](t) == [ -1, 1 ]
    [ -1, 1 ] ≤ u[2](t) * x[1:2](t) ≤ [ 0, 2 ]
end

println("\n=== dynamic")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x'(t) == 2x(t) + u(t)^2
    x'(t) == f(x(t), u(t))
end
