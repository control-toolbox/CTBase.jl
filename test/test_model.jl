function test_model()

# basic model
ocp = Model()
#
n = 2
m = 1
t0 = 0.
tf = 1.
x0 = [-1.0, 0.0]
xf = [ 0.0, 0.0]
#
state!(ocp, n)   # dimension of the state
control!(ocp, m) # dimension of the control
time!(ocp, [t0, tf])
constraint!(ocp, :initial, x0)
constraint!(ocp, :final,   xf)
#
A = [ 0.0 1.0
      0.0 0.0 ]
B = [ 0.0
      1.0 ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2) # default is to minimise

#
@test isautonomous(ocp)
@test dynamics(ocp)(0.0, [0.; 1.], 1.0) ≈ [1.; 1.] atol=1e-8
@test dynamics(ocp)(0.0, [0.; 1.], [1.0]) ≈ [1.; 1.] atol=1e-8
@test lagrange(ocp)(0.0, [0.; 0.], 1.0) ≈ 0.5 atol=1e-8
@test lagrange(ocp)(0.0, [0.; 0.], [1.0]) ≈ 0.5 atol=1e-8
@test mayer(ocp) === nothing
@test ismin(ocp)
@test initial_time(ocp) == t0
@test final_time(ocp) == tf
@test control_dimension(ocp) == m
@test state_dimension(ocp) == n

# -------------------------------------------------------------------------------------------
# 
# goddard (version 1, only nonlinear constraint, i.e. no ranges; no vectorial constraints either)
ocp = Model()
#
Cd = 310.; Tmax = 3.5; β = 500.; b = 2.; t0 = 0.; r0 = 1.; v0 = 0.
vmax = 0.1; m0 = 1.; mf = 0.6; x0 = [r0, v0, m0]
#
m = 1
n = 3
#
time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, n) # state dim
control!(ocp, m) # control dim
constraint!(ocp, :initial, x0)
constraint!(ocp, :control, u -> u[1], 0., 1.)
constraint!(ocp, :mixed, (x, u) -> x[1], r0, Inf, :state_con1)
constraint!(ocp, :mixed, (x, u) -> x[2], 0., vmax, :state_con2)
constraint!(ocp, :mixed, (x, u) -> x[3], m0, mf, :state_con3)
#
objective!(ocp, :mayer,  (t0, x0, tf, xf) -> xf[1], :max)
#
D(x) = Cd * x[2]^2 * exp(-β*(x[1]-1))
F0(x) = [ x[2], -D(x)/x[3]-1/x[1]^2, 0 ]
F1(x) = [ 0, Tmax/x[3], -b*Tmax ]
f(x, u) = F0(x) + u*F1(x)
constraint!(ocp, :dynamics, f)

#
@test isautonomous(ocp)
@test lagrange(ocp) === nothing
@test mayer(ocp)(t0, x0, tf, x0) ≈ x0[1] atol=1e-8
@test !ismin(ocp)
@test initial_time(ocp) == t0
@test final_time(ocp) === nothing
@test control_dimension(ocp) == m
@test state_dimension(ocp) == n

# -------------------------------------------------------------------------------------------
# 
# goddard (version 2, ranges, vectorial constraints)
ocp = Model()
#
Cd = 310.; Tmax = 3.5; β = 500.; b = 2.; t0 = 0.; r0 = 1.; v0 = 0.
vmax = 0.1; m0 = 1.; mf = 0.6; x0 = [r0, v0, m0]
#
m = 1
n = 3
#
time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, n) # state dim
control!(ocp, m) # control dim
constraint!(ocp, :initial, x0, :initial_con1)
constraint!(ocp, :control, 0., 1., :control_con1)
constraint!(ocp, :state, 1:2, [ r0, 0 ], [ Inf, vmax ], :state_con1)
constraint!(ocp, :state, 3, m0, mf, :state_con2)
#
objective!(ocp, :mayer, (t0, x0, tf, xf) -> xf[1], :max)
#
constraint!(ocp, :dynamics, f) # see previous defs

#
@test isautonomous(ocp)
@test lagrange(ocp) === nothing
@test mayer(ocp)(t0, x0, tf, x0) ≈ x0[1] atol=1e-8
@test !ismin(ocp)
@test initial_time(ocp) == t0
@test final_time(ocp) === nothing
@test control_dimension(ocp) == m
@test state_dimension(ocp) == n
@test constraint(ocp, :initial_con1)(x0) == x0 
@test constraint(ocp, :control_con1)(1) == 1 
@test constraint(ocp, :state_con1)(x0) == x0[1:2]
@test constraint(ocp, :state_con2)(x0) == x0[3]

end
