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

Replace calls in e of the form `(...x...)(t)` by `(...y...)(t)`.

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
	    :( $eee($tt) ) => (tt == t && has(eee, x)) ? subs(eee, x, y) : ee
	    _ => ee
        end
    end
    expr_it(e, foo(x, t, y), x -> x)
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

Return true if e contains an `(...x...)(t)` call.

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
            :( $eee($tt) ) => (tt == t && has(eee, x)) ? :yes : ee
            _ => ee end
        end
    end
    expr_it(e, foo(x, t), x -> x) == :yes
end

"""
$(TYPEDSIGNATURES)

Return the type constraint among
`:initial`, `:final`, `:boundary`, `:control_range`, `:control_fun`,
`:state_range`, `:state_fun`, `:mixed` (`:other` otherwise),
together with the appropriate value (range, updated expression...)

# Example
```jldoctest
julia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u; v = :v

julia> constraint_type(:( y'(t) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( x'(s) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( x(0)' ), t, t0, tf, x, u, v)
(:boundary, :(var"x#0"'))

julia> constraint_type(:( x(t)' ), t, t0, tf, x, u, v)
(:state_fun, :(x'))

julia> constraint_type(:( x(0) ), t, t0, tf, x, u, v)
(:initial, nothing)

julia> constraint_type(:( x[1:2:5](0) ), t, t0, tf, x, u, v)
(:initial, 1:2:5)

julia> constraint_type(:( x[1:2](0) ), t, t0, tf, x, u, v)
(:initial, 1:2)

julia> constraint_type(:( x[1](0) ), t, t0, tf, x, u, v)
(:initial, Index(1))

julia> constraint_type(:( 2x[1](0)^2 ), t, t0, tf, x, u, v)
(:boundary, :(2 * var"x#0"[1] ^ 2))

julia> constraint_type(:( x(tf) ), t, t0, tf, x, u, v)
(:final, nothing)
j
julia> constraint_type(:( x[1:2:5](tf) ), t, t0, tf, x, u, v)
(:final, 1:2:5)

julia> constraint_type(:( x[1:2](tf) ), t, t0, tf, x, u, v)
(:final, 1:2)

julia> constraint_type(:( x[1](tf) ), t, t0, tf, x, u, v)
(:final, Index(1))

julia> constraint_type(:( 2x[1](tf)^2 ), t, t0, tf, x, u, v)
(:boundary, :(2 * var"x#f"[1] ^ 2))

julia> constraint_type(:( x[1](tf) - x[2](0) ), t, t0, tf, x, u, v)
(:boundary, :(var"x#f"[1] - var"x#0"[2]))

julia> constraint_type(:( u[1:2:5](t) ), t, t0, tf, x, u, v)
(:control_range, 1:2:5)

julia> constraint_type(:( u[1:2](t) ), t, t0, tf, x, u, v)
(:control_range, 1:2)

julia> constraint_type(:( u[1](t) ), t, t0, tf, x, u, v)
(:control_range, Index(1))

julia> constraint_type(:( u(t) ), t, t0, tf, x, u, v)
(:control_range, nothing)

julia> constraint_type(:( 2u[1](t)^2 ), t, t0, tf, x, u, v)
(:control_fun, :(2 * u[1] ^ 2))

julia> constraint_type(:( x[1:2:5](t) ), t, t0, tf, x, u, v)
(:state_range, 1:2:5)

julia> constraint_type(:( x[1:2](t) ), t, t0, tf, x, u, v)
(:state_range, 1:2)

julia> constraint_type(:( x[1](t) ), t, t0, tf, x, u, v)
(:state_range, Index(1))

julia> constraint_type(:( x(t) ), t, t0, tf, x, u, v)
(:state_range, nothing)

julia> constraint_type(:( 2x[1](t)^2 ), t, t0, tf, x, u, v)
(:state_fun, :(2 * x[1] ^ 2))

julia> constraint_type(:( 2u[1](t)^2 * x(t) ), t, t0, tf, x, u, v)
(:mixed, :((2 * u[1] ^ 2) * x))

julia> constraint_type(:( 2u[1](0)^2 * x(t) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( 2u[1](0)^2 * x(t) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( 2u[1](t)^2 * x(t) + v ), t, t0, tf, x, u, v)
(:mixed, :((2 * u[1] ^ 2) * x + v))

julia> constraint_type(:( v[1:2:10] ), t, t0, tf, x, u, v)
(:variable_range, 1:2:9)

julia> constraint_type(:( v[1:10] ), t, t0, tf, x, u, v)
(:variable_range, 1:10)

julia> constraint_type(:( v[2] ), t, t0, tf, x, u, v)
(:variable_range, Index(2))

julia> constraint_type(:( v ), t, t0, tf, x, u, v)
(:variable_range, nothing)

julia> constraint_type(:( v^2  + 1 ), t, t0, tf, x, u, v)(:variable_fun, :(v ^ 2 + 1))

julia> constraint_type(:( v[2]^2 + 1 ), t, t0, tf, x, u, v)
(:variable_fun, :(v[2] ^ 2 + 1))
```
"""
constraint_type(e, t, t0, tf, x, u, v) =
    @match [ has(e, x, t0), has(e, x, tf), has(e, u, t), has(e, x, t), has(e, u, t0), has(e, u, tf), has(e, v) ] begin
        [ true , false, false, false, false, false, _ ] => @match e begin
            :( $y[$i:$p:$j]($s) ) => (y == x && s == t0) ? (:initial, i:p:j   ) : 
	                             (:boundary, replace_call(e, x, t0, Symbol(x, "#0")))
            :( $y[$i:$j   ]($s) ) => (y == x && s == t0) ? (:initial, i:j     ) :
	                             (:boundary, replace_call(e, x, t0, Symbol(x, "#0")))
            :( $y[$i      ]($s) ) => (y == x && s == t0) ? (:initial, Index(i)) :
	                             (:boundary, replace_call(e, x, t0, Symbol(x, "#0")))
            :( $y($s)           ) => (y == x && s == t0) ? (:initial, nothing ) : 
	                             (:boundary, replace_call(e, x, t0, Symbol(x, "#0")))
	    _                     => (:boundary, replace_call(e, x, t0, Symbol(x, "#0"))) end
        [ false, true , false, false, false, false, _ ] => @match e begin 
            :( $y[$i:$p:$j]($s) ) => (y == x && s == tf) ? (:final, i:p:j   ) :
	                             (:boundary, replace_call(e, x, tf, Symbol(x, "#f")))
            :( $y[$i:$j   ]($s) ) => (y == x && s == tf) ? (:final, i:j     ) :
	                             (:boundary, replace_call(e, x, tf, Symbol(x, "#f")))
            :( $y[$i      ]($s) ) => (y == x && s == tf) ? (:final, Index(i)) :
	                             (:boundary, replace_call(e, x, tf, Symbol(x, "#f")))
            :( $y($s) )           => (y == x && s == tf) ? (:final, nothing ) :
	                             (:boundary, replace_call(e, x, tf, Symbol(x, "#f")))
	    _                     => (:boundary, replace_call(e, x, tf, Symbol(x, "#f"))) end
        [ true , true , false, false, false, false, _ ] => begin
            e = replace_call(e, x, t0, Symbol(x, "#0"))
            e = replace_call(e, x, tf, Symbol(x, "#f"))
            (:boundary, e) end
        [ false, false, true , false, false, false, _ ] => @match e begin
            :( $c[$i:$p:$j]($s) ) => (c == u && s == t ) ? (:control_range, i:p:j   ) :
	                             (:control_fun, replace_call(e, u, t, u))
            :( $c[$i:$j   ]($s) ) => (c == u && s == t ) ? (:control_range, i:j     ) :
	                             (:control_fun, replace_call(e, u, t, u))
            :( $c[$i      ]($s) ) => (c == u && s == t ) ? (:control_range, Index(i)) :
	                             (:control_fun, replace_call(e, u, t, u))
            :( $c($s)           ) => (c == u && s == t ) ? (:control_range, nothing ) :
	                             (:control_fun, replace_call(e, u, t, u))
	    _                     => (:control_fun, replace_call(e, u, t, u)) end
        [ false, false, false, true , false, false, _ ] => @match e begin
            :( $y[$i:$p:$j]($s) ) => (y == x && s == t ) ? (:state_range, i:p:j   ) :
	                             (:state_fun, replace_call(e, x, t, x))
            :( $y[$i:$j   ]($s) ) => (y == x && s == t ) ? (:state_range, i:j     ) :
	                             (:state_fun, replace_call(e, x, t, x))
            :( $y[$i      ]($s) ) => (y == x && s == t ) ? (:state_range, Index(i)) :
	                             (:state_fun, replace_call(e, x, t, x))
            :( $y($s)           ) => (y == x && s == t ) ? (:state_range, nothing ) :
	                             (:state_fun, replace_call(e, x, t, x))
	    _                     => (:state_fun, replace_call(e, x, t, x)) end
        [ false, false, true , true , false, false, _ ] => begin
            e = replace_call(e, u, t, u)
            e = replace_call(e, x, t, x)
            (:mixed, e) end
        [ false, false, false, false, false, false, true ] => @match e begin
            :( $w[$i:$p:$j]     ) => (w == v) ? (:variable_range, i:p:j   ) : (:variable_fun, e)
            :( $w[$i:$j   ]     ) => (w == v) ? (:variable_range, i:j     ) : (:variable_fun, e)
            :( $w[$i      ]     ) => (w == v) ? (:variable_range, Index(i)) : (:variable_fun, e)
            _                     => (e == v) ? (:variable_range, nothing ) : (:variable_fun, e) end
        _ => :other
    end
