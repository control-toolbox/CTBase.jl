# onepass
# todo: unalias expressions (in constraints and cost, not declarations);
# add default unalias for x₁, etc. 

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
    aliases::Dict{Symbol, Any}=Dict{Symbol, Any}() # this Any could refined
    vars::Dict{Symbol, Any}=Dict{Symbol, Any}() # idem
end

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
parse!(p, ocp, e; log=false) = @match e begin
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
    :( ∫($e1) → min ) => p_objective!(p, ocp, e1, :min; log)
    :( ∫($e1) → max ) => p_objective!(p, ocp, e1, :max; log)
    _ =>

    if e isa LineNumberNode
        e
    elseif (e isa Expr) && (e.head == :block)
	Expr(:block, map(e -> parse!(p, ocp, e; log), e.args)...)
	# assumes that map is done sequentially
    else
        throw("syntax error")
    end
end

p_variable!(p, ocp, v, q=1; log=false) = begin
    log && println("variable: $v, dim: $q")
    p.vars[v] = q
    vv = QuoteNode(v)
    :( LineNumberNode(1, "variable: " * string($vv) * ", dim: " * string($q)) )
end

p_alias!(p, ocp, a, e; log=false) = begin
    log && println("alias: $a = $e")
    p.aliases[a] = e
    :( LineNumberNode(2, "alias: $a = $e") )
end

p_time!(p, ocp, t, t0, tf; log=false) = begin
    log && println("time: $t, initial time: $t0, final time: $tf")
    p.t = t 
    p.t0 = t0
    p.tf = tf
    tt = QuoteNode(t)
    @match (t0 ∈ keys(p.vars), tf ∈ keys(p.vars)) begin
        (false, false) => :( time!($ocp, [ $t0, $tf ] , string($tt)) )
        (false, true ) => :( time!($ocp, :initial, $t0, string($tt)) )
        (true , false) => :( time!($ocp, :final  , $tf, string($tt)) )
        _              => throw("parsing error: both initial and final time " *
	                        "cannot be variable")
    end
end

p_state!(p, ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    p.x = x
    :( state!($ocp, $n) ) # todo: add state name
end

p_control!(p, ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    p.u = u
    :( control!($ocp, $m) ) # todo: add control name
end

p_constraint_eq!(p, ocp, e1, e2; log) = begin
    log && println("constraint: $e1 == $e2")
    @match constraint_type(e1, p.t, p.t0, p.tf, p.x, p.u) begin
        (:initial, nothing) => :( constraint!($ocp, :initial,      $e2) )
	(:initial, val    ) => :( constraint!($ocp, :initial, $val, $e2) )
	(:final  , nothing) => :( constraint!($ocp, :final  ,      $e2) )
	(:final  , val    ) => :( constraint!($ocp, :final  , $val, $e2) )
	_ => throw("syntax error")
    end
end

p_dynamics!(p, ocp, x, t, e; log) = begin
    log && println("dynamics: $x'($t) == $e")
    ( x ≠ p.x ) && throw("dynamics: wrong state")
    ( t ≠ p.t ) && throw("dynamics: wrong time")
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
macro _def1(ocp, e)
    p = ParsingInfo()
    esc( parse!(p, ocp, e; log=true) )
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
macro def1(e)
    esc( quote ocp = Model(); @_def1 ocp $e; ocp end )
end
