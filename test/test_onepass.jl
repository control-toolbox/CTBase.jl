# test onepass

function test_onepass()

t0 = 0
o = @def1 t ∈ [ t0, t0 + 4 ], time
@test o.initial_time == t0
@test o.final_time == t0 + 4 
 
o = @def1 begin
    λ ∈ R^2, variable
    tf = λ₂
    t ∈ [ 0, tf ], time
    end
@test o.initial_time == 0
@test o.final_time == Index(2) 
 
o = @def1 begin
    t0 ∈ R, variable
    t ∈ [ t0, 1 ], time
    end
@test o.initial_time == Index(1)
@test o.final_time == 1

o = @def1 begin
    tf ∈ R, variable
    t ∈ [ 0, tf ], time
    end
@test o.initial_time == 0
@test o.final_time == Index(1)

o = @def1 begin
    v ∈ R², variable
    s ∈ [ v[1], v[2] ], time
    end
@test o.initial_time == Index(1)
@test o.final_time == Index(2)

o = @def1 begin
    v ∈ R², variable
    s0 = v₁
    sf = v₂
    s ∈ [ s0, sf ], time
    end
@test o.initial_time == Index(1)
@test o.final_time == Index(2)

@test_throws IncorrectArgument @def1 begin
    t0 ∈ R², variable
    t ∈ [ t0, 1 ], time
    end

@test_throws IncorrectArgument @def1 begin
    tf ∈ R², variable
    t ∈ [ 0, tf ], time
    end

@test_throws ParsingError @def1 begin
    v, variable
    t ∈ [ 0, tf[v] ], time
    end

@test_throws ParsingError @def1 begin
    v, variable
    t ∈ [ t0[v], 1 ], time
    end

@test_throws ParsingError @def1 begin
    v, variable
    t ∈ [ t0[v], tf[v+1] ], time
    end

o = @def1 begin
    x ∈ R, state
    u ∈ R, control
    end
@test o.state_dimension == 1
@test o.control_dimension == 1

o = @def1 begin
    t ∈ [ 0, 1 ], time
    x ∈ R^3, state
    u ∈ R^2, control
    x'(t) == [ x[1](t) + 2u[2](t), 2x[3](t), x[1](t) + u[2](t) ]
    end
@test o.state_dimension == 3
@test o.control_dimension == 2
x = [ 1, 2, 3 ]
u = [ -1, 2 ]
@test o.dynamics(x, u) == [ x[1] + 2u[2], 2x[3], x[1] + u[2] ]

t0 = 0
tf = 1
o = @def1 begin
    t ∈ [ t0, tf ], time
    x ∈ R^2, state
    u ∈ R, control
    x(t0) == [ -1, 0 ], (1) 
    x(tf) == [  0, 0 ] 
    x'(t) == A * x(t) + B * u(t)
    ∫( 0.5u(t)^2 ) → min
end
x = [ 1, 2 ]
u = -1 
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
@test constraint(o, :eq1)(x) == x
@test o.dynamics(x, u) == A * x + B * u
@test o.lagrange(x, u) == 0.5u^2 
@test o.criterion == :min

a = 1
f(b) = begin # closure of a, local c, and @def1 in function
    c = 3
    @def1 begin
        t ∈ [ a, b ], time
        x ∈ R, state
        u ∈ R, control
        x'(t) == x(t) + u(t) + b + c + d
    end
end
o = f(2)
d = 4
x = 10 
u = 20 
@test o.dynamics(x, u) == x + u + 2 + 3 + 4

o = @def1 begin
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    r = x₁
    v = x₂
    w = r + 2v
    r(0) == 0,    (1)
    v(0) == 1,    (♡)
    x'(t) == [ v(t), w(t)^2 ]
    ∫( u(t)^2 + x₁(t) ) → min
    end 
x = [ 1, 2 ]
u = 3 
@test constraint(o, :eq1)(x) == x[1]
@test constraint(o, Symbol("♡"))(x) == x[2]
@test o.dynamics(x, u) == [ x[2], (x[1] + 2x[2])^2 ]
@test o.lagrange(x, u) == u^2 + x[1] 
 
o = @def1 begin
    z ∈ R², variable
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    r = x₁
    v = x₂
    w = r + 2v
    r(0) == 0,    (1)
    v(0) == 1,    (♡)
    x'(t) == [ v(t), w(t)^2 + z₁ ]
    ∫( u(t)^2 + z₂ * x₁(t) ) → min
    end 
x = [ 1, 2 ]
u = 3 
z = [ 4, 5 ]
@test constraint(o, :eq1)(x) == x[1]
@test constraint(o, Symbol("♡"))(x) == x[2]
@test o.dynamics(x, u, z) == [ x[2], (x[1] + 2x[2])^2 + z[1] ]
@test o.lagrange(x, u, z) == u^2 + z[2] * x[1] 

o = @def1 begin
    tf, variable
    t ∈ [ 0, tf ], time
    x ∈ R², state
    r = x₁
    v = x₂
    w = r¹ + 2v³
    r(0) + w(tf) - tf² == 0,    (1)
    end 
tf = 2
x0 = [ 1, 2 ]
xf = [ 3, 4 ]
@test constraint(o, :eq1)(x0, xf, tf) == x0[1] + ( xf[1] + 2xf[2]^3 ) - tf^2
 
o = @def1 begin
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    r = x₁
    v = x₂
    r(0)^2 + v(1) == 0,    (1)
    v(0) == 1,             (♡)
    x'(t) == [ v(t), r(t)^2 ]
    ∫( u(t)^2 + x₁(t) ) → min
    end 
x0 = [ 2, 3 ] 
xf = [ 4, 5 ] 
x = [ 1, 2 ]
u = 3 
@test constraint(o, :eq1)(x0, xf) == x0[1]^2 + xf[2]
@test constraint(o, Symbol("♡"))(x0) == x0[2]
@test o.dynamics(x, u) == [ x[2], x[1]^2 ]
@test o.lagrange(x, u) == u^2 + x[1] 
 
o = @def1 begin
    z ∈ R, variable
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    r = x₁
    v = x₂
    r(0) - z == 0,    (1)
    v(0) == 1,        (♡)
    x'(t) == [ v(t), r(t)^2 + z ]
    ∫( u(t)^2 + z * x₁(t) ) → min
    end 
x0 = [ 2, 3 ] 
xf = [ 4, 5 ] 
x = [ 1, 2 ]
u = 3 
z = 4
@test constraint(o, :eq1)(x0, xf, z) == x0[1] - z
@test constraint(o, Symbol("♡"))(x0) == x0[2]
@test o.dynamics(x, u, z) == [ x[2], x[1]^2 + z ]
@test o.lagrange(x, u, z) == u^2 + z * x[1] 
 
o = @def1 begin
    z ∈ R, variable
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    r = x₁
    v = x₂
    0 ≤ r(0) - z ≤ 1,            (1)
    0 ≤ v(1)^2 ≤ 1,              (2)
    [ 0, 0 ] ≤ x(0) ≤ [ 1, 1 ],  (♡)
    x'(t) == [ v(t), r(t)^2 + z ]
    ∫( u(t)^2 + z * x₁(t) ) → min
    end 
x0 = [ 2, 3 ] 
xf = [ 4, 5 ] 
x = [ 1, 2 ]
u = 3 
z = 4
@test constraint(o, :eq1)(x0, xf, z) == x0[1] - z
@test constraint(o, :eq2)(x0, xf, z) == xf[2]^2
@test constraint(o, Symbol("♡"))(x0) == x0
@test o.dynamics(x, u, z) == [ x[2], x[1]^2 + z ]
@test o.lagrange(x, u, z) == u^2 + z * x[1] 

n = 11
m = 6
o = @def1 begin
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
o = @def1 begin
    z ∈ R^2, variable
    t ∈ [ 0, 1 ], time
    x ∈ R^n, state
    u ∈ R^m, control
    r = x₁
    v = x₂
    0 ≤ r(t) ≤ 1,                      (1)
    zeros(n) ≤ x(t) ≤ ones(n),         (2)
    [ 0, 0 ] ≤ x[1:2](t) - [ z₁, 1 ] ≤ [ 1, 1 ], (3)
    [ 0, 0 ] ≤ x[1:2:4](t) ≤ [ 1, 1 ],  (4)
    0 ≤ v(t)^2 ≤ 1,                    (5)
    zeros(m) ≤ u(t) ≤ ones(m),         (6)
    [ 0, 0 ] ≤ u[1:2](t) ≤ [ 1, 1 ],   (7)
    [ 0, 0 ] ≤ u[1:2:4](t) ≤ [ 1, 1 ], (8)
    0 ≤ u₂(t)^2 ≤ 1,                   (9)
    u₁(t) * x[1:2](t) + z + f() == 1, (10)
    0 ≤ u₁(t) * x[1:2](t).^3 + z ≤ 1, (11)
    end 
f() = [ 1, 1 ]
z = 3 * Vector{Float64}(1:2)
x = Vector{Float64}(1:n)
u = 2 * Vector{Float64}(1:m)
@test constraint(o, :eq1 )(x   ) == x[1] 
@test constraint(o, :eq2 )(x   ) == x
@test constraint(o, :eq3 )(x, z) == x[1:2] - [ z[1], 1 ]
@test constraint(o, :eq4 )(x   ) == x[1:2:4]
@test constraint(o, :eq5 )(x, z) == x[2]^2
@test constraint(o, :eq6 )(u   ) == u
@test constraint(o, :eq7 )(u   ) == u[1:2]
@test constraint(o, :eq8 )(u   ) == u[1:2:4]
@test constraint(o, :eq9 )(u, z) == u[2]^2
@test constraint(o, :eq10)(x, u, z) == u[1] * x[1:2] + z + f()
@test constraint(o, :eq11)(x, u, z) == u[1] * x[1:2].^3 + z

o = @def1 begin
    s ∈ [ 0, 1 ], time
    y ∈ R^4, state
    w ∈ R, control
    r = y₃
    v = y₄
    r(0) + v(1) → min
end 
y0 = [ 1, 2, 3, 4 ]
yf = 2 * [ 1, 2, 3, 4 ]
@test ismin(o)
@test o.mayer(y0, yf) == y0[3] + yf[4]


o = @def1 begin
    s ∈ [ 0, 1 ], time
    y ∈ R^4, state
    w ∈ R, control
    r = y₃
    v = y₄
    r(0) + v(1) → max
end 
y0 = [ 1, 2, 3, 4 ]
yf = 2 * [ 1, 2, 3, 4 ]
@test ismax(o)
@test o.mayer(y0, yf) == y0[3] + yf[4]

o = @def1 begin
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
@test ismin(o)
@test o.mayer(y0, yf, z) == y0[3] + yf[4] + z[2]

o = @def1 begin
    z ∈ R², variable
    s ∈ [ 0, z₁ ], time
    y ∈ R⁴, state
    w ∈ R, control
    r = y₃
    v = y₄
    aa = y₁ + w² + v³ + z₂ 
    y'(s) == [ aa(s), r²(s), 0, 0 ]
    r(0) + v(z₁) + z₂ → min
end 
z = [ 5, 6 ]
y = [ 1, 2, 3, 4 ]
y0 = y
yf = 3y0
w = 7
@test o.dynamics(y, w, z) == [ y[1] + w^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]
@test o.mayer(y0, yf, z) == y0[3] + yf[4] + z[2]

o = @def1 begin
    z ∈ R², variable
    s ∈ [ 0, z₁ ], time
    y ∈ R⁴, state
    w ∈ R, control
    r = y₃
    v = y₄
    aa = y₁(s) + v³ + z₂ 
    y'(s) == [ aa(s) + (w^2)(s), r²(s), 0, 0 ]
    r(0) + v(z₁) + z₂ → min
end 
z = [ 5, 6 ]
y = [ 1, 2, 3, 4 ]
y0 = y
yf = 3y0
w = 7
@test o.dynamics(y, w, z) == [ y[1] + w^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]
@test o.mayer(y0, yf, z) == y0[3] + yf[4] + z[2]

o = @def1 begin
    z ∈ R², variable
    s ∈ [ 0, z₁ ], time
    y ∈ R⁴, state
    w ∈ R, control
    r = y₃
    v = y₄
    aa = y₁(s) + v³ + z₂ 
    y'(s) == [ aa(s) + w^2, r²(s), 0, 0 ]
end 
z = [ 5, 6 ]
y = [ 1, 2, 3, 4 ]
y0 = y
yf = 3y0
ww = 9
@test o.dynamics(y, ww, z) ≠ [ y[1] + ww^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]

o = @def1 begin
    z ∈ R², variable
    s ∈ [ 0, z₁ ], time
    y ∈ R⁴, state
    w, control
    r = y₃
    v = y₄
    aa = y₁ + v³ + z₂ 
    aa(0) + y₂(z₁) → min
end 
z = [ 5, 6 ]
y0 = y
yf = 3y0
@test o.mayer(y0, yf, z) == y0[1] + y0[4]^3 + z[2] + yf[2]

o = @def1 begin
    z ∈ R², variable
    __t ∈ [ 0, z₁ ], time
    y ∈ R⁴, state
    w, control
    r = y₃
    v = y₄
    aa = y₁(__t) + v³ + z₂ 
    y'(__t) == [ aa(__t) + (w^2)(__t), r²(__t), 0, 0 ]
    aa(0) + y₂(z₁) → min
end 
z = [ 5, 6 ]
y = [ 1, 2, 3, 4 ]
y0 = y
yf = 3y0
w = 11
@test o.dynamics(y, w, z) == [ y[1] + w^2 + y[4]^3 + z[2], y[3]^2, 0, 0 ]
@test_throws MethodError o.mayer(y0, yf, z)

o = @def1 begin
    z ∈ R², variable
    __t ∈ [ 0, z₁ ], time
    y ∈ R⁴, state
    w, control
    r = y₃
    v = y₄
    aa = y₁(0) + v³ + z₂ 
    y'(__t) == [ aa(__t) + (w^2)(__t), r²(__t), 0, 0 ]
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
