#
# remark: all tests are independant
#         and define unrelated problems
#         (@def1 enforces this)

function test_ctparser()

    # phase 1: minimal problems, to check all possible syntaxes

    # time
    ocp = @def1 t ∈ [ 0.0 , 1.0 ], time ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == 0.0
    @test ocp.final_time   == 1.0

    t0 = 3.0
    ocp = @def1 begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == Index(1)

    tf = 3.14
    ocp = @def1 begin
        t0 ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == Index(1)
    @test ocp.final_time   == tf

    # control
    t0 = 1.0; tf = 1.1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
        u, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_names[1] == "u"

    t0 = 2.0; tf = 2.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        v[4], control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 4
    @test ocp.control_names[1] == "v₁"

    t0 = 3.0; tf = 3.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        w ∈ R^3, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 3
    @test ocp.control_names[1] == "w₁"

    t0 = 4.0; tf = 4.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        a ∈ R, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_names[1] == "a"


    t0 = 5.0; tf = 5.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        b ∈ R¹, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_names[1] == "b"


    t0 = 6.0; tf = 6.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        u ∈ R⁹, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 9
    @test ocp.control_names[1] == "u₁"


    n = 3
    t0 = 7.0; tf = 7.1
    ocp = @def1 begin
        t ∈ [ t0 , tf ], time
        u ∈ R^n, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == n
    @test ocp.control_names[1] == "u₁"


    return

    # template
    t0 = .0; tf = .1
    ocp = @def1 begin
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf

    # state
    @test @def1 y, state
    @test @def1 y[4], state
    @test @def1 y ∈ R^3, state
    @test @def1 y ∈ R, state
    n = 3
    @test @def1 y ∈ R^n, state

    # objective
    # @test @def1 r(t) → max
    # @test @def1 r(t) → min
    @test @def1 ∫( 0.5u(t)^2 ) → max
    @test @def1 ∫( 0.5u(t)^2 ) → min

    # alias
    @test @def1 r = x[1]
    @test @def1 v = x₂
    @test @def1 m = x₃

    # constraints
    @test @def1 begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R^2, control

        m = x₂

        x(t0) == [ r0, v0, m0 ]
        0  ≤ u(t) ≤ 1
        r0 ≤ x(t)[1] ≤ r1
        0  ≤ x₂(t) ≤ vmax
        mf ≤ m(t) ≤ m0
    end true

    @test @def1 begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R^2, control

        m = x₂

        x(t0) == [ r0, v0, m0 ], (1)
        0  ≤ u(t) ≤ 1          , (1bis)
        r0 ≤ x(t)[1] ≤ r1      , (deux)
        0  ≤ x₂(t) ≤ vmax     => (2bis)
        mf ≤ m(t) ≤ m0        => (1+1)
    end true

    # should pass parsing + evaluation
       t0 = 1.1
       tf = 1 ## debug: tf ∈ R, variable
       ocp1 = @def1  begin
           t ∈ [ t0, tf ], time
           x, state
           u, control

           0  ≤ u(t) ≤ 1    => (one)
           #x(tf) → max
       end true
       @test ocp1 isa  OptimalControlModel

    #
    tf = 1 ## debug: tf ∈ R, variable
    ocp2 = @def1  begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^n, control

        [0, 0, 0]  ≤ u(t) ≤ [1, 1, 1]
        #x₂(tf) → min
    end true

    @test ocp2 isa  OptimalControlModel

    #
    n = 3
    tf = 1 ## tf ∈ R, variable
    ocp3 = @def1  begin
        t ∈ [ t0, tf ], time
        x ∈ R^n, state
        u ∈ R^n, control

        v = x₂
        [0, 0, 0]  ≤ u(t) ≤ [1, 1, 1]
        #v(tf) → min
    end true
    @test ocp3 isa  OptimalControlModel

    # ... up to here: all the remaining are KO
    # @test_throws SyntaxError @def1  nothing true

    # @test_throws SyntaxError @def1  a == b == c true

    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf ], time
        t ∈ [ t0, tf ], time
    end true

    # bad time expression
    ## debug:
    ## @test_throws SyntaxError @def1 begin
    ##     t0, variable
    ##     tf, variable
    ##     t ∈ [ t0, tf ], time
    ## end true

    # multiple controls
    @test_throws SyntaxError @def1 begin
        u, control
        v, control
    end true

    @test_throws SyntaxError @def1 begin
        u, control
        w ∈ R^3, control
    end true

    @test_throws SyntaxError @def1 begin
        u[4], control
        w ∈ R^3, control
    end true

    @test_throws SyntaxError @def1 begin
        w ∈ R^3, control
        u, control
    end true

    @test_throws SyntaxError @def1 begin
        w ∈ R^3, control
        u[4], control
    end true

    @test_throws SyntaxError @def1 begin
        w ∈ R^3, control
        u ∈ R, control
    end true

    # multiple states
    @test_throws SyntaxError @def1 begin
        u, state
        v, state
    end true

    @test_throws SyntaxError @def1 begin
        u, state
        x ∈ R^3, state
    end true

    @test_throws SyntaxError @def1 begin
        x ∈ R^3, state
        u, state
    end true

    @test_throws SyntaxError @def1 begin
        x ∈ R^3, state
        u[4], state
    end true

    @test_throws SyntaxError @def1 begin
        u, state
        x ∈ R, state
    end true

    @test_throws SyntaxError @def1 begin
        x ∈ R, state
        u, state
    end true

    # multiple variables
    @test_throws SyntaxError @def1 begin
        tf, variable
        tf, variable
    end true

    @test_throws SyntaxError @def1 begin
        tf  ∈ R, variable
        tf, variable
    end true

    @test_throws SyntaxError @def1 begin
        tf, variable
        tf  ∈ R, variable
    end true

    # multiple objectives
    # @test_throws SyntaxError @def1 begin
    #      r(t)  → min
    #      x(t)  → max
    # end true
    # @test_throws SyntaxError @def1 begin
    #      x(t)  → max
    #      r(t)  → min
    # end true

    # multiple aliases
    @test_throws SyntaxError @def1 begin
        x[2], state
        x₂ = x₃
    end true

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
    end true

    # phase 2: now we can test more seriously

    # ocp5 = @def1 begin
    #     t ∈ [ t5_0, tf5_f ], time
    # end true ;
    # @test ocp5 isa  OptimalControlModel

    # t6_0 = 0 ## debug: t0 ∈ R, variable
    # ocp_6 = @def1 begin
    #     t ∈ [ t6_0, t6_f ], time
    # end true ;
    # @test ocp6 isa  OptimalControlModel

    # t7_0 = 1.1
    # t7_f = 2.2
    # ## debug: tf ∈ R, variable
    # ocp7 = @def1 begin
    #     t ∈ [ t7_0, t7_f ], time
    # end true ;
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
    # end true
    # @test ocp isa  OptimalControlModel
    # @test print_generated_code(ocp) == true

end
