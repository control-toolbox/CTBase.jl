function test_model() # 30 55 185
    ∅ = Vector{Real}()

    @testset "is_in_place" begin
        ocp = Model()
        @test !is_in_place(ocp)
        ocp = Model(; in_place = false)
        @test !is_in_place(ocp)
        ocp = Model(; in_place = true)
        @test is_in_place(ocp)

        ocp = Model(; autonomous = true, variable = true)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = true, variable = true, in_place = false)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = true, variable = true, in_place = true)
        @test is_in_place(ocp)

        ocp = Model(; autonomous = false, variable = true)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = false, variable = true, in_place = false)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = false, variable = true, in_place = true)
        @test is_in_place(ocp)

        ocp = Model(; autonomous = true, variable = false)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = true, variable = false, in_place = false)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = true, variable = false, in_place = true)
        @test is_in_place(ocp)

        ocp = Model(; autonomous = false, variable = false)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = false, variable = false, in_place = false)
        @test !is_in_place(ocp)
        ocp = Model(; autonomous = false, variable = false, in_place = true)
        @test is_in_place(ocp)
    end

    @testset "variable!" begin
        ocp = Model(variable = false)

        @test_throws UnauthorizedCall variable!(ocp, 1)
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable,
            rg = 2:3,
            lb = [0, 3],
            ub = [0, 3],
        )
        @test_throws UnauthorizedCall constraint!(ocp, :variable, lb = 0, ub = 1) # the variable here is of dimension 1
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable,
            rg = 1:2,
            lb = [0, 0],
            ub = [1, 2],
        )
        @test_throws UnauthorizedCall constraint!(ocp, :variable, lb = [3, 0, 1], ub = [3, 0, 1])

        ocp = Model(variable = true)
        variable!(ocp, 1)
        @test variable_dimension(ocp) == 1

        ocp = Model(variable = true)
        variable!(ocp, 1, "vv")
        @test is_variable_dependent(ocp)
        @test variable_dimension(ocp) == 1
        @test variable_components_names(ocp) == ["vv"]

        ocp = Model(variable = true)
        variable!(ocp, 1, :vv)
        @test variable_dimension(ocp) == 1
        @test variable_components_names(ocp) == ["vv"]

        ocp = Model(variable = true)
        variable!(ocp, 2)
        @test variable_dimension(ocp) == 2

        ocp = Model(variable = true)
        variable!(ocp, 2, "vv")
        @test variable_dimension(ocp) == 2
        @test variable_components_names(ocp) == ["vv₁", "vv₂"]

        ocp = Model(variable = true)
        variable!(ocp, 2, "uu", ["vv₁", "vv₂"])
        @test variable_dimension(ocp) == 2
        @test variable_components_names(ocp) == ["vv₁", "vv₂"]

        ocp = Model(variable = true)
        @test_throws MethodError variable!(ocp, 2, ["vv1", "vv2"])

        ocp = Model(variable = true)
        variable!(ocp, 2, :vv)
        @test variable_dimension(ocp) == 2
        @test variable_components_names(ocp) == ["vv₁", "vv₂"]
    end

    @testset "time, state and control set or not" begin
        for i ∈ 1:7
            ocp = Model()

            i == 2 && begin
                time!(ocp; t0 = 0, tf = 1)
            end
            i == 3 && begin
                state!(ocp, 2)
            end
            i == 4 && begin
                control!(ocp, 1)
            end
            i == 5 && begin
                time!(ocp; t0 = 0, tf = 1)
                state!(ocp, 2)
            end
            i == 6 && begin
                time!(ocp; t0 = 0, tf = 1)
                control!(ocp, 1)
            end
            i == 7 && begin
                state!(ocp, 2)
                control!(ocp, 1)
            end

            # constraint! 1
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :initial,
                rg = 1:2:5,
                lb = [0, 0, 0],
                ub = [0, 0, 0],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :initial,
                rg = 2:3,
                lb = [0, 0],
                ub = [0, 0],
            )
            @test_throws UnauthorizedCall constraint!(ocp, :final, rg = 2, lb = 0, ub = 0)

            # constraint! 2
            @test_throws UnauthorizedCall constraint!(ocp, :initial, lb = [0, 0], ub = [0, 0])
            @test_throws UnauthorizedCall constraint!(ocp, :final, lb = 2, ub = 2) # if the state is of dimension 1

            # constraint! 3
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :initial,
                rg = 2:3,
                lb = [0, 0],
                ub = [1, 2],
            )
            @test_throws UnauthorizedCall constraint!(ocp, :final, rg = 1, lb = 0, ub = 2)
            @test_throws UnauthorizedCall constraint!(ocp, :control, rg = 1, lb = 0, ub = 2)
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                rg = 2:3,
                lb = [0, 0],
                ub = [1, 2],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :initial,
                rg = 1:2:5,
                lb = [0, 0, 0],
                ub = [1, 2, 1],
            )

            # constraint! 4
            @test_throws UnauthorizedCall constraint!(ocp, :initial, lb = [0, 0, 0], ub = [1, 2, 1])
            @test_throws UnauthorizedCall constraint!(ocp, :final, lb = [0, 0, 0], ub = [1, 2, 1])
            @test_throws UnauthorizedCall constraint!(ocp, :control, lb = [0, 0], ub = [2, 3])
            @test_throws UnauthorizedCall constraint!(ocp, :state, lb = [0, 0, 0], ub = [1, 2, 1])

            # constraint! 5
            # variable independent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :boundary,
                f = (x0, xf) -> x0[3] + xf[2],
                lb = 0,
                ub = 1,
            )

            # variable dependent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :boundary,
                f = (x0, xf, v) -> x0[3] + xf[2] * v[1],
                lb = 0,
                ub = 1,
            )

            # time independent and variable independent ocp
            @test_throws UnauthorizedCall constraint!(ocp, :control, f = u -> 2u, lb = 0, ub = 1)
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = x -> x - 1,
                lb = [0, 0, 0],
                ub = [1, 2, 1],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (x, u) -> x[1] - u,
                lb = 0,
                ub = 1,
            )

            # time dependent and variable independent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :control,
                f = (t, u) -> 2u,
                lb = 0,
                ub = 1,
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = (t, x) -> x - t,
                lb = [0, 0, 0],
                ub = [1, 2, 1],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (t, x, u) -> x[1] - u,
                lb = 0,
                ub = 1,
            )

            # time independent and variable dependent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :control,
                f = (u, v) -> 2u * v[1],
                lb = 0,
                ub = 1,
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = (x, v) -> x - v[1],
                lb = [0, 0, 0],
                ub = [1, 2, 1],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (x, u, v) -> x[1] - v[2] * u,
                lb = 0,
                ub = 1,
            )

            # time dependent and variable dependent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :control,
                f = (t, u, v) -> 2u + v[2],
                lb = 0,
                ub = 1,
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = (t, x, v) -> x - t * v[1],
                lb = [0, 0, 0],
                ub = [1, 2, 1],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (t, x, u, v) -> x[1] * v[2] - u,
                lb = 0,
                ub = 1,
            )

            # constraint! 6
            # variable independent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :boundary,
                f = (x0, xf) -> x0[3] + xf[2],
                lb = 0,
                ub = 0,
            )

            # variable dependent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :boundary,
                f = (x0, xf, v) -> x0[3] + xf[2] * v[1],
                lb = 0,
                ub = 0,
            )

            # time independent and variable independent ocp
            @test_throws UnauthorizedCall constraint!(ocp, :control, f = u -> 2u, lb = 1, ub = 1)
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = x -> x - 1,
                lb = [0, 0, 0],
                ub = [0, 0, 0],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (x, u) -> x[1] - u,
                lb = 0,
                ub = 0,
            )

            # time dependent and variable independent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :control,
                f = (t, u) -> 2u,
                lb = 1,
                ub = 1,
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = (t, x) -> x - t,
                lb = [0, 0, 0],
                ub = [0, 0, 0],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (t, x, u) -> x[1] - u,
                lb = 0,
                ub = 0,
            )

            # time independent and variable dependent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :control,
                f = (u, v) -> 2u * v[1],
                lb = 1,
                ub = 1,
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = (x, v) -> x - v[2],
                lb = [0, 0, 0],
                ub = [0, 0, 0],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (x, u) -> x[1] - u + v[1],
                lb = 0,
                ub = 0,
            )

            # time dependent and variable dependent ocp
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :control,
                f = (t, u, v) -> 2u - t * v[2],
                lb = 1,
                ub = 1,
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :state,
                f = (t, x, v) -> x - t + v[1],
                lb = [0, 0, 0],
                ub = [0, 0, 0],
            )
            @test_throws UnauthorizedCall constraint!(
                ocp,
                :mixed,
                f = (t, x, u, v) -> x[1] - u * v[1],
                lb = 0,
                ub = 0,
            )
        end
    end

    @testset "initial and / or final time already set" begin
        ocp = Model(variable = true)
        @test !CTBase.__is_time_set(ocp)
        variable!(ocp, 1)
        time!(ocp; t0 = 0, indf = 1)
        @test CTBase.__is_time_set(ocp)

        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; ind0 = 1, tf = 1)
        @test CTBase.__is_time_set(ocp)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        @test CTBase.__is_time_set(ocp)

        ocp = Model()
        @test_throws MethodError time!(ocp; t0 = 0, indf = 1)
        @test_throws MethodError time!(ocp; ind0 = 1, tf = 1)

        ocp = Model(variable = true)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, indf = 1)
        @test_throws UnauthorizedCall time!(ocp; ind0 = 1, tf = 1)

        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; t0 = 0, indf = 1)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, indf = 1)
        @test_throws UnauthorizedCall time!(ocp; ind0 = 1, tf = 1)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, tf = 1)

        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; ind0 = 1, tf = 1)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, indf = 1)
        @test_throws UnauthorizedCall time!(ocp; ind0 = 1, tf = 1)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, tf = 1)

        ocp = Model(variable = true)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, indf = 1)
        @test_throws UnauthorizedCall time!(ocp; ind0 = 1, tf = 1)

        ocp = Model(variable = true)
        time!(ocp; t0 = 0, tf = 1)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, indf = 1)
        @test_throws UnauthorizedCall time!(ocp; ind0 = 1, tf = 1)
    end

    @testset "time and variable dependence" begin
        ocp = Model()
        @test is_autonomous(ocp)
        @test is_fixed(ocp)
        @test is_time_independent(ocp)
        @test !is_time_dependent(ocp)
        @test is_variable_independent(ocp)
        @test !is_variable_dependent(ocp)

        ocp = Model(autonomous = false)
        @test !is_autonomous(ocp)
        @test is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_independent(ocp)
        @test !is_variable_dependent(ocp)

        ocp = Model(variable = true)
        @test is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_independent(ocp)
        @test !is_time_dependent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)

        ocp = Model(autonomous = false, variable = true)
        @test !is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)
    end

    @testset "time and variable dependence bis" begin
        ocp = Model()
        @test is_autonomous(ocp)
        @test is_fixed(ocp)
        @test is_time_independent(ocp)
        @test !is_time_dependent(ocp)
        @test is_variable_independent(ocp)
        @test !is_variable_dependent(ocp)

        ocp = Model(NonAutonomous)
        @test !is_autonomous(ocp)
        @test is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_independent(ocp)
        @test !is_variable_dependent(ocp)

        ocp = Model(NonFixed)
        @test is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_independent(ocp)
        @test !is_time_dependent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)

        ocp = Model(NonAutonomous, NonFixed)
        @test !is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)

        ocp = Model(NonFixed, NonAutonomous)
        @test !is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)

        @test_throws IncorrectArgument Model(NonFixed, NonAutonomous, Autonomous)
        @test_throws IncorrectArgument Model(NonFixed, NonAutonomous, Autonomous)
        @test_throws IncorrectArgument Model(NonAutonomous, Autonomous)
        @test_throws IncorrectArgument Model(NonFixed, Int64)
        @test_throws IncorrectArgument Model(NonFixed, Int64)
    end

    @testset "time and variable dependence Bool" begin
        ocp = Model()
        @test is_autonomous(ocp)
        @test is_fixed(ocp)
        @test is_time_independent(ocp)
        @test !is_time_dependent(ocp)
        @test is_variable_independent(ocp)
        @test !is_variable_dependent(ocp)

        ocp = Model(NonAutonomous)
        @test !is_autonomous(ocp)
        @test is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_independent(ocp)
        @test !is_variable_dependent(ocp)

        ocp = Model(NonFixed)
        @test is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_independent(ocp)
        @test !is_time_dependent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)

        ocp = Model(NonAutonomous, NonFixed)
        @test !is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)

        ocp = Model(NonFixed, NonAutonomous)
        @test !is_autonomous(ocp)
        @test !is_fixed(ocp)
        @test is_time_dependent(ocp)
        @test !is_time_independent(ocp)
        @test is_variable_dependent(ocp)
        @test !is_variable_independent(ocp)

        @test_throws IncorrectArgument Model(NonFixed, NonAutonomous, Autonomous)
        @test_throws IncorrectArgument Model(NonFixed, NonAutonomous, Autonomous)
        @test_throws IncorrectArgument Model(NonAutonomous, Autonomous)
        @test_throws IncorrectArgument Model(NonFixed, Int64)
        @test_throws IncorrectArgument Model(NonFixed, Int64)
    end

    @testset "state!" begin
        ocp = Model()
        state!(ocp, 1)
        @test state_dimension(ocp) == 1
        @test state_components_names(ocp) == ["x"]

        ocp = Model()
        state!(ocp, 1, "y")
        @test state_dimension(ocp) == 1
        @test state_components_names(ocp) == ["y"]

        ocp = Model()
        state!(ocp, 2)
        @test state_dimension(ocp) == 2
        @test state_components_names(ocp) == ["x₁", "x₂"]

        ocp = Model()
        @test_throws MethodError state!(ocp, 2, ["y₁", "y₂"])

        ocp = Model()
        state!(ocp, 2, :y)
        @test state_dimension(ocp) == 2
        @test state_components_names(ocp) == ["y₁", "y₂"]

        ocp = Model()
        state!(ocp, 2, "y")
        @test state_dimension(ocp) == 2
        @test state_components_names(ocp) == ["y₁", "y₂"]

        ocp = Model()
        state!(ocp, 2, "y", ["z₁", "z₂"])
        @test state_dimension(ocp) == 2
        @test state_components_names(ocp) == ["z₁", "z₂"]
    end

    @testset "control!" begin
        ocp = Model()
        control!(ocp, 1)
        @test control_dimension(ocp) == 1
        @test control_components_names(ocp) == ["u"]

        ocp = Model()
        control!(ocp, 1, "v")
        @test control_dimension(ocp) == 1
        @test control_components_names(ocp) == ["v"]

        ocp = Model()
        control!(ocp, 2)
        @test control_dimension(ocp) == 2
        @test control_components_names(ocp) == ["u₁", "u₂"]

        ocp = Model()
        @test_throws MethodError control!(ocp, 2, ["v₁", "v₂"])

        ocp = Model()
        control!(ocp, 2, :v)
        @test control_dimension(ocp) == 2
        @test control_components_names(ocp) == ["v₁", "v₂"]

        ocp = Model()
        control!(ocp, 2, "v")
        @test control_dimension(ocp) == 2
        @test control_components_names(ocp) == ["v₁", "v₂"]

        ocp = Model()
        control!(ocp, 2, "u", ["v₁", "v₂"])
        @test control_dimension(ocp) == 2
        @test control_components_names(ocp) == ["v₁", "v₂"]
    end

    @testset "time!" begin
        # initial and final times
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        @test !CTBase.has_free_initial_time(ocp)
        @test !CTBase.has_free_final_time(ocp)
        @test initial_time(ocp) == 0
        @test final_time(ocp) == 1
        @test time_name(ocp) == "t"

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1, name = "s")
        @test initial_time(ocp) == 0
        @test final_time(ocp) == 1
        @test time_name(ocp) == "s"

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1, name = :s)
        @test initial_time(ocp) == 0
        @test final_time(ocp) == 1
        @test time_name(ocp) == "s"

        # initial time
        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; t0 = 0, indf = 1)
        @test !CTBase.has_free_initial_time(ocp)
        @test CTBase.has_free_final_time(ocp)
        @test initial_time(ocp) == 0
        @test final_time(ocp) == 1
        @test time_name(ocp) == "t"

        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; t0 = 0, indf = 1, name = "s")
        @test initial_time(ocp) == 0
        @test final_time(ocp) == 1
        @test time_name(ocp) == "s"

        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; t0 = 0, indf = 1, name = :s)
        @test initial_time(ocp) == 0
        @test final_time(ocp) == 1
        @test time_name(ocp) == "s"

        # final time
        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; ind0 = 1, tf = 1)
        @test CTBase.has_free_initial_time(ocp)
        @test !CTBase.has_free_final_time(ocp)
        @test initial_time(ocp) == 1
        @test final_time(ocp) == 1
        @test time_name(ocp) == "t"

        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; ind0 = 1, tf = 1, name = "s")
        @test initial_time(ocp) == 1
        @test final_time(ocp) == 1
        @test time_name(ocp) == "s"

        ocp = Model(variable = true)
        variable!(ocp, 1)
        time!(ocp; ind0 = 1, tf = 1, name = :s)
        @test initial_time(ocp) == 1
        @test final_time(ocp) == 1
        @test time_name(ocp) == "s"
    end

    @testset "is_min vs is_max" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        objective!(ocp, :mayer, (x0, xf) -> x0[1] + xf[2])
        @test is_min(ocp)
        @test !is_max(ocp)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        objective!(ocp, :mayer, (x0, xf) -> x0[1] + xf[2], :max)
        @test is_max(ocp)
        @test !is_min(ocp)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
        @test is_min(ocp)
        @test !is_max(ocp)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        objective!(ocp, :lagrange, (x, u) -> 0.5u^2, :max)
        @test is_max(ocp)
        @test !is_min(ocp)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        objective!(ocp, :bolza, (x0, xf) -> x0[1] + xf[2], (x, u) -> x[1]^2 + u^2) # the control is of dimension 1
        @test is_min(ocp)
        @test !is_max(ocp)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        objective!(ocp, :bolza, (x0, xf) -> x0[1] + xf[2], (x, u) -> x[1]^2 + u^2, :max) # the control is of dimension 1
        @test is_max(ocp)
        @test !is_min(ocp)
    end

    @testset "constraint! 1" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        @test_throws IncorrectArgument constraint!(
            ocp,
            :initial,
            lb = [0, 1],
            ub = [0, 1],
            label = :c0,
        )
        constraint!(ocp, :initial, lb = 0, ub = 0, label = :c0)
        constraint!(ocp, :final, lb = 1, ub = 1, label = :cf)
        @test constraint(ocp, :c0)(12, ∅) == 12
        @test constraint(ocp, :cf)(∅, 12) == 12

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :initial, lb = [0, 1], ub = [0, 1], label = :c0)
        constraint!(ocp, :final, lb = [1, 2], ub = [1, 2], label = :cf)
        @test constraint(ocp, :c0)([12, 13], ∅) == [12, 13]
        @test constraint(ocp, :cf)(∅, [12, 13]) == [12, 13]

        # constraint already exists
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :initial, lb = 0, ub = 0, label = :c)
        @test_throws UnauthorizedCall constraint!(ocp, :final, lb = 0, ub = 0, label = :c)
    end

    @testset "constraint! 2" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        x = 12
        x0 = 0
        xf = 1
        constraint!(ocp, :initial, rg = 1, lb = x0, ub = x0, label = :c0)
        constraint!(ocp, :final, rg = 1, lb = xf, ub = xf, label = :cf)
        @test constraint(ocp, :c0)(x, ∅) == x
        @test constraint(ocp, :cf)(∅, x) == x

        constraint!(ocp, :initial, rg = 1, lb = x0, ub = x0, label = :c00)
        constraint!(ocp, :final, rg = 1, lb = xf, ub = xf, label = :cff)
        @test constraint(ocp, :c00)(x, ∅) == x
        @test constraint(ocp, :cff)(∅, x) == x

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        x = [12, 13]
        x0 = [0, 1]
        xf = [1, 2]
        @test_throws IncorrectArgument constraint!(
            ocp,
            :initial,
            rg = 2,
            lb = x0,
            ub = x0,
            label = :c0,
        )
        @test_throws IncorrectArgument constraint!(
            ocp,
            :final,
            rg = 2,
            lb = xf,
            ub = xf,
            label = :cf,
        )

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        x = [12, 13]
        x0 = [0, 1]
        xf = [1, 2]
        constraint!(ocp, :initial, rg = 1:2, lb = x0, ub = x0, label = :c0)
        constraint!(ocp, :final, rg = 1:2, lb = xf, ub = xf, label = :cf)
        @test constraint(ocp, :c0)(x, ∅) == x[1:2]
        @test constraint(ocp, :cf)(∅, x) == x[1:2]

        # constraint already exists
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :initial, rg = 1, lb = 0, ub = 0, label = :c)
        @test_throws UnauthorizedCall constraint!(ocp, :final, rg = 1, lb = 0, ub = 0, label = :c)
    end

    @testset "constraint! 3" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :initial, lb = 0, ub = 1, label = :c0)
        constraint!(ocp, :final, lb = 1, ub = 2, label = :cf)
        constraint!(ocp, :control, lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, lb = 0, ub = 1, label = :cs)
        @test constraint(ocp, :c0)(12, ∅) == 12
        @test constraint(ocp, :cf)(∅, 12) == 12
        @test constraint(ocp, :cu)(12) == 12
        @test constraint(ocp, :cs)(12) == 12

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        constraint!(ocp, :initial, lb = [0, 1], ub = [1, 2], label = :c0)
        constraint!(ocp, :final, lb = [1, 2], ub = [2, 3], label = :cf)
        constraint!(ocp, :control, lb = [0, 1], ub = [1, 2], label = :cu)
        constraint!(ocp, :state, lb = [0, 1], ub = [1, 2], label = :cs)
        @test constraint(ocp, :c0)([12, 13], ∅) == [12, 13]
        @test constraint(ocp, :cf)(∅, [12, 13]) == [12, 13]
        @test constraint(ocp, :cu)([12, 13]) == [12, 13]
        @test constraint(ocp, :cs)([12, 13]) == [12, 13]

        # constraint already exists
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :initial, lb = 0, ub = 1, label = :c)
        @test_throws UnauthorizedCall constraint!(ocp, :final, lb = 0, ub = 1, label = :c)
    end

    @testset "constraint! 4" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :initial, rg = 1, lb = 0, ub = 1, label = :c0)
        constraint!(ocp, :final, rg = 1, lb = 1, ub = 2, label = :cf)
        constraint!(ocp, :control, rg = 1, lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, rg = 1, lb = 0, ub = 1, label = :cs)
        @test constraint(ocp, :c0)(12, ∅) == 12
        @test constraint(ocp, :cf)(∅, 12) == 12
        @test constraint(ocp, :cu)(12) == 12
        @test constraint(ocp, :cs)(12) == 12

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        @test_throws IncorrectArgument constraint!(
            ocp,
            :initial,
            rg = 2,
            lb = [0, 1],
            ub = [1, 2],
            label = :c0,
        )
        @test_throws IncorrectArgument constraint!(
            ocp,
            :final,
            rg = 2,
            lb = [1, 2],
            ub = [2, 3],
            label = :cf,
        )
        @test_throws IncorrectArgument constraint!(
            ocp,
            :control,
            rg = 2,
            lb = [0, 1],
            ub = [1, 2],
            label = :cu,
        )
        @test_throws IncorrectArgument constraint!(
            ocp,
            :state,
            rg = 2,
            lb = [0, 1],
            ub = [1, 2],
            label = :cs,
        )

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        constraint!(ocp, :initial, rg = 1:2, lb = [0, 1], ub = [1, 2], label = :c0)
        constraint!(ocp, :final, rg = 1:2, lb = [1, 2], ub = [2, 3], label = :cf)
        constraint!(ocp, :control, rg = 1:2, lb = [0, 1], ub = [1, 2], label = :cu)
        constraint!(ocp, :state, rg = 1:2, lb = [0, 1], ub = [1, 2], label = :cs)
        @test constraint(ocp, :c0)([12, 13], ∅) == [12, 13]
        @test constraint(ocp, :cf)(∅, [12, 13]) == [12, 13]
        @test constraint(ocp, :cu)([12, 13]) == [12, 13]
        @test constraint(ocp, :cs)([12, 13]) == [12, 13]

        # constraint already exists
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :initial, rg = 1, lb = 0, ub = 1, label = :c)
        @test_throws UnauthorizedCall constraint!(ocp, :final, rg = 1, lb = 0, ub = 1, label = :c)
    end

    @testset "constraint! 5" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :boundary, f = (x0, xf) -> x0 + xf, lb = 0, ub = 0, label = :cb)
        constraint!(ocp, :control, f = u -> u, lb = 0, ub = 0, label = :cu)
        constraint!(ocp, :state, f = x -> x, lb = 0, ub = 0, label = :cs)
        constraint!(ocp, :mixed, f = (x, u) -> x + u, lb = 1, ub = 1, label = :cm)
        @test constraint(ocp, :cb)(12, 13) == 12 + 13
        @test constraint(ocp, :cu)(12) == 12
        @test constraint(ocp, :cs)(12) == 12
        @test constraint(ocp, :cm)(12, 13) == 12 + 13

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        constraint!(ocp, :boundary, f = (x0, xf) -> x0[1] + xf[1], lb = 0, ub = 0, label = :cb)
        constraint!(ocp, :control, f = u -> u[1], lb = 0, ub = 0, label = :cu)
        constraint!(ocp, :state, f = x -> x[1], lb = 0, ub = 0, label = :cs)
        constraint!(ocp, :mixed, f = (x, u) -> x[1] + u[1], lb = 1, ub = 1, label = :cm)
        @test constraint(ocp, :cb)([13, 14], [16, 17]) == 13 + 16
        @test constraint(ocp, :cu)([12, 13]) == 12
        @test constraint(ocp, :cs)([12, 13]) == 12
        @test constraint(ocp, :cm)([12, 13], [14, 15]) == 12 + 14

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 3)
        control!(ocp, 3)
        constraint!(
            ocp,
            :boundary,
            f = (x0, xf) -> [x0[1] + xf[1], x0[2] + xf[2]],
            lb = [0, 0],
            ub = [0, 0],
            label = :cb,
        )
        constraint!(ocp, :control, f = u -> u[1:2], lb = [0, 0], ub = [0, 0], label = :cu)
        constraint!(ocp, :state, f = x -> x[1:2], lb = [0, 0], ub = [0, 0], label = :cs)
        constraint!(
            ocp,
            :mixed,
            f = (x, u) -> [x[1] + u[1], x[2] + u[2]],
            lb = [0, 0],
            ub = [0, 0],
            label = :cm,
        )
        @test constraint(ocp, :cb)([13, 14, 15], [17, 18, 19]) == [13 + 17, 14 + 18]
        @test constraint(ocp, :cu)([12, 13, 14]) == [12, 13]
        @test constraint(ocp, :cs)([12, 13, 14]) == [12, 13]
        @test constraint(ocp, :cm)([12, 13, 14], [15, 16, 17]) == [12 + 15, 13 + 16]

        # constraint already exists
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :control, f = u -> u, lb = 0, ub = 1, label = :c)
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :control,
            f = u -> u,
            lb = 0,
            ub = 1,
            label = :c,
        )
    end

    @testset "constraint! 6" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :boundary, f = (x0, xf) -> x0 + xf, lb = 0, ub = 1, label = :cb)
        constraint!(ocp, :control, f = u -> u, lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, f = x -> x, lb = 0, ub = 1, label = :cs)
        constraint!(ocp, :mixed, f = (x, u) -> x + u, lb = 1, ub = 1, label = :cm)
        @test constraint(ocp, :cb)(12, 13) == 12 + 13
        @test constraint(ocp, :cu)(12) == 12
        @test constraint(ocp, :cs)(12) == 12
        @test constraint(ocp, :cm)(12, 13) == 12 + 13

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        constraint!(ocp, :boundary, f = (x0, xf) -> x0[1] + xf[1], lb = 0, ub = 1, label = :cb)
        constraint!(ocp, :control, f = u -> u[1], lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, f = x -> x[1], lb = 0, ub = 1, label = :cs)
        constraint!(ocp, :mixed, f = (x, u) -> x[1] + u[1], lb = 1, ub = 1, label = :cm)
        @test constraint(ocp, :cb)([13, 14], [16, 17]) == 13 + 16
        @test constraint(ocp, :cu)([12, 13]) == 12
        @test constraint(ocp, :cs)([12, 13]) == 12
        @test constraint(ocp, :cm)([12, 13], [14, 15]) == 12 + 14

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(
            ocp,
            :boundary,
            f = (x0, xf) -> [x0[1] + xf[1], x0[2] + xf[2]],
            lb = [0, 0],
            ub = [1, 1],
            label = :cb,
        )
        constraint!(ocp, :control, f = u -> u[1:2], lb = [0, 0], ub = [1, 1], label = :cu)
        constraint!(ocp, :state, f = x -> x[1:2], lb = [0, 0], ub = [1, 1], label = :cs)
        constraint!(
            ocp,
            :mixed,
            f = (x, u) -> [x[1] + u[1], x[2] + u[2]],
            lb = [0, 0],
            ub = [1, 1],
            label = :cm,
        )
        @test constraint(ocp, :cb)([13, 14, 15], [17, 18, 19]) == [13 + 17, 14 + 18]
        @test constraint(ocp, :cu)([12, 13, 14]) == [12, 13]
        @test constraint(ocp, :cs)([12, 13, 14]) == [12, 13]
        @test constraint(ocp, :cm)([12, 13, 14], [15, 16, 17]) == [12 + 15, 13 + 16]
    end

    @testset "constraint! 7" begin
        x = 1
        u = 2
        v = [3, 4, 5, 6]
        x0 = 7
        xf = 8
        ocp = Model(variable = true)
        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :variable, lb = [0, 0, 0, 0], ub = [1, 1, 1, 1], label = :eq1)
        constraint!(ocp, :variable, rg = 1, lb = 0, ub = 1, label = :eq2)
        constraint!(ocp, :variable, rg = 1:2, lb = [0, 0], ub = [1, 2], label = :eq3)
        constraint!(ocp, :variable, rg = 1:2:4, lb = [0, 0], ub = [-1, 1], label = :eq4)
        constraint!(
            ocp,
            :variable,
            f = v -> v .^ 2,
            lb = [0, 0, 0, 0],
            ub = [1, 0, 1, 0],
            label = :eq5,
        )
        @test constraint(ocp, :eq1)(v) == v
        @test constraint(ocp, :eq2)(v) == v[1]
        @test constraint(ocp, :eq3)(v) == v[1:2]
        @test constraint(ocp, :eq4)(v) == v[1:2:4]
        @test constraint(ocp, :eq5)(v) == v .^ 2
    end

    @testset "constraint! 8" begin
        x = 1
        u = 2
        v = [3, 4, 5, 6]
        x0 = 7
        xf = 8
        ocp = Model(variable = true)
        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :boundary, f = (x0, xf, v) -> x0 + xf + v[1], lb = 0, ub = 1, label = :cb)
        constraint!(ocp, :control, f = (u, v) -> u + v[1], lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, f = (x, v) -> x + v[1], lb = 0, ub = 1, label = :cs)
        constraint!(ocp, :mixed, f = (x, u, v) -> x + u + v[1], lb = 1, ub = 1, label = :cm)
        constraint!(ocp, :variable, lb = [0, 0, 0, 0], ub = [0, 0, 0, 0], label = :eq1)
        constraint!(ocp, :variable, rg = 1, lb = 0, ub = 0, label = :eq2)
        constraint!(ocp, :variable, rg = 1:2, lb = [0, 0], ub = [0, 0], label = :eq3)
        constraint!(ocp, :variable, rg = 1:2:4, lb = [0, 0], ub = [0, 0], label = :eq4)
        constraint!(
            ocp,
            :variable,
            f = v -> v .^ 2,
            lb = [0, 0, 0, 0],
            ub = [0, 0, 0, 0],
            label = :eq5,
        )
        @test constraint(ocp, :cb)(x0, xf, v) == x0 + xf + v[1]
        @test constraint(ocp, :cu)(u, v) == u + v[1]
        @test constraint(ocp, :cs)(x, v) == x + v[1]
        @test constraint(ocp, :cm)(x, u, v) == x + u + v[1]
        @test constraint(ocp, :eq1)(v) == v
        @test constraint(ocp, :eq2)(v) == v[1]
        @test constraint(ocp, :eq3)(v) == v[1:2]
        @test constraint(ocp, :eq4)(v) == v[1:2:4]
        @test constraint(ocp, :eq5)(v) == v .^ 2
    end

    @testset "constraint! 9" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        dynamics!(ocp, (x, u) -> x + u)
        @test dynamics(ocp)(1, 2) == 3

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        dynamics!(ocp, (x, u) -> x[1] + u[1])
        @test dynamics(ocp)([1, 2], [3, 4]) == 4

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        dynamics!(ocp, (x, u) -> [x[1] + u[1], x[2] + u[2]])
        @test dynamics(ocp)([1, 2], [3, 4]) == [4, 6]

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        dynamics!(ocp, (x, u) -> [x[1] + u, x[2] + u])
        @test dynamics(ocp)([1, 2], 3) == [4, 5]
    end

    @testset "constraint! 10" begin
        ocp = Model(autonomous = false)
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :initial, lb = 0, ub = 1, label = :c0)
        constraint!(ocp, :final, lb = 1, ub = 2, label = :cf)
        @test constraint(ocp, :c0)(12, ∅) == 12
        @test constraint(ocp, :cf)(∅, 12) == 12
    end

    @testset "constraint! 11" begin
        dummy(u) = u^2 + u

        ocp = Model(variable = true)
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        variable!(ocp, 3)
        constraint!(ocp, :state, lb = 0, ub = 1, label = :c0)
        constraint!(ocp, :control, f = dummy, lb = 1, ub = 1, label = :c1)
        constraint!(ocp, :variable, rg = 1:2:3, lb = [-Inf, -Inf], ub = [0, 0], label = :c2)

        ocp_bis = Model(variable = true)
        time!(ocp_bis; t0 = 0, tf = 1)
        state!(ocp_bis, 1)
        control!(ocp_bis, 1)
        variable!(ocp_bis, 3)
        constraint!(ocp_bis, :state, lb = 0, ub = 1, label = :c0)
        constraint!(ocp_bis, :control, f = dummy, ub = 1, lb = 1, label = :c1)
        constraint!(ocp_bis, :variable, rg = 1:2:3, ub = [0, 0], label = :c2)

        @test constraints(ocp) == constraints(ocp_bis)

        ocp_ter = Model(variable = true)
        time!(ocp_ter; t0 = 0, tf = 1)
        state!(ocp_ter, 3)
        control!(ocp_ter, 1)
        variable!(ocp_ter, 1)
        constraint!(ocp_ter, :variable, lb = 1, ub = 1, label = :c0)
        constraint!(ocp_ter, :control, f = dummy, lb = 1, ub = Inf, label = :c1)
        constraint!(ocp_ter, :state, rg = 1:2:3, lb = [0, 0], ub = [0, 0], label = :c2)

        ocp_quad = Model(variable = true)
        time!(ocp_quad; t0 = 0, tf = 1)
        state!(ocp_quad, 3)
        control!(ocp_quad, 1)
        variable!(ocp_quad, 1)
        constraint!(ocp_quad, :variable, lb = 1, ub = 1, label = :c0)
        constraint!(ocp_quad, :control, f = dummy, lb = 1, label = :c1)
        constraint!(ocp_quad, :state, rg = 1:2:3, lb = [0, 0], ub = [0, 0], label = :c2)

        @test constraints(ocp_ter) == constraints(ocp_quad)

        ocp_error = ocp_error = Model(variable = true)
        time!(ocp_error; t0 = 0, tf = 1)
        state!(ocp_error, 3)
        control!(ocp_error, 1)
        variable!(ocp_error, 1)
        @test_throws UnauthorizedCall constraint!(ocp_error, :variable)
        @test_throws UnauthorizedCall constraint!(ocp_error, :control, f = dummy, label = :c1)
        @test_throws UnauthorizedCall constraint!(ocp_error, :state, rg = 1:2:3, label = :c2)
        @test_throws IncorrectArgument constraint!(
            ocp_error,
            :state,
            rg = 1:2:3,
            f = dummy,
            lb = [0, 0],
            ub = [0, 0],
            label = :c3,
        )
        @test_throws IncorrectArgument constraint!(
            ocp_error,
            :state,
            f = dummy,
            rg = 1:2:3,
            lb = [0, 0],
            ub = [0, 0],
            label = :c4,
        )
        @test_throws IncorrectArgument constraint!(
            ocp_error,
            :foo,
            lb = [0, 0],
            ub = [0, 0],
            label = :c5,
        )
    end

    @testset "remove_constraint! and constraints_labels" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        constraint!(ocp, :boundary, f = (x0, xf) -> x0 + xf, lb = 0, ub = 1, label = :cb)
        constraint!(ocp, :control, f = u -> u, lb = 0, ub = 1, label = :cu)
        k = constraints_labels(ocp)
        @test :cb ∈ k
        @test :cu ∈ k
        remove_constraint!(ocp, :cb)
        k = constraints_labels(ocp)
        @test :cb ∉ k
        @test_throws IncorrectArgument remove_constraint!(ocp, :dummy_con)
    end

    @testset "nlp_constraints! without variable" begin
        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :initial, rg = 2, lb = 10, ub = 10, label = :ci)
        constraint!(ocp, :final, rg = 1, lb = 1, ub = 1, label = :cf)
        constraint!(ocp, :control, lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, lb = [0, 1], ub = [1, 2], label = :cs)
        constraint!(ocp, :boundary, f = (x0, xf) -> x0[2] + xf[2], lb = 0, ub = 1, label = :cb)
        constraint!(ocp, :control, f = u -> u, lb = 0, ub = 1, label = :cuu)
        constraint!(ocp, :state, f = x -> x, lb = [0, 1], ub = [1, 2], label = :css)
        constraint!(ocp, :mixed, f = (x, u) -> x[1] + u, lb = 1, ub = 1, label = :cm)

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ, ξu),
        (ηl, η, ηu),
        (ψl, ψ, ψu),
        (ϕl, ϕ, ϕu),
        (θl, θ, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = Real[]

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
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([1])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([1, 2])

        # variable
        @test sort(vl) == sort([])
        @test sort(vind) == sort([])
        @test sort(vu) == sort([])
        @test sort(θl) == sort([])
        @test sort(θu) == sort([])
        @test sort(θ(v)) == sort([])

        # dimensions (set)
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 0
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 0
    end

    @testset "nlp_constraints! with variable" begin
        ocp = Model(variable = true)
        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :initial, rg = 2, lb = 10, ub = 10, label = :ci)
        constraint!(ocp, :final, rg = 1, lb = 1, ub = 1, label = :cf)
        constraint!(ocp, :control, lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, lb = [0, 1], ub = [1, 2], label = :cs)
        constraint!(
            ocp,
            :boundary,
            f = (x0, xf, v) -> x0[2] + xf[2] + v[1],
            lb = 0,
            ub = 1,
            label = :cb,
        )
        constraint!(ocp, :control, f = (u, v) -> u + v[2], lb = 0, ub = 1, label = :cuu)
        constraint!(ocp, :state, f = (x, v) -> x + v[1:2], lb = [0, 1], ub = [1, 2], label = :css)
        constraint!(ocp, :mixed, f = (x, u, v) -> x[1] + u + v[2], lb = 1, ub = 1, label = :cm)
        constraint!(ocp, :variable, lb = [0, 0, 0, 0], ub = [5, 5, 5, 5], label = :cv1)
        constraint!(ocp, :variable, rg = 1:2, lb = [1, 2], ub = [3, 4], label = :cv2)
        constraint!(ocp, :variable, rg = 3, lb = 2, ub = 3, label = :cv3)
        constraint!(ocp, :variable, f = v -> v[3]^2, lb = 0, ub = 1, label = :cv4)

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ, ξu),
        (ηl, η, ηu),
        (ψl, ψ, ψu),
        (ϕl, ϕ, ϕu),
        (θl, θ, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = [1, 2, 3, 4]

        # control
        @test sort(ξl) == sort([0])
        @test sort(ξu) == sort([1])
        @test sort(ξ(-1, 1, v)) == sort([1 + v[2]])

        # state
        @test sort(ηl) == sort([0, 1])
        @test sort(ηu) == sort([1, 2])
        @test sort(η(-1, [1, 1], v)) == sort([1, 1] + v[1:2])

        # mixed
        @test sort(ψl) == sort([1])
        @test sort(ψu) == sort([1])
        @test sort(ψ(-1, [1, 1], 2, v)) == sort([3 + v[2]])

        # boundary
        @test sort(ϕl) == sort([10, 1, 0])
        @test sort(ϕu) == sort([10, 1, 1])
        @test sort(ϕ([1, 3], [4, 100], v)) == sort([3, 4, 103 + v[1]])

        # variable
        @test sort(θl) == sort([0])
        @test sort(θu) == sort([1])
        @test sort(θ(v)) == sort([v[3]^2])

        # box constraint
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([1])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([1, 2])
        @test sort(vl) == sort([0, 0, 0, 0, 1, 2, 2])
        @test sort(vind) == sort([1, 2, 3, 4, 1, 2, 3])
        @test sort(vu) == sort([5, 5, 5, 5, 3, 4, 3])

        # dimensions
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 1
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 7
    end

    @testset "nlp_constraints! without variable (in place)" begin
        ocp = Model(; in_place = true)
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :initial, rg = 2, lb = 10, ub = 10, label = :ci)
        constraint!(ocp, :final, rg = 1, lb = 1, ub = 1, label = :cf)
        constraint!(ocp, :control, lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, lb = [0, 1], ub = [1, 2], label = :cs)
        constraint!(
            ocp,
            :boundary,
            f = (r, x0, xf) -> (r[:] .= x0[2] + xf[2]; nothing),
            lb = 0,
            ub = 1,
            label = :cb,
        )
        constraint!(ocp, :control, f = (r, u) -> (r[:] .= u; nothing), lb = 0, ub = 1, label = :cuu)
        constraint!(
            ocp,
            :state,
            f = (r, x) -> (r[:] .= x; nothing),
            lb = [0, 1],
            ub = [1, 2],
            label = :css,
        )
        constraint!(
            ocp,
            :mixed,
            f = (r, x, u) -> (r[:] .= x[1] + u; nothing),
            lb = 1,
            ub = 1,
            label = :cm,
        )

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ!, ξu),
        (ηl, η!, ηu),
        (ψl, ψ!, ψu),
        (ϕl, ϕ!, ϕu),
        (θl, θ!, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = Real[]

        # control
        @test sort(ξl) == sort([0])
        @test sort(ξu) == sort([1])
        r = [0.0]
        ξ!(r, -1, 1, v)
        @test sort(r) == sort([1])

        # state
        @test sort(ηl) == sort([0, 1])
        @test sort(ηu) == sort([1, 2])
        r = [0.0, 0.0]
        η!(r, -1, [1, 1], v)
        @test sort(r) == sort([1, 1])

        # mixed
        @test sort(ψl) == sort([1])
        @test sort(ψu) == sort([1])
        r = [0.0]
        ψ!(r, -1, [1, 1], 2, v)
        @test sort(r) == sort([3])

        # boundary
        @test sort(ϕl) == sort([10, 1, 0])
        @test sort(ϕu) == sort([10, 1, 1])
        r = [0.0, 0.0, 0.0]
        ϕ!(r, [1, 3], [4, 100], v)
        @test sort(r) == sort([3, 4, 103])

        # box constraint
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([1])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([1, 2])

        # variable
        @test sort(vl) == sort([])
        @test sort(vind) == sort([])
        @test sort(vu) == sort([])
        @test sort(θl) == sort([])
        @test sort(θu) == sort([])
        r = Real[]
        θ!(r, v)
        @test sort(r) == sort([])

        # dimensions (set)
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 0
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 0
    end

    @testset "nlp_constraints! with variable (in place)" begin
        ocp = Model(; variable = true, in_place = true)
        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)
        constraint!(ocp, :initial, rg = 2, lb = 10, ub = 10, label = :ci)
        constraint!(ocp, :final, rg = 1, lb = 1, ub = 1, label = :cf)
        constraint!(ocp, :control, lb = 0, ub = 1, label = :cu)
        constraint!(ocp, :state, lb = [0, 1], ub = [1, 2], label = :cs)
        constraint!(
            ocp,
            :boundary,
            f = (r, x0, xf, v) -> (r[:] .= x0[2] + xf[2] + v[1]; nothing),
            lb = 0,
            ub = 1,
            label = :cb,
        )
        constraint!(
            ocp,
            :control,
            f = (r, u, v) -> (r[:] .= u + v[2]; nothing),
            lb = 0,
            ub = 1,
            label = :cuu,
        )
        constraint!(
            ocp,
            :state,
            f = (r, x, v) -> (r[:] .= x + v[1:2]; nothing),
            lb = [0, 1],
            ub = [1, 2],
            label = :css,
        )
        constraint!(
            ocp,
            :mixed,
            f = (r, x, u, v) -> (r[:] .= x[1] + u + v[2]; nothing),
            lb = 1,
            ub = 1,
            label = :cm,
        )
        constraint!(ocp, :variable, lb = [0, 0, 0, 0], ub = [5, 5, 5, 5], label = :cv1)
        constraint!(ocp, :variable, rg = 1:2, lb = [1, 2], ub = [3, 4], label = :cv2)
        constraint!(ocp, :variable, rg = 3, lb = 2, ub = 3, label = :cv3)
        constraint!(
            ocp,
            :variable,
            f = (r, v) -> (r[:] .= v[3]^2; nothing),
            lb = 0,
            ub = 1,
            label = :cv4,
        )

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ!, ξu),
        (ηl, η!, ηu),
        (ψl, ψ!, ψu),
        (ϕl, ϕ!, ϕu),
        (θl, θ!, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = [1, 2, 3, 4]

        # control
        @test sort(ξl) == sort([0])
        @test sort(ξu) == sort([1])
        r = [0.0]
        ξ!(r, -1, 1, v)
        @test sort(r) == sort([1 + v[2]])

        # state
        @test sort(ηl) == sort([0, 1])
        @test sort(ηu) == sort([1, 2])
        r = [0.0, 0.0]
        η!(r, -1, [1, 1], v)
        @test sort(r) == sort([1, 1] + v[1:2])

        # mixed
        @test sort(ψl) == sort([1])
        @test sort(ψu) == sort([1])
        r = [0.0]
        ψ!(r, -1, [1, 1], 2, v)
        @test sort(r) == sort([3 + v[2]])

        # boundary
        @test sort(ϕl) == sort([10, 1, 0])
        @test sort(ϕu) == sort([10, 1, 1])
        r = [0.0, 0.0, 0.0]
        ϕ!(r, [1, 3], [4, 100], v)
        @test sort(r) == sort([3, 4, 103 + v[1]])

        # variable
        @test sort(θl) == sort([0])
        @test sort(θu) == sort([1])
        r = [0.0]
        θ!(r, v)
        @test sort(r) == sort([v[3]^2])

        # box constraint
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([1])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([1, 2])
        @test sort(vl) == sort([0, 0, 0, 0, 1, 2, 2])
        @test sort(vind) == sort([1, 2, 3, 4, 1, 2, 3])
        @test sort(vu) == sort([5, 5, 5, 5, 3, 4, 3])

        # dimensions
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 1
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 7
    end

    @testset "val vs lb and ub, errors" begin
        ocp = Model(variable = true)

        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)

        # error val with ub
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :initial;
            rg = 2,
            val = 10,
            ub = 10,
            label = :ci,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :final;
            rg = 1,
            val = 1,
            ub = 1,
            label = :cf,
        )
        @test_throws UnauthorizedCall constraint!(ocp, :control; val = 0, ub = 0, label = :cu)
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :state;
            val = [0, 1],
            ub = [0, 1],
            label = :cs,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :boundary;
            f = (x0, xf, v) -> x0[2] + xf[2] + v[1],
            val = 2,
            ub = 2,
            label = :cb,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :control;
            f = (u, v) -> u + v[2],
            val = 20,
            ub = 20,
            label = :cuu,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :state;
            f = (x, v) -> x + v[1:2],
            val = [100, 101],
            ub = [100, 101],
            label = :css,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :mixed;
            f = (x, u, v) -> x[1] + u + v[2],
            val = -1,
            ub = -1,
            label = :cm,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            val = [5, 5, 5, 5],
            ub = [5, 5, 5, 5],
            label = :cv1,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            rg = 1:2,
            val = [10, 20],
            ub = [10, 20],
            label = :cv2,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            rg = 3,
            val = 1000,
            ub = 1000,
            label = :cv3,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            f = v -> v[3]^2,
            val = -10,
            ub = -10,
            label = :cv4,
        )

        ocp = Model(variable = true)

        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)

        # error val with lb
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :initial;
            rg = 2,
            val = 10,
            lb = 10,
            label = :ci,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :final;
            rg = 1,
            val = 1,
            lb = 1,
            label = :cf,
        )
        @test_throws UnauthorizedCall constraint!(ocp, :control; val = 0, lb = 0, label = :cu)
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :state;
            val = [0, 1],
            lb = [0, 1],
            label = :cs,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :boundary;
            f = (x0, xf, v) -> x0[2] + xf[2] + v[1],
            val = 2,
            lb = 2,
            label = :cb,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :control;
            f = (u, v) -> u + v[2],
            val = 20,
            lb = 20,
            label = :cuu,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :state;
            f = (x, v) -> x + v[1:2],
            val = [100, 101],
            lb = [100, 101],
            label = :css,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :mixed;
            f = (x, u, v) -> x[1] + u + v[2],
            val = -1,
            lb = -1,
            label = :cm,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            val = [5, 5, 5, 5],
            lb = [5, 5, 5, 5],
            label = :cv1,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            rg = 1:2,
            val = [10, 20],
            lb = [10, 20],
            label = :cv2,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            rg = 3,
            val = 1000,
            lb = 1000,
            label = :cv3,
        )
        @test_throws UnauthorizedCall constraint!(
            ocp,
            :variable;
            f = v -> v[3]^2,
            val = -10,
            lb = -10,
            label = :cv4,
        )
    end

    @testset "val vs lb and ub, 1/2" begin
        ocp = Model(variable = true)

        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)

        constraint!(ocp, :initial; rg = 2, lb = 10, ub = 10, label = :ci)
        constraint!(ocp, :final; rg = 1, lb = 1, ub = 1, label = :cf)
        constraint!(ocp, :control; lb = 0, ub = 0, label = :cu)
        constraint!(ocp, :state; lb = [0, 1], ub = [0, 1], label = :cs)
        constraint!(
            ocp,
            :boundary;
            f = (x0, xf, v) -> x0[2] + xf[2] + v[1],
            lb = 2,
            ub = 2,
            label = :cb,
        )
        constraint!(ocp, :control; f = (u, v) -> u + v[2], lb = 20, ub = 20, label = :cuu)
        constraint!(
            ocp,
            :state;
            f = (x, v) -> x + v[1:2],
            lb = [100, 101],
            ub = [100, 101],
            label = :css,
        )
        constraint!(ocp, :mixed; f = (x, u, v) -> x[1] + u + v[2], lb = -1, ub = -1, label = :cm)
        constraint!(ocp, :variable; lb = [5, 5, 5, 5], ub = [5, 5, 5, 5], label = :cv1)
        constraint!(ocp, :variable; rg = 1:2, lb = [10, 20], ub = [10, 20], label = :cv2)
        constraint!(ocp, :variable; rg = 3, lb = 1000, ub = 1000, label = :cv3)
        constraint!(ocp, :variable; f = v -> v[3]^2, lb = -10, ub = -10, label = :cv4)

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ, ξu),
        (ηl, η, ηu),
        (ψl, ψ, ψu),
        (ϕl, ϕ, ϕu),
        (θl, θ, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = [1, 2, 3, 4]

        # control
        @test sort(ξl) == sort([20])
        @test sort(ξu) == sort([20])
        @test sort(ξ(-1, 1, v)) == sort([1 + v[2]])

        # state
        @test sort(ηl) == sort([100, 101])
        @test sort(ηu) == sort([100, 101])
        @test sort(η(-1, [1, 1], v)) == sort([1, 1] + v[1:2])

        # mixed
        @test sort(ψl) == sort([-1])
        @test sort(ψu) == sort([-1])
        @test sort(ψ(-1, [1, 1], 2, v)) == sort([3 + v[2]])

        # boundary
        @test sort(ϕl) == sort([10, 1, 2])
        @test sort(ϕu) == sort([10, 1, 2])
        @test sort(ϕ([1, 3], [4, 100], v)) == sort([3, 4, 103 + v[1]])

        # variable
        @test sort(θl) == sort([-10])
        @test sort(θu) == sort([-10])
        @test sort(θ(v)) == sort([v[3]^2])

        # box constraint
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([0])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([0, 1])
        @test sort(vl) == sort([5, 5, 5, 5, 10, 20, 1000])
        @test sort(vind) == sort([1, 2, 3, 4, 1, 2, 3])
        @test sort(vu) == sort([5, 5, 5, 5, 10, 20, 1000])

        # dimensions
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 1
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 7
    end

    @testset "val vs lb and ub, 2/2" begin
        ocp = Model(variable = true)

        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)

        constraint!(ocp, :initial; rg = 2, val = 10, label = :ci)
        constraint!(ocp, :final; rg = 1, val = 1, label = :cf)
        constraint!(ocp, :control; val = 0, label = :cu)
        constraint!(ocp, :state; val = [0, 1], label = :cs)
        constraint!(ocp, :boundary; f = (x0, xf, v) -> x0[2] + xf[2] + v[1], val = 2, label = :cb)
        constraint!(ocp, :control; f = (u, v) -> u + v[2], val = 20, label = :cuu)
        constraint!(ocp, :state; f = (x, v) -> x + v[1:2], val = [100, 101], label = :css)
        constraint!(ocp, :mixed; f = (x, u, v) -> x[1] + u + v[2], val = -1, label = :cm)
        constraint!(ocp, :variable; val = [5, 5, 5, 5], label = :cv1)
        constraint!(ocp, :variable; rg = 1:2, val = [10, 20], label = :cv2)
        constraint!(ocp, :variable; rg = 3, val = 1000, label = :cv3)
        constraint!(ocp, :variable; f = v -> v[3]^2, val = -10, label = :cv4)

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ, ξu),
        (ηl, η, ηu),
        (ψl, ψ, ψu),
        (ϕl, ϕ, ϕu),
        (θl, θ, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = [1, 2, 3, 4]

        # control
        @test sort(ξl) == sort([20])
        @test sort(ξu) == sort([20])
        @test sort(ξ(-1, 1, v)) == sort([1 + v[2]])

        # state
        @test sort(ηl) == sort([100, 101])
        @test sort(ηu) == sort([100, 101])
        @test sort(η(-1, [1, 1], v)) == sort([1, 1] + v[1:2])

        # mixed
        @test sort(ψl) == sort([-1])
        @test sort(ψu) == sort([-1])
        @test sort(ψ(-1, [1, 1], 2, v)) == sort([3 + v[2]])

        # boundary
        @test sort(ϕl) == sort([10, 1, 2])
        @test sort(ϕu) == sort([10, 1, 2])
        @test sort(ϕ([1, 3], [4, 100], v)) == sort([3, 4, 103 + v[1]])

        # variable
        @test sort(θl) == sort([-10])
        @test sort(θu) == sort([-10])
        @test sort(θ(v)) == sort([v[3]^2])

        # box constraint
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([0])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([0, 1])
        @test sort(vl) == sort([5, 5, 5, 5, 10, 20, 1000])
        @test sort(vind) == sort([1, 2, 3, 4, 1, 2, 3])
        @test sort(vu) == sort([5, 5, 5, 5, 10, 20, 1000])

        # dimensions
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 1
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 7
    end

    @testset "val vs lb and ub, 1/2 (in place)" begin
        ocp = Model(variable = true, in_place = true)

        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)

        constraint!(ocp, :initial; rg = 2, lb = 10, ub = 10, label = :ci)
        constraint!(ocp, :final; rg = 1, lb = 1, ub = 1, label = :cf)
        constraint!(ocp, :control; lb = 0, ub = 0, label = :cu)
        constraint!(ocp, :state; lb = [0, 1], ub = [0, 1], label = :cs)
        constraint!(
            ocp,
            :boundary;
            f = (r, x0, xf, v) -> (r[:] .= x0[2] + xf[2] + v[1]; nothing),
            lb = 2,
            ub = 2,
            label = :cb,
        )
        constraint!(
            ocp,
            :control;
            f = (r, u, v) -> (r[:] .= u + v[2]; nothing),
            lb = 20,
            ub = 20,
            label = :cuu,
        )
        constraint!(
            ocp,
            :state;
            f = (r, x, v) -> (r[:] .= x + v[1:2]; nothing),
            lb = [100, 101],
            ub = [100, 101],
            label = :css,
        )
        constraint!(
            ocp,
            :mixed;
            f = (r, x, u, v) -> (r[:] .= x[1] + u + v[2]; nothing),
            lb = -1,
            ub = -1,
            label = :cm,
        )
        constraint!(ocp, :variable; lb = [5, 5, 5, 5], ub = [5, 5, 5, 5], label = :cv1)
        constraint!(ocp, :variable; rg = 1:2, lb = [10, 20], ub = [10, 20], label = :cv2)
        constraint!(ocp, :variable; rg = 3, lb = 1000, ub = 1000, label = :cv3)
        constraint!(
            ocp,
            :variable;
            f = (r, v) -> (r[:] .= v[3]^2; nothing),
            lb = -10,
            ub = -10,
            label = :cv4,
        )

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ!, ξu),
        (ηl, η!, ηu),
        (ψl, ψ!, ψu),
        (ϕl, ϕ!, ϕu),
        (θl, θ!, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = [1, 2, 3, 4]

        # control
        @test sort(ξl) == sort([20])
        @test sort(ξu) == sort([20])
        r = [0.0]
        ξ!(r, -1, 1, v)
        @test sort(r) == sort([1 + v[2]])

        # state
        @test sort(ηl) == sort([100, 101])
        @test sort(ηu) == sort([100, 101])
        r = [0.0, 0.0]
        η!(r, -1, [1, 1], v)
        @test sort(r) == sort([1, 1] + v[1:2])

        # mixed
        @test sort(ψl) == sort([-1])
        @test sort(ψu) == sort([-1])
        r = [0.0]
        ψ!(r, -1, [1, 1], 2, v)
        @test sort(r) == sort([3 + v[2]])

        # boundary
        @test sort(ϕl) == sort([10, 1, 2])
        @test sort(ϕu) == sort([10, 1, 2])
        r = [0.0, 0.0, 0.0]
        ϕ!(r, [1, 3], [4, 100], v)
        @test sort(r) == sort([3, 4, 103 + v[1]])

        # variable
        @test sort(θl) == sort([-10])
        @test sort(θu) == sort([-10])
        r = [0.0]
        θ!(r, v)
        @test sort(r) == sort([v[3]^2])

        # box constraint
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([0])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([0, 1])
        @test sort(vl) == sort([5, 5, 5, 5, 10, 20, 1000])
        @test sort(vind) == sort([1, 2, 3, 4, 1, 2, 3])
        @test sort(vu) == sort([5, 5, 5, 5, 10, 20, 1000])

        # dimensions
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 1
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 7
    end

    @testset "val vs lb and ub, 2/2 (in place)" begin
        ocp = Model(variable = true, in_place = true)

        time!(ocp; t0 = 0, tf = 1)
        variable!(ocp, 4)
        state!(ocp, 2)
        control!(ocp, 1)

        constraint!(ocp, :initial; rg = 2, val = 10, label = :ci)
        constraint!(ocp, :final; rg = 1, val = 1, label = :cf)
        constraint!(ocp, :control; val = 0, label = :cu)
        constraint!(ocp, :state; val = [0, 1], label = :cs)
        constraint!(
            ocp,
            :boundary;
            f = (r, x0, xf, v) -> (r[:] .= x0[2] + xf[2] + v[1]; nothing),
            val = 2,
            label = :cb,
        )
        constraint!(
            ocp,
            :control;
            f = (r, u, v) -> (r[:] .= u + v[2]; nothing),
            val = 20,
            label = :cuu,
        )
        constraint!(
            ocp,
            :state;
            f = (r, x, v) -> (r[:] .= x + v[1:2]; nothing),
            val = [100, 101],
            label = :css,
        )
        constraint!(
            ocp,
            :mixed;
            f = (r, x, u, v) -> (r[:] .= x[1] + u + v[2]; nothing),
            val = -1,
            label = :cm,
        )
        constraint!(ocp, :variable; val = [5, 5, 5, 5], label = :cv1)
        constraint!(ocp, :variable; rg = 1:2, val = [10, 20], label = :cv2)
        constraint!(ocp, :variable; rg = 3, val = 1000, label = :cv3)
        constraint!(
            ocp,
            :variable;
            f = (r, v) -> (r[:] .= v[3]^2; nothing),
            val = -10,
            label = :cv4,
        )

        # dimensions (not set yet)
        @test dim_control_constraints(ocp) === nothing
        @test dim_state_constraints(ocp) === nothing
        @test dim_mixed_constraints(ocp) === nothing
        @test dim_path_constraints(ocp) === nothing
        @test dim_boundary_constraints(ocp) === nothing
        @test dim_variable_constraints(ocp) === nothing
        @test dim_control_range(ocp) === nothing
        @test dim_state_range(ocp) === nothing
        @test dim_variable_range(ocp) === nothing

        (ξl, ξ!, ξu),
        (ηl, η!, ηu),
        (ψl, ψ!, ψu),
        (ϕl, ϕ!, ϕu),
        (θl, θ!, θu),
        (ul, uind, uu),
        (xl, xind, xu),
        (vl, vind, vu) = nlp_constraints!(ocp)

        v = [1, 2, 3, 4]

        # control
        @test sort(ξl) == sort([20])
        @test sort(ξu) == sort([20])
        r = [0.0]
        ξ!(r, -1, 1, v)
        @test sort(r) == sort([1 + v[2]])

        # state
        @test sort(ηl) == sort([100, 101])
        @test sort(ηu) == sort([100, 101])
        r = [0.0, 0.0]
        η!(r, -1, [1, 1], v)
        @test sort(r) == sort([1, 1] + v[1:2])

        # mixed
        @test sort(ψl) == sort([-1])
        @test sort(ψu) == sort([-1])
        r = [0.0]
        ψ!(r, -1, [1, 1], 2, v)
        @test sort(r) == sort([3 + v[2]])

        # boundary
        @test sort(ϕl) == sort([10, 1, 2])
        @test sort(ϕu) == sort([10, 1, 2])
        r = [0.0, 0.0, 0.0]
        ϕ!(r, [1, 3], [4, 100], v)
        @test sort(r) == sort([3, 4, 103 + v[1]])

        # variable
        @test sort(θl) == sort([-10])
        @test sort(θu) == sort([-10])
        r = [0.0]
        θ!(r, v)
        @test sort(r) == sort([v[3]^2])

        # box constraint
        @test sort(ul) == sort([0])
        @test sort(uind) == sort([1])
        @test sort(uu) == sort([0])
        @test sort(xl) == sort([0, 1])
        @test sort(xind) == sort([1, 2])
        @test sort(xu) == sort([0, 1])
        @test sort(vl) == sort([5, 5, 5, 5, 10, 20, 1000])
        @test sort(vind) == sort([1, 2, 3, 4, 1, 2, 3])
        @test sort(vu) == sort([5, 5, 5, 5, 10, 20, 1000])

        # dimensions
        @test dim_control_constraints(ocp) == 1
        @test dim_state_constraints(ocp) == 2
        @test dim_mixed_constraints(ocp) == 1
        @test dim_path_constraints(ocp) == 4
        @test dim_boundary_constraints(ocp) == 3
        @test dim_variable_constraints(ocp) == 1
        @test dim_control_range(ocp) == 1
        @test dim_state_range(ocp) == 2
        @test dim_variable_range(ocp) == 7
    end

    @testset "objective!" begin
        ocp = Model()
        @test_throws UnauthorizedCall objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
        @test_throws UnauthorizedCall objective!(ocp, :mayer, (t0, x0, tf, xf) -> 0.5x0^2)
        @test_throws UnauthorizedCall objective!(
            ocp,
            :bolza,
            (t0, x0, tf, xf) -> 0.5x0^2,
            (x, u) -> 0.5u^2,
        )

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
        @test lagrange(ocp)(1, 2) == 2

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)
        @test lagrange(ocp)([1, 2], [3, 4]) == 4.5

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        objective!(ocp, :mayer, (x0, xf) -> 0.5x0^2)
        @test mayer(ocp)(2, 3) == 2

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        objective!(ocp, :mayer, (x0, xf) -> 0.5x0[1]^2)
        @test mayer(ocp)([2, 3], [5, 6]) == 2

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        objective!(ocp, :bolza, (x0, xf) -> 0.5x0^2, (x, u) -> 0.5u^2)
        @test mayer(ocp)(2, 3) == 2
        @test lagrange(ocp)(1, 2) == 2

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        objective!(ocp, :bolza, (x0, xf) -> 0.5x0[1]^2, (x, u) -> 0.5u[1]^2)
        @test mayer(ocp)([2, 3], [5, 6]) == 2
        @test lagrange(ocp)([1, 2], [3, 4]) == 4.5

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        objective!(ocp, :lagrange, (x, u) -> 0.5u[1]^2)
        @test lagrange(ocp)([1, 2], [3, 4]) == 4.5
        @test isnothing(mayer(ocp))

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 2)
        control!(ocp, 2)
        objective!(ocp, :mayer, (x0, xf) -> 0.5x0[1]^2)
        @test mayer(ocp)([2, 3], [5, 6]) == 2
        @test isnothing(lagrange(ocp))
    end

    @testset "redeclarations" begin
        ocp = Model(variable = true)
        variable!(ocp, 1)
        @test_throws UnauthorizedCall variable!(ocp, 1)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        @test_throws UnauthorizedCall time!(ocp; t0 = 0, tf = 1)

        ocp = Model()
        state!(ocp, 1)
        @test_throws UnauthorizedCall state!(ocp, 1)

        ocp = Model()
        control!(ocp, 1)
        @test_throws UnauthorizedCall control!(ocp, 1)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        dynamics!(ocp, (x, u) -> x + u)
        @test_throws UnauthorizedCall dynamics!(ocp, (x, u) -> x + u)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        objective!(ocp, :mayer, (x0, xf) -> x0 + xf)
        @test_throws UnauthorizedCall objective!(ocp, :mayer, (x0, xf) -> x0 + xf)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        objective!(ocp, :lagrange, (x, u) -> x + u)
        @test_throws UnauthorizedCall objective!(ocp, :lagrange, (x, u) -> x + u)

        ocp = Model()
        time!(ocp; t0 = 0, tf = 1)
        state!(ocp, 1)
        control!(ocp, 1)
        objective!(ocp, :bolza, (x0, xf) -> x0 + xf, (x, u) -> x + u)
        @test_throws UnauthorizedCall objective!(ocp, :bolza, (x0, xf) -> x0 + xf, (x, u) -> x + u)
    end
end
