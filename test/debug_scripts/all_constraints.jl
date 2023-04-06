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

    x(t0) == x0                => initial_1
    x[2](t0) == x02            => initial_2
    x[2:3](t0) == y0           => initial_3
    x0_b ≤ x(t0) ≤ x0_u        => initial_4
    y0_b ≤ x[2:3](t0) ≤ y0_u   => initial_5
    x[2](t0)^2 == 1            => initial_6
    1 ≤ x[2](t0)^2 ≤ 2         => initial_7
end

println("=== final")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(tf) == xf                => final_1
    xf_b ≤ x(tf) ≤ xf_u        => final_2
    x[2](tf) == xf2            => final_3
    x[2:3](tf) == yf           => final_4
    yf_b ≤ x[2:3](tf) ≤ yf_u   => final_5
    x[2](tf)^2 == 1            => final_6
    1 ≤ x[2](tf)^2 ≤ 2         => final_7
end

println("=== boundary")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(tf) - tf*x(t0) == [ 0, 1 ]            => boundary_1
    [ 0, 1 ] ≤ x(tf) - tf*x(t0) ≤ [ 1, 3 ]  => boundary_2
end

println("=== control")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u_b ≤ u(t) ≤ u_u               => control_1
    u2_b ≤ u[2](t) ≤ u2_u          => control_2
    v_b ≤ u[2:3](t) ≤ v_u          => control_3
    u[1](t)^2 + u[2](t)^2 == 1     => control_4
    1 ≤ u[1](t)^2 + u[2](t)^2 ≤ 2  => control_5
end

println("=== state")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    _b ≤ x(t) ≤ x_u                              => state_1
    x2_b ≤ x[2](t) ≤ x2_u                        => state_2
    y_b ≤ x[2:3](t) ≤ y_u                        => state_3
    x[1:2](t) + x[3:4](t) == [ -1, 1 ]           => state_4
    [ -1, 1 ] ≤ x[1:2](t) + x[3:4](t) ≤ [ 0, 2 ] => state_5
end

println("=== mixed")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u[2](t) * x[1:2](t) == [ -1, 1 ]             => mixed_1
    [ -1, 1 ] ≤ u[2](t) * x[1:2](t) ≤ [ 0, 2 ]   => mixed_2
    u[2](t) * x[1:2](t) ≤  [ -1, 1 ]             => mixed_3
    u[2](t) * x[1:2](t) ≥  [ -1, 1 ]             => mixed_4
end

println("=== dynamic")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x'(t) == 2x(t) + u(t)^2          => dynamic_1
    x'(t) == f(x(t), u(t))           => dynamic_2
end
