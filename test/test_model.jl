function test_model()

@testset "variable" begin
    ocp = Model()
    variable!(ocp, 1)
    @test ocp.variable_dimension == 1
    
    ocp = Model()
    variable!(ocp, 1, "vv")
    @test ocp.variable_dimension == 1
    @test ocp.variable_names == [ "vv" ]
    
    ocp = Model()
    variable!(ocp, 1, :vv)
    @test ocp.variable_dimension == 1
    @test ocp.variable_names ==[ "vv" ]
    
    ocp = Model()
    variable!(ocp, 2)
    @test ocp.variable_dimension == 2
    
    ocp = Model()
    variable!(ocp, 2, "vv")
    @test ocp.variable_dimension == 2
    @test ocp.variable_names == [ "vv₁", "vv₂" ]
    
    ocp = Model()
    variable!(ocp, 2, [ "vv1", "vv2" ])
    @test ocp.variable_dimension == 2
    @test ocp.variables_names == [ "vv1", "vv2" ]

    ocp = Model()
    variable!(ocp, 2, :vv)
    @test ocp.variable_dimension == 2
    @test ocp.variable_names == [ "vv₁", "vv₂" ]
end

@testset "state and control dimensions set or not" begin
    ocp = Model()
    @test !CTBase.dims_set(ocp)
    state!(ocp, 2)
    @test !CTBase.dims_set(ocp)
    control!(ocp, 1)
    @test CTBase.dims_set(ocp)
    ocp = Model()
    @test_throws UnauthorizedCall objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test_throws UnauthorizedCall objective!(ocp, :bolza, (t0, x0, tf, xf) -> tf, (x, u) -> 0.5u^2)
    @test_throws UnauthorizedCall nlp_constraints(ocp)
    @test_throws UnauthorizedCall constraint!(ocp, :initial, 0, 1, :c0)
    @test_throws UnauthorizedCall constraint!(ocp, :final, 1, 2, :cf)
    @test_throws UnauthorizedCall constraint!(ocp, :control, 0, 1, :cu)
    @test_throws UnauthorizedCall constraint!(ocp, :state, 0, 1, :cs)
end

@testset "initial and / or final time set" begin
    ocp = Model()
    @test !CTBase.time_set(ocp)
    variable!(ocp, 1)
    time!(ocp, 0, Index(1))
    @test CTBase.time_set(ocp)
    ocp = Model()
    variable!(ocp, 1)
    time!(ocp, Index(1), 1)
    @test CTBase.time_set(ocp)
    ocp = Model()
    time!(ocp, 0, 1)
    @test CTBase.time_set(ocp)
    time!(ocp, [0, 1])
    @test CTBase.time_set(ocp)
    ocp = Model()
    variable!(ocp, 1)
    time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
    @test_throws UnauthorizedCall time!(ocp, 0, 1)
    ocp = Model()
    variable!(ocp, 1)
    time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
    @test_throws UnauthorizedCall time!(ocp, 0, 1)
    ocp = Model()
    time!(ocp, [0, 1])
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
ocp = Model()
    time!(ocp, 0, 1)
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)
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
    time!(ocp, 0, 1)
    @test ocp.initial_time == 0
    @test ocp.final_time == 1
    @test ocp.time_name == "t"
    ocp = Model()
    time!(ocp, 0, 1, "s")
    @test ocp.initial_time == 0
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
    ocp = Model()
    time!(ocp, 0, 1, :s)
    @test ocp.initial_time == 0
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
    # initial and final times (bis)
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
    variable!(ocp, 1)
    time!(ocp, 0, Index(1))
    @test ocp.initial_time == 0
    @test ocp.final_time == Index(1)
    @test ocp.time_name == "t"
    ocp = Model()
    variable!(ocp, 1)
    time!(ocp, 0, Index(1), "s")
    @test ocp.initial_time == 0
    @test ocp.final_time == Index(1)
    @test ocp.time_name == "s"
    ocp = Model()
    variable!(ocp, 1)
    time!(ocp, 0, Index(1), :s)
    @test ocp.initial_time == 0
    @test ocp.final_time == Index(1)
    @test ocp.time_name == "s"
    # final time
    ocp = Model()
    variable!(ocp, 1)
    time!(ocp, Index(1), 1)
    @test ocp.initial_time == Index(1)
    @test ocp.final_time == 1
    @test ocp.time_name == "t"
    ocp = Model()
    variable!(ocp, 1)
    time!(ocp, Index(1), 1, "s")
    @test ocp.initial_time == Index(1)
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
    ocp = Model()
    time!(ocp, Index(1), 1, :s)
    @test ocp.initial_time == Index(1)
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
end

@testset "constraint! 1/7" begin

    ocp = Model()

    constraint!(ocp, :initial, 0, :c0)
    constraint!(ocp, :final, 1, :cf)
    @test constraint(ocp, :c0)(12) == 12
    @test constraint(ocp, :cf)(12) == 12

    ocp = Model()
    constraint!(ocp, :initial, [0, 1], :c0)
    constraint!(ocp, :final, [1, 2], :cf)
    @test constraint(ocp, :c0)([12, 13]) == [12, 13]
    @test constraint(ocp, :cf)([12, 13]) == [12, 13]

    # constraint already exists
    ocp = Model()
    constraint!(ocp, :initial, 0, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, 0, :c)

end

@testset "constraint! 2/7" begin
    
    ocp = Model()
    x  = 12
    x0 = 0
    xf = 1
    constraint!(ocp, :initial, Index(1), x0, :c0)
    constraint!(ocp, :final, Index(1), xf, :cf)
    @test constraint(ocp, :c0)(x) == x
    @test constraint(ocp, :cf)(x) == x

    ocp = Model()
    x  = [12, 13]
    x0 = [0, 1]
    xf = [1, 2]
    constraint!(ocp, :initial, Index(2), x0, :c0)
    constraint!(ocp, :final, Index(2), xf, :cf)
    @test constraint(ocp, :c0)(x) == x[2]
    @test constraint(ocp, :cf)(x) == x[2]

    ocp = Model()
    x  = [12, 13]
    x0 = [0, 1]
    xf = [1, 2]
    constraint!(ocp, :initial, 1:2, x0, :c0)
    constraint!(ocp, :final, 1:2, xf, :cf)
    @test constraint(ocp, :c0)(x) == x[1:2]
    @test constraint(ocp, :cf)(x) == x[1:2]

    # constraint already exists
    ocp = Model()
    constraint!(ocp, :initial, Index(1), 0, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, Index(1), 0, :c)

end

@testset "constraint! 3/7" begin

    ocp = Model()
    state!(ocp, 1)
    control!(ocp, 1)
    constraint!(ocp, :initial, 0, 1, :c0)
    constraint!(ocp, :final, 1, 2, :cf)
    constraint!(ocp, :control, 0, 1, :cu)
    constraint!(ocp, :state, 0, 1, :cs)
    @test constraint(ocp, :c0)(12) == 12
    @test constraint(ocp, :cf)(12) == 12
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12

    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 2)
    constraint!(ocp, :initial, [0, 1], [1, 2], :c0)
    constraint!(ocp, :final, [1, 2], [2, 3], :cf)
    constraint!(ocp, :control, [0, 1], [1, 2], :cu)
    constraint!(ocp, :state, [0, 1], [1, 2], :cs)
    @test constraint(ocp, :c0)([12, 13]) == [12, 13]
    @test constraint(ocp, :cf)([12, 13]) == [12, 13]
    @test constraint(ocp, :cu)([12, 13]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13]) == [12, 13]

    # constraint already exists
    ocp = Model()
    state!(ocp, 1)
    control!(ocp, 1)
    constraint!(ocp, :initial, 0, 1, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, 0, 1, :c)

end

@testset "constraint! 4/7" begin
 
    ocp = Model()
    constraint!(ocp, :initial, Index(1), 0, 1, :c0)
    constraint!(ocp, :final, Index(1), 1, 2, :cf)
    constraint!(ocp, :control, Index(1), 0, 1, :cu)
    constraint!(ocp, :state, Index(1), 0, 1, :cs)
    @test constraint(ocp, :c0)(12) == 12
    @test constraint(ocp, :cf)(12) == 12
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12

    ocp = Model()
    constraint!(ocp, :initial, Index(2), [0, 1], [1, 2], :c0)
    constraint!(ocp, :final, Index(2), [1, 2], [2, 3], :cf)
    constraint!(ocp, :control, Index(2), [0, 1], [1, 2], :cu)
    constraint!(ocp, :state, Index(2), [0, 1], [1, 2], :cs)
    @test constraint(ocp, :c0)([12, 13]) == 13
    @test constraint(ocp, :cf)([12, 13]) == 13
    @test constraint(ocp, :cu)([12, 13]) == 13
    @test constraint(ocp, :cs)([12, 13]) == 13

    ocp = Model()
    constraint!(ocp, :initial, 1:2, [0, 1], [1, 2], :c0)
    constraint!(ocp, :final, 1:2, [1, 2], [2, 3], :cf)
    constraint!(ocp, :control, 1:2, [0, 1], [1, 2], :cu)
    constraint!(ocp, :state, 1:2, [0, 1], [1, 2], :cs)
    @test constraint(ocp, :c0)([12, 13]) == [12, 13]
    @test constraint(ocp, :cf)([12, 13]) == [12, 13]
    @test constraint(ocp, :cu)([12, 13]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13]) == [12, 13]

    # constraint already exists
    ocp = Model()
    constraint!(ocp, :initial, Index(1), 0, 1, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, Index(1), 0, 1, :c)

end

@testset "constraint! 5/7" begin

    ocp = Model()
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> t0+x0+tf+xf, 0, :cb)
    constraint!(ocp, :control, u->u, 0, :cu)
    constraint!(ocp, :state, x->x, 0, :cs)
    constraint!(ocp, :mixed, (x,u)->x+u, 1, :cm)
    @test constraint(ocp, :cb)(12, 13, 14, 15) == 12+13+14+15
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12
    @test constraint(ocp, :cm)(12, 13) == 12+13

    ocp = Model()
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> t0+x0[1]+tf+xf[1], 0, :cb)
    constraint!(ocp, :control, u->u[1], 0, :cu)
    constraint!(ocp, :state, x->x[1], 0, :cs)
    constraint!(ocp, :mixed, (x,u)->x[1]+u[1], 1, :cm)
    @test constraint(ocp, :cb)(12, [13, 14], 15, [16, 17]) == 12+13+15+16
    @test constraint(ocp, :cu)([12, 13]) == 12
    @test constraint(ocp, :cs)([12, 13]) == 12
    @test constraint(ocp, :cm)([12, 13], [14, 15]) == 12+14

    ocp = Model()
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> [t0+x0[1]+tf+xf[1], t0+x0[2]+tf+xf[2]], 0, :cb)
    constraint!(ocp, :control, u->u[1:2], 0, :cu)
    constraint!(ocp, :state, x->x[1:2], 0, :cs)
    constraint!(ocp, :mixed, (x,u)->[x[1]+u[1], x[2]+u[2]], 1, :cm)
    @test constraint(ocp, :cb)(12, [13, 14, 15], 16, [17, 18, 19]) == [12+13+16+17, 12+14+16+18]
    @test constraint(ocp, :cu)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cm)([12, 13, 14], [15, 16, 17]) == [12+15, 13+16]
    
    # constraint already exists
    ocp = Model()
    constraint!(ocp, :control, u->u, 0, 1, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :control, u->u, 0, 1, :c)

end

@testset "constraint! 6/7" begin

    ocp = Model()
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> t0+x0+tf+xf, 0, 1, :cb)
    constraint!(ocp, :control, u->u, 0, 1, :cu)
    constraint!(ocp, :state, x->x, 0, 1, :cs)
    constraint!(ocp, :mixed, (x,u)->x+u, 1, 1, :cm)
    @test constraint(ocp, :cb)(12, 13, 14, 15) == 12+13+14+15
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12
    @test constraint(ocp, :cm)(12, 13) == 12+13

    ocp = Model()
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> t0+x0[1]+tf+xf[1], 0, 1, :cb)
    constraint!(ocp, :control, u->u[1], 0, 1, :cu)
    constraint!(ocp, :state, x->x[1], 0, 1, :cs)
    constraint!(ocp, :mixed, (x,u)->x[1]+u[1], 1, 1, :cm)
    @test constraint(ocp, :cb)(12, [13, 14], 15, [16, 17]) == 12+13+15+16
    @test constraint(ocp, :cu)([12, 13]) == 12
    @test constraint(ocp, :cs)([12, 13]) == 12
    @test constraint(ocp, :cm)([12, 13], [14, 15]) == 12+14

    ocp = Model()
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> [t0+x0[1]+tf+xf[1], t0+x0[2]+tf+xf[2]], 0, 1, :cb)
    constraint!(ocp, :control, u->u[1:2], 0, 1, :cu)
    constraint!(ocp, :state, x->x[1:2], 0, 1, :cs)
    constraint!(ocp, :mixed, (x,u)->[x[1]+u[1], x[2]+u[2]], 1, 1, :cm)
    @test constraint(ocp, :cb)(12, [13, 14, 15], 16, [17, 18, 19]) == [12+13+16+17, 12+14+16+18]
    @test constraint(ocp, :cu)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cm)([12, 13, 14], [15, 16, 17]) == [12+15, 13+16]

end

@testset "constraint! 7/7" begin
    
    ocp = Model()
    state!(ocp, 1)
    control!(ocp, 1)
    constraint!(ocp, :dynamics, (x, u) -> x+u)
    @test ocp.dynamics(1, 2) == 3

    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 2)
    constraint!(ocp, :dynamics, (x, u) -> x[1]+u[1])
    @test ocp.dynamics([1, 2], [3, 4]) == 4

    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 2)
    constraint!(ocp, :dynamics, (x, u) -> [x[1]+u[1], x[2]+u[2]])
    @test ocp.dynamics([1, 2], [3, 4]) == [4, 6]

    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 1)
    constraint!(ocp, :dynamics, (x, u) -> [x[1]+u, x[2]+u])
    @test ocp.dynamics([1, 2], 3) == [4, 5]

end

@testset "remove_constraint! and constraints_labels" begin
    
    ocp = Model()
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> t0+x0+tf+xf, 0, 1, :cb)
    constraint!(ocp, :control, u->u, 0, 1, :cu)
    k = constraints_labels(ocp)
    @test :cb ∈ k
    @test :cu ∈ k
    remove_constraint!(ocp, :cb)
    k = constraints_labels(ocp)
    @test :cb ∉ k
    @test_throws IncorrectArgument remove_constraint!(ocp, :dummy_con)

end

@testset "nlp_constraints" begin
    
    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 1)
    constraint!(ocp, :initial, Index(2), 10, :ci)
    constraint!(ocp, :final, Index(1), 1, :cf)
    constraint!(ocp, :control, 0, 1, :cu)
    constraint!(ocp, :state, [0, 1], [1, 2], :cs)
    constraint!(ocp, :boundary, (t0, x0, tf, xf) -> [t0+tf, x0[2]+xf[2]], [0, 1], [1, 2], :cb)
    constraint!(ocp, :control, u->u, 0, 1, :cuu)
    constraint!(ocp, :state, x->x, [0, 1], [1, 2], :css)
    constraint!(ocp, :mixed, (x,u)->x[1]+u, 1, 1, :cm)

    (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), 
    (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)

    #=
    println("ξl = ", ξl)
    println("ξ = ", ξ)
    println("ξu = ", ξu)
    println("ηl = ", ηl)
    println("η = ", η)
    println("ηu = ", ηu)
    println("ψl = ", ψl)
    println("ψ = ", ψ)
    println("ψu = ", ψu)
    println("ϕl = ", ϕl)
    println("ϕ = ", ϕ)
    println("ϕu = ", ϕu)
    println("ulb = ", ulb)
    println("uind = ", uind)
    println("uub = ", uub)
    println("xlb = ", xlb)
    println("xind = ", xind)
    println("xub = ", xub)
    =#

    # control
    @test sort(ξl) == sort([0])
    @test sort(ξu) == sort([1])
    @test sort(ξ(_Time(-1), [1])) == sort([1])

    # state
    @test sort(ηl) == sort([0, 1])
    @test sort(ηu) == sort([1, 2])
    @test sort(η(_Time(-1), [1, 1])) == sort([1, 1])

    # mixed
    @test sort(ψl) == sort([1])
    @test sort(ψu) == sort([1])
    @test sort(ψ(_Time(-1), [1, 1], [2])) == sort([3])

    # boundary
    @test sort(ϕl) == sort([10, 1, 0, 1])
    @test sort(ϕu) == sort([10, 1, 1, 2])
    @test sort(ϕ(1, [1, 3], 20, [4, 100])) == sort([3, 4, 21, 103])

    # box constraint
    @test sort(ulb) == sort([0])
    @test sort(uind) == sort([1])
    @test sort(uub) == sort([1])
    @test sort(xlb) == sort([0, 1])
    @test sort(xind) == sort([1, 2])
    @test sort(xub) == sort([1, 2])

end

@testset "objective!" begin
    
    ocp = Model()
    @test_throws UnauthorizedCall objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test_throws UnauthorizedCall objective!(ocp, :mayer, (t0, x0, tf, xf) -> 0.5x0^2)
    @test_throws UnauthorizedCall objective!(ocp, :bolza, (t0, x0, tf, xf) -> 0.5x0^2, (x, u) -> 0.5u^2)

    ocp = Model()
    state!(ocp, 1)
    control!(ocp, 1)
    objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test ocp.lagrange(1, 2) == 2

    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)
    @test ocp.lagrange([1, 2], [3, 4]) == 4.5

    ocp = Model()
    state!(ocp, 1)
    control!(ocp, 1)
    objective!(ocp, :mayer, (t0, x0, tf, xf) -> 0.5x0^2)
    @test ocp.mayer(1, 2, 3, 4) == 2

    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :mayer, (t0, x0, tf, xf) -> 0.5x0[1]^2)
    @test ocp.mayer(1, [2, 3], 4, [5, 6]) == 2

    ocp = Model()
    state!(ocp, 1)
    control!(ocp, 1)
    objective!(ocp, :bolza, (t0, x0, tf, xf) -> 0.5x0^2, (x, u) -> 0.5u^2)
    @test ocp.mayer(1, 2, 3, 4) == 2
    @test ocp.lagrange(1, 2) == 2
    
    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :bolza, (t0, x0, tf, xf) -> 0.5x0[1]^2, (x, u) -> 0.5u[1]^2)
    @test ocp.mayer(1, [2, 3], 4, [5, 6]) == 2
    @test ocp.lagrange([1, 2], [3, 4]) == 4.5

    # replacing the objective
    ocp = Model()
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)
    @test ocp.lagrange([1, 2], [3, 4]) == 4.5
    @test isnothing(ocp.mayer)
    objective!(ocp, :mayer, (t0, x0, tf, xf) -> 0.5x0[1]^2)
    @test ocp.mayer(1, [2, 3], 4, [5, 6]) == 2
    @test isnothing(ocp.lagrange)

end

end
