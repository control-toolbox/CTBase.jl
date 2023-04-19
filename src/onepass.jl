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
    aliases::Dict{Symbol, Union{Real, Symbol, Expr}}=Dict{Symbol, Any}() # this Any could refined
    vars::Dict{Symbol, Union{Real, Symbol, Expr}}=Dict{Symbol, Any}() # idem
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
    tt0 = QuoteNode(t0)
    ttf = QuoteNode(tf)
    @match (t0 ∈ keys(p.vars), tf ∈ keys(p.vars)) begin
        (false, false) => :( time!($ocp, [ $t0, $tf ] , string($tt)) )
        (false, true ) => begin
	    (p.vars[tf] ≠ 1) && throw("variable final time must be one dimensional")
	    :( time!($ocp, :initial, $t0, string($tt)) ) end
        (true , false) => begin
	    (p.vars[t0] ≠ 1) && throw("variable initial time must be one dimensional")
	    :( time!($ocp, :final  , $tf, string($tt)) ) end
        _              => begin
	    (p.vars[t0] ≠ 1) && throw("variable initial time must be one dimensional")
	    (p.vars[tf] ≠ 1) && throw("variable final time must be one dimensional")
	    :( LineNumberNode(1, "free initial time: " * string($tt0) *
	                         ", free final time: " * string($ttf)) ) end
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

p_constraint_eq!(p, ocp, e1, e2, label=gensym(); log=false) = begin
    log && println("constraint: $e1 == $e2,    ($label)")
    (label isa Integer) && ( label = Symbol(:eq, label) )
    llabel = QuoteNode(label)
    @match constraint_type(e1, p.t, p.t0, p.tf, p.x, p.u) begin
        (:initial, nothing) => :( constraint!($ocp, :initial,       $e2, $llabel) )
	(:initial, val    ) => :( constraint!($ocp, :initial, $val, $e2, $llabel) )
	(:final  , nothing) => :( constraint!($ocp, :final  ,       $e2, $llabel) )
	(:final  , val    ) => :( constraint!($ocp, :final  , $val, $e2, $llabel) )
	_ => throw("syntax error")
    end
end

p_dynamics!(p, ocp, x, t, e; log=false) = begin
    log && println("dynamics: $x'($t) == $e")
    ( x ≠ p.x ) && throw("dynamics: wrong state")
    ( t ≠ p.t ) && throw("dynamics: wrong time")
    e = replace_call(e, p.x, p.t, p.x)
    e = replace_call(e, p.u, p.t, p.u)
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
    e = replace_call(e, p.x, p.t, p.x)
    e = replace_call(e, p.u, p.t, p.u)
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
