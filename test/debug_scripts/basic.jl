#!/usr/bin/env julia
#
# basic problem using macros
#

# find local CTBase
basename = '/' * joinpath(split(Base.source_path(), '/')[1:end-3])
println(basename)
using Pkg; Pkg.activate(basename)

using CTBase


t0 = 0.0
tf = 1.0

x0 = [-1, 0]
xf = [ 0, 0]

A = [ 0 1
      0 0 ]
B = [ 0
      1 ]

n = 2

ocp = @def verbose_threshold=50 debug=true begin

    t ∈ [ t0, tf], time
    x ∈ R^n, state
    u ∈ R, control

    x(t0) == x0    => (1)
    x(tf) == xf    ,  (deux)

    ẋ(t) == A*x(t) + B*u(t)

    ∫( 0.5u(t)^2 ) → min

end

# print problem definition
println("== Basic problem:")
display(ocp)
