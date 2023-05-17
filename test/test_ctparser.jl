#
# remark: all tests are independant
#         and define unrelated problems
#         (@def0 enforces this)

function test_ctparser()

    # phase 1: minimal problems, to check all possible syntaxes

    # time
    ocp = @def0 t ∈ [ 0.0 , 1.0 ], time ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == 0.0
    @test ocp.final_time   == 1.0

    t0 = 3.0
    ocp = @def0 begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == Index(1)

    tf = 3.14
    ocp = @def0 begin
        t0 ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == Index(1)
    @test ocp.final_time   == tf

    # state
    t0 = 1.0; tf = 1.1
    ocp = @def0 begin
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
    ocp = @def0 begin
        t ∈ [ t0 , tf ], time
        v ∈ R^4, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 4
    @test ocp.state_names == [ "v₁", "v₂", "v₃", "v₄"]

    t0 = 3.0; tf = 3.1
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
        t ∈ [ t0 , tf ], time
        v ∈ R^4, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 4
    @test ocp.control_names == [ "v₁", "v₂", "v₃", "v₄"]

    t0 = 3.0; tf = 3.1
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
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
    ocp = @def0 begin
        t ∈ [ t0, tf ], time
        a, variable
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.variable_dimension == 1
    @test ocp.variable_names == [ "a" ]

    t0 = .0; tf = .1
    ocp = @def0 begin
        t ∈ [ t0, tf ], time
        a ∈ R³, variable
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.variable_dimension == 3
    @test ocp.variable_names == [ "a₁", "a₂", "a₃" ]

    # alias
    t0 = .0; tf = .1
    ocp = @def0 begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^3, control

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
    ocp = @def0 begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^3, control
        ∫( 0.5u(t)^2 ) → min
    end ;
    @test ocp isa OptimalControlModel

    t0 = .0; tf = .1
    ocp = @def0 begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^3, control
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
    ocp = @def0 begin
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

    ocp = @def0 begin
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

    # dyslexic definition:  t -> u -> x -> t
    u0 = 9.0; uf = 9.1
    z0 = 1.0; z1 = 2.0
    k0 = 2.0; kmax = sqrt(2)
    b0 = 3.0; bf = 1.1

    ocp = @def0 begin
        u ∈ [ u0, uf ], time
        t ∈ R^2, state
        x ∈ R^2, control

        b = t₂

        t(u0) == [ z0, k0, b0 ]
        0  ≤ x(u) ≤ 1
        z0 ≤ t(u)[1] ≤ z1
        0  ≤ t₂(u) ≤ kmax
        bf ≤ b(u) ≤ b0
    end
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "u"
    @test ocp.initial_time == u0
    @test ocp.final_time   == uf
    @test ocp.control_names == ["x₁", "x₂"]
    @test ocp.control_dimension == 2
    @test ocp.state_names   == [ "t₁", "t₂"]
    @test ocp.state_dimension == 2


    # error detections (this can be tricky -> need more work)

    # this one is detected by the generated code (and not the parser)
    @test_throws CTException @def0 begin
        t ∈ [ t0, tf ], time
        t ∈ [ t0, tf ], time
    end

    # illegal constraint name (1bis), detected by the parser
    t0 = 9.0; tf = 9.1
    r0 = 1.0; v0 = 2.0; m0 = 3.0
    @test_throws ParsingError @def0 begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R^2, control

        0  ≤ u(t) ≤ 1          , (1bis)
    end ;

    # t0 is unknown in the x(t0) constraint, detected by the parser
    r0 = 1.0; v0 = 2.0; m0 = 3.0
    @test_throws ParsingError @def0 begin
        t ∈ [ 0, 1 ], time
        x ∈ R^2, state
        u ∈ R^2, control

        x(t0) == [ r0, v0, m0 ], (1)
        0  ≤ u(t) ≤ 1          , (1bis)
    end ;

    #
end
