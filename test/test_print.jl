function test_print()

    #
    @test display(Model()) isa Nothing

    #
    ocp = Model(autonomous=false)
    state!(ocp, 2, "state", ["r", "v"]) # dimension of the state with the names of the components
    control!(ocp, 1)           # dimension of the control
    time!(ocp, 0, 1, "s")    # initial and final time, with the name of the variable time
    __constraint!(ocp, :initial, [-1, 0], [-1, 0])
    __constraint!(ocp, :final  , [ 0, 0], [0, 0])
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    dynamics!(ocp, (t, x, u) -> A*x + B*u)
    __constraint!(ocp, :state, (t, x) -> x[2], 0, 1)
    __constraint!(ocp, :control, (t, u) -> u, -1, 1)
    __constraint!(ocp, :mixed, (t, x, u) -> x[1]+u, 2, 3)
    __constraint!(ocp, :state, Index(1), -10, 10)
    __constraint!(ocp, :control, -2, 2)
    objective!(ocp, :bolza, (t0, x0, tf, xf) -> tf, (t, x, u) -> 0.5u^2)
    @test display(ocp) isa Nothing

    #
    ocp = Model(autonomous=false)
    state!(ocp, 1, "y") # dimension of the state with the names of the components
    control!(ocp, 1, "v")           # dimension of the control
    time!(ocp, 0, 1, "s")    # initial and final time, with the name of the variable time
    __constraint!(ocp, :initial, -1, -1)
    __constraint!(ocp, :final  , 0, 0)
    dynamics!(ocp, (t, x, u) -> x+u)
    __constraint!(ocp, :state, (t, x) -> x, 0, 1)
    __constraint!(ocp, :control, (t, u) -> u, -1, 1)
    __constraint!(ocp, :mixed, (t, x, u) -> x+u, 2, 3)
    __constraint!(ocp, :state, -10, 10)
    __constraint!(ocp, :control, -2, 2)
    objective!(ocp, :mayer, (t0, x0, tf, xf) -> tf)
    @test display(ocp) isa Nothing

    #
    ocp = Model(autonomous=false, variable=true)
    variable!(ocp, 1)
    state!(ocp, 1, "y") # dimension of the state with the names of the components
    control!(ocp, 2)           # dimension of the control
    time!(ocp, 0, Index(1), "s")    # initial and final time, with the name of the variable time
    __constraint!(ocp, :initial, -1, -1)
    __constraint!(ocp, :final  , 0, 0)
    dynamics!(ocp, (t, x, u) -> x+u)
    objective!(ocp, :mayer, (t0, x0, tf, xf) -> tf)
    @test display(ocp) isa Nothing

end
