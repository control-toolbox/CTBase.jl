function test_model() # 30 55 185

∅ = Vector{Real}()

@testset "variable" begin
    ocp = Model(variable=false)
    @test_throws UnauthorizedCall variable!(ocp, 1)
    @test_throws UnauthorizedCall constraint!(ocp, :variable, 2:3, [ 0, 3 ])
    @test_throws UnauthorizedCall constraint!(ocp, :variable, 0, 1) # the variable here is of dimension 1
    @test_throws UnauthorizedCall constraint!(ocp, :variable, 1:2, [ 0, 0 ], [ 1, 2 ])
    @test_throws UnauthorizedCall constraint!(ocp, :variable, [ 3, 0, 1 ])

    ocp = Model(variable=true)
    variable!(ocp, 1)
    @test ocp.variable_dimension == 1
    
    ocp = Model(variable=true)
    variable!(ocp, 1, "vv")
    @test is_variable_dependent(ocp)
    @test ocp.variable_dimension == 1
    @test ocp.variable_components_names == [ "vv" ]
    
    ocp = Model(variable=true)
    variable!(ocp, 1, :vv)
    @test ocp.variable_dimension == 1
    @test ocp.variable_components_names ==[ "vv" ]
    
    ocp = Model(variable=true)
    variable!(ocp, 2)
    @test ocp.variable_dimension == 2
    
    ocp = Model(variable=true)
    variable!(ocp, 2, "vv")
    @test ocp.variable_dimension == 2
    @test ocp.variable_components_names == [ "vv₁", "vv₂" ]
    
    ocp = Model(variable=true)
    variable!(ocp, 2, [ "vv1", "vv2" ])
    @test ocp.variable_dimension == 2
    @test ocp.variable_components_names == [ "vv1", "vv2" ]

    ocp = Model(variable=true)
    variable!(ocp, 2, :vv)
    @test ocp.variable_dimension == 2
    @test ocp.variable_components_names == [ "vv₁", "vv₂" ]
end

@testset "time, state and control set or not" begin

    for i ∈ 1:7

    ocp = Model()

    i == 2 && begin time!(ocp, 0, 1) end
    i == 3 && begin state!(ocp, 2) end
    i == 4 && begin control!(ocp, 1) end
    i == 5 && begin time!(ocp, 0, 1); state!(ocp, 2) end
    i == 6 && begin time!(ocp, 0, 1); control!(ocp, 1) end
    i == 7 && begin state!(ocp, 2); control!(ocp, 1) end

    # constraint! 1
    @test_throws UnauthorizedCall constraint!(ocp, :initial, 1:2:5, [ 0, 0, 0 ])
    @test_throws UnauthorizedCall constraint!(ocp, :initial, 2:3, [ 0, 0 ])
    @test_throws UnauthorizedCall constraint!(ocp, :final, Index(2), 0)

    # constraint! 2
    @test_throws UnauthorizedCall constraint!(ocp, :initial, [ 0, 0 ])
    @test_throws UnauthorizedCall constraint!(ocp, :final, 2) # if the state is of dimension 1

    # constraint! 3
    @test_throws UnauthorizedCall constraint!(ocp, :initial, 2:3, [ 0, 0 ], [ 1, 2 ])
    @test_throws UnauthorizedCall constraint!(ocp, :final, Index(1), 0, 2)
    @test_throws UnauthorizedCall constraint!(ocp, :control, Index(1), 0, 2)
    @test_throws UnauthorizedCall constraint!(ocp, :state, 2:3, [ 0, 0 ], [ 1, 2 ])
    @test_throws UnauthorizedCall constraint!(ocp, :initial, 1:2:5, [ 0, 0, 0 ], [ 1, 2, 1 ])

    # constraint! 4
    @test_throws UnauthorizedCall constraint!(ocp, :initial, [ 0, 0, 0 ], [ 1, 2, 1 ])
    @test_throws UnauthorizedCall constraint!(ocp, :final, [ 0, 0, 0 ], [ 1, 2, 1 ])
    @test_throws UnauthorizedCall constraint!(ocp, :control, [ 0, 0 ], [ 2, 3 ])
    @test_throws UnauthorizedCall constraint!(ocp, :state, [ 0, 0, 0 ], [ 1, 2, 1 ])

    # constraint! 5
    # variable independent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :boundary, (x0, xf) -> x0[3]+xf[2], 0, 1)

    # variable dependent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :boundary, (x0, xf, v) -> x0[3]+xf[2]*v[1], 0, 1)

    # time independent and variable independent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, u -> 2u, 0, 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, x -> x-1, [ 0, 0, 0 ], [ 1, 2, 1 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (x, u) -> x[1]-u, 0, 1)

    # time dependent and variable independent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, (t, u) -> 2u, 0, 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, (t, x) -> x-t, [ 0, 0, 0 ], [ 1, 2, 1 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (t, x, u) -> x[1]-u, 0, 1)

    # time independent and variable dependent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, (u, v) -> 2u*v[1], 0, 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, (x, v) -> x-v[1], [ 0, 0, 0 ], [ 1, 2, 1 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (x, u, v) -> x[1]-v[2]*u, 0, 1)

    # time dependent and variable dependent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, (t, u, v) -> 2u+v[2], 0, 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, (t, x, v) -> x-t*v[1], [ 0, 0, 0 ], [ 1, 2, 1 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (t, x, u, v) -> x[1]*v[2]-u, 0, 1)

    # constraint! 6
    # variable independent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :boundary, (x0, xf) -> x0[3]+xf[2], 0)

    # variable dependent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :boundary, (x0, xf, v) -> x0[3]+xf[2]*v[1], 0)

    # time independent and variable independent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, u -> 2u, 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, x -> x-1, [ 0, 0, 0 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (x, u) -> x[1]-u, 0)

    # time dependent and variable independent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, (t, u) -> 2u, 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, (t, x) -> x-t, [ 0, 0, 0 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (t, x, u) -> x[1]-u, 0)

    # time independent and variable dependent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, (u, v) -> 2u*v[1], 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, (x, v) -> x-v[2], [ 0, 0, 0 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (x, u) -> x[1]-u+v[1], 0)

    # time dependent and variable dependent ocp
    @test_throws UnauthorizedCall  constraint!(ocp, :control, (t, u, v) -> 2u-t*v[2], 1)
    @test_throws UnauthorizedCall  constraint!(ocp, :state, (t, x, v) -> x-t+v[1], [ 0, 0, 0 ])
    @test_throws UnauthorizedCall  constraint!(ocp, :mixed, (t, x, u, v) -> x[1]-u*v[1], 0)

    end

end

@testset "initial and / or final time already set" begin
    ocp = Model(variable=true)
    @test !CTBase.__is_time_set(ocp)
    variable!(ocp, 1)
    time!(ocp, 0, Index(1))
    @test CTBase.__is_time_set(ocp)

    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, Index(1), 1)
    @test CTBase.__is_time_set(ocp)
    
    ocp = Model()
    time!(ocp, 0, 1)
    @test CTBase.__is_time_set(ocp)

    ocp = Model()
    time!(ocp, [0, 1])
    @test CTBase.__is_time_set(ocp)

    ocp = Model()
    @test_throws MethodError time!(ocp, 0, Index(1))
    @test_throws MethodError time!(ocp, Index(1), 1)

    ocp = Model(variable=true)
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)

    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
    @test_throws UnauthorizedCall time!(ocp, 0, 1)

    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])
    @test_throws UnauthorizedCall time!(ocp, 0, 1)

    ocp = Model(variable=true)
    time!(ocp, [0, 1])
    @test_throws UnauthorizedCall time!(ocp, 0, Index(1))
    @test_throws UnauthorizedCall time!(ocp, Index(1), 1)
    @test_throws UnauthorizedCall time!(ocp, [0, 1])

    ocp = Model(variable=true)
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

@testset "time and variable dependence" begin
    ocp = Model()
    @test is_time_independent(ocp)
    @test !is_time_dependent(ocp)
    @test is_variable_independent(ocp)
    @test !is_variable_dependent(ocp)

    ocp = Model(autonomous=false)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_independent(ocp)
    @test !is_variable_dependent(ocp)

    ocp = Model(variable=true)
    @test is_time_independent(ocp)
    @test !is_time_dependent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)

    ocp = Model(autonomous=false, variable=true)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)
end

@testset "time and variable dependence bis" begin
    ocp = Model()
    @test is_time_independent(ocp)
    @test !is_time_dependent(ocp)
    @test is_variable_independent(ocp)
    @test !is_variable_dependent(ocp)

    ocp = Model(NonAutonomous)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_independent(ocp)
    @test !is_variable_dependent(ocp)

    ocp = Model(NonFixed)
    @test is_time_independent(ocp)
    @test !is_time_dependent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)

    ocp = Model(NonAutonomous, NonFixed)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)

    ocp = Model(NonFixed, NonAutonomous)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)

    @test_throws IncorrectArgument Model(NonFixed, NonAutonomous, Autonomous)
    @test_throws IncorrectArgument Model(NonAutonomous, Autonomous)
    @test_throws IncorrectArgument Model(NonFixed, Int64)

end

@testset "time and variable dependence Bool" begin
    ocp = Model()
    @test is_time_independent(ocp)
    @test !is_time_dependent(ocp)
    @test is_variable_independent(ocp)
    @test !is_variable_dependent(ocp)

    ocp = Model(NonAutonomous)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_independent(ocp)
    @test !is_variable_dependent(ocp)

    ocp = Model(NonFixed)
    @test is_time_independent(ocp)
    @test !is_time_dependent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)

    ocp = Model(NonAutonomous, NonFixed)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)

    ocp = Model(NonFixed, NonAutonomous)
    @test is_time_dependent(ocp)
    @test !is_time_independent(ocp)
    @test is_variable_dependent(ocp)
    @test !is_variable_independent(ocp)

    @test_throws IncorrectArgument Model(NonFixed, NonAutonomous, Autonomous)
    @test_throws IncorrectArgument Model(NonAutonomous, Autonomous)
    @test_throws IncorrectArgument Model(NonFixed, Int64)

end

@testset "state!" begin
    ocp = Model()
    state!(ocp, 1)
    @test ocp.state_dimension == 1
    @test ocp.state_components_names == ["x"]

    ocp = Model()
    state!(ocp, 1, "y")
    @test ocp.state_dimension == 1
    @test ocp.state_components_names == ["y"]

    ocp = Model()
    state!(ocp, 2)
    @test ocp.state_dimension == 2
    @test ocp.state_components_names == ["x₁", "x₂"]

    ocp = Model()
    state!(ocp, 2, ["y₁", "y₂"])
    @test ocp.state_dimension == 2
    @test ocp.state_components_names == ["y₁", "y₂"]

    ocp = Model()
    state!(ocp, 2, :y)
    @test ocp.state_dimension == 2
    @test ocp.state_components_names == ["y₁", "y₂"]

    ocp = Model()
    state!(ocp, 2, "y")
    @test ocp.state_dimension == 2
    @test ocp.state_components_names == ["y₁", "y₂"]
end

@testset "control!" begin
    ocp = Model()
    control!(ocp, 1)
    @test ocp.control_dimension == 1
    @test ocp.control_components_names == ["u"]

    ocp = Model()
    control!(ocp, 1, "v")
    @test ocp.control_dimension == 1
    @test ocp.control_components_names == ["v"]

    ocp = Model()
    control!(ocp, 2)
    @test ocp.control_dimension == 2
    @test ocp.control_components_names == ["u₁", "u₂"]

    ocp = Model()
    control!(ocp, 2, ["v₁", "v₂"])
    @test ocp.control_dimension == 2
    @test ocp.control_components_names == ["v₁", "v₂"]

    ocp = Model()
    control!(ocp, 2, :v)
    @test ocp.control_dimension == 2
    @test ocp.control_components_names == ["v₁", "v₂"]

    ocp = Model()
    control!(ocp, 2, "v")
    @test ocp.control_dimension == 2
    @test ocp.control_components_names == ["v₁", "v₂"]
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
    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, 0, Index(1))
    @test ocp.initial_time == 0
    @test ocp.final_time == Index(1)
    @test ocp.time_name == "t"
    
    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, 0, Index(1), "s")
    @test ocp.initial_time == 0
    @test ocp.final_time == Index(1)
    @test ocp.time_name == "s"

    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, 0, Index(1), :s)
    @test ocp.initial_time == 0
    @test ocp.final_time == Index(1)
    @test ocp.time_name == "s"
    
    # final time
    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, Index(1), 1)
    @test ocp.initial_time == Index(1)
    @test ocp.final_time == 1
    @test ocp.time_name == "t"

    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, Index(1), 1, "s")
    @test ocp.initial_time == Index(1)
    @test ocp.final_time == 1
    @test ocp.time_name == "s"

    ocp = Model(variable=true)
    variable!(ocp, 1)
    time!(ocp, Index(1), 1, :s)
    @test ocp.initial_time == Index(1)
    @test ocp.final_time == 1
    @test ocp.time_name == "s"
end

@testset "is_min vs is_max" begin
    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :mayer, (x0, xf) -> x0[1] + xf[2])
    @test is_min(ocp)
    @test !is_max(ocp)

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :mayer, (x0, xf) -> x0[1] + xf[2], :max)
    @test is_max(ocp)
    @test !is_min(ocp)

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test is_min(ocp)
    @test !is_max(ocp)

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :lagrange, (x, u) -> 0.5u^2, :max)
    @test is_max(ocp)
    @test !is_min(ocp)

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :bolza, (x0, xf) -> x0[1] + xf[2], (x, u) -> x[1]^2 + u^2) # the control is of dimension 1
    @test is_min(ocp)
    @test !is_max(ocp)
    
    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 1)
    objective!(ocp, :bolza, (x0, xf) -> x0[1] + xf[2], (x, u) -> x[1]^2 + u^2, :max) # the control is of dimension 1
    @test is_max(ocp)
    @test !is_min(ocp)

end

@testset "constraint! 1" begin

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    @test_throws IncorrectArgument constraint!(ocp, :initial, [0, 1], :c0)
    constraint!(ocp, :initial, 0, :c0)
    constraint!(ocp, :final, 1, :cf)
    @test constraint(ocp, :c0)(12, ∅) == 12
    @test constraint(ocp, :cf)(∅, 12) == 12

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    constraint!(ocp, :initial, [0, 1], :c0)
    constraint!(ocp, :final, [1, 2], :cf)
    @test constraint(ocp, :c0)([12, 13], ∅) == [12, 13]
    @test constraint(ocp, :cf)(∅, [12, 13]) == [12, 13]

    # constraint already exists
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :initial, 0, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, 0, :c)

end

@testset "constraint! 2" begin
    
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    x  = 12
    x0 = 0
    xf = 1
    constraint!(ocp, :initial, Index(1), x0, :c0)
    constraint!(ocp, :final, Index(1), xf, :cf)
    @test constraint(ocp, :c0)(x, ∅) == x
    @test constraint(ocp, :cf)(∅, x) == x

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    x  = [12, 13]
    x0 = [0, 1]
    xf = [1, 2]
    @test_throws IncorrectArgument constraint!(ocp, :initial, Index(2), x0, :c0)
    @test_throws IncorrectArgument constraint!(ocp, :final, Index(2), xf, :cf)

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    x  = [12, 13]
    x0 = [0, 1]
    xf = [1, 2]
    constraint!(ocp, :initial, 1:2, x0, :c0)
    constraint!(ocp, :final, 1:2, xf, :cf)
    @test constraint(ocp, :c0)(x, ∅) == x[1:2]
    @test constraint(ocp, :cf)(∅, x) == x[1:2]

    # constraint already exists
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    constraint!(ocp, :initial, Index(1), 0, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, Index(1), 0, :c)

end

@testset "constraint! 3" begin

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :initial, 0, 1, :c0)
    constraint!(ocp, :final, 1, 2, :cf)
    constraint!(ocp, :control, 0, 1, :cu)
    constraint!(ocp, :state, 0, 1, :cs)
    @test constraint(ocp, :c0)(12, ∅) == 12
    @test constraint(ocp, :cf)(∅ ,12) == 12
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 2)
    constraint!(ocp, :initial, [0, 1], [1, 2], :c0)
    constraint!(ocp, :final, [1, 2], [2, 3], :cf)
    constraint!(ocp, :control, [0, 1], [1, 2], :cu)
    constraint!(ocp, :state, [0, 1], [1, 2], :cs)
    @test constraint(ocp, :c0)([12, 13], ∅) == [12, 13]
    @test constraint(ocp, :cf)(∅, [12, 13]) == [12, 13]
    @test constraint(ocp, :cu)([12, 13]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13]) == [12, 13]

    # constraint already exists
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :initial, 0, 1, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, 0, 1, :c)

end

@testset "constraint! 4" begin
 
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :initial, Index(1), 0, 1, :c0)
    constraint!(ocp, :final, Index(1), 1, 2, :cf)
    constraint!(ocp, :control, Index(1), 0, 1, :cu)
    constraint!(ocp, :state, Index(1), 0, 1, :cs)
    @test constraint(ocp, :c0)(12, ∅) == 12
    @test constraint(ocp, :cf)(∅, 12) == 12
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 2)
    @test_throws IncorrectArgument constraint!(ocp, :initial, Index(2), [0, 1], [1, 2], :c0)
    @test_throws IncorrectArgument constraint!(ocp, :final, Index(2), [1, 2], [2, 3], :cf)
    @test_throws IncorrectArgument constraint!(ocp, :control, Index(2), [0, 1], [1, 2], :cu)
    @test_throws IncorrectArgument constraint!(ocp, :state, Index(2), [0, 1], [1, 2], :cs)

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 2)
    constraint!(ocp, :initial, 1:2, [0, 1], [1, 2], :c0)
    constraint!(ocp, :final, 1:2, [1, 2], [2, 3], :cf)
    constraint!(ocp, :control, 1:2, [0, 1], [1, 2], :cu)
    constraint!(ocp, :state, 1:2, [0, 1], [1, 2], :cs)
    @test constraint(ocp, :c0)([12, 13], ∅) == [12, 13]
    @test constraint(ocp, :cf)(∅, [12, 13]) == [12, 13]
    @test constraint(ocp, :cu)([12, 13]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13]) == [12, 13]

    # constraint already exists
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    constraint!(ocp, :initial, Index(1), 0, 1, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :final, Index(1), 0, 1, :c)

end

@testset "constraint! 5" begin

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :boundary, (x0, xf) -> x0+xf, 0, :cb)
    constraint!(ocp, :control, u->u, 0, :cu)
    constraint!(ocp, :state, x->x, 0, :cs)
    constraint!(ocp, :mixed, (x,u)->x+u, 1, :cm)
    @test constraint(ocp, :cb)(12, 13) == 12+13
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12
    @test constraint(ocp, :cm)(12, 13) == 12+13

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 2)
    constraint!(ocp, :boundary, (x0, xf) -> x0[1]+xf[1], 0, :cb)
    constraint!(ocp, :control, u->u[1], 0, :cu)
    constraint!(ocp, :state, x->x[1], 0, :cs)
    constraint!(ocp, :mixed, (x,u)->x[1]+u[1], 1, :cm)
    @test constraint(ocp, :cb)([13, 14], [16, 17]) == 13+16
    @test constraint(ocp, :cu)([12, 13]) == 12
    @test constraint(ocp, :cs)([12, 13]) == 12
    @test constraint(ocp, :cm)([12, 13], [14, 15]) == 12+14

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 3); control!(ocp, 3)
    constraint!(ocp, :boundary, (x0, xf) -> [x0[1]+xf[1], x0[2]+xf[2]], [0, 0], :cb)
    constraint!(ocp, :control, u->u[1:2], [0, 0], :cu)
    constraint!(ocp, :state, x->x[1:2], [0, 0], :cs)
    constraint!(ocp, :mixed, (x,u)->[x[1]+u[1], x[2]+u[2]], [0, 0], :cm)
    @test constraint(ocp, :cb)([13, 14, 15], [17, 18, 19]) == [13+17, 14+18]
    @test constraint(ocp, :cu)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cm)([12, 13, 14], [15, 16, 17]) == [12+15, 13+16]
    
    # constraint already exists
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    constraint!(ocp, :control, u->u, 0, 1, :c)
    @test_throws UnauthorizedCall constraint!(ocp, :control, u->u, 0, 1, :c)

end

@testset "constraint! 6" begin

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :boundary, (x0, xf) -> x0+xf, 0, 1, :cb)
    constraint!(ocp, :control, u->u, 0, 1, :cu)
    constraint!(ocp, :state, x->x, 0, 1, :cs)
    constraint!(ocp, :mixed, (x,u)->x+u, 1, 1, :cm)
    @test constraint(ocp, :cb)(12, 13) == 12+13
    @test constraint(ocp, :cu)(12) == 12
    @test constraint(ocp, :cs)(12) == 12
    @test constraint(ocp, :cm)(12, 13) == 12+13

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 2)
    constraint!(ocp, :boundary, (x0, xf) -> x0[1]+xf[1], 0, 1, :cb)
    constraint!(ocp, :control, u->u[1], 0, 1, :cu)
    constraint!(ocp, :state, x->x[1], 0, 1, :cs)
    constraint!(ocp, :mixed, (x,u)->x[1]+u[1], 1, 1, :cm)
    @test constraint(ocp, :cb)([13, 14], [16, 17]) == 13+16
    @test constraint(ocp, :cu)([12, 13]) == 12
    @test constraint(ocp, :cs)([12, 13]) == 12
    @test constraint(ocp, :cm)([12, 13], [14, 15]) == 12+14

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    constraint!(ocp, :boundary, (x0, xf) -> [x0[1]+xf[1], x0[2]+xf[2]], [0, 0], [1, 1], :cb)
    constraint!(ocp, :control, u->u[1:2], [0, 0], [1, 1], :cu)
    constraint!(ocp, :state, x->x[1:2], [0, 0], [1, 1], :cs)
    constraint!(ocp, :mixed, (x,u)->[x[1]+u[1], x[2]+u[2]], [0, 0], [1, 1], :cm)
    @test constraint(ocp, :cb)([13, 14, 15], [17, 18, 19]) == [13+17, 14+18]
    @test constraint(ocp, :cu)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cs)([12, 13, 14]) == [12, 13]
    @test constraint(ocp, :cm)([12, 13, 14], [15, 16, 17]) == [12+15, 13+16]

end

@testset "constraint! 7" begin

    x = 1
    u = 2
    v = [ 3, 4, 5, 6 ]
    x0 = 7
    xf = 8
    ocp = Model(variable=true)
    time!(ocp, 0, 1)
    variable!(ocp, 4)
    state!(ocp, 1)
    control!(ocp, 1)
    constraint!(ocp, :variable, [ 0, 0, 0, 0 ], [ 1, 1, 1, 1 ], :eq1)
    constraint!(ocp, :variable, Index(1), 0, 1, :eq2)
    constraint!(ocp, :variable, 1:2, [ 0, 0 ], [ 1, 2 ], :eq3)
    constraint!(ocp, :variable, 1:2:4, [ 0, 0 ], [ -1, 1 ], :eq4)
    constraint!(ocp, :variable, v -> v.^2, [ 0, 0, 0, 0 ], [ 1, 0, 1, 0 ], :eq5)
    @test constraint(ocp, :eq1)(v) == v
    @test constraint(ocp, :eq2)(v) == v[1]
    @test constraint(ocp, :eq3)(v) == v[1:2]
    @test constraint(ocp, :eq4)(v) == v[1:2:4]
    @test constraint(ocp, :eq5)(v) == v.^2

end

@testset "constraint! 8" begin

    x = 1
    u = 2
    v = [ 3, 4, 5, 6 ]
    x0 = 7
    xf = 8
    ocp = Model(variable=true)
    time!(ocp, 0, 1)
    variable!(ocp, 4)
    state!(ocp, 1)
    control!(ocp, 1)
    constraint!(ocp, :boundary, (x0, xf, v) -> x0 + xf + v[1], 0, 1, :cb)
    constraint!(ocp, :control, (u, v) -> u + v[1], 0, 1, :cu)
    constraint!(ocp, :state, (x, v) -> x + v[1], 0, 1, :cs)
    constraint!(ocp, :mixed, (x, u, v) -> x + u + v[1], 1, 1, :cm)
    constraint!(ocp, :variable, [ 0, 0, 0, 0 ], :eq1)
    constraint!(ocp, :variable, Index(1), 0, :eq2)
    constraint!(ocp, :variable, 1:2, [ 0, 0 ], :eq3)
    constraint!(ocp, :variable, 1:2:4, [ 0, 0 ], :eq4)
    constraint!(ocp, :variable, v -> v.^2, [ 0, 0, 0, 0 ], :eq5)
    @test constraint(ocp, :cb)(x0, xf, v) == x0 + xf + v[1]
    @test constraint(ocp, :cu)(u, v) == u + v[1]
    @test constraint(ocp, :cs)(x, v) == x + v[1]
    @test constraint(ocp, :cm)(x, u, v) == x + u + v[1]
    @test constraint(ocp, :eq1)(v) == v
    @test constraint(ocp, :eq2)(v) == v[1]
    @test constraint(ocp, :eq3)(v) == v[1:2]
    @test constraint(ocp, :eq4)(v) == v[1:2:4]
    @test constraint(ocp, :eq5)(v) == v.^2

end

@testset "constraint! 9" begin
    
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :dynamics, (x, u) -> x+u)
    @test ocp.dynamics(1, 2) == 3

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 2)
    constraint!(ocp, :dynamics, (x, u) -> x[1]+u[1])
    @test ocp.dynamics([1, 2], [3, 4]) == 4

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 2)
    constraint!(ocp, :dynamics, (x, u) -> [x[1]+u[1], x[2]+u[2]])
    @test ocp.dynamics([1, 2], [3, 4]) == [4, 6]

    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    constraint!(ocp, :dynamics, (x, u) -> [x[1]+u, x[2]+u])
    @test ocp.dynamics([1, 2], 3) == [4, 5]

end

@testset "constraint! 10" begin

    ocp = Model(autonomous=false); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :initial, 0, 1, :c0)
    constraint!(ocp, :final, 1, 2, :cf)
    @test constraint(ocp, :c0)(12, ∅) == 12
    @test constraint(ocp, :cf)(∅ ,12) == 12

end

@testset "remove_constraint! and constraints_labels" begin
    
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 1); control!(ocp, 1)
    constraint!(ocp, :boundary, (x0, xf) -> x0+xf, 0, 1, :cb)
    constraint!(ocp, :control, u->u, 0, 1, :cu)
    k = constraints_labels(ocp)
    @test :cb ∈ k
    @test :cu ∈ k
    remove_constraint!(ocp, :cb)
    k = constraints_labels(ocp)
    @test :cb ∉ k
    @test_throws IncorrectArgument remove_constraint!(ocp, :dummy_con)

end

@testset "nlp_constraints without variable" begin
    
    ocp = Model(); time!(ocp, 0, 1); state!(ocp, 2); control!(ocp, 1)
    constraint!(ocp, :initial, Index(2), 10, :ci)
    constraint!(ocp, :final, Index(1), 1, :cf)
    constraint!(ocp, :control, 0, 1, :cu)
    constraint!(ocp, :state, [0, 1], [1, 2], :cs)
    constraint!(ocp, :boundary, (x0, xf) -> x0[2]+xf[2], 0, 1, :cb)
    constraint!(ocp, :control, u->u, 0, 1, :cuu)
    constraint!(ocp, :state, x->x, [0, 1], [1, 2], :css)
    constraint!(ocp, :mixed, (x,u)->x[1]+u, 1, 1, :cm)

    (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (θl, θ, θu),
    (ulb, uind, uub), (xlb, xind, xub), (vlb, vind, vub) = nlp_constraints(ocp)

    v = Real[]
    
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
    pξlrintln("ϕu = ", ϕu)
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
    @test sort(ξ(-1, 1, v)) == sort([1])

    # state
    @test sort(ηl) == sort([0, 1])
    @test sort(ηu) == sort([1, 2])
    @test sort(η(-1, [1, 1], v)) == sort([1, 1])

    # mixed
    @test sort(ψl) == sort([1])
    @test sort(ψu) == sort([1])
    @test sort(ψ(-1, [1, 1], 2, v)) == sort([3])

    # boundary
    @test sort(ϕl) == sort([10, 1, 0])
    @test sort(ϕu) == sort([10, 1, 1])
    @test sort(ϕ([1, 3], [4, 100], v)) == sort([3, 4, 103])

    # box constraint
    @test sort(ulb) == sort([0])
    @test sort(uind) == sort([1])
    @test sort(uub) == sort([1])
    @test sort(xlb) == sort([0, 1])
    @test sort(xind) == sort([1, 2])
    @test sort(xub) == sort([1, 2])

    # variable
    @test sort(vlb) == sort([ ])
    @test sort(vind) == sort([ ])
    @test sort(vub) == sort([ ])
    @test sort(θl) == sort([ ])
    @test sort(θu) == sort([ ])
    @test sort(θ(v)) == sort([ ])

end

@testset "nlp_constraints with variable" begin
    
    ocp = Model(variable=true)
    time!(ocp, 0, 1)
    variable!(ocp, 4)
    state!(ocp, 2)
    control!(ocp, 1)
    constraint!(ocp, :initial, Index(2), 10, :ci)
    constraint!(ocp, :final, Index(1), 1, :cf)
    constraint!(ocp, :control, 0, 1, :cu)
    constraint!(ocp, :state, [0, 1], [1, 2], :cs)
    constraint!(ocp, :boundary, (x0, xf, v) -> x0[2]+xf[2]+v[1], 0, 1, :cb)
    constraint!(ocp, :control, (u, v) -> u+v[2], 0, 1, :cuu)
    constraint!(ocp, :state, (x, v) -> x+v[1:2], [0, 1], [1, 2], :css)
    constraint!(ocp, :mixed, (x, u, v) -> x[1]+u+v[2], 1, 1, :cm)
    constraint!(ocp, :variable, [ 0, 0, 0, 0 ], [ 5, 5, 5, 5 ], :cv1)
    constraint!(ocp, :variable, 1:2, [ 1, 2 ], [ 3, 4 ], :cv2)
    constraint!(ocp, :variable, Index(3), 2, 3, :cv3)
    constraint!(ocp, :variable, v -> v[3]^2, 0, 1, :cv4)

    (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (θl, θ, θu),
    (ulb, uind, uub), (xlb, xind, xub), (vlb, vind, vub) = nlp_constraints(ocp)

    v = [ 1, 2, 3, 4 ]

    # control
    @test sort(ξl) == sort([0])
    @test sort(ξu) == sort([1])
    @test sort(ξ(-1, 1, v)) == sort([ 1+v[2] ])

    # state
    @test sort(ηl) == sort([0, 1])
    @test sort(ηu) == sort([1, 2])
    @test sort(η(-1, [1, 1], v)) == sort([1, 1]+v[1:2])

    # mixed
    @test sort(ψl) == sort([1])
    @test sort(ψu) == sort([1])
    @test sort(ψ(-1, [1, 1], 2, v)) == sort([ 3+v[2] ])

    # boundary
    @test sort(ϕl) == sort([10, 1, 0])
    @test sort(ϕu) == sort([10, 1, 1])
    @test sort(ϕ([1, 3], [4, 100], v)) == sort([ 3, 4, 103+v[1] ])

    # box constraint
    @test sort(ulb) == sort([0])
    @test sort(uind) == sort([1])
    @test sort(uub) == sort([1])
    @test sort(xlb) == sort([0, 1])
    @test sort(xind) == sort([1, 2])
    @test sort(xub) == sort([1, 2])

    # variable
    @test sort(vlb) == sort([ 0, 0, 0, 0, 1, 2, 2 ])
    @test sort(vind) == sort([ 1, 2, 3, 4, 1, 2, 3 ])
    @test sort(vub) == sort([ 5, 5, 5, 5, 3, 4, 3 ])
    @test sort(θl) == sort([ 0 ])
    @test sort(θu) == sort([ 1 ])
    @test sort(θ(v)) == sort([ v[3]^2 ])

end

@testset "objective!" begin
    
    ocp = Model()
    @test_throws UnauthorizedCall objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test_throws UnauthorizedCall objective!(ocp, :mayer, (t0, x0, tf, xf) -> 0.5x0^2)
    @test_throws UnauthorizedCall objective!(ocp, :bolza, (t0, x0, tf, xf) -> 0.5x0^2, (x, u) -> 0.5u^2)

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 1)
    control!(ocp, 1)
    objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
    @test ocp.lagrange(1, 2) == 2

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)
    @test ocp.lagrange([1, 2], [3, 4]) == 4.5

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 1)
    control!(ocp, 1)
    objective!(ocp, :mayer, (x0, xf) -> 0.5x0^2)
    @test ocp.mayer(2, 3) == 2

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :mayer, (x0, xf) -> 0.5x0[1]^2)
    @test ocp.mayer([2, 3], [5, 6]) == 2

    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 1)
    control!(ocp, 1)
    objective!(ocp, :bolza, (x0, xf) -> 0.5x0^2, (x, u) -> 0.5u^2)
    @test ocp.mayer(2, 3) == 2
    @test ocp.lagrange(1, 2) == 2
    
    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :bolza, (x0, xf) -> 0.5x0[1]^2, (x, u) -> 0.5u[1]^2)
    @test ocp.mayer([2, 3], [5, 6]) == 2
    @test ocp.lagrange([1, 2], [3, 4]) == 4.5

    # replacing the objective
    ocp = Model()
    time!(ocp, 0, 1)
    state!(ocp, 2)
    control!(ocp, 2)
    objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)
    @test ocp.lagrange([1, 2], [3, 4]) == 4.5
    @test isnothing(ocp.mayer)
    objective!(ocp, :mayer, (x0, xf) -> 0.5x0[1]^2)
    @test ocp.mayer([2, 3], [5, 6]) == 2
    @test isnothing(ocp.lagrange)

end

end
