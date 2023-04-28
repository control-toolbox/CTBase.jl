#
# remark: all tests are independant
#         and define unrelated problems
#         (@def1 enforces this)

function test_ctparser()

    # phase 1: minimal problems, to check all possible syntaxes

    # time
    ocp = @def1 t ∈ [ 0.0 , 1.0 ], time ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == 0.0
    @test ocp.final_time   == 1.0

    t0 = 3.0
    ocp = @def1 begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == Index(1)

    tf = 3.14
    ocp = @def1 begin
        t0 ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == Index(1)
    @test ocp.final_time   == tf

    # state
    t0 = 1.0; tf = 1.1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        u, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 1
    @test ocp.state_names == [ "u" ]

    t0 = 2.0; tf = 2.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        v[4], state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 4
    @test ocp.state_names == [ "v₁", "v₂", "v₃", "v₄"]

    t0 = 3.0; tf = 3.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        w ∈ R^3, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 3
    @test ocp.state_names ==  [ "w₁", "w₂", "w₃"]

    t0 = 4.0; tf = 4.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        a ∈ R, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 1
    @test ocp.state_names == [ "a" ]


    t0 = 5.0; tf = 5.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        b ∈ R¹, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 1
    @test ocp.state_names == [ "b" ]


    t0 = 6.0; tf = 6.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        u ∈ R⁹, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 9
    @test ocp.state_names ==  [ "u₁", "u₂", "u₃", "u₄", "u₅", "u₆", "u₇", "u₈", "u₉"]


    n = 3
    t0 = 7.0; tf = 7.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        u ∈ R^n, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == n
    @test ocp.state_names == [ "u₁", "u₂", "u₃"]


    # control
    t0 = 1.0; tf = 1.1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        u, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_names == [ "u" ]

    t0 = 2.0; tf = 2.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        v[4], control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 4
    @test ocp.control_names == [ "v₁", "v₂", "v₃", "v₄"]

    t0 = 3.0; tf = 3.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        w ∈ R^3, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 3
    @test ocp.control_names ==  [ "w₁", "w₂", "w₃"]

    t0 = 4.0; tf = 4.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        a ∈ R, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_names == [ "a" ]


    t0 = 5.0; tf = 5.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        b ∈ R¹, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_names == [ "b" ]


    t0 = 6.0; tf = 6.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        u ∈ R⁹, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 9
    @test ocp.control_names ==  [ "u₁", "u₂", "u₃", "u₄", "u₅", "u₆", "u₇", "u₈", "u₉"]


    n = 3
    t0 = 7.0; tf = 7.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        u ∈ R^n, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == n
    @test ocp.control_names == [ "u₁", "u₂", "u₃"]


    # variables
    t0 = .0; tf = .1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        a, variable
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.variable_dimension == 1
    @test ocp.variable_names == [ "a" ]

    t0 = .0; tf = .1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        a[3], variable
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.variable_dimension == 3
    @test ocp.variable_names == [ "a₁", "a₂", "a₃" ]

    # alias
    t0 = .0; tf = .1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        x[3], state
        u[3], control

        r = x[1]
        v = x₂
        a = x₃
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_names == [ "u₁", "u₂", "u₃"]
    @test ocp.control_dimension == 3
    @test ocp.state_names   ==  ["x₁", "x₂", "x₃"]
    @test ocp.state_dimension == 3

    # objectives
    t0 = .0; tf = .1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        x[3], state
        u[3], control
        ∫( 0.5u(t)^2 ) → min
    end ;
    @test ocp isa OptimalControlModel

    t0 = .0; tf = .1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        x[3], state
        u[3], control
        ∫( 0.5u(t)^2 ) → max
    end ;
    @test ocp isa OptimalControlModel

    # constraints

    # minimal constraint tests
    # remark: constraint are heavily tested in test_ctparser_constraints.jl
    t0 = 9.0; tf = 9.1
    r0 = 1.0; r1 = 2.0
    v0 = 2.0; vmax = sqrt(2)
    m0 = 3.0; mf = 1.1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R^2, control

        m = x₂

        x(t0) == [ r0, v0, m0 ], (1)
        0  ≤ u(t) ≤ 1          , (deux)
        r0 ≤ x(t)[1] ≤ r1      , (trois)
        0  ≤ x₂(t) ≤ vmax      , (quatre)
        mf ≤ m(t) ≤ m0         , (5)
    end
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_names == [ "u₁", "u₂"]
    @test ocp.control_dimension == 2
    @test ocp.state_names   == ["x₁", "x₂"]
    @test ocp.state_dimension == 2

    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R^2, control

        m = x₂

        x(t0) == [ r0, v0, m0 ]
        0  ≤ u(t) ≤ 1
        r0 ≤ x(t)[1] ≤ r1
        0  ≤ x₂(t) ≤ vmax
        mf ≤ m(t) ≤ m0
    end
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_names == [ "u₁", "u₂"]
    @test ocp.control_dimension == 2
    @test ocp.state_names   == ["x₁", "x₂"]
    @test ocp.state_dimension == 2

    return

    # template
    t0 = .0; tf = .1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        x[3], state
        u[3], control
    end ;
    @test ocp isa OptimalControlModel

    # ... up to here: all the remaining are KO
    # @test_throws SyntaxError @def1  nothing true

    # @test_throws SyntaxError @def1  a == b == c true

    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf ], time
        t ∈ [ t0, tf ], time
    end

    # bad time expression
    ## debug:
    ## @test_throws SyntaxError @def1 begin
    ##     t0, variable
    ##     tf, variable
    ##     t ∈ [ t0, tf ], time
    ## end

    # multiple controls
    @test_throws SyntaxError @def1 begin
        u, control
        v, control
    end

    @test_throws SyntaxError @def1 begin
        u, control
        w ∈ R^3, control
    end

    @test_throws SyntaxError @def1 begin
        u[4], control
        w ∈ R^3, control
    end

    @test_throws SyntaxError @def1 begin
        w ∈ R^3, control
        u, control
    end

    @test_throws SyntaxError @def1 begin
        w ∈ R^3, control
        u[4], control
    end

    @test_throws SyntaxError @def1 begin
        w ∈ R^3, control
        u ∈ R, control
    end

    # multiple states
    @test_throws SyntaxError @def1 begin
        u, state
        v, state
    end

    @test_throws SyntaxError @def1 begin
        u, state
        x ∈ R^3, state
    end

    @test_throws SyntaxError @def1 begin
        x ∈ R^3, state
        u, state
    end

    @test_throws SyntaxError @def1 begin
        x ∈ R^3, state
        u[4], state
    end

    @test_throws SyntaxError @def1 begin
        u, state
        x ∈ R, state
    end

    @test_throws SyntaxError @def1 begin
        x ∈ R, state
        u, state
    end

    # multiple variables
    @test_throws SyntaxError @def1 begin
        tf, variable
        tf, variable
    end

    @test_throws SyntaxError @def1 begin
        tf  ∈ R, variable
        tf, variable
    end

    @test_throws SyntaxError @def1 begin
        tf, variable
        tf  ∈ R, variable
    end

    # multiple objectives
    # @test_throws SyntaxError @def1 begin
    #      r(t)  → min
    #      x(t)  → max
    # end
    # @test_throws SyntaxError @def1 begin
    #      x(t)  → max
    #      r(t)  → min
    # end

    # multiple aliases
    @test_throws SyntaxError @def1 begin
        x[2], state
        x₂ = x₃
    end

    # multiple constraints
    x = Vector{Float64}(1:20)
    t0 = 0.0
    t1 = 1.0
    @test @def1 begin
        t ∈ [ t0, tf ], time
        r ∈ R, state
        c ∈ R, control

        r(t0) == x[1]
        r(tf) == x[2]
    end

    # phase 2: now we can test more seriously

    # ocp5 = @def1 begin
    #     t ∈ [ t5_0, tf5_f ], time
    # end ;
    # @test ocp5 isa  OptimalControlModel

    # t6_0 = 0 ## debug: t0 ∈ R, variable
    # ocp_6 = @def1 begin
    #     t ∈ [ t6_0, t6_f ], time
    # end ;
    # @test ocp6 isa  OptimalControlModel

    # t7_0 = 1.1
    # t7_f = 2.2
    # ## debug: tf ∈ R, variable
    # ocp7 = @def1 begin
    #     t ∈ [ t7_0, t7_f ], time
    # end ;
    # @test ocp7 isa  OptimalControlModel

    # debug function
    # ocp = Model()
    # @test print_generated_code(ocp) == false

    # t0 = 1.1
    # m0 = 100.0
    # mf =  10.0
    # tf = 1 ## debug: tf ∈ R, variable
    # ocp = @def1 begin
    #     t ∈ [ t0, tf ], time
    #     x ∈ R^3, state
    #     u, control
    #     v = x₂
    #     m = x₃
    #     0  ≤ u(t) ≤ 1
    #     mf ≤ m(t) ≤ m0
    # end
    # @test ocp isa  OptimalControlModel
    # @test print_generated_code(ocp) == true

end
