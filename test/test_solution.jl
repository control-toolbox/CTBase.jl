function test_solution()

    # Fixed ocp
    @def ocp begin
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [ -1, 0 ]
        x(1) == [ 0, 0 ]
        ẋ(t) == [ x₂(t), u(t) ]
        ∫( 0.5u(t)^2 ) → min
    end

    state = t -> t 
    control = t -> 2t 
    objective = 1
    sol = OptimalControlSolution(ocp; state=state, control=control, objective=objective)

    @test sol.objective == objective
    @test typeof(sol) == OptimalControlSolution

    # Fixed ocp
    @def ocp begin
        v ∈ R, variable
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [ -1, 0 ]
        x(1) == [ 0, 0 ]
        ẋ(t) == [ x₂(t), u(t) ]
        ∫( 0.5u(t)^2 ) → min
    end

    state = t -> t 
    control = t -> 2t 
    objective = 1
    variable = 1
    sol = OptimalControlSolution(ocp; state, control, objective, variable)
    
    @test sol.variable == variable
    @test typeof(sol) == OptimalControlSolution
    @test_throws UndefKeywordError OptimalControlSolution(ocp; state, control, objective)

end