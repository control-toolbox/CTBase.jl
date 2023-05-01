# test utils
function test_ctparser_utils()

e = :( ∫( r(t)^2 + 2u₁(t)) → min )
@test subs(e, :r, :( x[1] )) == :(∫((x[1])(t) ^ 2 + 2 * u₁(t)) → min)

e = :( ∫( u₁(t)^2 + 2u₂(t)) → min )
for i ∈ 1:2
     e = subs(e, Symbol(:u, Char(8320+i)), :( u[$i] ))
end
@test e == :(∫((u[1])(t) ^ 2 + 2 * (u[2])(t)) → min)

t = :t; t0 = 0; tf = :tf; x = :x; u = :u;
e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )
x0 = Symbol(x, 0)
@test subs(e, :( $x[1]($(t0)) ), :( $x0[1] )) == :(x0[1] * (2 * x(tf)) - (x[2])(tf) * (2 * x(0)))

e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )
x0 = Symbol(x, "#0")
xf = Symbol(x, "#f")
e = replace_call(e, x, t0, x0)
@test replace_call(e, x, tf, xf) == :(var"x#0"[1] * (2var"x#f") - var"x#f"[2] * (2var"x#0"))

e = :( A*x(t) + B*u(t) )
@test replace_call(replace_call(e, x, t, x), u, t, u) == :(A * x + B * u)

e = :( F0(x(t)) + u(t)*F1(x(t)) )
@test replace_call(replace_call(e, x, t, x), u, t, u) == :(F0(x) + u * F1(x))

e = :( 0.5u(t)^2  )
@test replace_call(e, u, t, u) == :(0.5 * u ^ 2)

e = :( ∫( x[1](t)^2 + 2*u(t) ) → min )
@test has(e, :x, :t)
@test has(e, :u, :t)
@test !has(e, :v, :t)
@test has(e, 2)
@test has(e, :x)
@test has(e, :min)
@test has(e, :( x[1](t)^2 ))
@test !has(e, :( x[1](t)^3 ))
@test !has(e, 3)
@test !has(e, :max)
@test has(:x, :x)
@test !has(:x, 2)
@test !has(:x, :y)

t = :t; t0 = 0; tf = :tf; x = :x; u = :u; v = :v
@test constraint_type(:( y'(t)                 ), t, t0, tf, x, u, v) ==  :other
@test constraint_type(:( x'(s)                 ), t, t0, tf, x, u, v) ==  :other
@test constraint_type(:( x(0)'                 ), t, t0, tf, x, u, v) == (:boundary, :(var"x#0"'))
@test constraint_type(:( x'(0)                 ), t, t0, tf, x, u, v) == (:boundary, :(var"x#0"'))
@test constraint_type(:( x(t)'                 ), t, t0, tf, x, u, v) == (:state_fun, :(var"x#t"'))
@test constraint_type(:( x(0)                  ), t, t0, tf, x, u, v) == (:initial, nothing)
@test constraint_type(:( x[1:2:5](0)           ), t, t0, tf, x, u, v) == (:initial, 1:2:5)
@test constraint_type(:( x[1:2](0)             ), t, t0, tf, x, u, v) == (:initial, 1:2)
@test constraint_type(:( x[1](0)               ), t, t0, tf, x, u, v) == (:initial, Index(1))
@test constraint_type(:( x[1:2](0)             ), t, t0, tf, x, u, v) == (:initial, 1:2)
@test constraint_type(:( 2x[1](0)^2            ), t, t0, tf, x, u, v) == (:boundary, :(2 * var"x#0"[1] ^ 2))
@test constraint_type(:( x(tf)                 ), t, t0, tf, x, u, v) == (:final, nothing)
@test constraint_type(:( x[1:2:5](tf)          ), t, t0, tf, x, u, v) == (:final, 1:2:5)
@test constraint_type(:( x[1:2](tf)            ), t, t0, tf, x, u, v) == (:final, 1:2)
@test constraint_type(:( x[1](tf)              ), t, t0, tf, x, u, v) == (:final, Index(1))
@test constraint_type(:( x[1:2](tf)            ), t, t0, tf, x, u, v) == (:final, 1:2)
@test constraint_type(:( x[1](tf) - x[2](0)    ), t, t0, tf, x, u, v) == (:boundary, :(var"x#f"[1] - var"x#0"[2]))
@test constraint_type(:( 2x[1](tf)^2           ), t, t0, tf, x, u, v) == (:boundary, :(2 * var"x#f"[1] ^ 2))
@test constraint_type(:( u[1:2:5](t)           ), t, t0, tf, x, u, v) == (:control_range, 1:2:5)
@test constraint_type(:( u[1:2](t)             ), t, t0, tf, x, u, v) == (:control_range, 1:2)
@test constraint_type(:( u[1](t)               ), t, t0, tf, x, u, v) == (:control_range, Index(1))
@test constraint_type(:( u(t)                  ), t, t0, tf, x, u, v) == (:control_range, nothing)
@test constraint_type(:( 2u[1](t)^2            ), t, t0, tf, x, u, v) == (:control_fun, :(2 * var"u#t"[1] ^ 2))
@test constraint_type(:( x[1:2:5](t)           ), t, t0, tf, x, u, v) == (:state_range, 1:2:5)
@test constraint_type(:( x[1:2](t)             ), t, t0, tf, x, u, v) == (:state_range, 1:2)
@test constraint_type(:( x[1](t)               ), t, t0, tf, x, u, v) == (:state_range, Index(1))
@test constraint_type(:( x(t)                  ), t, t0, tf, x, u, v) == (:state_range, nothing)
@test constraint_type(:( 2x[1](t)^2            ), t, t0, tf, x, u, v) == (:state_fun, :(2 * var"x#t"[1] ^ 2))
@test constraint_type(:( 2u[1](t)^2 * x(t)     ), t, t0, tf, x, u, v) == (:mixed, :((2 * var"u#t"[1] ^ 2) * var"x#t"))
@test constraint_type(:( 2u[1](0)^2 * x(t)     ), t, t0, tf, x, u, v) ==  :other
@test constraint_type(:( 2u[1](t)^2 * x(t) + v ), t, t0, tf, x, u, v) == (:mixed, :((2 * var"u#t"[1] ^ 2) * var"x#t" + v))
@test constraint_type(:( v[1:2:10]             ), t, t0, tf, x, u, v) == (:variable_range, 1:2:9)
@test constraint_type(:( v[1:10]               ), t, t0, tf, x, u, v) == (:variable_range, 1:10)
@test constraint_type(:( v[2]                  ), t, t0, tf, x, u, v) == (:variable_range, Index(2))
@test constraint_type(:( v                     ), t, t0, tf, x, u, v) == (:variable_range, nothing)
@test constraint_type(:( v^2 + 1               ), t, t0, tf, x, u, v) == (:variable_fun, :(v ^ 2 + 1))
@test constraint_type(:( v[2]^2 + 1            ), t, t0, tf, x, u, v) == (:variable_fun, :(v[2] ^ 2 + 1))

end
