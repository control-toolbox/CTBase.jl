# onepass
# todo: add aliases doing, if they exist, an expansion / replace pass on the e
# at the beginning of parse!

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
parse!(__ocp, ocp, e; log=true) = @match e begin
    :( $v ∈ R^$q, variable ) => p_variable!(__ocp, ocp, v, q; log)
    :( $v ∈ R   , variable ) => p_variable!(__ocp, ocp, v   ; log)
    :( $t ∈ [ $t0, $tf ], time ) => p_time!(__ocp, ocp, t, t0, tf; log)
    :( $x ∈ R^$n, state ) => p_state!(__ocp, ocp, x, n; log)
    :( $x ∈ R   , state ) => p_state!(__ocp, ocp, x   ; log)
    :( $u ∈ R^$m, control ) => p_control!(__ocp, ocp, u, m; log)
    :( $u ∈ R   , control ) => p_control!(__ocp, ocp, u   ; log)
    _ =>
    if e isa LineNumberNode
        e
    elseif (e isa Expr) && (e.head == :block)
        Expr(:block, map(e -> parse!(__ocp, ocp, e), e.args)...)
    else
        throw("syntax error")
    end
end

p_variable!(__ocp, ocp, v, q=1; log=false) = begin
    log && println("variable: $v, dim: $q")
    __ocp.parsed.vars[v] = q
    LineNumberNode(0, "variable: $v, dim: $q")
end

p_time!(__ocp, ocp, t, t0, tf; log=false) = begin
    log && println("time: $t, initial time: $t0, final time: $tf")
    __ocp.parsed.t = t
    __ocp.parsed.t0 = t0
    __ocp.parsed.tf = tf
    tt = QuoteNode(t)
    cond = (t0 ∈ keys(__ocp.parsed.vars), tf ∈ keys(__ocp.parsed.vars))
    @match cond begin
        (false, false) => :( time!($ocp, [ $t0, $tf ] , String($tt)) )
        (false, true ) => :( time!($ocp, :initial, $t0, String($tt)) )
        (true , false) => :( time!($ocp, :final  , $tf, String($tt)) )
        _              => throw("both initial and final time cannot be variable")
    end
end

p_state!(__ocp, ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    __ocp.parsed.x = x
    :( state!($ocp, $n) ) # debug: add state name
end

p_control!(__ocp, ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    __ocp.parsed.u = u
    :( control!($ocp, $m) ) # debug: add control name
end

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
macro __def1(ocp, e)
    oocp = QuoteNode(ocp)
    ee = QuoteNode(e)
    quote parse!($(esc(ocp)), $oocp, $ee; log=true) end
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
    esc( quote eval(@__def1 $ocp $e) end )
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
    ocp = Model()
    esc(quote @def1 $ocp $e; $ocp end)
end
