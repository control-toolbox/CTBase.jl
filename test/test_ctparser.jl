#
# remark: all tests are independant
#         and define unrelated problems
#         (@def enforces this)

function test_ctparser()

    # phase 1: only syntax checking and dupplicate detection

    # all the followings are OK....
    # variables
    @test @def syntax_only=true :(tf, variable)

    # time
    @test @def syntax_only=true :(t ∈ [ t0, tf ], time)

    # control
    @test @def syntax_only=true :(u, control)
    @test @def syntax_only=true :(u[4], control)
    @test @def syntax_only=true :(u ∈ R^3, control)
    @test @def syntax_only=true :(u ∈ R, control)

    # state
    @test @def syntax_only=true :(y, state)
    @test @def syntax_only=true :(y[4], state)
    @test @def syntax_only=true :(y ∈ R^3, state)
    @test @def syntax_only=true :(y ∈ R, state)

    # objective
    @test @def syntax_only=true :(r(t) -> max)
    @test @def syntax_only=true :(r(t) → max)
    @test @def syntax_only=true :(r(t) -> min)
    @test @def syntax_only=true :(r(t) → min)
    @test @def syntax_only=true :(∫( 0.5u(t)^2 ) -> max)
    @test @def syntax_only=true :(∫( 0.5u(t)^2 ) → max)
    @test @def syntax_only=true :(∫( 0.5u(t)^2 ) -> min)
    @test @def syntax_only=true :(∫( 0.5u(t)^2 ) → min)

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
    ocp = @def debug=true begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
        x, state
        u, control

        0  ≤ u(t) ≤ 1    => (one)
        x(tf) → max
    end ;
    @test ocp isa  OptimalControlModel

    #
    ocp = @def debug=true begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^3, control

        v = x₂
        [0, 0, 0]  ≤ u(t) ≤ [1, 1, 1]
        v(tf) → min
    end ;
    @test ocp isa  OptimalControlModel

    # ... up to here: all the remaining are KO
    @test_throws "@def parsing error" @def syntax_only=true :( nothing)

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

    # multiple controls
    @test_throws "@def parsing error" @def syntax_only=true begin
        u, control
        v, control
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u, control
        w ∈ R^3, control
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u[4], control
        w ∈ R^3, control
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        w ∈ R^3, control
        u, control
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        w ∈ R^3, control
        u[4], control
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        w ∈ R^3, control
        u ∈ R, control
    end

    # multiple states
    @test_throws "@def parsing error" @def syntax_only=true begin
        u, state
        v, state
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u, state
        x ∈ R^3, state
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        x ∈ R^3, state
        u, state
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        x ∈ R^3, state
        u[4], state
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        u, state
        x ∈ R, state
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        x ∈ R, state
        u, state
    end

    # multiple variables
    @test_throws "@def parsing error" @def syntax_only=true begin
        tf, variable
        tf, variable
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        tf  ∈ R, variable
        tf, variable
    end

    @test_throws "@def parsing error" @def syntax_only=true begin
        tf, variable
        tf  ∈ R, variable
    end

    # multiple objectives
    @test_throws "@def parsing error" @def syntax_only=true begin
         r(t) -> min
         x(t) -> max
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
         x(t) -> max
         r(t) -> min
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
         r(t)  → min
         x(t)  → max
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
         x(t)  → max
         r(t)  → min
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
         r(t) →  min
         x(t) -> max
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
         x(t) →  max
         r(t) -> min
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
         r(t) -> min
         x(t)  → max
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
         x(t)  → max
         r(t) -> min
    end

    # multiple aliases
    @test_throws "@def parsing error" @def syntax_only=true begin
        r = x[1]
        r = x[1]
        x₂ = x₃
    end

    # # aliases loops (not implemented yet)
    # @test_throws "@def parsing error" @def syntax_only=true begin
    #     r = u
    #     u = r
    # end
    # @test_throws "@def parsing error" @def syntax_only=true begin
    #     a = b
    #     b = c
    #     c = a
    # end

    # multiple constraints
    @test_throws "@def parsing error" @def syntax_only=true begin
        r(t) == t0
        r(t) == t0
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
        r(t) == t0 , named
        r(t) == t0
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
        r(t) == t0 => named
        r(t) == t0
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
        r(t) == t0
        r(t) == t0 , named
    end
    @test_throws "@def parsing error" @def syntax_only=true begin
        r(t) == t0
        r(t) == t0 => named
    end

    # phase 2: now we can test more seriously

    t0 = 1.1
    tf = 2.2
    ocp = @def begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa  OptimalControlModel

    ocp = @def begin
        t0 ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa  OptimalControlModel

    ocp = @def begin
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa  OptimalControlModel

    # time must exist in our world
    @test_throws "@def parsing error" @def begin
    end

    # t0 = 1.1
    # ocp = @def begin
    #     tf ∈ R, variable
    #     t ∈ [ t0, tf ], time
    #     x ∈ R^3, state
    #     u, control
    #     v = x₂
    #     m = x₃
    #     0  ≤ u(t) ≤ 1
    #     mf ≤ m(t) ≤ m0
    #     r(tf) -> max
    # end
    # @test ocp isa  OptimalControlModel

    # macro args tests
    @test @def syntax_only=true verbose_threshold=10 :( t ∈ [ t0, tf ], time)
    @test @def syntax_only=true verbose_threshold=-100 :( t ∈ [ t0, tf ], time)
    @test @def syntax_only=true verbose_threshold=1100 :( t ∈ [ t0, tf ], time)
    @test @def debug=true syntax_only=true :( t ∈ [ t0, tf ], time )

end
