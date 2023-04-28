#
# test all constraints on @def1 macro
#
# ref: https://github.com/control-toolbox/CTBase.jl/issues/9
#

function test_ctparser_constraints()

    # all used variables must be definedbefore each test
    x0   = 11.11
    x02  = 11.111
    x0_b = 11.1111
    x0_u = 11.11111
    y0   = 2.22
    y0_b = 2.222
    y0_u = 2.2222

    # === initial
    t0   = 0.0
    tf   = 1.0
    n    = 3
    ocp1 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x(t0) == x0
        x[2](t0) == x02
        x[2:3](t0) == y0
        x0_b ≤ x(t0) ≤ x0_u
        y0_b ≤ x[2:3](t0) ≤ y0_u
    end
    @test ocp1 isa OptimalControlModel
    @test ocp1.state_dimension == n
    @test ocp1.control_dimension == n
    @test ocp1.initial_time == t0
    @test ocp1.final_time == tf

    t0   = 0.1
    tf   = 1.1
    n    = 4
    ocp2 = @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x(t0) == x0                , initial_1
        x[2](t0) == x02            , initial_2
        x[2:3](t0) == y0           , initial_3
        x0_b ≤ x(t0) ≤ x0_u        , initial_4
        y0_b ≤ x[2:3](t0) ≤ y0_u   , initial_5
    end
    @test ocp2 isa OptimalControlModel
    @test ocp2.state_dimension == n
    @test ocp2.control_dimension == n
    @test ocp2.initial_time == t0
    @test ocp2.final_time == tf


    # all used variables must be definedbefore each test
    xf   = 11.11
    xf2  = 11.111
    xf_b = 11.1111
    xf_u = 11.11111
    yf   = 2.22
    yf_b = 2.222
    yf_u = 2.2222

    # === final
    t0   = 0.2
    tf   = 1.2
    n    = 5
    ocp3 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x(tf) == xf
        xf_b ≤ x(tf) ≤ xf_u
        x[2](tf) == xf2
        x[2:3](tf) == yf
        yf_b ≤ x[2:3](tf) ≤ yf_u
    end
    @test ocp3 isa OptimalControlModel
    @test ocp3.state_dimension == n
    @test ocp3.control_dimension == n
    @test ocp3.initial_time == t0
    @test ocp3.final_time == tf

    t0   = 0.3
    tf   = 1.3
    n    = 6
    ocp4 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x(tf) == xf                , final_1
        xf_b ≤ x(tf) ≤ xf_u        , final_2
        x[2](tf) == xf2            , final_3
        x[2:3](tf) == yf           , final_4
        yf_b ≤ x[2:3](tf) ≤ yf_u   , final_5
    end
    @test ocp4 isa OptimalControlModel
    @test ocp4.state_dimension == n
    @test ocp4.control_dimension == n
    @test ocp4.initial_time == t0
    @test ocp4.final_time == tf


    # === boundary
    t0   = 0.4
    tf   = 1.4
    n    = 7
    ocp5 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x(tf) - tf*x(t0) == [ 0, 1 ]
        [ 0, 1 ] ≤ x(tf) - tf*x(t0) ≤ [ 1, 3 ]
        x[2](t0)^2 == 1
        1 ≤ x[2](t0)^2 ≤ 2
        x[2](tf)^2 == 1
        1 ≤ x[2](tf)^2 ≤ 2

    end
    @test ocp5 isa OptimalControlModel
    @test ocp5.state_dimension == n
    @test ocp5.control_dimension == n
    @test ocp5.initial_time == t0
    @test ocp5.final_time == tf

    t0   = 0.5
    tf   = 1.5
    n    = 8
    ocp6 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x(tf) - tf*x(t0) == [ 0, 1 ]            , boundary_1
        [ 0, 1 ] ≤ x(tf) - tf*x(t0) ≤ [ 1, 3 ]  , boundary_2
        x[2](t0)^2 == 1                         , boundary_3
        1 ≤ x[2](t0)^2 ≤ 2                      , boundary_4
        x[2](tf)^2 == 1                         , boundary_5
        1 ≤ x[2](tf)^2 ≤ 2                      , boundary_6

    end
    @test ocp6 isa OptimalControlModel
    @test ocp6.state_dimension == n
    @test ocp6.control_dimension == n
    @test ocp6.initial_time == t0
    @test ocp6.final_time == tf


    # define more variables
    u_b  = 1.0
    u_u  = 2.0
    u2_b = 3.0
    u2_u = 4.0
    v_b  = 5.0
    v_u  = 6.0

    t0   = 0.6
    tf   = 1.6
    n    = 9
    ocp7 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        u_b ≤ u(t) ≤ u_u
        #u(t) == u_u
        u2_b ≤ u[2](t) ≤ u2_u
        #u[2](t) == u2_u
        v_b ≤ u[2:3](t) ≤ v_u
        #u[2:3](t) == v_u
        u[1](t)^2 + u[2](t)^2 == 1
        1 ≤ u[1](t)^2 + u[2](t)^2 ≤ 2
    end
    @test ocp7 isa OptimalControlModel
    @test ocp7.state_dimension == n
    @test ocp7.control_dimension == n
    @test ocp7.initial_time == t0
    @test ocp7.final_time == tf

    t0   = 0.7
    tf   = 1.7
    n    = 3
    ocp8 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        u_b ≤ u(t) ≤ u_u               , control_1
        #u(t) == u_u                    , control_2
        u2_b ≤ u[2](t) ≤ u2_u          , control_3
        #u[2](t) == u2_u                , control_4
        v_b ≤ u[2:3](t) ≤ v_u          , control_5
        #u[2:3](t) == v_u               , control_6
        u[1](t)^2 + u[2](t)^2 == 1     , control_7
        1 ≤ u[1](t)^2 + u[2](t)^2 ≤ 2  , control_8
    end
    @test ocp8 isa OptimalControlModel
    @test ocp8.state_dimension == n
    @test ocp8.control_dimension == n
    @test ocp8.initial_time == t0
    @test ocp8.final_time == tf


    # more vars
    x_b  = 10.0
    x_u  = 11.0
    x2_b = 13.0
    x2_u = 14.0
    x_u  = 15.0
    y_u  = 16.0

    # === state
    t0   = 0.8
    tf   = 1.8
    n    = 10
    ocp9 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x_b ≤ x(t) ≤ x_u
        #x(t) == x_u
        x2_b ≤ x[2](t) ≤ x2_u
        #x[2](t) == x2_u
        #x[2:3](t) == y_u
        x_u ≤ x[2:3](t) ≤ y_u
        x[1:2](t) + x[3:4](t) == [ -1, 1 ]
        [ -1, 1 ] ≤ x[1:2](t) + x[3:4](t) ≤ [ 0, 2 ]
    end
    @test ocp9 isa OptimalControlModel
    @test ocp9.state_dimension == n
    @test ocp9.control_dimension == n
    @test ocp9.initial_time == t0
    @test ocp9.final_time == tf

    t0   = 0.9
    tf   = 1.9
    n    = 11
    ocp10 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        x_b ≤ x(t) ≤ x_u                             , state_1
        #x(t) == x_u                                  , state_2
        x2_b ≤ x[2](t) ≤ x2_u                        , state_3
        #x[2](t) == x2_u                              , state_4
        #x[2:3](t) == y_u                             , state_5
        x_u ≤ x[2:3](t) ≤ y_u                        , state_6
        x[1:2](t) + x[3:4](t) == [ -1, 1 ]           , state_7
        [ -1, 1 ] ≤ x[1:2](t) + x[3:4](t) ≤ [ 0, 2 ] , state_8
    end
    @test ocp10 isa OptimalControlModel
    @test ocp10.state_dimension == n
    @test ocp10.control_dimension == n
    @test ocp10.initial_time == t0
    @test ocp10.final_time == tf


    # === mixed
    t0   = 0.111
    tf   = 1.111
    n    = 12
    ocp11 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        u[2](t) * x[1:2](t) == [ -1, 1 ]
        [ -1, 1 ] ≤ u[2](t) * x[1:2](t) ≤ [ 0, 2 ]
    end
    @test ocp11 isa OptimalControlModel
    @test ocp11.state_dimension == n
    @test ocp11.control_dimension == n
    @test ocp11.initial_time == t0
    @test ocp11.final_time == tf

    ocp12 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R^n, state
        u ∈ R^n, control

        u[2](t) * x[1:2](t) == [ -1, 1 ]                       , mixed_1
        [ -1, 1 ] ≤ u[2](t) * x[1:2](t) ≤ [ 0, 2 ]             , mixed_2
    end
    @test ocp12 isa OptimalControlModel
    @test ocp12.state_dimension == n
    @test ocp12.control_dimension == n
    @test ocp12.initial_time == t0
    @test ocp12.final_time == tf


    # === dynamics

    t0   = 0.112
    tf   = 1.112
    ocp13 = @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R, state
        u ∈ R, control

        x'(t) == 2x(t) + u(t)^2
        x'(t) == f(x(t), u(t))
    end
    @test ocp13 isa OptimalControlModel
    @test ocp13.state_dimension   == 1
    @test ocp13.control_dimension == 1
    @test ocp13.initial_time == t0
    @test ocp13.final_time == tf

    # some syntax (even parseable) are not allowed
    # this is the actual exhaustive list
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        x(t) == x_u        , constant_state_not_allowed
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        x(t) == x_u
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        x[2](t) == x2_u    , constant_state_index_not_allowed
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        x[2](t) == x2_u
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        x[2:3](t) == y_u    , constant_state_range_not_allowed
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        x[2:3](t) == y_u
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        u(t) == u_u         , constant_control_not_allowed
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        u(t) == u_u
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        u[2](t) == u2_u     , constant_control_index_not_allowed
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        u[2](t) == u2_u
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        u[2:3](t) == v_u    , constant_control_range_not_allowed
    end
    @test_throws SyntaxError @def1 begin
        t ∈ [ t0, tf], time
        x ∈ R^3, state
        u ∈ R^3, control
        u[2:3](t) == v_u
    end
    @test_throws SyntaxError @def1 begin

        t ∈ [ t0, tf], time
        x ∈ R, state
        u ∈ R, control

        x'(t) == f(x(t), u(t))  , named_dynamics_not_allowed  # but allowed if unnamed !
    end


end
