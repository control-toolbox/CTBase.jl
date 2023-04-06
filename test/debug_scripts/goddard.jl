#!/usr/bin/env julia
#
# Goddard
#

# find local CTBase
basename = '/' * joinpath(split(Base.source_path(), '/')[1:end-3])
println(basename)
using Pkg; Pkg.activate(basename)

using CTBase

Cd = 310
Tmax = 3.5
β = 500
b = 2
N = 100
t0 = 0
r0 = 1
v0 = 0
vmax = 0.1
m0 = 1
mf = 0.6

# Problem definition
ocp = @def verbose_threshold=100 begin

    tf, variable
    t ∈ [ t0, tf ], time
    x ∈ R^3, state
    u ∈ R, control

    r = x₁
    v = x₂
    m = x₃

    x(t0) == [ r0, v0, m0 ]
    0  ≤ u(t) ≤ 1
    0  ≤ r(t),           (1)
    0  ≤ v(t) ≤ vmax,    (2bis)
    mf ≤ m(t) ≤ m0,      (trois)

    ẋ(t) == F0(x(t)) + u(t)*F1(x(t))

    r(tf) -> max

end

function F0(x)
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    F = [ v, -D/m - 1/r^2, 0 ]
    return F
end

function F1(x)
    r, v, m = x
    F = [ 0, Tmax/m, -b*Tmax ]
    return F
end

# print problem definition
println("== Basic problem:")
display(ocp)

#
print_generated_code()
#code_debug_info()
