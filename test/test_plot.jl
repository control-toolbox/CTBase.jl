function test_plot()

    # create a solution
    n = 2
    m = 1
    t0 = 0.0
    tf = 1.0
    x0 = [-1.0, 0.0]
    xf = [0.0, 0.0]
    a = x0[1]
    b = x0[2]
    C = [
        -(tf - t0)^3/6.0 (tf-t0)^2/2.0
        -(tf - t0)^2/2.0 (tf-t0)
    ]
    D = [-a - b * (tf - t0), -b] + xf
    p0 = C \ D
    α = p0[1]
    β = p0[2]
    x(t) = [
        a + b * (t - t0) + β * (t - t0)^2 / 2.0 - α * (t - t0)^3 / 6.0,
        b + β * (t - t0) - α * (t - t0)^2 / 2.0,
    ]
    p(t) = [α, -α * (t - t0) + β]
    u(t) = [p(t)[2]]
    objective = 0.5 * (α^2 * (tf - t0)^3 / 3 + β^2 * (tf - t0) - α * β * (tf - t0)^2)
    #
    N = 201
    times = range(t0, tf, N)
    #

    sol = OptimalControlSolution()
    sol.state_dimension = n
    sol.control_dimension = m
    sol.time_grid = times
    sol.time_name = "t"
    sol.state = x
    sol.state_name = "x"
    sol.state_components_names = ["x" * ctindices(i) for i ∈ range(1, n)]
    sol.costate = p
    sol.control = u
    sol.control_name = "u"
    sol.control_components_names = ["u"]
    sol.objective = objective
    sol.iterations = 0
    sol.stopping = :dummy
    sol.message = "ceci est un test"
    sol.success = true

    #
    @test plot(sol, layout = :split) isa Plots.Plot
    @test plot(sol, layout = :group) isa Plots.Plot
    @test display(sol) isa Nothing

end
