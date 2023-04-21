# ctparser_utils

"""
$(TYPEDSIGNATURES)

Expr iterator: apply `_Expr` to nodes and `f` to leaves of the AST.

# Example
```jldoctest
julia> id(e) = expr_it(e, Expr, x -> x)
```
"""
expr_it(e, _Expr, f) =
    if e isa Expr
    args = e.args
    n = length(args)
    newargs = [ expr_it(e.args[i], _Expr, f) for i ∈ 1:n ]
        return _Expr(e.head, newargs...)
    else
        return f(e)
    end

"""
$(TYPEDSIGNATURES)

Substitute expression `e1` by expression `e2` in expression `e`.

# Examples
```jldoctest
julia> e = :( ∫( r(t)^2 + 2u₁(t)) → min )
:(∫(r(t) ^ 2 + 2 * u₁(t)) → min)

julia> subs(e, :r, :( x[1] ))
:(∫((x[1])(t) ^ 2 + 2 * u₁(t)) → min)

julia> e = :( ∫( u₁(t)^2 + 2u₂(t)) → min )
:(∫(u₁(t) ^ 2 + 2 * u₂(t)) → min)

julia> for i ∈ 1:2
       e = subs(e, Symbol(:u, Char(8320+i)), :( u[\$i] ))
       end; e
:(∫((u[1])(t) ^ 2 + 2 * (u[2])(t)) → min)

julia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;

julia> e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )
:((x[1])(0) * (2 * x(tf)) - (x[2])(tf) * (2 * x(0)))

julia> x0 = Symbol(x, 0); subs(e, :( \$x[1](\$(t0)) ), :( \$x0[1] ))
:(x0[1] * (2 * x(tf)) - (x[2])(tf) * (2 * x(0)))
```
"""
subs(e, e1 :: Union{Symbol, Real}, e2) = expr_it(e, Expr, x -> x == e1 ? e2 : x) # optimised for some litterals (including symbols)

subs(e, e1, e2) = begin
    foo(e1, e2) = (h, args...) -> begin
        f = Expr(h, args...)
        f == e1 ? e2 : f
    end
    expr_it(e, foo(e1, e2), f -> f == e1 ? e2 : f)
end

"""
$(TYPEDSIGNATURES)

Replace calls in e such as `x(t)`, `x[i](t)` or `x[i:j](t)` by `y`, `y[i](t)` or `y[i:j](t)`, resp.

# Example
```jldoctest

julia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;

julia> e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )
:((x[1])(0) * (2 * x(tf)) - (x[2])(tf) * (2 * x(0)))

julia> x0 = Symbol(x, 0); e = replace_call(e, x, t0, x0)
:(x0[1] * (2 * x(tf)) - (x[2])(tf) * (2x0))

julia> xf = Symbol(x, "f"); replace_call(ans, x, tf, xf)
:(x0[1] * (2xf) - xf[2] * (2x0))

julia> e = :( A*x(t) + B*u(t) ); replace_call(replace_call(e, x, t, x), u, t, u)
:(A * x + B * u)

julia> e = :( F0(x(t)) + u(t)*F1(x(t)) ); replace_call(replace_call(e, x, t, x), u, t, u)
:(F0(x) + u * F1(x))

julia> e = :( 0.5u(t)^2  ); replace_call(e, u, t, u)
:(0.5 * u ^ 2)
```
"""
replace_call(e, x, t, y) = begin
    foo(x, t, y) = (h, args...) -> begin
        ee = Expr(h, args...)
	@match ee begin
	    :( $xx[     ]($tt) ) => (xx == x && tt == t) ? :( $y[  ]    ) : ee
	    :( $xx[$i   ]($tt) ) => (xx == x && tt == t) ? :( $y[$i]    ) : ee
	    :( $xx[$i:$j]($tt) ) => (xx == x && tt == t) ? :( $y[$i:$j] ) : ee
            :( $xx[$i:$p:$j]($tt) ) => (xx == x && tt == t) ? :( $y[$i:$p:$j] ) : ee
	    :( $xx($tt)        ) => (xx == x && tt == t) ? :( $y        ) : ee
	    _ => ee
        end
    end
    expr_it(e, foo(x, t, y), x -> x)
end

"""
$(TYPEDSIGNATURES)

Replace ANY call in e such as `x(t)`, `x[i](t)` or `x[i:j](t)` by `x`, `x[i](t)` or `x[i:j](t)`, resp.

# Example
```jldoctest

julia> e = :( F0(x(t)) + u(t)*F1(x(t)) ); replace_call(e, :t)
:(F0(x) + u * F1(x))
```
"""
replace_call(e, t) = begin
    foo(t) = (h, args...) -> begin
        ee = Expr(h, args...)
    @match ee begin
        :( $x[     ]($tt)    ) => (tt == t) ? :( $x[  ]    ) : ee
        :( $x[$i   ]($tt)    ) => (tt == t) ? :( $x[$i]    ) : ee
        :( $x[$i:$j]($tt)    ) => (tt == t) ? :( $x[$i:$j] ) : ee
        :( $x[$i:$p:$j]($tt) ) => (tt == t) ? :( $x[$i:$p:$j] ) : ee
        :( $x($tt)           ) => (tt == t) ? :( $x        ) : ee
        _ => ee
        end
    end
    expr_it(e, foo(t), x -> x)
end

"""
$(TYPEDSIGNATURES)

Return true if e contains e1.

# Example
```jldoctest
julia> e = :( ∫( x[1](t)^2 + 2*u(t) ) → min )
:(∫((x[1])(t) ^ 2 + 2 * u(t)) → min)

julia> has(e, 2)
true

julia> has(e, :x)
true

julia> has(e, :min)
true

julia> has(e, :( x[1](t)^2 ))
true

julia> !has(e, :( x[1](t)^3 ))
true

julia> !has(e, 3)
true

julia> !has(e, :max)
true

julia> has(:x, :x)
true

julia> !has(:x, 2)
true

julia> !has(:x, :y)
true
```
"""
has(e, e1) = begin
    foo(e1) = (h, args...) -> begin
        ee = Expr(h, args...)
    if :yes ∈ args
        :yes
    else
        ee == e1 ? :yes : ee
        end
    end
    expr_it(e, foo(e1), x -> x == e1 ? :yes : x) == :yes
end

"""
$(TYPEDSIGNATURES)

Return true if e contains an `x(t)`, `x[i](t)`, `x[i:j](t)` or  `x[i:p:j](t)` call.

# Example
```jldoctest
julia> e = :( ∫( x[1](t)^2 + 2*u(t) ) → min )
:(∫((x[1])(t) ^ 2 + 2 * u(t)) → min)

julia> has(e, :x, :t)
true

julia> has(e, :u, :t)
true
```
"""
has(e, x, t) = begin
    foo(x, t) = (h, args...) -> begin
        ee = Expr(h, args...)
	if :yes ∈ args
	    :yes
	else @match ee begin
            :( $xx[        ]($tt) ) => (xx == x && tt == t) ? :yes : ee
            :( $xx[$i      ]($tt) ) => (xx == x && tt == t) ? :yes : ee
            :( $xx[$i:$j   ]($tt) ) => (xx == x && tt == t) ? :yes : ee
            :( $xx[$i:$p:$j]($tt) ) => (xx == x && tt == t) ? :yes : ee
            :( $xx($tt)           ) => (xx == x && tt == t) ? :yes : ee
            _ => ee end
        end
    end
    expr_it(e, foo(x, t), x -> x) == :yes
end

"""
$(TYPEDSIGNATURES)

Return the type constraint among
`:dynamics`, `:initial`, `:final`, `:boundary`, `:control_range`, `:control_fun`,
`:state_range`, `:state_fun`, `:mixed` (`:other` otherwise),
together with the appropriate value (range, updated expression...)

# Example
```jldoctest
julia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;

julia> constraint_type(:( x'(t) ), t, t0, tf, x, u)
(:dynamics, nothing)

julia> constraint_type(:( y'(t) ), t, t0, tf, x, u)
(:other, nothing)

julia> constraint_type(:( x'(s) ), t, t0, tf, x, u)
(:other, nothing)

julia> constraint_type(:( x(0)' ), t, t0, tf, x, u)
(:boundary, :(var"x#0"'))

julia> constraint_type(:( x(t)' ), t, t0, tf, x, u)
(:state_fun, :(x'))

julia> constraint_type(:( x(0) ), t, t0, tf, x, u)
(:initial, nothing)

julia> constraint_type(:( x[1:2:5](0) ), t, t0, tf, x, u)
(:initial, 1:2:5)

julia> constraint_type(:( x[1:2](0) ), t, t0, tf, x, u)
(:initial, 1:2)

julia> constraint_type(:( x[1](0) ), t, t0, tf, x, u)
(:initial, Index(1))

julia> constraint_type(:( 2x[1](0)^2 ), t, t0, tf, x, u)
(:boundary, :(2 * var"x#0"[1] ^ 2))

julia> constraint_type(:( x(tf) ), t, t0, tf, x, u)
(:final, nothing)
j
julia> constraint_type(:( x[1:2:5](tf) ), t, t0, tf, x, u)
(:final, 1:2:5)

julia> constraint_type(:( x[1:2](tf) ), t, t0, tf, x, u)
(:final, 1:2)

julia> constraint_type(:( x[1](tf) ), t, t0, tf, x, u)
(:final, Index(1))

julia> constraint_type(:( 2x[1](tf)^2 ), t, t0, tf, x, u)
(:boundary, :(2 * var"x#f"[1] ^ 2))

julia> constraint_type(:( x[1](tf) - x[2](0) ), t, t0, tf, x, u)
(:boundary, :(var"x#f"[1] - var"x#0"[2]))

julia> constraint_type(:( u[1:2:5](t) ), t, t0, tf, x, u)
(:control_range, 1:2:5)

julia> constraint_type(:( u[1:2](t) ), t, t0, tf, x, u)
(:control_range, 1:2)

julia> constraint_type(:( u[1](t) ), t, t0, tf, x, u)
(:control_range, Index(1))

julia> constraint_type(:( u(t) ), t, t0, tf, x, u)
(:control_range, nothing)

julia> constraint_type(:( 2u[1](t)^2 ), t, t0, tf, x, u)
(:control_fun, :(2 * u[1] ^ 2))

julia> constraint_type(:( x[1:2:5](t) ), t, t0, tf, x, u)
(:state_range, 1:2:5)

julia> constraint_type(:( x[1:2](t) ), t, t0, tf, x, u)
(:state_range, 1:2)

julia> constraint_type(:( x[1](t) ), t, t0, tf, x, u)
(:state_range, Index(1))

julia> constraint_type(:( x(t) ), t, t0, tf, x, u)
(:state_range, nothing)

julia> constraint_type(:( 2x[1](t)^2 ), t, t0, tf, x, u)
(:state_fun, :(2 * x[1] ^ 2))

julia> constraint_type(:( 2u[1](t)^2 * x(t) ), t, t0, tf, x, u)
(:mixed, :((2 * u[1] ^ 2) * x))

julia> constraint_type(:( 2u[1](0)^2 * x(t) ), t, t0, tf, x, u)
(:other, nothing)
```
"""
constraint_type(e, t, t0, tf, x, u) =
    if @match e begin :( $y'($s) ) => y == x && s == t; _ => false end
        (:dynamics, nothing)
    else @match [ has(e, x, t0), has(e, x, tf), has(e, u, t), has(e, x, t), has(e, u, t0), has(e, u, tf) ] begin
        [ true , false, false, false, false, false ] => @match e begin
            :( $y[$i:$p:$j]($s) ) => (y == x && s == t0) ? (:initial, i:p:j   ) : :other
            :( $y[$i:$j   ]($s) ) => (y == x && s == t0) ? (:initial, i:j     ) : :other
            :( $y[$i      ]($s) ) => (y == x && s == t0) ? (:initial, Index(i)) : :other
	    _                  => (:boundary, replace_call(e, x, t0, Symbol(x, "#0"))) end
        [ false, true , false, false, false, false ] => @match e begin 
            :( $y[$i:$p:$j]($s) ) => (y == x && s == tf) ? (:final, i:p:j   ) : :other
            :( $y[$i:$j   ]($s) ) => (y == x && s == tf) ? (:final, i:j     ) : :other
            :( $y[$i      ]($s) ) => (y == x && s == tf) ? (:final, Index(i)) : :other
	    _                  => (:boundary, replace_call(e, x, tf, Symbol(x, "#f"))) end
        [ true , true , false, false, false, false ] => begin
            ee = replace_call(e , x, t0, Symbol(x, "#0"))
            ee = replace_call(ee, x, tf, Symbol(x, "#f"))
            (:boundary, ee) end
        [ false, false, true , false, false, false ] => @match e begin
            :( $v[$i:$p:$j]($s) ) => (v == u && s == t ) ? (:control_range, i:p:j   ) : :other
            :( $v[$i:$j   ]($s) ) => (v == u && s == t ) ? (:control_range, i:j     ) : :other
            :( $v[$i      ]($s) ) => (v == u && s == t ) ? (:control_range, Index(i)) : :other
	    _                  => (:control_fun, replace_call(e, u, t, u)) end                
        [ false, false, false, true , false, false ] => @match e begin
            :( $y[$i:$p:$j]($s) ) => (y == x && s == t ) ? (:state_range, i:p:j   ) : :other
            :( $y[$i:$j   ]($s) ) => (y == x && s == t ) ? (:state_range, i:j     ) : :other
            :( $y[$i      ]($s) ) => (y == x && s == t ) ? (:state_range, Index(i)) : :other
	    _                  => (:state_fun  , replace_call(e, x, t, x)) end                
        [ false, false, true , true , false, false ] => begin
            ee = replace_call(e , u, t, u)
            ee = replace_call(ee, x, t, x);
            (:mixed, ee) end
        _  => (:other, nothing) end
    end

# type of input lines
@enum _ctparser_line_type e_time e_state_scalar e_state_vector e_control_scalar e_control_vector e_constraint e_named_constraint e_alias e_objective_min e_objective_max e_variable

"""
$(TYPEDSIGNATURES)

Figure the type of parsed line passed as argument

Returns a tuple (_type, Array{Any} )

Example:
"""
input_line_type(e) =
    @match e begin
        :($t ∈ [ $a, $b ], time)   => (e_time, [t, a, b])
        :($s ∈ R^$d, state )       => (e_state_vector, [s, d])
        :($s ∈ R², state )         => (e_state_vector, [s, 2])
        :($s ∈ R³, state )         => (e_state_vector, [s, 3])
        :($s ∈ R⁴, state )         => (e_state_vector, [s, 4])
        :($s ∈ R⁵, state )         => (e_state_vector, [s, 5])
        :($s ∈ R⁶, state )         => (e_state_vector, [s, 6])
        :($s ∈ R⁷, state )         => (e_state_vector, [s, 7])
        :($s ∈ R⁸, state )         => (e_state_vector, [s, 8])
        :($s ∈ R⁹, state )         => (e_state_vector, [s, 9])
        :($s[$d], state )          => (e_state_vector, [s, d])
        :($s ∈ R, state )          => (e_state_scalar, [s])
        :($s, state )              => (e_state_scalar, [s])
        :($s ∈ R^$d, control )     => (e_control_vector, [s, d])
        :($s ∈ R², control )       => (e_control_vector, [s, 2])
        :($s ∈ R³, control )       => (e_control_vector, [s, 3])
        :($s ∈ R⁴, control )       => (e_control_vector, [s, 4])
        :($s ∈ R⁵, control )       => (e_control_vector, [s, 5])
        :($s ∈ R⁶, control )       => (e_control_vector, [s, 6])
        :($s ∈ R⁷, control )       => (e_control_vector, [s, 7])
        :($s ∈ R⁸, control )       => (e_control_vector, [s, 8])
        :($s ∈ R⁹, control )       => (e_control_vector, [s, 9])
        :($s[$d], control )        => (e_control_vector, [s, d])
        :($s ∈ R, control )        => (e_control_scalar, [s])
        :($s, control )            => (e_control_scalar, [s])
        :($t ∈ R, variable )       => (e_variable, [t])
        :($t, variable )           => (e_variable, [t])
        :($a = $b)                 => (e_alias, [a, b])
        :($a -> begin min end)     => (e_objective_min, [a]) # debug: not allowed, remove
        :($a → min)                => (e_objective_min, [a])
        :($a -> begin max end)     => (e_objective_max, [a]) # debug: not allowed, remove
        :($a → max)                => (e_objective_max, [a])
        :($x == $y => ($n))        => (e_named_constraint, [n, :(==), x, y])
        :($x <= $y <= $z => ($n))  => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x ≤  $y ≤  $z => ($n))  => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x == $y , ($n))         => (e_named_constraint, [n, :(==), x, y])
        :($x <= $y <= $z, ($n))    => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x ≤  $y ≤  $z, ($n))    => (e_named_constraint, [n, :(≤),  y, x, z])
        :($x == $y)                => (e_constraint,       [:(==),    x, y])
        :($x <= $y <= $z)          => (e_constraint,       [:(≤),     y, x, z])
        :($x ≤  $y ≤  $z)          => (e_constraint,       [:(≤),     y, x, z])
        _                          => (:other , [])
    end
