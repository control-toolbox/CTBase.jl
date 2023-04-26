# onepass
# todo: eq / ineq (type = variable)

"""
$(TYPEDEF)

**Fields**

"""
@with_kw mutable struct ParsingInfo
    t::Union{Symbol, Nothing}=nothing
    t0::Union{Real, Symbol, Expr, Nothing}=nothing
    tf::Union{Real, Symbol, Expr, Nothing}=nothing
    x::Union{Symbol, Nothing}=nothing
    u::Union{Symbol, Nothing}=nothing
    v::Union{Symbol, Nothing}=nothing
    v_dim::Integer=0
    aliases::OrderedDict{Symbol, Union{Real, Symbol, Expr}}=__init_aliases()
end

__init_aliases() = begin
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

__sub(i) = join(Char(0x2080 + d) for d in reverse!(digits(i)))

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
        :( $e1 == $e2         ) => p_constraint_eq!(p, ocp, e1, e2; log)
        :( $e1 == $e2, $label ) => p_constraint_eq!(p, ocp, e1, e2, label; log)
        :( ∫($e1) → min ) => p_objective!(p, ocp, e1, :min; log)
        :( ∫($e1) → max ) => p_objective!(p, ocp, e1, :max; log)
        _ =>
    
        if e isa LineNumberNode
            e
        elseif e isa Expr && e.head == :block
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
    p.v_dim = q
    vv = QuoteNode(v)
    q isa Integer && for i ∈ 1:q p.aliases[Symbol(v, __sub(i))] = :( $v[$i] ) end
    :( variable!($ocp, $q, $vv) )
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
    @match (has(t0, p.v), has(tf, p.v)) begin
        (false, false) => :( time!($ocp, $t0, $tf, $tt) )
        (true , false) => @match t0 begin
	    :( $v1[$i] ) =>  (v1 == p.v) ? :( time!($ocp, Index($i), $tf, $tt) ) : throw(SyntaxError("bad time declaration"))
	    :( $v1     ) =>  (v1 == p.v && 1 == p.v_dim) ? :( time!($ocp, Index(1), $tf, $tt) ) : throw(SyntaxError("bad time declaration"))
	    _            => throw(SyntaxError("bad time declaration")) end
        (false, true ) => @match tf begin
	    :( $v1[$i] ) =>  (v1 == p.v) ? :( time!($ocp, $t0, Index($i), $tt) ) : throw(SyntaxError("bad time declaration"))
	    :( $v1     ) =>  (v1 == p.v && 1 == p.v_dim) ? :( time!($ocp, $t0, Index(1), $tt) ) : throw(SyntaxError("bad time declaration"))
	    _            => throw(SyntaxError("bad time declaration")) end
	_              => @match (t0, tf) begin
	    (:( $v1[$i] ), :( $v2[$j] )) => (v1 == v2 == p.v) ? :( time!($ocp, Index($i), Index($j), $tt) ) : throw(SyntaxError("bad time declaration"))
	    _ => throw(SyntaxError("bad time declaration")) end
    end
end

p_state!(p, ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    p.x = x
    xx = QuoteNode(x)
    n isa Integer && for i ∈ 1:n p.aliases[Symbol(x, __sub(i))] = :( $x[$i] ) end
    :( state!($ocp, $n, $xx) )
end

p_control!(p, ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    p.u = u
    uu = QuoteNode(u)
    m isa Integer && for i ∈ 1:m p.aliases[Symbol(u, __sub(i))] = :( $u[$i] ) end
    :( control!($ocp, $m, $uu) )
end

p_constraint_eq!(p, ocp, e1, e2, label=gensym(); log=false) = begin
    log && println("constraint: $e1 == $e2,    ($label)")
    label isa Integer && ( label = Symbol(:eq, label) )
    llabel = QuoteNode(label)
    @match constraint_type(e1, p.t, p.t0, p.tf, p.x, p.u, p.v) begin
        (:initial , nothing) => :( constraint!($ocp, :initial,       $e2, $llabel) )
	(:initial , val    ) => :( constraint!($ocp, :initial, $val, $e2, $llabel) )
	(:final   , nothing) => :( constraint!($ocp, :final  ,       $e2, $llabel) )
	(:final   , val    ) => :( constraint!($ocp, :final  , $val, $e2, $llabel) )
	(:boundary, ee1    ) => begin
            gs = gensym()
	    x0 = Symbol(p.x, "#0")
	    xf = Symbol(p.x, "#f")
	    if isnothing(p.v)
	        quote
                    function $gs($x0, $xf)
	                $ee1
	            end
	            constraint!($ocp, :boundary, $gs, $e2, $llabel)
		end
	    else
	        quote
                    function $gs($x0, $xf, $(p.v))
	                $ee1
	            end
	            constraint!($ocp, :boundary, $gs, $e2, $llabel)
		end
	    end end
	_ => throw(SyntaxError("bad constraint declaration"))
    end
end

p_dynamics!(p, ocp, x, t, e; log=false) = begin
    log && println("dynamics: $x'($t) == $e")
    x ≠ p.x && throw(SyntaxError("wrong state for dynamics"))
    t ≠ p.t && throw(SyntaxError("wrong time for dynamics"))
    e = replace_call(e, p.t)
    gs = gensym()
    if isnothing(p.v)
        quote
            function $gs($(p.x), $(p.u))
    	        $e
    	    end
    	constraint!($ocp, :dynamics, $gs)
        end
    else
        quote
            function $gs($(p.x), $(p.u), $(p.v))
    	        $e
    	    end
    	constraint!($ocp, :dynamics, $gs)
        end
    end
end

p_objective!(p, ocp, e, type; log) = begin
    log && println("objective: ∫($e) → $type")
    e = replace_call(e, p.t)
    ttype = QuoteNode(type)
    gs = gensym()
    if isnothing(p.v)
        quote
            function $gs($(p.x), $(p.u))
	        $e
	    end
	    objective!($ocp, :lagrange, $gs, $ttype)
        end
    else
        quote
            function $gs($(p.x), $(p.u), $(p.v))
	        $e
	    end
	    objective!($ocp, :lagrange, $gs, $ttype)
        end
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
