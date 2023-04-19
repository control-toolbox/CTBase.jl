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

Base.show(io::IO, p::ParsingInfo) = begin
    println(io, "t  = ", p.t) 
    println(io, "t0 = ", p.t0) 
    println(io, "tf = ", p.tf) 
    println(io, "x  = ", p.x) 
    println(io, "u  = ", p.u) 
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
	code = LineNumberNode(0, "start")
	for ee ∈ e.args
	    code = Expr(:block, code, parse!(p, ocp, ee; log))
	end
        code
    else
        throw("syntax error")
    end
end

p_variable!(p, ocp, v, q=1; log=false) = begin
    log && println("variable: $v, dim: $q")
    p.vars[v] = q
    :( LineNumberNode(1, "variable: $v, dim: $(esc(q))") )
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
        (false, false) => :( time!($ocp, [ $(esc(t0)), $(esc(tf)) ], String($tt)) )
        (false, true ) => :( time!($ocp, :initial, $(esc(t0)), String($tt)) )
        (true , false) => :( time!($ocp, :final  , $(esc(tf)), String($tt)) )
        _              => throw("parsing error: both initial and final time " *
	                        "cannot be variable")
    end
end

p_state!(p, ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    p.x = x
    :( state!($ocp, $(esc(n))) ) # todo: add state name
end

p_control!(p, ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    p.u = u
    :( control!($ocp, $(esc(m))) ) # todo: add control name
end

p_constraint_eq!(p, ocp, e1, e2; log) = begin
    log && println("constraint: $e1 == $e2")
    @match constraint_type(e1, p.t, p.t0, p.tf, p.x, p.u) begin
        (:initial, nothing) => :( constraint!($ocp, :initial,      $(esc(e2))) )
	(:initial, val    ) => :( constraint!($ocp, :initial, val, $(esc(e2))) )
	(:final  , nothing) => :( constraint!($ocp, :final  ,      $(esc(e2))) )
	(:final  , val    ) => :( constraint!($ocp, :final  , val, $(esc(e2))) )
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
	    $(esc(e))
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
	    $(esc(e))
	end
	objective!($ocp, :lagrange, $gs, $ttype)
    end
end
 
"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
macro def1(ocp, e)
    #esc( parse(ocp, e; log=true) )
    p = ParsingInfo()
    parse!(p, esc(ocp), e; log=true)
end

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
macro def1(e)
    #esc( quote ocp = Model(); @def1 ocp $e; ocp end ) # debug: todo
    quote ocp = Model(); @def1 ocp $e; ocp end
end
