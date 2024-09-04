# ctparser_utils

"""
$(TYPEDSIGNATURES)

Expr iterator: apply `_Expr` to nodes and `f` to leaves of the AST.

# Example
```@example
julia> id(e) = expr_it(e, Expr, x -> x)
```
"""
expr_it(e, _Expr, f) =
    if e isa Expr
        args = e.args
        n = length(args)
        newargs = [expr_it(e.args[i], _Expr, f) for i ∈ 1:n]
        return _Expr(e.head, newargs...)
    else
        return f(e)
    end

"""
$(TYPEDSIGNATURES)

Substitute expression `e1` by expression `e2` in expression `e`.

# Examples
```@example
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
subs(e, e1::Union{Symbol, Real}, e2) = expr_it(e, Expr, x -> x == e1 ? e2 : x) # optimised for some litterals (including symbols)

subs(e, e1, e2) = begin
    foo(e1, e2) = (h, args...) -> begin
        f = Expr(h, args...)
        f == e1 ? e2 : f
    end
    expr_it(e, foo(e1, e2), f -> f == e1 ? e2 : f)
end

"""
$(TYPEDSIGNATURES)

Replace calls in e of the form `(...x...)(t)` by `(...y...)`.

# Example
```@example

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

julia> e = :( 0.5u(t)^2 ); replace_call(e, u, t, u)
:(0.5 * u ^ 2)
```
"""
replace_call(e, x::Symbol, t, y) = replace_call(e, [x], t, [y])

"""
$(TYPEDSIGNATURES)

Replace calls in e of the form `(...x1...x2...)(t)` by `(...y1...y2...)` for all symbols `x1`, `x2`... in the vector `x`.

# Example
```@example

julia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;

julia> e = :( (x^2 + u[1])(t) ); replace_call(e, [ x, u ], t , [ :xx, :uu ])
:(xx ^ 2 + uu[1])

julia> e = :( ((x^2)(t) + u[1])(t) ); replace_call(e, [ x, u ], t , [ :xx, :uu ])
:(xx ^ 2 + uu[1])

julia> e = :( ((x^2)(t0) + u[1])(t) ); replace_call(e, [ x, u ], t , [ :xx, :uu ])
:((xx ^ 2)(t0) + uu[1])
```
"""
replace_call(e, x::Vector{Symbol}, t, y) = begin
    @assert length(x) == length(y)
    foo(x, t, y) = (h, args...) -> begin
        ee = Expr(h, args...)
        @match ee begin
            :($eee($tt)) && if tt == t
            end => let ch = false
                for i = 1:length(x)
                    if has(eee, x[i])
                        eee = subs(eee, x[i], y[i])
                        ch = true # todo: unnecessary (as subs can be idempotent)?
                    end
                end
                ch ? eee : ee
            end
            _ => ee
        end
    end
    expr_it(e, foo(x, t, y), x -> x)
end

"""
$(TYPEDSIGNATURES)

Return true if e contains e1.

# Example
```@example
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

Return true if e contains a `(...x...)(t)` call.

# Example
```@example
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
        else
            @match ee begin
                :($eee($tt)) => (tt == t && has(eee, x)) ? :yes : ee
                _ => ee
            end
        end
    end
    expr_it(e, foo(x, t), x -> x) == :yes
end

"""
$(TYPEDSIGNATURES)

Return the type constraint among
`:initial`, `:final`, `:boundary`, `:control_range`, `:control_fun`,
`:state_range`, `:state_fun`, `:mixed`, `:variable_range`, `:variable_fun` (`:other` otherwise),
together with the appropriate value (range, updated expression...) Expressions like `u(t0)` where `u`
is the control and `t0` the initial time return `:other`.

# Example
```@example
julia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u; v = :v

julia> constraint_type(:( ẏ(t) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( ẋ(s) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( x(0)' ), t, t0, tf, x, u, v)
:boundary

julia> constraint_type(:( x(t)' ), t, t0, tf, x, u, v)
:state_fun

julia> constraint_type(:( x(0) ), t, t0, tf, x, u, v)
(:initial, nothing)

julia> constraint_type(:( x[1:2:5](0) ), t, t0, tf, x, u, v)
(:initial, 1:2:5)

julia> constraint_type(:( x[1:2](0) ), t, t0, tf, x, u, v)
(:initial, 1:2)

julia> constraint_type(:( x[1](0) ), t, t0, tf, x, u, v)
(:initial, 1)

julia> constraint_type(:( 2x[1](0)^2 ), t, t0, tf, x, u, v)
:boundary

julia> constraint_type(:( x(tf) ), t, t0, tf, x, u, v)
(:final, nothing)
j
julia> constraint_type(:( x[1:2:5](tf) ), t, t0, tf, x, u, v)
(:final, 1:2:5)

julia> constraint_type(:( x[1:2](tf) ), t, t0, tf, x, u, v)
(:final, 1:2)

julia> constraint_type(:( x[1](tf) ), t, t0, tf, x, u, v)
(:final, 1)

julia> constraint_type(:( 2x[1](tf)^2 ), t, t0, tf, x, u, v)
:boundary

julia> constraint_type(:( x[1](tf) - x[2](0) ), t, t0, tf, x, u, v)
:boundary

julia> constraint_type(:( u[1:2:5](t) ), t, t0, tf, x, u, v)
(:control_range, 1:2:5)

julia> constraint_type(:( u[1:2](t) ), t, t0, tf, x, u, v)
(:control_range, 1:2)

julia> constraint_type(:( u[1](t) ), t, t0, tf, x, u, v)
(:control_range, 1)

julia> constraint_type(:( u(t) ), t, t0, tf, x, u, v)
(:control_range, nothing)

julia> constraint_type(:( 2u[1](t)^2 ), t, t0, tf, x, u, v)
:control_fun

julia> constraint_type(:( x[1:2:5](t) ), t, t0, tf, x, u, v)
(:state_range, 1:2:5)

julia> constraint_type(:( x[1:2](t) ), t, t0, tf, x, u, v)
(:state_range, 1:2)

julia> constraint_type(:( x[1](t) ), t, t0, tf, x, u, v)
(:state_range, 1)

julia> constraint_type(:( x(t) ), t, t0, tf, x, u, v)
(:state_range, nothing)

julia> constraint_type(:( 2x[1](t)^2 ), t, t0, tf, x, u, v)
:state_fun

julia> constraint_type(:( 2u[1](t)^2 * x(t) ), t, t0, tf, x, u, v)
:mixed

julia> constraint_type(:( 2u[1](0)^2 * x(t) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( 2u[1](0)^2 * x(t) ), t, t0, tf, x, u, v)
:other

julia> constraint_type(:( 2u[1](t)^2 * x(t) + v ), t, t0, tf, x, u, v)
:mixed

julia> constraint_type(:( v[1:2:10] ), t, t0, tf, x, u, v)
(:variable_range, 1:2:9)

julia> constraint_type(:( v[1:10] ), t, t0, tf, x, u, v)
(:variable_range, 1:10)

julia> constraint_type(:( v[2] ), t, t0, tf, x, u, v)
(:variable_range, 2)

julia> constraint_type(:( v ), t, t0, tf, x, u, v)
(:variable_range, nothing)

julia> constraint_type(:( v^2  + 1 ), t, t0, tf, x, u, v)
:variable_fun
julia> constraint_type(:( v[2]^2 + 1 ), t, t0, tf, x, u, v)
:variable_fun
```
"""
constraint_type(e, t, t0, tf, x, u, v) = begin
    @match [
        has(e, x, t0),
        has(e, x, tf),
        has(e, u, t),
        has(e, x, t),
        has(e, u, t0),
        has(e, u, tf),
        has(e, v)
    ] begin
        [true, false, false, false, false, false, _] => @match e begin
            :($y[($i):($p):($j)]($s)) && if (y == x && s == t0)
            end => (:initial, i:p:j)
            :($y[($i):($j)]($s)) && if (y == x && s == t0)
            end => (:initial, i:j)
            :($y[$i]($s)) && if (y == x && s == t0)
            end => (:initial, i)
            :($y($s)) && if (y == x && s == t0)
            end => (:initial, nothing)
            _ => :boundary
        end
        [false, true, false, false, false, false, _] => @match e begin
            :($y[($i):($p):($j)]($s)) && if (y == x && s == tf)
            end => (:final, i:p:j)
            :($y[($i):($j)]($s)) && if (y == x && s == tf)
            end => (:final, i:j)
            :($y[$i]($s)) && if (y == x && s == tf)
            end => (:final, i)
            :($y($s)) && if (y == x && s == tf)
            end => (:final, nothing)
            _ => :boundary
        end
        [true, true, false, false, false, false, _] => :boundary
        [false, false, true, false, false, false, _] => @match e begin
            :($c[($i):($p):($j)]($s)) && if (c == u && s == t)
            end => (:control_range, i:p:j)
            :($c[($i):($j)]($s)) && if (c == u && s == t)
            end => (:control_range, i:j)
            :($c[$i]($s)) && if (c == u && s == t)
            end => (:control_range, i)
            :($c($s)) && if (c == u && s == t)
            end => (:control_range, nothing)
            _ => :control_fun
        end
        [false, false, false, true, false, false, _] => @match e begin
            :($y[($i):($p):($j)]($s)) && if (y == x && s == t)
            end => (:state_range, i:p:j)
            :($y[($i):($j)]($s)) && if (y == x && s == t)
            end => (:state_range, i:j)
            :($y[$i]($s)) && if (y == x && s == t)
            end => (:state_range, i)
            :($y($s)) && if (y == x && s == t)
            end => (:state_range, nothing)
            _ => :state_fun
        end
        [false, false, true, true, false, false, _] => :mixed
        [false, false, false, false, false, false, true] => @match e begin
            :($w[($i):($p):($j)]) && if (w == v)
            end => (:variable_range, i:p:j)
            :($w[($i):($j)]) && if (w == v)
            end => (:variable_range, i:j)
            :($w[$i]) && if (w == v)
            end => (:variable_range, i)
            _ && if (e == v)
            end => (:variable_range, nothing)
            _ => :variable_fun
        end
        _ => :other
    end
end
