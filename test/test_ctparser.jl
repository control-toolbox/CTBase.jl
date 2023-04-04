#
# remark: all tests are independant
#         and define unrelated problems
#         (@def enforces this)

function test_ctparser()

    # all the followings are OK....
    # variables
    @test @def syntax_only=true :(tf, variable)

    # time
    @test @def syntax_only=true :(t ∈ [ t0, tf ], time)

    # control
    @test @def syntax_only=true :(u, control)
    @test @def syntax_only=true :(v[4], control)
    @test @def syntax_only=true :(w ∈ R^3, control)

    # state
    @test @def syntax_only=true :(x ∈ R^3, state)
    @test @def syntax_only=true :(y, state)
    @test @def syntax_only=true :(z[4], state)

    # objective
    @test @def syntax_only=true :(r(t) -> max)

    # alias
    @test @def syntax_only=true :(r = x[1])
    @test @def syntax_only=true :(v = x₂)
    @test @def syntax_only=true :(m = x₃)

    # constraints
    @test @def syntax_only=true begin
        x(t0) == [ r0, v0, m0 ]
        0  ≤ u(t) ≤ 1
        r0 ≤ x(t)[1]
        0  ≤ x₂(t) ≤ vmax
        mf ≤ m(t) ≤ m0
    end

    @test @def syntax_only=true begin
        x(t0) == [ r0, v0, m0 ], (1)
        0  ≤ u(t) ≤ 1          , (1bis)
        r0 ≤ x(t)[1]           , (deux)
        0  ≤ x₂(t) ≤ vmax     => (2bis)
        mf ≤ m(t) ≤ m0        => (1+1)
    end

    # should pass parsing + evaluation
    t0 = 1.1
    ocp = @def begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u, control
        v = x₂
        m = x₃
        0  ≤ u(t) ≤ 1
        mf ≤ m(t) ≤ m0
        r(tf) -> max
    end
    @test ocp isa  OptimalControlModel

    # ... up to here: all the remaining are KO
    @test_throws "@def parsing error" @def syntax_only=true begin
        t ∈ [ t0, tf ], time
        t ∈ [ t0, tf ], time
    end

    # bad time expression
    @test_throws "@def parsing error" @def begin
        t0, variable
        tf, variable
        t ∈ [ t0, tf ], time
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u, control
        v, control
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u, control
        w ∈ R^3, control
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u, state
        v, state
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u, state
        x ∈ R^3, state
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        tf, variable
        tf, variable
    end

     @test_throws "@def parsing error" @def syntax_only=true begin
         r(t) -> min
         x(t) -> max
    end

end
