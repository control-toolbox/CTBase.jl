function test_model()

@testset "state and control dimensions set or not" begin
    ocp = Model()
    @test CTBase.dims_not_set(ocp)
    state!(ocp, 2)
    @test CTBase.dims_not_set(ocp)
    control!(ocp, 1)
    @test !CTBase.dims_not_set(ocp)
    ocp = Model()
    @test_throws IncorrectArgument objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test_throws IncorrectArgument objective!(ocp, :bolza, (t0, x0, tf, xf) -> tf, (x, u) -> 0.5u^2)
    @test_throws IncorrectArgument nlp_constraints(ocp)
end

@testset "initial and / or final time set" begin
    ocp = Model()
    @test !CTBase.time_set(ocp)
    time!(ocp, :initial, 0)
    @test CTBase.time_set(ocp)
    ocp = Model()
    time!(ocp, :final, 1)
    @test CTBase.time_set(ocp)
    ocp = Model()
    time!(ocp, [0, 1])
    @test CTBase.time_set(ocp)
    ocp = Model()
    time!(ocp, :initial, 0)
    @test_throws UnauthorizedCall time!(ocp, :initial, 0)
    @test_throws UnauthorizedCall time!(ocp, :final, 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
    ocp = Model()
    time!(ocp, :final, 1)
    @test_throws UnauthorizedCall time!(ocp, :initial, 0)
    @test_throws UnauthorizedCall time!(ocp, :final, 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
    ocp = Model()
    time!(ocp, [0, 1])
    @test_throws UnauthorizedCall time!(ocp, :initial, 0)
    @test_throws UnauthorizedCall time!(ocp, :final, 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
end

@testset "Index" begin
    @test Index(1) == Index(1)
    @test Index(1) ≤ Index(2)
    @test Index(1) < Index(2)
    v = [10, 20]
    @test v[Index(1)] == v[1]
    @test_throws MethodError v[Index(1):Index(2)]
    x = 1
    @test x[Index(1)] == x
end

@testset "isautonomous vs isnonautonomous" begin
    ocp = Model()
    @test isautonomous(ocp)
    @test !isnonautonomous(ocp)
    ocp = Model(time_dependence=:nonautonomous)
    @test isnonautonomous(ocp)
    @test !isautonomous(ocp)
end

@testset "ismin vs ismax" begin
    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test ismin(ocp)
    @test !ismax(ocp)
    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :lagrange, (x, u) -> 0.5u^2, :max)
    @test ismax(ocp)
    @test !ismin(ocp)
end

@testset "state!" begin
    ocp = Model()
    state!(ocp, 1)
    @test ocp.state_dimension == 1
    @test ocp.state_names == ["x"]
    ocp = Model()
    state!(ocp, 1, "y")
    @test ocp.state_dimension == 1
    @test ocp.state_names == ["y"]
    ocp = Model()
    state!(ocp, 2)
    @test ocp.state_dimension == 2
    @test ocp.state_names == ["x₁", "x₂"]
    ocp = Model()
    state!(ocp, 2, ["y₁", "y₂"])
    @test ocp.state_dimension == 2
    @test ocp.state_names == ["y₁", "y₂"]
    ocp = Model()
    state!(ocp, 2, :y)
    @test ocp.state_dimension == 2
    @test ocp.state_names == ["y₁", "y₂"]
    ocp = Model()
    state!(ocp, 2, "y")
    @test ocp.state_dimension == 2
    @test ocp.state_names == ["y₁", "y₂"]
end

@testset "control!" begin
    ocp = Model()
    control!(ocp, 1)
    @test ocp.control_dimension == 1
    @test ocp.control_names == ["u"]
    ocp = Model()
    control!(ocp, 1, "v")
    @test ocp.control_dimension == 1
    @test ocp.control_names == ["v"]
    ocp = Model()
    control!(ocp, 2)
    @test ocp.control_dimension == 2
    @test ocp.control_names == ["u₁", "u₂"]
    ocp = Model()
    control!(ocp, 2, ["v₁", "v₂"])
    @test ocp.control_dimension == 2
    @test ocp.control_names == ["v₁", "v₂"]
    ocp = Model()
    control!(ocp, 2, :v)
    @test ocp.control_dimension == 2
    @test ocp.control_names == ["v₁", "v₂"]
    ocp = Model()
    control!(ocp, 2, "v")
    @test ocp.control_dimension == 2
    @test ocp.control_names == ["v₁", "v₂"]
end

@testset "time!" begin
    # initial and final times
    ocp = Model()
    time!(ocp, [0, 1])
    @test ocp.initial_time == 0
    @test ocp.final_time == 1
    @test ocp.time_name == "t"
    ocp = Model()
    time!(ocp, [0, 1], "s")
    @test ocp.initial_time == 0
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
    ocp = Model()
    time!(ocp, [0, 1], :s)
    @test ocp.initial_time == 0
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
    # initial time
    ocp = Model()
    time!(ocp, :initial, 0)
    @test ocp.initial_time == 0
    @test isnothing(ocp.final_time)
    @test ocp.time_name == "t"
    ocp = Model()
    time!(ocp, :initial, 0, "s")
    @test ocp.initial_time == 0
    @test isnothing(ocp.final_time)
    @test ocp.time_name == "s"
    ocp = Model()
    time!(ocp, :initial, 0, :s)
    @test ocp.initial_time == 0
    @test isnothing(ocp.final_time)
    @test ocp.time_name == "s"
    # final time
    ocp = Model()
    time!(ocp, :final, 1)
    @test isnothing(ocp.initial_time)
    @test ocp.final_time == 1
    @test ocp.time_name == "t"
    ocp = Model()
    time!(ocp, :final, 1, "s")
    @test isnothing(ocp.initial_time)
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
    ocp = Model()
    time!(ocp, :final, 1, :s)
    @test isnothing(ocp.initial_time)
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
end

#=
# basic model
ocp = Model(time_dependence=:autonomous)
#
n = 2
m = 1
t0 = 0
tf = 1
x0 = [-1, 0]
xf = [ 0, 0]
#
state!(ocp, n, ["r", "v"])   # dimension of the state
control!(ocp, m) # dimension of the control
time!(ocp, [t0, tf])
constraint!(ocp, :initial, x0)
constraint!(ocp, :final  , xf)
#
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)
objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2) # default is to minimise

#
@test display(ocp) isa Nothing
@test display(ocp.constraints) isa Nothing

@test_throws IncorrectArgument remove_constraint!(ocp, :dummy_con)

#
@test isautonomous(ocp)
@test ocp.dynamics(0.0, [0, 1], 10) ≈ [ 1, 10 ] atol=1e-8
@test ocp.dynamics(0.0, [0, 1], [ 1 ]) ≈ [ 1, 1 ] atol=1e-8
@test ocp.lagrange(0.0, [0, 0], 1) ≈ 0.5 atol=1e-8
@test ocp.lagrange(0.0, [0, 0], [ 1 ]) ≈ 0.5 atol=1e-8
@test ocp.mayer === nothing
@test ismin(ocp)
@test ocp.initial_time == t0
@test ocp.final_time == tf
@test ocp.control_dimension == m
@test ocp.state_dimension == n

# replace the cost
objective!(ocp, :bolza, (t0, x0, tf, xf) -> 0, (x, u) -> 0.5u^2)
@test ocp.lagrange(0.0, [0, 0], 1) ≈ 0.5 atol=1e-8
@test ocp.mayer(0.0, [0, 0], 1, [0, 0]) ≈ 0 atol=1e-8

# -------------------------------------------------------------------------------------------
# 
# goddard (version 1, only nonlinear constraint, i.e. no ranges; no vectorial constraints either)
ocp = Model()
#
Cd = 310; Tmax = 3.5; β = 500; b = 2; t0 = 0; r0 = 1; v0 = 0
vmax = 0.1; m0 = 1; mf = 0.6; x0 = [r0, v0, m0]
#
m = 1
n = 3
#
time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, n) # state dim
control!(ocp, m) # control dim
constraint!(ocp, :initial, x0)
constraint!(ocp, :control, u -> u[1], 0, 1)
constraint!(ocp, :mixed, (x, u) -> x[1], r0, Inf, :state_con1)
constraint!(ocp, :mixed, (x, u) -> x[2], 0, vmax, :state_con2)
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
@test ocp.lagrange === nothing
@test ocp.mayer(t0, x0, tf, x0) ≈ x0[1] atol=1e-8
@test !ismin(ocp)
@test ocp.initial_time == t0
@test ocp.final_time === nothing
@test ocp.control_dimension == m
@test ocp.state_dimension == n

# -------------------------------------------------------------------------------------------
# 
# goddard (version 2, ranges, vectorial constraints)
ocp = Model()
Cd = 310; Tmax = 3.5; β = 500; b = 2; t0 = 0; r0 = 1; v0 = 0
vmax = 0.1; m0 = 1; mf = 0.6; x0 = [r0, v0, m0]
m = 1
n = 3

time!(ocp, :initial, t0) # if not provided, final time is free
state!(ocp, n) # state dim
control!(ocp, m) # control dim
constraint!(ocp, :initial, x0, :initial_con1)
constraint!(ocp, :control, 0, 1, :control_con1)
#constraint!(ocp, :control, Index(1), 0, 1, :control_con1)
constraint!(ocp, :state, 1:2, [ r0, 0 ], [ Inf, vmax ], :state_con1)
constraint!(ocp, :state, Index(3), m0, mf, :state_con2)

objective!(ocp, :mayer, (t0, x0, tf, xf) -> xf[1], :max)

constraint!(ocp, :dynamics, f) # see previous defs

@test isautonomous(ocp)
@test ocp.lagrange === nothing
@test ocp.mayer(t0, x0, tf, x0) ≈ x0[1] atol=1e-8
@test !ismin(ocp)

@test ocp.initial_time == t0
@test ocp.final_time === nothing
@test ocp.control_dimension == m
@test ocp.state_dimension == n

@test constraint(ocp, :initial_con1)(x0) == x0 
@test constraint(ocp, :control_con1)(1) == 1 
@test constraint(ocp, :state_con1)(x0) == x0[1:2]
@test constraint(ocp, :state_con2)(x0) == x0[3]

(ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)
@test ξl == [ ]
@test ξu == [ ]
@test ηl == [ ]
@test ηu == [ ]
@test ψl == [ ] 
@test ψu == [ ]
@test ϕl == x0 
@test ϕu == x0 
@test ulb == [ 0 ][uind]
@test uub == [ 1 ][uind]
@test xlb == [ r0, 0, m0 ][xind]
@test xub == [ Inf, vmax, mf ][xind]
@test [ Inf, vmax, mf ][Index(2)] == vmax
@test [ Inf, vmax, mf ][Index(2)][Index(1)] == vmax
=#

end
