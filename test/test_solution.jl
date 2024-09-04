function test_solution()

    # Fixed ocp
    @def ocp begin
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end

    times = range(0, 1, 10)
    x = t -> t
    u = t -> 2t
    p = t -> t
    obj = 1
    sol = OptimalControlSolution(
        ocp; state=x, control=u, costate=p, objective=obj, time_grid=times
    )

    @test objective(sol) == obj
    @test typeof(sol) == OptimalControlSolution

    # getters
    @test all(state_discretized(sol) .== x.(times))
    @test all(control_discretized(sol) .== u.(times))
    @test all(costate_discretized(sol) .== p.(times))

    # NonFixed ocp
    @def ocp begin
        v ∈ R, variable
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end

    x = t -> t
    u = t -> 2t
    obj = 1
    v = 1
    sol = OptimalControlSolution(ocp; state=x, control=u, objective=obj, variable=v)

    @test variable(sol) == v
    @test typeof(sol) == OptimalControlSolution
    @test_throws UndefKeywordError OptimalControlSolution(ocp; x, u, obj)
end
