function test_print()

    #
    @test display(Model()) isa Nothing

    @def ocp begin
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end
    @test display(ocp) isa Nothing

    #
    ocp = Model(; autonomous = false)
    state!(ocp, 2, "state", ["r", "v"]) # dimension of the state with the names of the components
    control!(ocp, 1)           # dimension of the control
    time!(ocp; t0 = 0, tf = 1, name = "s")    # initial and final time, with the name of the variable time
    constraint!(ocp, :initial; lb = [-1, 0], ub = [-1, 0])
    constraint!(ocp, :final; lb = [0, 0], ub = [0, 0])
    A = [0 1
         0 0]
    B = [0
         1]
    dynamics!(ocp, (t, x, u) -> A * x + B * u)
    constraint!(ocp, :state; f = (t, x) -> x[2], lb = 0, ub = 1)
    constraint!(ocp, :control; f = (t, u) -> u, lb = -1, ub = 1)
    constraint!(ocp, :mixed; f = (t, x, u) -> x[1] + u, lb = 2, ub = 3)
    constraint!(ocp, :state; rg = 1, lb = -10, ub = 10)
    constraint!(ocp, :control; lb = -2, ub = 2)
    objective!(ocp, :bolza, (t0, x0, tf, xf) -> tf, (t, x, u) -> 0.5u^2)
    @test display(ocp) isa Nothing

    #
    ocp = Model(; autonomous = false)
    state!(ocp, 1, "y") # dimension of the state with the names of the components
    control!(ocp, 1, "v")           # dimension of the control
    time!(ocp; t0 = 0, tf = 1, name = "s")    # initial and final time, with the name of the variable time
    constraint!(ocp, :initial; lb = -1, ub = -1)
    constraint!(ocp, :final; lb = 0, ub = 0)
    dynamics!(ocp, (t, x, u) -> x + u)
    constraint!(ocp, :state; f = (t, x) -> x, lb = 0, ub = 1)
    constraint!(ocp, :control; f = (t, u) -> u, lb = -1, ub = 1)
    constraint!(ocp, :mixed; f = (t, x, u) -> x + u, lb = 2, ub = 3)
    constraint!(ocp, :state; lb = -10, ub = 10)
    constraint!(ocp, :control; lb = -2, ub = 2)
    objective!(ocp, :mayer, (t0, x0, tf, xf) -> tf)
    @test display(ocp) isa Nothing

    #
    ocp = Model(; autonomous = false, variable = true)
    variable!(ocp, 1)
    state!(ocp, 1, "y") # dimension of the state with the names of the components
    control!(ocp, 2)           # dimension of the control
    time!(ocp; t0 = 0, indf = 1, name = "s")    # initial and final time, with the name of the variable time
    constraint!(ocp, :initial; lb = -1, ub = -1)
    constraint!(ocp, :final; lb = 0, ub = 0)
    dynamics!(ocp, (t, x, u) -> x + u)
    objective!(ocp, :mayer, (t0, x0, tf, xf) -> tf)
    @test display(ocp) isa Nothing
end
