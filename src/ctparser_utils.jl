"""
    expr_it(e, _Expr, f)

Expr iterator: apply `_Expr` to nodes and `f` to leaves of the AST.

# Example
```jldoctest
julia> id(e) = expr_it(e, Expr, x -> x)
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
    prune_call(e, x, t)

Prune calls `x(t)` into just `x` in an expression.
    prune_call(e, t)
Prune anything like `foo(t)` into `foo` in an expression.

# Examples
```jldoctest
julia> e = :( ∫( x(t)^2 + 2u[1](t)) → min )
:(∫(x(t) ^ 2 + 2 * u(t)) → min)

julia> prune_call(e, :x, :t)
:(∫(x ^ 2 + 2 * (u[1])(t)) → min)
```
"""
prune_call(e, x, t) = begin
    foo(x, t) = (h, args...) ->
    if Expr(h, args...) == :($x($t))
        x
    else
        Expr(h, args...)
    end
    expr_it(e, foo(x, t), x -> x)
end

"""
    prune_call(e, t)
Prune anything like `foo(t)` into `foo` in an expression.

# Examples
```jldoctest
julia> e = :( ∫( x(t)^2 + 2u[1](t)) → min )
:(∫(x(t) ^ 2 + 2 * u(t)) → min)

julia> prune_call(e, :t)
:(∫(x ^ 2 + 2 * u[1]) → min)
```
"""
prune_call(e, t) = begin
    foo(t) = (h, args...) ->
    if h == :call && args[2] == t
        args[1]
    else
        Expr(h, args...)
    end
    expr_it(e, foo(t), x -> x)
end

"""
    subs(e, x, y)

Substitute x by y in expression e.

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
```
"""
subs(e, x, y) = expr_it(e, Expr, z -> z == x ? y : z)

"""
    has(e, x, t)

Return true if e contains an x(t), x[i](t) or x[i:j](t) call.

# Example
```jldoctest
julia> e = :( ∫( x[1](t)^2 + 2*u(t) ) → min )
julia> has(e, :x, :t)
true
julia> has(e, :u, :t)
true
```
"""
has(e, x, t) = begin # debug: rewrite with @match
    foo(x, t) = (h, args...) ->
    if Expr(h, args...) == :($x($t))
        :yes
    elseif h == :ref && length(args) ≥ 1 && args[1] == x
        x
    else
        isempty(findall(x -> x == :yes, args)) ? Expr(h, args...) : :yes
    end
    expr_it(e, foo(x, t), x -> x) == :yes
end

"""
    constraint_type(e, t, t0, tf, x, u) = begin

Return the type constraint among 
`:initial`, `:final`, `:boundary`, `:control_range`, `:control_fun`, `:state_range`,
`:state_fun`, `:mixed` (`:other` otherwise).

# Example
```jldoctest
julia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;

julia> constraint_type(:( x[1:2](0) ), t, t0, tf, x, u)
(:initial, 1:2)

julia> constraint_type(:( x[1](0) ), t, t0, tf, x, u)
(:initial, 1)

julia> constraint_type(:( x[1:2](tf) ), t, t0, tf, x, u)
(:final, 1:2)

julia> constraint_type(:( x[1](tf) ), t, t0, tf, x, u)
(:final, 1)

julia> constraint_type(:( x[1](tf) - x[2](0) ), t, t0, tf, x, u)
:boundary

julia> constraint_type(:( u[1:2](t) ), t, t0, tf, x, u)
(:control_range, 1:2)

julia> constraint_type(:( u[1](t) ), t, t0, tf, x, u)
(:control_range, 1)

julia> constraint_type(:( 2u[1](t)^2 ), t, t0, tf, x, u)
:control_fun

julia> constraint_type(:( x[1:2](t) ), t, t0, tf, x, u)
(:state_range, 1:2)

julia> constraint_type(:( x[1](t) ), t, t0, tf, x, u)
(:state_range, 1)

julia> constraint_type(:( 2x[1](t)^2 ), t, t0, tf, x, u)
:state_fun

julia> constraint_type(:( 2u[1](t)^2 * x(t) ), t, t0, tf, x, u)
:mixed

julia> constraint_type(:( 2u[1](0)^2 * x(t) ), t, t0, tf, x, u)
:other
```
"""
constraint_type(e, t, t0, tf, x, u) =
    @match [ has(e, x, t0), has(e, x, tf), has(e, u, t), has(e, x, t), has(e, u, t0), has(e, u, tf) ] begin
        [ true , false, false, false, false, false ] => @match e begin
            :( $y[$i:$j]($s) ) => (y == x && s == t0) ? (:initial, i:j     ) : :other
            :( $y[$i   ]($s) ) => (y == x && s == t0) ? (:initial, Index(i)) : :other
	    _                  => :other end                
        [ false, true , false, false, false, false ] => @match e begin 
            :( $y[$i:$j]($s) ) => (y == x && s == tf) ? (:final, i:j     ) : :other
            :( $y[$i   ]($s) ) => (y == x && s == tf) ? (:final, Index(i)) : :other
	    _                  => :other end                
        [ true , true , false, false, false, false ] => :boundary
        [ false, false, true , false, false, false ] => @match e begin
             :( $v[$i:$j]($s) ) => (v == u && s == t) ? (:control_range, i:j     ) : :other
             :( $v[$i   ]($s) ) => (v == u && s == t) ? (:control_range, Index(i)) : :other
	     _                  => :control_fun end                
        [ false, false, false, true, false, false  ] => @match e begin
            :( $y[$i:$j]($s) ) => (y == x && s == t) ? (:state_range, i:j     ) : :other
            :( $y[$i   ]($s) ) => (y == x && s == t) ? (:state_range, Index(i)) : :other
	    _                  => :state_fun end                
        [ false, false, true , true, false, false  ] => :mixed
        _                      => :other
    end

# debug: provide (?) transformed expression into the appropriate function:
# - pruning t
# - replacing x(t0) by x0 (and returning x0 ... -> e) 
# - case of variables: now = tf (may be t0, but outside POC)
