function test_ctparser_utils()

# test utils
e = :( ∫( r(t)^2 + 2u₁(t)) → min )
@test subs(e, :r, :( x[1] )) == :(∫((x[1])(t) ^ 2 + 2 * u₁(t)) → min)

e = :( ∫( u₁(t)^2 + 2u₂(t)) → min )
f = [ e, :foo, :foo ]
for i ∈ 1:2
     f[i+1] = subs(f[i], Symbol(:u, Char(8320+i)), :( u[$i] ))
end
@test f[3] == :(∫((u[1])(t) ^ 2 + 2 * (u[2])(t)) → min)

t = :t; t0 = 0; tf = :tf; x = :x; u = :u;
e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )
x0 = Symbol(x, 0)
@test subs(e, :( $x[1]($(t0)) ), :( $x0[1] )) == :(x0[1] * (2 * x(tf)) - (x[2])(tf) * (2 * x(0)))

e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )
x0 = Symbol(x, "#0")
xf = Symbol(x, "#f")
e = replace_call(e, x, t0, x0)
@test replace_call(e, x, tf, xf) == :(var"x#0"[1] * (2var"x#f") - var"x#f"[2] * (2var"x#0"))

e = :( ∫( x[1](t)^2 + 2*u(t) ) → min )
@test has(e, :x, :t)
@test has(e, :u, :t)
@test !has(e, :v, :t)

t = :t; t0 = 0; tf = :tf; x = :x; u = :u
@test constraint_type(:( x[1:2](0)          ), t, t0, tf, x, u) == (:initial, 1:2)
@test constraint_type(:( x[1](0)            ), t, t0, tf, x, u) == (:initial, 1)
@test constraint_type(:( x[1:2](tf)         ), t, t0, tf, x, u) == (:final, 1:2)
@test constraint_type(:( x[1](tf)           ), t, t0, tf, x, u) == (:final, 1)
@test constraint_type(:( x[1](tf) - x[2](0) ), t, t0, tf, x, u) == (:boundary, :(var"x#f"[1] - var"x#0"[2]))
@test constraint_type(:( u[1:2](t)          ), t, t0, tf, x, u) == (:control_range, 1:2)
@test constraint_type(:( u[1](t)            ), t, t0, tf, x, u) == (:control_range, 1)
@test constraint_type(:( 2u[1](t)^2         ), t, t0, tf, x, u) == (:control_fun, :(2 * u[1] ^ 2))
@test constraint_type(:( x[1:2](t)          ), t, t0, tf, x, u) == (:state_range, 1:2)
@test constraint_type(:( x[1](t)            ), t, t0, tf, x, u) == (:state_range, 1)
@test constraint_type(:( 2x[1](t)^2         ), t, t0, tf, x, u) == (:state_fun, :(2 * x[1] ^ 2))
@test constraint_type(:( 2u[1](t)^2 * x(t)  ), t, t0, tf, x, u) == (:mixed, :((2 * u[1] ^ 2) * x))
@test constraint_type(:( 2u[1](0)^2 * x(t)  ), t, t0, tf, x, u) ==  :other  

end
