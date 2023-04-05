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

t = :t; t0 = 0; tf = :tf; x = :x; u = :u
@test constraint_type(:( x[1:2](0)          ), t, t0, tf, x, u) == (:initial, 1:2)
@test constraint_type(:( x[1](0)            ), t, t0, tf, x, u) == (:initial, Index(1))
@test constraint_type(:( 2x[1](0)^2         ), t, t0, tf, x, u) == (:boundary, :(2 * var"x#0"[1] ^ 2))
@test constraint_type(:( x[1:2](tf)         ), t, t0, tf, x, u) == (:final, 1:2)
@test constraint_type(:( x[1](tf)           ), t, t0, tf, x, u) == (:final, Index(1))
@test constraint_type(:( x[1](tf) - x[2](0) ), t, t0, tf, x, u) == (:boundary, :(var"x#f"[1] - var"x#0"[2]))
@test constraint_type(:( 2x[1](tf)^2        ), t, t0, tf, x, u) == (:boundary, :(2 * var"x#f"[1] ^ 2))
@test constraint_type(:( u[1:2](t)          ), t, t0, tf, x, u) == (:control_range, 1:2)
@test constraint_type(:( u[1](t)            ), t, t0, tf, x, u) == (:control_range, Index(1))
@test constraint_type(:( 2u[1](t)^2         ), t, t0, tf, x, u) == (:control_fun, :(2 * u[1] ^ 2))
@test constraint_type(:( x[1:2](t)          ), t, t0, tf, x, u) == (:state_range, 1:2)
@test constraint_type(:( x[1](t)            ), t, t0, tf, x, u) == (:state_range, Index(1))
@test constraint_type(:( 2x[1](t)^2         ), t, t0, tf, x, u) == (:state_fun, :(2 * x[1] ^ 2))
@test constraint_type(:( 2u[1](t)^2 * x(t)  ), t, t0, tf, x, u) == (:mixed, :((2 * u[1] ^ 2) * x))
@test constraint_type(:( 2u[1](0)^2 * x(t)  ), t, t0, tf, x, u) ==  :other

@test (@__def t ∈ [ t0, tf ], time).initial_time == nothing

end
