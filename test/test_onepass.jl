# test onepass
# todo: test variable

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
@test constraint(o, :eq1 )(x) == x[1]
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
@test constraint(o, :eq1 )(x) == x[1]
@test constraint(o, Symbol("♡"))(x) == x[2]
@test o.dynamics(x, u, z) == [ x[2], (x[1] + 2x[2])^2 + z[1] ]
@test o.lagrange(x, u, z) == u^2 + z[2] * x[1] 
 
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
@test constraint(o, :eq1 )(x0, xf) == x0[1]^2 + xf[2]
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
@test constraint(o, :eq1 )(x0, xf, z) == x0[1] - z
@test constraint(o, Symbol("♡"))(x0) == x0[2]
@test o.dynamics(x, u, z) == [ x[2], x[1]^2 + z ]
@test o.lagrange(x, u, z) == u^2 + z * x[1] 
 
end 
