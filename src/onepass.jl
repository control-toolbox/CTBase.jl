# onepass
# todo: 

"""
$(TYPEDEF)

**Fields**

"""
@with_kw mutable struct ParsingInfo
    v::Union{Symbol, Nothing}=nothing
    t::Union{Symbol, Nothing}=nothing
    t0::Union{Real, Symbol, Expr, Nothing}=nothing
    tf::Union{Real, Symbol, Expr, Nothing}=nothing
    x::Union{Symbol, Nothing}=nothing
    u::Union{Symbol, Nothing}=nothing
    aliases::OrderedDict{Symbol, Union{Real, Symbol, Expr}}=_init_aliases()
end

_init_aliases() = begin
    al = OrderedDict{Symbol, Union{Real, Symbol, Expr}}()
    al[:R¹] = :( R^1 )
    al[:R²] = :( R^2 )
    al[:R³] = :( R^3 )
    al[:R⁴] = :( R^4 )
    al[:R⁵] = :( R^5 )
    al[:R⁶] = :( R^6 )
    al[:R⁷] = :( R^7 )
    al[:R⁸] = :( R^8 )
    al[:R⁹] = :( R^9 )
    al
end

_sub(i) = join(Char(0x2080 + d) for d in reverse!(digits(i)))

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
parse!(p, ocp, e; log=false) = begin
    for a ∈ keys(p.aliases)
        e = subs(e, a, p.aliases[a])
    end
    @match e begin
        :( $v ∈ R^$q, variable ) => p_variable!(p, ocp, v, q; log)
        :( $v ∈ R   , variable ) => p_variable!(p, ocp, v   ; log)
        :( $t ∈ [ $t0, $tf ], time ) => p_time!(p, ocp, t, t0, tf; log)
        :( $x ∈ R^$n, state ) => p_state!(p, ocp, x, n; log)
        :( $x ∈ R   , state ) => p_state!(p, ocp, x   ; log)
        :( $u ∈ R^$m, control ) => p_control!(p, ocp, u, m; log)
        :( $u ∈ R   , control ) => p_control!(p, ocp, u   ; log)
        :( $a = $e1 ) => p_alias!(p, ocp, a, e1; log)
        :( $x'($t) == $e1 ) => p_dynamics!(p, ocp, x, t, e1; log)
        :( $e1 == $e2 ) => p_constraint_eq!(p, ocp, e1, e2; log)
        :( $e1 == $e2, $label ) => p_constraint_eq!(p, ocp, e1, e2, label; log)
        :( ∫($e1) → min ) => p_objective!(p, ocp, e1, :min; log)
        :( ∫($e1) → max ) => p_objective!(p, ocp, e1, :max; log)
        _ =>
    
        if e isa LineNumberNode
            e
        elseif (e isa Expr) && (e.head == :block)
    	Expr(:block, map(e -> parse!(p, ocp, e; log), e.args)...)
    	# assumes that map is done sequentially
        else
            throw(SyntaxError("unknown syntax"))
        end
    end
end

p_variable!(p, ocp, v, q=1; log=false) = begin
    log && println("variable: $v, dim: $q")
    p.v = v
    (q isa Integer) && for i ∈ 1:q p.aliases[Symbol(v, _sub(i))] = :( $v[$i] ) end
    :( variable!($ocp, $q) ) # todo: add variable name
end

p_alias!(p, ocp, a, e; log=false) = begin
    log && println("alias: $a = $e")
    p.aliases[a] = e
    aa = QuoteNode(a)
    ee = QuoteNode(e)
    :( LineNumberNode(0, "alias: " * string($aa) *" = " * string($ee)) )
end

p_time!(p, ocp, t, t0, tf; log=false) = begin

    log && println("time: $t, initial time: $t0, final time: $tf")
    p.t = t 
    p.t0 = t0
    p.tf = tf
    tt = QuoteNode(t)
    tt0 = QuoteNode(t0)
    ttf = QuoteNode(tf)
    @match (has(t0, p.v), has(tf, p.v)) begin
        (false, false) => :( time!($ocp, [ $t0, $tf ] , string($tt)) )
        (true , false) => @match t0 begin
	    :( $v1[$i] ) =>  (v1 == p.v) ? :( time!($ocp, Index(i), tf, string($tt)) ) : throw(SyntaxError("bad time declaration"))
	    :( $v1     ) =>  (v1 == p.v) ? :( time!($ocp, Index(1), tf, string($tt)) ) : throw(SyntaxError("bad time declaration"))
	    _            => throw(SyntaxError("bad time declaration")) end
        (false, true ) => @match tf begin
	    :( $v1[$i] ) =>  (v1 == p.v) ? :( time!($ocp, t0, Index(i), string($tt)) ) : throw(SyntaxError("bad time declaration"))
	    :( $v1     ) =>  (v1 == p.v) ? :( time!($ocp, t0, Index(1), string($tt)) ) : throw(SyntaxError("bad time declaration"))
	    _            => throw(SyntaxError("bad time declaration")) end
	_              => @match (t0, tf) begin
	    (:( $v1[$i], $v2[$j] )) => (v1 == v2 == p.v) ? :( time!($ocp, Index(i), Index(j), string($tt)) ) : throw(SyntaxError("bad time declaration"))
	    _ => throw(SyntaxError("bad time declaration")) end
    end
end

p_state!(p, ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    p.x = x
    (n isa Integer) && for i ∈ 1:n p.aliases[Symbol(x, _sub(i))] = :( $x[$i] ) end
    :( state!($ocp, $n) ) # todo: add state name
end

p_control!(p, ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    p.u = u
    (m isa Integer) && for i ∈ 1:m p.aliases[Symbol(u, _sub(i))] = :( $u[$i] ) end
    :( control!($ocp, $m) ) # todo: add control name
end

p_constraint_eq!(p, ocp, e1, e2, label=gensym(); log=false) = begin
    log && println("constraint: $e1 == $e2,    ($label)")
    (label isa Integer) && ( label = Symbol(:eq, label) )
    llabel = QuoteNode(label)
    @match constraint_type(e1, p.t, p.t0, p.tf, p.x, p.u) begin
        (:initial, nothing) => :( constraint!($ocp, :initial,       $e2, $llabel) )
	(:initial, val    ) => :( constraint!($ocp, :initial, $val, $e2, $llabel) )
	(:final  , nothing) => :( constraint!($ocp, :final  ,       $e2, $llabel) )
	(:final  , val    ) => :( constraint!($ocp, :final  , $val, $e2, $llabel) )
	_ => throw(SyntaxError("bad constraint declaration"))
    end
end

p_dynamics!(p, ocp, x, t, e; log=false) = begin
    log && println("dynamics: $x'($t) == $e")
    ( x ≠ p.x ) && throw(SyntaxError("wrong state for dynamics"))
    ( t ≠ p.t ) && throw(SyntaxError("wrong time for dynamics"))
    e = replace_call(e, p.t)
    gs = gensym()
    quote
        function $gs($(p.x), $(p.u))
	    $e
	end
	constraint!($ocp, :dynamics, $gs)
    end
end

p_objective!(p, ocp, e, type; log) = begin
    log && println("objective: ∫($e) → $type")
    e = replace_call(e, p.t)
    ttype = QuoteNode(type)
    gs = gensym()
    quote
        function $gs($(p.x), $(p.u))
	    $e
	end
	objective!($ocp, :lagrange, $gs, $ttype)
    end
end
 
"""
$(TYPEDSIGNATURES)

Implement def1 macro core.

"""
macro _def1(ocp, e, log=false)
    p = ParsingInfo()
    esc( parse!(p, ocp, e; log=log) )
end

"""
$(TYPEDSIGNATURES)

Define an optimal control problem. One pass parsing of the definition.

# Example
```jldoctest
@def1 begin
    t ∈ [ 0, 1 ], time
    x ∈ R^2, state
    u ∈ R  , control
    x(0) == [ 1, 2 ]
    x(1) == [ 0, 0 ]
    x'(t) == [ x[2](t), u(t) ]
    ∫( u(t)^2 ) → min
end
```
"""
macro def1(e, log=false)
    esc( quote ocp = Model(); @_def1 ocp $e $log; ocp end )
end
