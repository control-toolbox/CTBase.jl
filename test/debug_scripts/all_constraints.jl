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

# all used variables must be definedbefore each test
t0   = 0.0
tf   = 1.0
x0   = 11.11
x02  = 11.111
x0_b = 11.1111
x0_u = 11.11111
y0   = 2.22
y0_b = 2.222
y0_u = 2.2222

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

@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(t0) == x0                => initial_1
    x[2](t0) == x02            => initial_2
    x[2:3](t0) == y0           => initial_3
    x0_b ≤ x(t0) ≤ x0_u        => initial_4
    y0_b ≤ x[2:3](t0) ≤ y0_u   => initial_5
end


# all used variables must be definedbefore each test
xf   = 11.11
xf2  = 11.111
xf_b = 11.1111
xf_u = 11.11111
yf   = 2.22
yf_b = 2.222
yf_u = 2.2222

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

@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(tf) == xf                => final_1
    xf_b ≤ x(tf) ≤ xf_u        => final_2
    x[2](tf) == xf2            => final_3
    x[2:3](tf) == yf           => final_4
    yf_b ≤ x[2:3](tf) ≤ yf_u   => final_5
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
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x(tf) - tf*x(t0) == [ 0, 1 ]            => boundary_1
    [ 0, 1 ] ≤ x(tf) - tf*x(t0) ≤ [ 1, 3 ]  => boundary_2
    x[2](t0)^2 == 1                         => boundary_3
    1 ≤ x[2](t0)^2 ≤ 2                      => boundary_4
    x[2](tf)^2 == 1                         => boundary_5
    1 ≤ x[2](tf)^2 ≤ 2                      => boundary_6

end


# define more variables
u_b  = 1.0
u_u  = 2.0
u2_b = 3.0
u2_u = 4.0
v_b  = 5.0
v_u  = 6.0

println("\n=== control")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u_b ≤ u(t) ≤ u_u
    #u(t) == u_u
    u2_b ≤ u[2](t) ≤ u2_u
    #u[2](t) == u2_u
    v_b ≤ u[2:3](t) ≤ v_u
    #u[2:3](t) == v_u
    u[1](t)^2 + u[2](t)^2 == 1
    1 ≤ u[1](t)^2 + u[2](t)^2 ≤ 2
end
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u_b ≤ u(t) ≤ u_u               => control_1
    #u(t) == u_u                    => control_2
    u2_b ≤ u[2](t) ≤ u2_u          => control_3
    #u[2](t) == u2_u                => control_4
    v_b ≤ u[2:3](t) ≤ v_u          => control_5
    #u[2:3](t) == v_u               => control_6
    u[1](t)^2 + u[2](t)^2 == 1     => control_7
    1 ≤ u[1](t)^2 + u[2](t)^2 ≤ 2  => control_8
end


# more vars
x_b  = 10.0
x_u  = 11.0
x2_b = 13.0
x2_u = 14.0
x_u  = 15.0
y_u  = 16.0

println("\n=== state")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x_b ≤ x(t) ≤ x_u
    #x(t) == x_u
    x2_b ≤ x[2](t) ≤ x2_u
    #x[2](t) == x2_u
    #x[2:3](t) == y_u
    x_u ≤ x[2:3](t) ≤ y_u
    x[1:2](t) + x[3:4](t) == [ -1, 1 ]
    [ -1, 1 ] ≤ x[1:2](t) + x[3:4](t) ≤ [ 0, 2 ]
end

@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x_b ≤ x(t) ≤ x_u                             => state_1
    #x(t) == x_u                                  => state_2
    x2_b ≤ x[2](t) ≤ x2_u                        => state_3
    #x[2](t) == x2_u                              => state_4
    #x[2:3](t) == y_u                             => state_5
    x_u ≤ x[2:3](t) ≤ y_u                        => state_6
    x[1:2](t) + x[3:4](t) == [ -1, 1 ]           => state_7
    [ -1, 1 ] ≤ x[1:2](t) + x[3:4](t) ≤ [ 0, 2 ] => state_8
end


println("\n=== mixed")
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u[2](t) * x[1:2](t) == [ -1, 1 ]
    [ -1, 1 ] ≤ u[2](t) * x[1:2](t) ≤ [ 0, 2 ]
end
@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    u[2](t) * x[1:2](t) == [ -1, 1 ]                       => mixed_1
    [ -1, 1 ] ≤ u[2](t) * x[1:2](t) ≤ [ 0, 2 ]             => mixed_2
end


println("\n=== dynamics")

@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

    x'(t) == 2x(t) + u(t)^2
    x'(t) == f(x(t), u(t))
end


@def begin

    t ∈ [ t0, tf], time
    x ∈ R^3, state
    u ∈ R^3, control

#    x'(t) == 2x(t) + u(t)^2          => dynamics_1
#    x'(t) == f(x(t), u(t))           => dynamics_2
end
