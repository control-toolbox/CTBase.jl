# test onepass

function test_onepass()

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "@def o syntax" begin
    println("@def o syntax testset...")

    oo = @def begin
        λ ∈ R^2, variable
        tf = λ₂
        t ∈ [ 0, tf ], time
    end
    @test oo.initial_time == 0
    @test oo.final_time == Index(2)

    a = 1
    f(b) = begin # closure of a, local c, and @def in function
        c = 3
        ocp = @def begin
            t ∈ [ a, b ], time
            x ∈ R, state
            u ∈ R, control
            ẋ(t) == x(t) + u(t) + b + c + d
        end
        return ocp
    end
    b = 2
    o = f(b)
    d = 4
    x = 10
    u = 20
    @test o.dynamics(x, u) == x + u + b + 3 + d

end

@testset "log" begin
    println("log testset...")

    @def o begin
        λ ∈ R^2, variable
        tf = λ₂
        t ∈ [ 0, tf ], time
    end true
    @test o.initial_time == 0
    @test o.final_time == Index(2)
end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "aliases" begin
    println("aliases testset...")

    @def o begin
        x = (y, z) ∈ R², state
        u = (uu1, uu2, uu3) ∈ R³, control
        v = (vv1, vv2) ∈ R², variable
    end
    @test o.state_components_names == [ "y", "z" ]
    @test o.control_components_names == [ "uu1", "uu2", "uu3" ]
    @test o.variable_components_names == [ "vv1", "vv2" ]

    @def o begin
        x = [y, z] ∈ R², state
        u = [uu1, uu2, uu3] ∈ R³, control
        v = [vv1, vv2] ∈ R², variable
    end
    @test o.state_components_names == [ "y", "z" ]
    @test o.control_components_names == [ "uu1", "uu2", "uu3" ]
    @test o.variable_components_names == [ "vv1", "vv2" ]

    @test_throws ParsingError @def o begin # a name must be provided
        (y, z) ∈ R², state
    end

    @test_throws ParsingError @def o begin # a name must be provided
        (uu1, uu2, uu3) ∈ R³, control
    end

    @test_throws ParsingError @def o begin # a name must be provided
        (vv1, vv2) ∈ R², variable
    end

    @test_throws ParsingError @def o begin # a name must be provided
        [y, z] ∈ R², state
    end

    @test_throws ParsingError @def o begin # a name must be provided
        [uu1, uu2, uu3] ∈ R³, control
    end

    @test_throws ParsingError @def o begin # a name must be provided
        [vv1, vv2] ∈ R², variable
    end

    @def o begin
        t ∈ [ 0, 1 ], time
        x = ( r, v ) ∈ R², state
        u ∈ R, control
        w = r + 2v
        r(0) == 0,    (1)
        v(0) == 1,    (♡)
        ẋ(t) == [ v(t), w(t)^2 ]
        ∫( u(t)^2 + x₁(t) ) → min
    end
    x = [ 1, 2 ]
    x0  = 2 * x
    xf  = 3 * x
    u = 3
    @test constraint(o, :eq1)(x0, xf) == x0[1]
    @test constraint(o, Symbol("♡"))(x0, xf) == x0[2]
    @test o.dynamics(x, u) == [ x[2], (x[1] + 2x[2])^2 ]
    @test o.lagrange(x, u) == u^2 + x[1]

    @def o begin
        t ∈ [ 0, 1 ], time
        x = [ r, v ] ∈ R², state
        u ∈ R, control
        w = r + 2v
        r(0) == 0,    (1)
        v(0) == 1,    (♡)
        ẋ(t) == [ v(t), w(t)^2 ]
        ∫( u(t)^2 + x₁(t) ) → min
    end
    x = [ 1, 2 ]
    x0  = 2 * x
    xf  = 3 * x
    u = 3
    @test constraint(o, :eq1)(x0, xf) == x0[1]
    @test constraint(o, Symbol("♡"))(x0, xf) == x0[2]
    @test o.dynamics(x, u) == [ x[2], (x[1] + 2x[2])^2 ]
    @test o.lagrange(x, u) == u^2 + x[1]

    @def o begin
        t ∈ [ 0, 1 ], time
        x = [ r, v ] ∈ R², state
        c = [ u, b ] ∈ R², control
        w = r + 2v
        b(t) == 0
        r(0) == 0,    (1)
        v(0) == 1,    (♡)
        ẋ(t) == [ v(t), w(t)^2 ]
        ∫( u(t)^2 + b(t)^2 + x₁(t) ) → min
    end
    x = [ 1, 2 ]
    x0  = 2 * x
    xf  = 3 * x
    u = 3
    c = [ u, 0 ]
    @test constraint(o, :eq1)(x0, xf) == x0[1]
    @test constraint(o, Symbol("♡"))(x0, xf) == x0[2]
    @test o.dynamics(x, c) == [ x[2], (x[1] + 2x[2])^2 ]
    @test o.lagrange(x, c) == u^2 + x[1]

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R^3, state
        u = (u₁, v) ∈ R^2, control
        ẋ(t) == [ x[1](t) + 2v(t), 2x[3](t), x[1](t) + v(t) ]
    end
    @test o.state_dimension == 3
    @test o.control_dimension == 2
    x = [ 1, 2, 3 ]
    u = [ -1, 2 ]
    @test o.dynamics(x, u) == [ x[1] + 2u[2], 2x[3], x[1] + u[2] ]

    t0 = .0; tf = .1
    @def ocp begin
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
    @test ocp.control_name == "u"
    @test ocp.control_dimension == 3
    @test ocp.state_name ==  "x"
    @test ocp.state_dimension == 3

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "variable" begin
    println("variable testset...")

    @def o begin
        λ ∈ R^2, variable
        tf = λ₂
        t ∈ [ 0, tf ], time
    end
    @test o.initial_time == 0
    @test o.final_time == Index(2)
    
    @def o begin
        λ = (λ₁, tf) ∈ R^2, variable
        t ∈ [ 0, tf ], time
    end
    @test o.initial_time == 0
    @test o.final_time == Index(2)
    
    @def o begin
        t0 ∈ R, variable
        t ∈ [ t0, 1 ], time
    end
    @test o.initial_time == Index(1)
    @test o.final_time == 1
    
    @def o begin
        tf ∈ R, variable
        t ∈ [ 0, tf ], time
    end
    @test o.initial_time == 0
    @test o.final_time == Index(1)
    
    @def o begin
        v ∈ R², variable
        s ∈ [ v[1], v[2] ], time
    end
    @test o.initial_time == Index(1)
    @test o.final_time == Index(2)
    
    @def o begin
        v ∈ R², variable
        s0 = v₁
        sf = v₂
        s ∈ [ s0, sf ], time
    end
    @test o.initial_time == Index(1)
    @test o.final_time == Index(2)
    
    @test_throws IncorrectArgument @def o begin
        t0 ∈ R², variable
        t ∈ [ t0, 1 ], time
    end
    
    @test_throws IncorrectArgument @def o begin
        tf ∈ R², variable
        t ∈ [ 0, tf ], time
    end
    
    @test_throws ParsingError @def o begin
        v, variable
        t ∈ [ 0, tf[v] ], time
    end
    
    @test_throws ParsingError @def o begin
        v, variable
        t ∈ [ t0[v], 1 ], time
    end
    
    @test_throws ParsingError @def o begin
        v, variable
        t ∈ [ t0[v], tf[v+1] ], time
    end

    t0 = .0; tf = .1
    @def ocp begin
        t ∈ [ t0, tf ], time
        a ∈ R, variable
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.variable_dimension == 1
    @test ocp.variable_name == "a"

    t0 = .0; tf = .1
    @def ocp begin
        t ∈ [ t0, tf ], time
        a ∈ R³, variable
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.variable_dimension == 3
    @test ocp.variable_name == "a"

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "time" begin
    println("time testset...")

    t0 = 0
    @def o t ∈ [ t0, t0 + 4 ], time
    @test o.initial_time == t0
    @test o.final_time == t0 + 4

    @test_throws ParsingError @def o t ∈ 1

    @def ocp t ∈ [ 0.0 , 1.0 ], time;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == 0.0
    @test ocp.final_time   == 1.0

    t0 = 3.0
    @def ocp begin
        tf ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == Index(1)

    tf = 3.14
    @def ocp begin
        t0 ∈ R, variable
        t ∈ [ t0, tf ], time
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == Index(1)
    @test ocp.final_time   == tf

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "state / control" begin
    println("state / control testset...")

    @def o begin
        x ∈ R, state
        u ∈ R, control
    end
    @test o.state_dimension == 1
    @test o.control_dimension == 1

    # state
    t0 = 1.0; tf = 1.1
    @def ocp begin
        t ∈ [ t0, tf ], time
        u ∈ R, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 1
    @test ocp.state_name == "u"

    t0 = 2.0; tf = 2.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        v ∈ R^4, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 4
    @test ocp.state_name == "v"

    t0 = 3.0; tf = 3.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        w ∈ R^3, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 3
    @test ocp.state_name ==  "w"

    t0 = 4.0; tf = 4.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        a ∈ R, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 1
    @test ocp.state_name == "a"

    t0 = 5.0; tf = 5.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        b ∈ R¹, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 1
    @test ocp.state_name == "b"

    t0 = 6.0; tf = 6.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        u ∈ R⁹, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == 9
    @test ocp.state_name ==  "u"

    n = 3
    t0 = 7.0; tf = 7.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        u ∈ R^n, state
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.state_dimension == n
    @test ocp.state_name == "u"

    # control
    t0 = 1.0; tf = 1.1
    @def ocp begin
        t ∈ [ t0, tf ], time
        u ∈ R, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_name == "u"

    t0 = 2.0; tf = 2.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        v ∈ R^4, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 4
    @test ocp.control_name == "v"

    t0 = 3.0; tf = 3.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        w ∈ R^3, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 3
    @test ocp.control_name ==  "w"

    t0 = 4.0; tf = 4.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        a ∈ R, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_name == "a"


    t0 = 5.0; tf = 5.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        b ∈ R¹, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 1
    @test ocp.control_name == "b"

    t0 = 6.0; tf = 6.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        u ∈ R⁹, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == 9
    @test ocp.control_name == "u"

    n = 3
    t0 = 7.0; tf = 7.1
    @def ocp begin
        t ∈ [ t0 , tf ], time
        u ∈ R^n, control
    end ;
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_dimension == n
    @test ocp.control_name == "u"

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "dynamics" begin
    println("dynamics testset...")

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R^3, state
        u ∈ R^2, control
        ẋ(t) == [ x[1](t) + 2u[2](t), 2x[3](t), x[1](t) + u[2](t) ]
    end
    @test o.state_dimension == 3
    @test o.control_dimension == 2
    x = [ 1, 2, 3 ]
    u = [ -1, 2 ]
    @test o.dynamics(x, u) == [ x[1] + 2u[2], 2x[3], x[1] + u[2] ]
    @def o begin
        z ∈ R², variable
        s ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁
        ẏ(s) == [ aa(s), r²(s) + w(s) + z₁, 0, 0 ]
    end
    z = [ 5, 6 ]
    y = [ 1, 2, 3, 4 ]
    w = 9
    @test o.dynamics(y, w, z) == [ y[1], y[3]^2 + w + z[1], 0, 0 ]
    
    @def o begin
        z ∈ R², variable
        __s ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁(__s)
        ẏ(__s) == [ aa(__s), r²(__s) + w(__s) + z₁, 0, 0 ]
    end
    z = [ 5, 6 ]
    y = [ 1, 2, 3, 4 ]
    w = 9
    @test_throws MethodError o.dynamics(y, w, z)
    
    @def o begin
        z ∈ R², variable
        s ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁(s) + v³ + z₂
        ẏ(s) == [ aa(s) + w(s)^2, r²(s), 0, 0 ]
    end
    z = [ 5, 6 ]
    y = [ 1, 2, 3, 4 ]
    y0 = y
    yf = 3y0
    ww = 19
    @test o.dynamics(y, ww, z) == [ y[1] + ww^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]

    @def o begin
        z ∈ R², variable
        __t ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁(0) + v³ + z₂
        ẏ(__t) == [ aa(__t) + (w^2)(__t), r²(__t), 0, 0 ]
        aa(0) + y₂(z₁) → min
    end
    z = [ 5, 6 ]
    y = [ 1, 2, 3, 4 ]
    y0 = y
    yf = 3y0
    w = 11
    @test_throws MethodError o.dynamics(y, w, z)
    @test o.mayer(y0, yf, z) == y0[1] + y0[4]^3 + z[2] + yf[2]

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "constraints" begin
    println("constraints testset...")

    @def o begin
        tf ∈ R, variable
        t ∈ [ 0, tf ], time
        x ∈ R², state
        u ∈ R, control
        r = x₁
        v = x₂
        w = r¹ + 2v³
        r(0) + w(tf) - tf² == 0,    (1)
    end
    tf = 2
    x0 = [ 1, 2 ]
    xf = [ 3, 4 ]
    @test constraint(o, :eq1)(x0, xf, tf) == x0[1] + ( xf[1] + 2xf[2]^3 ) - tf^2
    
    n = 11
    m = 6
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R^n, state
        u ∈ R^m, control
        r = x₁
        v = x₂
        0 ≤ r(t) ≤ 1,                      (1)
        zeros(n) ≤ x(t) ≤ ones(n),         (2)
        [ 0, 0 ] ≤ x[1:2](t) ≤ [ 1, 1 ],   (3)
        [ 0, 0 ] ≤ x[1:2:4](t) ≤ [ 1, 1 ], (4)
        0 ≤ v(t)^2 ≤ 1,                    (5)
        zeros(m) ≤ u(t) ≤ ones(m),         (6)
        [ 0, 0 ] ≤ u[1:2](t) ≤ [ 1, 1 ],   (7)
        [ 0, 0 ] ≤ u[1:2:4](t) ≤ [ 1, 1 ], (8)
        0 ≤ u₂(t)^2 ≤ 1,                   (9)
        u₁(t) * x[1:2](t) == 1,           (10)
        0 ≤ u₁(t) * x[1:2](t).^3 ≤ 1,     (11)
    end
    x = Vector{Float64}(1:n)
    u = 2 * Vector{Float64}(1:m)
    @test constraint(o, :eq1 )(x) == x[1]
    @test constraint(o, :eq2 )(x) == x
    @test constraint(o, :eq3 )(x) == x[1:2]
    @test constraint(o, :eq4 )(x) == x[1:2:4]
    @test constraint(o, :eq5 )(x) == x[2]^2
    @test constraint(o, :eq6 )(u) == u
    @test constraint(o, :eq7 )(u) == u[1:2]
    @test constraint(o, :eq8 )(u) == u[1:2:4]
    @test constraint(o, :eq9 )(u) == u[2]^2
    @test constraint(o, :eq10)(x, u) == u[1] * x[1:2]
    @test constraint(o, :eq11)(x, u) == u[1] * x[1:2].^3
    
    n = 11
    m = 6
    @def o begin
        z ∈ R^2, variable
        t ∈ [ 0, 1 ], time
        x ∈ R^n, state
        u ∈ R^m, control
        r = x₁
        v = x₂
        0 ≤ r(t) ≤ 1,                                (1)
        zeros(n) ≤ x(t) ≤ ones(n),                   (2)
        [ 0, 0 ] ≤ x[1:2](t) - [ z₁, 1 ] ≤ [ 1, 1 ], (3)
        [ 0, 0 ] ≤ x[1:2:4](t) ≤ [ 1, 1 ],           (4)
        0 ≤ v(t)^2 ≤ 1,                              (5)
        zeros(m) ≤ u(t) ≤ ones(m),                   (6)
        [ 0, 0 ] ≤ u[1:2](t) ≤ [ 1, 1 ],             (7)
        [ 0, 0 ] ≤ u[1:2:4](t) ≤ [ 1, 1 ],           (8)
        0 ≤ u₂(t)^2 ≤ 1,                             (9)
        u₁(t) * x[1:2](t) + z + f() == 1,           (10)
        0 ≤ u₁(t) * x[1:2](t).^3 + z ≤ 1,           (11)
    end
    f() = [ 1, 1 ]
    z = 3 * Vector{Float64}(1:2)
    x = Vector{Float64}(1:n)
    u = 2 * Vector{Float64}(1:m)
    @test constraint(o, :eq1 )(x, z) == x[1]
    @test constraint(o, :eq2 )(x, z) == x
    @test constraint(o, :eq3 )(x, z) == x[1:2] - [ z[1], 1 ]
    @test constraint(o, :eq4 )(x, z) == x[1:2:4]
    @test constraint(o, :eq5 )(x, z) == x[2]^2
    @test constraint(o, :eq6 )(u, z) == u
    @test constraint(o, :eq7 )(u, z) == u[1:2]
    @test constraint(o, :eq8 )(u, z) == u[1:2:4]
    @test constraint(o, :eq9 )(u, z) == u[2]^2
    @test constraint(o, :eq10)(x, u, z) == u[1] * x[1:2] + z + f()
    @test constraint(o, :eq11)(x, u, z) == u[1] * x[1:2].^3 + z

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        begin
            r = x₁
            v = x₂
            w = r + 2v
            r(0) == 0,    (1)
        end
        v(0) == 1,    (♡)
        ẋ(t) == [ v(t), w(t)^2 ]
        ∫( u(t)^2 + x₁(t) ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = 3
    @test constraint(o, :eq1)(x0, xf) == x0[1]
    @test constraint(o, Symbol("♡"))(x0, xf) == x0[2]
    @test o.dynamics(x, u) == [ x[2], (x[1] + 2x[2])^2 ]
    @test o.lagrange(x, u) == u^2 + x[1]
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        r = x₁
        v = x₂
        w = r + 2v
        r(0) == 0,    (1)
        v(0) == 1,    (♡)
        ẋ(t) == [ v(t), w(t)^2 ]
        ∫( u(t)^2 + x₁(t) ) → min
    end
    x = [ 1, 2 ]
    x0  = 2 * x
    xf  = 3 * x
    u = 3
    @test constraint(o, :eq1)(x0, xf) == x0[1]
    @test constraint(o, Symbol("♡"))(x0, xf) == x0[2]
    @test o.dynamics(x, u) == [ x[2], (x[1] + 2x[2])^2 ]
    @test o.lagrange(x, u) == u^2 + x[1]
    
    @def o begin
        z ∈ R², variable
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        r = x₁
        v = x₂
        w = r + 2v
        r(0) == 0,    (1)
        v(0) == 1,    (♡)
        ẋ(t) == [ v(t), w(t)^2 + z₁ ]
        ∫( u(t)^2 + z₂ * x₁(t) ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * [ 1, 2 ]
    xf = 3 * [ 1, 2 ]
    u = 3
    z = [ 4, 5 ]
    @test constraint(o, :eq1)(x0, xf, z) == x0[1]
    @test constraint(o, Symbol("♡"))(x0, xf, z) == x0[2]
    @test o.dynamics(x, u, z) == [ x[2], (x[1] + 2x[2])^2 + z[1] ]
    @test o.lagrange(x, u, z) == u^2 + z[2] * x[1]
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        r = x₁
        v = x₂
        r(0)^2 + v(1) == 0,    (1)
        v(0) == 1,             (♡)
        ẋ(t) == [ v(t), r(t)^2 ]
        ∫( u(t)^2 + x₁(t) ) → min
    end
    x0 = [ 2, 3 ]
    xf = [ 4, 5 ]
    x = [ 1, 2 ]
    u = 3
    @test constraint(o, :eq1)(x0, xf) == x0[1]^2 + xf[2]
    @test constraint(o, Symbol("♡"))(x0, xf) == x0[2]
    @test o.dynamics(x, u) == [ x[2], x[1]^2 ]
    @test o.lagrange(x, u) == u^2 + x[1]
    
    @def o begin
        z ∈ R, variable
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        r = x₁
        v = x₂
        r(0) - z == 0,    (1)
        v(0) == 1,        (♡)
        ẋ(t) == [ v(t), r(t)^2 + z ]
        ∫( u(t)^2 + z * x₁(t) ) → min
    end
    x0 = [ 2, 3 ]
    xf = [ 4, 5 ]
    x = [ 1, 2 ]
    u = 3
    z = 4
    @test constraint(o, :eq1)(x0, xf, z) == x0[1] - z
    @test constraint(o, Symbol("♡"))(x0, xf, z) == x0[2]
    @test o.dynamics(x, u, z) == [ x[2], x[1]^2 + z ]
    @test o.lagrange(x, u, z) == u^2 + z * x[1]
    
    @def o begin
        z ∈ R, variable
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        r = x₁
        v = x₂
        0 ≤ r(0) - z ≤ 1,            (1)
        0 ≤ v(1)^2 ≤ 1,              (2)
        [ 0, 0 ] ≤ x(0) ≤ [ 1, 1 ],  (♡)
        ẋ(t) == [ v(t), r(t)^2 + z ]
        ∫( u(t)^2 + z * x₁(t) ) → min
    end
    x0 = [ 2, 3 ]
    xf = [ 4, 5 ]
    x = [ 1, 2 ]
    u = 3
    z = 4
    @test constraint(o, :eq1)(x0, xf, z) == x0[1] - z
    @test constraint(o, :eq2)(x0, xf, z) == xf[2]^2
    @test constraint(o, Symbol("♡"))(x0, xf, z) == x0
    @test o.dynamics(x, u, z) == [ x[2], x[1]^2 + z ]
    @test o.lagrange(x, u, z) == u^2 + z * x[1]
    
    @def o begin
        z ∈ R, variable
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R, control
        r = x₁
        v = x₂
        1 ≥ r(0) - z ≥ 0,            (1)
        1 ≥ v(1)^2 ≥ 0,              (2)
        [ 1, 1 ] ≥ x(0) ≥ [ 0, 0 ],  (3)
        ẋ(t) == [ v(t), r(t)^2 + z ]
        ∫( u(t)^2 + z * x₁(t) ) → min
    end
    x0 = [ 2, 3 ]
    xf = [ 4, 5 ]
    x = [ 1, 2 ]
    u = 3
    z = 4
    @test constraint(o, :eq1)(x0, xf, z) == x0[1] - z
    @test constraint(o, :eq2)(x0, xf, z) == xf[2]^2
    @test constraint(o, :eq3)(x0, xf, z) == x0
    @test o.dynamics(x, u, z) == [ x[2], x[1]^2 + z ]
    @test o.lagrange(x, u, z) == u^2 + z * x[1]
    @test o.constraints[:eq1][3] == 0
    @test o.constraints[:eq1][4] == 1
    @test o.constraints[:eq2][3] == 0
    @test o.constraints[:eq2][4] == 1
    @test o.constraints[:eq3][3] == [ 0, 0 ]
    @test o.constraints[:eq3][4] == [ 1, 1 ]

    @def o begin
        v ∈ R², variable
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        x(0) - v₁ == 0,             (1)
        x(1) - v₁ == 0,             (2)
        0 ≤ x(0) - v₁ ≤ 1,          (3)
        0 ≤ x(1) - v₁ ≤ 1,          (4)
        x(0) + x(1) - v₂ == 0,      (5)
        0 ≤ x(0) + x(1) - v₂ ≤ 1,   (6)
        x(t) - v₁ == 0,             (7)
        u(t) - v₁ == 0,             (8)
        z = v₁ + 2v₂               
        0 ≤ x(t) - z ≤ 1,           (9)
        0 ≤ u(t) - z ≤ 1,          (10)
        0 ≤ x(t) + u(t) - z ≤ 1,   (11)
        ẋ(t) == z * x(t) + 2u(t)       
        v₁ == 1,                   (12)
        0 ≤ v₁ ≤ 1,                (13)
        z == 1,                    (14)
        0 ≤ z ≤ 1,                 (15)
        z * x(1) → min
    end
    x = 1
    x0 = 2
    xf = 3
    u = 4
    v = [ 5, 6 ]
    z = v[1] + 2v[2]
    @test constraint(o,  :eq1)(x0, xf, v) == x0 - v[1]
    @test constraint(o,  :eq2)(x0, xf, v) == xf - v[1]
    @test constraint(o,  :eq3)(x0, xf, v) == x0 - v[1]
    @test constraint(o,  :eq4)(x0, xf, v) == xf - v[1]
    @test constraint(o,  :eq5)(x0, xf, v) == x0 + xf - v[2]
    @test constraint(o,  :eq6)(x0, xf, v) == x0 + xf - v[2]
    @test constraint(o,  :eq7)(x, v) == x - v[1]
    @test constraint(o,  :eq9)(x, v) == x - z
    @test constraint(o, :eq10)(u, v) == u - z
    @test constraint(o, :eq11)(x, u, v) == x + u - z
    @test constraint(o, :eq12)(v) == v[1] 
    @test constraint(o, :eq13)(v) == v[1] 
    @test constraint(o, :eq14)(v) == v[1] + 2v[2]
    @test constraint(o, :eq15)(v) == v[1] + 2v[2]
    
    @def o begin
        v ∈ R, variable
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R², control
        x(0) ≤ 0
        x(0) ≤ 0,              (1)
        x(1) ≤ 0
        x(1) ≤ 0,              (2)
        x³(0) ≤ 0
        x³(0) ≤ 0,             (3)
        x³(1) ≤ 0
        x³(1) ≤ 0,             (4)
        x(t) ≤ 0
        x(t) ≤ 0,              (5)
        x(t) ≤ 0
        x(t) ≤ 0,              (6)
        u₁(t) ≤ 0
        u₁(t) ≤ 0,              (7)
        u₁(t) ≤ 0
        u₁(t) ≤ 0,              (8)
        x³(t) ≤ 0
        x³(t) ≤ 0,             (9)
        x³(t) ≤ 0
        x³(t) ≤ 0,            (10)
        (u₁^3)(t) ≤ 0
        (u₁^3)(t) ≤ 0,            (11)
        (u₁^3)(t) ≤ 0
        (u₁^3)(t) ≤ 0,            (12)
        x(t) + (u₁^3)(t) ≤ 0
        x(t) + (u₁^3)(t) ≤ 0,     (13)
        x(t) + (u₁^3)(t) ≤ 0
        x(t) + (u₁^3)(t) ≤ 0,     (14)
        v ≤ 0
        v ≤ 0,                (15)
    end
    
    @test o.constraints[:eq1 ][3] == -Inf
    @test o.constraints[:eq2 ][3] == -Inf
    @test o.constraints[:eq3 ][3] == -Inf
    @test o.constraints[:eq4 ][3] == -Inf
    @test o.constraints[:eq5 ][3] == -Inf
    @test o.constraints[:eq6 ][3] == -Inf
    @test o.constraints[:eq7 ][3] == -Inf
    @test o.constraints[:eq8 ][3] == -Inf
    @test o.constraints[:eq9 ][3] == -Inf
    @test o.constraints[:eq10][3] == -Inf
    @test o.constraints[:eq11][3] == -Inf
    @test o.constraints[:eq12][3] == -Inf
    @test o.constraints[:eq13][3] == -Inf
    @test o.constraints[:eq14][3] == -Inf
    @test o.constraints[:eq15][3] == -Inf
    @test o.constraints[:eq1 ][4] == 0
    @test o.constraints[:eq2 ][4] == 0
    @test o.constraints[:eq3 ][4] == 0
    @test o.constraints[:eq4 ][4] == 0
    @test o.constraints[:eq5 ][4] == 0
    @test o.constraints[:eq6 ][4] == 0
    @test o.constraints[:eq7 ][4] == 0
    @test o.constraints[:eq8 ][4] == 0
    @test o.constraints[:eq9 ][4] == 0
    @test o.constraints[:eq10][4] == 0
    @test o.constraints[:eq11][4] == 0
    @test o.constraints[:eq12][4] == 0
    @test o.constraints[:eq13][4] == 0
    @test o.constraints[:eq14][4] == 0
    @test o.constraints[:eq15][4] == 0
    
    @def o begin
        v ∈ R, variable
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R², control
        x(0) ≥ 0
        x(0) ≥ 0,              (1)
        x(1) ≥ 0
        x(1) ≥ 0,              (2)
        x³(0) ≥ 0
        x³(0) ≥ 0,             (3)
        x³(1) ≥ 0
        x³(1) ≥ 0,             (4)
        x(t) ≥ 0
        x(t) ≥ 0,              (5)
        x(t) ≥ 0
        x(t) ≥ 0,              (6)
        u₁(t) ≥ 0
        u₁(t) ≥ 0,             (7)
        u₁(t) ≥ 0
        u₁(t) ≥ 0,             (8)
        x³(t) ≥ 0
        x³(t) ≥ 0,             (9)
        x³(t) ≥ 0
        x³(t) ≥ 0,            (10)
        (u₁^3)(t) ≥ 0
        (u₁^3)(t) ≥ 0,        (11)
        (u₁^3)(t) ≥ 0
        (u₁^3)(t) ≥ 0,        (12)
        x(t) + (u₁^3)(t) ≥ 0
        x(t) + (u₁^3)(t) ≥ 0, (13)
        x(t) + (u₁^3)(t) ≥ 0
        x(t) + (u₁^3)(t) ≥ 0, (14)
        v ≥ 0
        v ≥ 0,                (15)
    end
    
    @test o.constraints[:eq1 ][3] == 0
    @test o.constraints[:eq2 ][3] == 0
    @test o.constraints[:eq3 ][3] == 0
    @test o.constraints[:eq4 ][3] == 0
    @test o.constraints[:eq5 ][3] == 0
    @test o.constraints[:eq6 ][3] == 0
    @test o.constraints[:eq7 ][3] == 0
    @test o.constraints[:eq8 ][3] == 0
    @test o.constraints[:eq9 ][3] == 0
    @test o.constraints[:eq10][3] == 0
    @test o.constraints[:eq11][3] == 0
    @test o.constraints[:eq12][3] == 0
    @test o.constraints[:eq13][3] == 0
    @test o.constraints[:eq14][3] == 0
    @test o.constraints[:eq15][3] == 0
    @test o.constraints[:eq1 ][4] == Inf
    @test o.constraints[:eq2 ][4] == Inf
    @test o.constraints[:eq3 ][4] == Inf
    @test o.constraints[:eq4 ][4] == Inf
    @test o.constraints[:eq5 ][4] == Inf
    @test o.constraints[:eq6 ][4] == Inf
    @test o.constraints[:eq7 ][4] == Inf
    @test o.constraints[:eq8 ][4] == Inf
    @test o.constraints[:eq9 ][4] == Inf
    @test o.constraints[:eq10][4] == Inf
    @test o.constraints[:eq11][4] == Inf
    @test o.constraints[:eq12][4] == Inf
    @test o.constraints[:eq13][4] == Inf
    @test o.constraints[:eq14][4] == Inf
    @test o.constraints[:eq15][4] == Inf

    @def o begin
        v ∈ R^2, variable
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R², control
        x(0) ≤ [ 0, 0 ]
        x(0) ≤ [ 0, 0 ],              (1)
        x(1) ≤ [ 0, 0 ]
        x(1) ≤ [ 0, 0 ],               (2)
        [ x₁(0)^3, 0 ] ≤ [ 0, 0 ]
        [ x₁(0)^3, 0 ] ≤ [ 0, 0 ],     (3)
        x(t) ≤ [ 0, 0 ]
        x(t) ≤ [ 0, 0 ],             (4)
        u(t) ≤ [ 0, 0 ]
        u(t) ≤ [ 0, 0 ],         (5)
        [ x₁(t)^3, 0 ] ≤ [ 0, 0 ]
        [ x₁(t)^3, 0 ] ≤ [ 0, 0 ], (6)
        [ u₁(t)^3, 0 ] ≤ [ 0, 0 ]
        [ u₁(t)^3, 0 ] ≤ [ 0, 0 ], (7)
        [ u₁(t)^3, x₁(t) ] ≤ [ 0, 0 ]
        [ u₁(t)^3, x₁(t) ] ≤ [ 0, 0 ], (8)
        v ≤ [ 0, 0 ]
        v ≤ [ 0, 0 ], (9)
        [ v₁^2, 0 ] ≤ [ 0, 0 ]
        [ v₁^2, 0 ] ≤ [ 0, 0 ], (10)
    end
    
    @test o.constraints[:eq1 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq2 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq3 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq4 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq5 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq6 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq7 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq8 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq9 ][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq10][3] ==-[ Inf, Inf ]
    @test o.constraints[:eq1 ][4] == [ 0, 0 ]
    @test o.constraints[:eq2 ][4] == [ 0, 0 ]
    @test o.constraints[:eq3 ][4] == [ 0, 0 ]
    @test o.constraints[:eq4 ][4] == [ 0, 0 ]
    @test o.constraints[:eq5 ][4] == [ 0, 0 ]
    @test o.constraints[:eq6 ][4] == [ 0, 0 ]
    @test o.constraints[:eq7 ][4] == [ 0, 0 ]
    @test o.constraints[:eq8 ][4] == [ 0, 0 ]
    @test o.constraints[:eq9 ][4] == [ 0, 0 ]
    @test o.constraints[:eq10][4] == [ 0, 0 ]

    @def o begin
        v ∈ R^2, variable
        t ∈ [ 0, 1 ], time
        x ∈ R², state
        u ∈ R², control
        x(0) ≥ [ 0, 0 ]
        x(0) ≥ [ 0, 0 ],              (1)
        x(1) ≥ [ 0, 0 ]
        x(1) ≥ [ 0, 0 ],               (2)
        [ x₁(0)^3, 0 ] ≥ [ 0, 0 ]
        [ x₁(0)^3, 0 ] ≥ [ 0, 0 ],     (3)
        x(t) ≥ [ 0, 0 ]
        x(t) ≥ [ 0, 0 ],             (4)
        u(t) ≥ [ 0, 0 ]
        u(t) ≥ [ 0, 0 ],         (5)
        [ x₁(t)^3, 0 ] ≥ [ 0, 0 ]
        [ x₁(t)^3, 0 ] ≥ [ 0, 0 ], (6)
        [ u₁(t)^3, 0 ] ≥ [ 0, 0 ]
        [ u₁(t)^3, 0 ] ≥ [ 0, 0 ], (7)
        [ u₁(t)^3, x₁(t) ] ≥ [ 0, 0 ]
        [ u₁(t)^3, x₁(t) ] ≥ [ 0, 0 ], (8)
        v ≥ [ 0, 0 ]
        v ≥ [ 0, 0 ], (9)
        [ v₁^2, 0 ] ≥ [ 0, 0 ]
        [ v₁^2, 0 ] ≥ [ 0, 0 ], (10)
    end
    
    @test o.constraints[:eq1 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq2 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq3 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq4 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq5 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq6 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq7 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq8 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq9 ][4] == [ Inf, Inf ]
    @test o.constraints[:eq10][4] == [ Inf, Inf ]
    @test o.constraints[:eq1 ][3] == [ 0, 0 ]
    @test o.constraints[:eq2 ][3] == [ 0, 0 ]
    @test o.constraints[:eq3 ][3] == [ 0, 0 ]
    @test o.constraints[:eq4 ][3] == [ 0, 0 ]
    @test o.constraints[:eq5 ][3] == [ 0, 0 ]
    @test o.constraints[:eq6 ][3] == [ 0, 0 ]
    @test o.constraints[:eq7 ][3] == [ 0, 0 ]
    @test o.constraints[:eq8 ][3] == [ 0, 0 ]
    @test o.constraints[:eq9 ][3] == [ 0, 0 ]
    @test o.constraints[:eq10][3] == [ 0, 0 ]


    t0 = 9.0; tf = 9.1
    r0 = 1.0; r1 = 2.0
    v0 = 2.0; vmax = sqrt(2)
    m0 = 3.0; mf = 1.1
    @def ocp begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^2, control

        m = x₂

        x(t0) == [ r0, v0, m0 ], (1)
        0  ≤ u[1](t) ≤ 1       , (deux)
        r0 ≤ x(t)[1] ≤ r1      , (trois)
        0  ≤ x₂(t) ≤ vmax      , (quatre)
        mf ≤ m(t) ≤ m0         , (5)
    end
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_name == "u"
    @test ocp.control_dimension == 2
    @test ocp.state_name == "x"
    @test ocp.state_dimension == 3

    @def ocp begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^2, control

        m = x₂

        x(t0) == [ r0, v0, m0 ]
        0  ≤ u(t)[2] ≤ 1
        r0 ≤ x(t)[1] ≤ r1
        0  ≤ x₂(t) ≤ vmax
        mf ≤ m(t) ≤ m0
    end
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "t"
    @test ocp.initial_time == t0
    @test ocp.final_time   == tf
    @test ocp.control_name == "u"
    @test ocp.control_dimension == 2
    @test ocp.state_name == "x"
    @test ocp.state_dimension == 3

    # dyslexic definition:  t -> u -> x -> t
    u0 = 9.0; uf = 9.1
    z0 = 1.0; z1 = 2.0
    k0 = 2.0; kmax = sqrt(2)
    b0 = 3.0; bf = 1.1

    @def ocp begin
        u ∈ [ u0, uf ], time
        t ∈ R^3, state
        x ∈ R^2, control
        b = t₂
        t(u0) == [ z0, k0, b0 ]
        0  ≤ x[2](u) ≤ 1
        z0 ≤ t(u)[1] ≤ z1
        0  ≤ t₂(u) ≤ kmax
        bf ≤ b(u) ≤ b0
    end
    @test ocp isa OptimalControlModel
    @test ocp.time_name == "u"
    @test ocp.initial_time == u0
    @test ocp.final_time   == uf
    @test ocp.control_name == "x"
    @test ocp.control_dimension == 2
    @test ocp.state_name == "t"
    @test ocp.state_dimension == 3

#
# test all constraints on @def macro
#
# ref: https://github.com/control-toolbox/CTBase.jl/issues/9
#

#function test_ctparser_constraints()

    # all used variables must be definedbefore each test
    x0   = [ 1, 2, 11.11 ]
    x02  = 11.111
    x0_b = 11.1111
    x0_u = 11.11111
    y0   = [ 1, 2.22 ]
    y0_b = [ 1, 2.222 ]
    y0_u = [ 2, 2.2222 ]

    # === initial
    t0   = 0.0
    tf   = 1.0
    n    = 3
    @def ocp1 begin

        t ∈ [ t0, tf ], time
        x ∈ R^n, state
        u ∈ R^n, control
        x(t0) == x0
        x[2](t0) == x02
        x[2:3](t0) == y0
        x0_b ≤ x₂(t0) ≤ x0_u
        y0_b ≤ x[2:3](t0) ≤ y0_u
    end
    @test ocp1 isa OptimalControlModel
    @test ocp1.state_dimension == n
    @test ocp1.control_dimension == n
    @test ocp1.initial_time == t0
    @test ocp1.final_time == tf

    t0   = 0.1
    tf   = 1.1
    x0   = ones(4)
    n    = 4
    @def ocp2 begin
        t ∈ [ t0, tf ], time
        x ∈ R^n, state
        u ∈ R^n, control

        x(t0) == x0                , initial_1
        x[2](t0) == 1              , initial_2
        x[2:3](t0) == [ 1, 2 ]     , initial_3
        x0 ≤ x(t0) ≤ x0 .+ 1       , initial_4
        [ 1, 2 ] ≤ x[2:3](t0) ≤ [ 3, 4 ], initial_5
    end
    @test ocp2 isa OptimalControlModel
    @test ocp2.state_dimension == n
    @test ocp2.control_dimension == n
    @test ocp2.initial_time == t0
    @test ocp2.final_time == tf


    # all used variables must be defined before each test
    xf   = 11.11 * ones(4)
    xf2  = 11.111
    xf_b = 11.1111 * ones(4)
    xf_u = 11.11111 * ones(4)
    yf   = 2.22 * ones(2)
    yf_b = 2.222 * ones(2)
    yf_u = 2.2222 * ones(2)

    # === final
    t0   = 0.2
    tf   = 1.2
    n    = 4
    @def ocp3 begin
        t ∈ [ t0, tf ], time
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
    xf   = 11.11 * ones(n)
    xf2  = 11.111
    xf_b = 11.1111 * ones(n)
    xf_u = 11.11111 * ones(n)
    yf   = 2.22 * ones(2)
    yf_b = 2.222 * ones(2)
    yf_u = 2.2222 * ones(2)

    @def ocp4 begin

        t ∈ [ t0, tf ], time
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
    n    = 2
    @def ocp5 begin
        t ∈ [ t0, tf ], time
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
    n    = 2
    @def ocp6 begin
        t ∈ [ t0, tf ], time
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
    n    = 2
    @def ocp7 begin
        t ∈ [ t0, tf ], time
        x ∈ R^n, state
        u ∈ R^n, control
        u_b ≤ u[1](t) ≤ u_u
        u2_b ≤ u[1](t) ≤ u2_u
        v_b ≤ u[2](t) ≤ v_u
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
    n    = 2
    u_b  = 1.0
    u_u  = 2.0
    u2_b = 3.0
    u2_u = 4.0
    v_b  = 5.0
    v_u  = 6.0
    @def ocp8 begin
        t ∈ [ t0, tf ], time
        x ∈ R^n, state
        u ∈ R^n, control
        u_b ≤ u[2](t) ≤ u_u               , control_1
        u2_b ≤ u[1](t) ≤ u2_u          , control_3
        [ 1, v_b ] ≤ u[1:2](t) ≤ [ 2, v_u ], control_5
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
    @def ocp9 begin
        t ∈ [ t0, tf ], time
        x ∈ R^n, state
        u ∈ R^n, control
        x_b ≤ x[3](t) ≤ x_u
        #x(t) == x_u
        x2_b ≤ x[2](t) ≤ x2_u
        #x[2](t) == x2_u
        #x[2:3](t) == y_u
        x_u ≤ x[10](t) ≤ y_u
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
    @def ocp10 begin
        t ∈ [ t0, tf ], time
        x ∈ R^n, state
        u ∈ R^n, control
        x_b ≤ x[3](t) ≤ x_u                             , state_1
        #x(t) == x_u                                  , state_2
        x2_b ≤ x[2](t) ≤ x2_u                        , state_3
        #x[2](t) == x2_u                              , state_4
        #x[2:3](t) == y_u                             , state_5
        x_u ≤ x[3](t) ≤ y_u                        , state_6
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
    @def ocp11 begin

        t ∈ [ t0, tf ], time
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

    @def ocp12 begin
        t ∈ [ t0, tf ], time
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
    @def ocp13 begin
        t ∈ [ t0, tf ], time
        x ∈ R, state
        u ∈ R, control
        ẋ(t) == 2x(t) + u(t)^2
    end
    @test ocp13 isa OptimalControlModel
    @test ocp13.state_dimension   == 1
    @test ocp13.control_dimension == 1
    @test ocp13.initial_time == t0
    @test ocp13.final_time == tf

    # some syntax (even parseable) are not allowed
    # this is the actual exhaustive list
    # note: equality constraints on ranges for state and control
    # are now allowed to ensure a uniform treatment of equalities
    # as particular inequalities
    @test_throws ParsingError @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R, state
        u ∈ R, control
        ẋ(t) == f(x(t), u(t))  , named_dynamics_not_allowed  # but allowed if unnamed !
    end

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "Lagrange cost" begin
    println("lagrange testset...")

    # --------------------------------
    # min
    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        ∫( 0.5u(t)^2 ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == 0.5u^2
    @test o.criterion == :min

    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        -∫( 0.5u(t)^2 ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == -0.5u^2
    @test o.criterion == :min

    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        0.5 * ∫( u(t)^2 ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == 0.5u^2
    @test o.criterion == :min
    
    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        0.5∫( u(t)^2 ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == 0.5u^2
    @test o.criterion == :min
    
    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        -0.5 * ∫( u(t)^2 ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == -0.5u^2
    @test o.criterion == :min

    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        (-0.5 + tf) * ∫( u(t)^2 ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == (-0.5 + tf) * u^2
    @test o.criterion == :min

    t0 = 0
    tf = 1
    @test_throws ParsingError @def o begin # a call to the time (t, here) must not appear before the integral
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        (-0.5 + t) * ∫( u(t)^2 ) → min
    end

    t0 = 0
    tf = 1
    @test_throws ParsingError @def o begin # a call to the time (t, here) must not appear before the integral
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        (-0.5 + x(t)) * ∫( u(t)^2 ) → min
    end

    # -----------------------------------
    # max 
    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        ∫( 0.5u(t)^2 ) → max
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == 0.5u^2
    @test o.criterion == :max

    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        -∫( 0.5u(t)^2 ) → max
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == -0.5u^2
    @test o.criterion == :max

    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        0.5 * ∫( u(t)^2 ) → max
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == 0.5u^2
    @test o.criterion == :max
    
    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        0.5∫( u(t)^2 ) → max
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == 0.5u^2
    @test o.criterion == :max
    
    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        -0.5 * ∫( u(t)^2 ) → max
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == -0.5u^2
    @test o.criterion == :max

    # -----------------------------------
    t0 = .0; tf = .1
    @def ocp begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^3, control
        ∫( 0.5u(t)^2 ) → min
    end ;
    @test ocp isa OptimalControlModel

    t0 = .0; tf = .1
    @def ocp begin
        t ∈ [ t0, tf ], time
        x ∈ R^3, state
        u ∈ R^3, control
        ∫( 0.5u(t)^2 ) → max
    end ;
    @test ocp isa OptimalControlModel

end

   t0 = 0
    tf = 1
    @test_throws ParsingError @def o begin # a call to the time (t, here) must not appear before the integral
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        (-0.5 + t) * ∫( u(t)^2 ) → max
    end

    t0 = 0
    tf = 1
    @test_throws ParsingError @def o begin # a call to the time (t, here) must not appear before the integral
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        (-0.5 + x(t)) * ∫( u(t)^2 ) → max
    end


# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "Bolza cost" begin
    println("Bolza testset...")

    # -------------------------------
    # min 
    # Mayer ± Lagrange
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 3x(1)) + ∫(x(t) + u(t)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 3xf
    @test o.lagrange(x, u) ==  x + u
    @test o.criterion == :min

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) + ∫(x(t) + u(t)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  x + u
    @test o.criterion == :min

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) + 2 * ∫(x(t) + u(t)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  2(x + u)
    @test o.criterion == :min

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) - ∫(x(t) + u(t)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  -(x + u)
    @test o.criterion == :min
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) - 2 * ∫(x(t) + u(t)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  -2(x + u)
    @test o.criterion == :min

    @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) + t * ∫(x(t) + u(t)) → min
    end

   @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) - t * ∫(x(t) + u(t)) → min
    end
 
    # -------------------------------
    # max 
    # Mayer ± Lagrange
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 5x(1)) + ∫(x(t) + u(t)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 5xf
    @test o.lagrange(x, u) ==  x + u
    @test o.criterion == :max

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) + 2 * ∫(x(t) + u(t)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  2(x + u)
    @test o.criterion == :max

    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) - ∫(x(t) + u(t)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  -(x + u)
    @test o.criterion == :max
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) - 2 * ∫(x(t) + u(t)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  -2(x + u)
    @test o.criterion == :max

    @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) + t * ∫(x(t) + u(t)) → max
    end

   @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        (x(0) + 2x(1)) - t * ∫(x(t) + u(t)) → max
    end
 
    # -------------------------------
    # min 
    # Lagrange ± Mayer
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        ∫(x(t) + u(t)) + (x(0) + 2x(1)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  x + u
    @test o.criterion == :min
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        2 * ∫(x(t) + u(t)) + (x(0) + 2x(1)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  2(x + u)
    @test o.criterion == :min
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        ∫(x(t) + u(t)) - (x(0) + 2x(1)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  -(x0 + 2xf)
    @test o.lagrange(x, u) ==  x + u
    @test o.criterion == :min
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        2 * ∫(x(t) + u(t)) - (x(0) + 2x(1)) → min
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  -(x0 + 2xf)
    @test o.lagrange(x, u) ==  2(x + u)
    @test o.criterion == :min

    @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        t * ∫(x(t) + u(t)) + 1 → min
    end
 
    @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        t * ∫(x(t) + u(t)) - 1 → min
    end
 
    # -------------------------------
    # max
    # Lagrange ± Mayer
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        ∫(x(t) + u(t)) + (x(0) + 2x(1)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  x + u
    @test o.criterion == :max
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        2 * ∫(x(t) + u(t)) + (x(0) + 2x(1)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  x0 + 2xf
    @test o.lagrange(x, u) ==  2(x + u)
    @test o.criterion == :max
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        ∫(x(t) + u(t)) - (x(0) + 2x(1)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  -(x0 + 2xf)
    @test o.lagrange(x, u) ==  x + u
    @test o.criterion == :max
    
    @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        2 * ∫(x(t) + u(t)) - (x(0) + 2x(1)) → max
    end
    x = 1
    u = 2
    x0 = 3
    xf = 4
    @test o.mayer(x0, xf) ==  -(x0 + 2xf)
    @test o.lagrange(x, u) ==  2(x + u)
    @test o.criterion == :max

    @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        t * ∫(x(t) + u(t)) + 1 → max
    end
 
    @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R, state
        u ∈ R, control
        t * ∫(x(t) + u(t)) - 1 → max
    end
    
end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "Mayer cost" begin
    println("Mayer testset...")

    @def o begin
        s ∈ [ 0, 1 ], time
        y ∈ R^4, state
        w ∈ R, control
        r = y₃
        v = y₄
        r(0) + v(1) → min
    end
    y0 = [ 1, 2, 3, 4 ]
    yf = 2 * [ 1, 2, 3, 4 ]
    @test is_min(o)
    @test o.mayer(y0, yf) == y0[3] + yf[4]

    @def o begin
        s ∈ [ 0, 1 ], time
        y ∈ R^4, state
        w ∈ R, control
        r = y₃
        v = y₄
        r(0) + v(1) → max
    end
    y0 = [ 1, 2, 3, 4 ]
    yf = 2 * [ 1, 2, 3, 4 ]
    @test is_max(o)
    @test o.mayer(y0, yf) == y0[3] + yf[4]
    
    @def o begin
        z ∈ R^2, variable
        s ∈ [ 0, z₁ ], time
        y ∈ R^4, state
        w ∈ R, control
        r = y₃
        v = y₄
        r(0) + v(z₁) + z₂ → min
    end
    z = [ 5, 6 ]
    y0 = [ 1, 2, 3, 4 ]
    yf = 2 * [ 1, 2, 3, 4 ]
    @test is_min(o)
    @test o.mayer(y0, yf, z) == y0[3] + yf[4] + z[2]

    @def o begin
        z ∈ R², variable
        s ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁ + w² + v³ + z₂
        ẏ(s) == [ aa(s), r²(s), 0, 0 ]
        r(0) + v(z₁) + z₂ → min
    end
    z = [ 5, 6 ]
    y = [ 1, 2, 3, 4 ]
    y0 = y
    yf = 3y0
    w = 7
    @test o.dynamics(y, w, z) == [ y[1] + w^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]
    @test o.mayer(y0, yf, z) == y0[3] + yf[4] + z[2]
    
    @def o begin
        z ∈ R², variable
        s ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁(s) + v³ + z₂
        ẏ(s) == [ aa(s) + (w^2)(s), r²(s), 0, 0 ]
        r(0) + v(z₁) + z₂ → min
    end
    z = [ 5, 6 ]
    y = [ 1, 2, 3, 4 ]
    y0 = y
    yf = 3y0
    w = 7
    @test o.dynamics(y, w, z) == [ y[1] + w^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]
    @test o.mayer(y0, yf, z) == y0[3] + yf[4] + z[2]

    @def o begin
        z ∈ R², variable
        s ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁ + v³ + z₂
        aa(0) + y₂(z₁) → min
    end
    z = [ 5, 6 ]
    y0 = y
    yf = 3y0
    @test o.mayer(y0, yf, z) == y0[1] + y0[4]^3 + z[2] + yf[2]

    @def o begin
        z ∈ R², variable
        __t ∈ [ 0, z₁ ], time
        y ∈ R⁴, state
        w ∈ R, control
        r = y₃
        v = y₄
        aa = y₁(__t) + v³ + z₂
        ẏ(__t) == [ aa(__t) + (w^2)(__t), r²(__t), 0, 0 ]
        aa(0) + y₂(z₁) → min
    end
    z = [ 5, 6 ]
    y = [ 1, 2, 3, 4 ]
    y0 = y
    yf = 3y0
    w = 11
    @test o.dynamics(y, w, z) == [ y[1] + w^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]
    @test_throws UndefVarError o.mayer(y0, yf, z)

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "closure" begin
    println("closure testset...")

    a = 1
    f(b) = begin # closure of a, local c, and @def in function
        c = 3
        @def ocp begin
            t ∈ [ a, b ], time
            x ∈ R, state
            u ∈ R, control
            ẋ(t) == x(t) + u(t) + b + c + d
        end
        return ocp
    end
    b = 2
    o = f(b)
    d = 4
    x = 10
    u = 20
    @test o.dynamics(x, u) == x + u + b + 3 + d

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "error detection" begin 

    # error detections (this can be tricky -> need more work)

    # this one is detected by the generated code (and not the parser)
    t0 = 9.0; tf = 9.1
    @test_throws CTException @def o begin
        t ∈ [ t0, tf ], time
        t ∈ [ t0, tf ], time
    end

    # illegal constraint name (1bis), detected by the parser
    t0 = 9.0; tf = 9.1
    r0 = 1.0; v0 = 2.0; m0 = 3.0
    @test_throws ParsingError @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R^2, control
        0  ≤ u(t) ≤ 1          , (1bis)
    end

    # t0 is unknown in the x(t0) constraint, detected by the parser
    r0 = 1.0; v0 = 2.0; m0 = 3.0
    @test_throws ParsingError @def o begin
        t ∈ [ 0, 1 ], time
        x ∈ R^2, state
        u ∈ R^2, control
        x(t0) == [ r0, v0, m0 ], (1)
        0  ≤ u(t) ≤ 1          , (1bis)
    end

    # bad syntax for Bolza cost interpreted as a Mayer term with trailing ∫ 
    @test_throws ParsingError @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        1 + 2 + ∫( u(t)^2 ) → min # should be ( 1 + 2 ) + ∫(...)
    end

    @test_throws ParsingError @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        ∫( u(t)^2 ) + 1 + 2 → min # should be ∫(...) + ( 1 + 2 )
    end

    @test_throws ParsingError @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        ẋ(t) == A * x(t) + B * u(t)
        ∫( u(t)^2 ) / 2 → min # forbidden
    end

end

# ---------------------------------------------------------------
# ---------------------------------------------------------------
@testset "derivative and integral non unicode keywords" begin
    println("derivative and integral non unicode keywords testset...")

    # --------------------------------
    # min
    t0 = 0
    tf = 1
    @def o begin
        t ∈ [ t0, tf ], time
        x ∈ R^2, state
        u ∈ R, control
        x(t0) == [ -1, 0 ], (1)
        x(tf) == [  0, 0 ]
        derivative(x)(t) == A * x(t) + B * u(t)
        integral( 0.5u(t)^2 ) → min
    end
    x = [ 1, 2 ]
    x0 = 2 * x
    xf = 3 * x
    u = -1
    A = [ 0 1
          0 0 ]
    B = [ 0
          1 ]
    @test constraint(o, :eq1)(x0, xf) == x0
    @test o.dynamics(x, u) == A * x + B * u
    @test o.lagrange(x, u) == 0.5u^2
    @test o.criterion == :min

end