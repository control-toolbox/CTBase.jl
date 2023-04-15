# onepass
# todo: add aliases doing, if they exist, an expansion / replace pass on the e
# at the beginning of parse

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
parse(ocp, e; log=true) = @match e begin
    :( $v ∈ R^$q, variable ) => p_variable(ocp, v, q; log)
    :( $v ∈ R   , variable ) => p_variable(ocp, v   ; log)
    :( $t ∈ [ $t0, $tf ], time ) => p_time(ocp, t, t0, tf; log)
    :( $x ∈ R^$n, state ) => p_state(ocp, x, n; log)
    :( $x ∈ R   , state ) => p_state(ocp, x   ; log)
    :( $u ∈ R^$m, control ) => p_control(ocp, u, m; log)
    :( $u ∈ R   , control ) => p_control(ocp, u   ; log)
    _ =>
    if e isa LineNumberNode
        e
    elseif (e isa Expr) && (e.head == :block)
        Expr(:block, map(e -> parse(ocp, e), e.args)...)
    else
        throw("syntax error")
    end
end

p_variable(ocp, v, q=1; log=false) = begin
    log && println("variable: $v, dim: $q")
    vv = QuoteNode(v)
    code = :( $ocp.parsed.vars[$vv] = $q )
    code
end

p_time(ocp, t, t0, tf; log=false) = begin
    log && println("time: $t, initial time: $t0, final time: $tf")
    tt = QuoteNode(t)
    tt0 = QuoteNode(t0)
    ttf = QuoteNode(tf)
    code = :( $ocp.parsed.t = $tt )
    code = Expr(:block, code, :( $ocp.parsed.t0 = $t0 ))
    code = Expr(:block, code, :( $ocp.parsed.tf = $tf ))
    code = Expr(:block, code, quote
        cond = ($tt0 ∈ keys($ocp.parsed.vars), $ttf ∈ keys($ocp.parsed.vars))
	println("cond = ", cond) # debug
        @match cond begin
            (false, false) => time!($ocp, [ $t0, $tf ] , String($tt))
            (false, true ) => time!($ocp, :initial, $t0, String($tt))
            (true , false) => time!($ocp, :final  , $tf, String($tt))
            _              => throw("both initial and final time cannot be variable")
        end
    end)
    code
end

p_state(ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    xx = QuoteNode(x)
    code = :( $ocp.parsed.x = $xx )
    code = Expr(:block, code, :( state!($ocp, $n) )) # debug: add state name
    code
end

p_control(ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    uu = QuoteNode(u)
    code = :( $ocp.parsed.u = $uu )
    code = Expr(:block, code, :( control!($ocp, $m) )) # debug: add control name
    code
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
    esc( parse(ocp, e; log=true) )
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
    esc( quote ocp = Model(); @def1 ocp $e; ocp end )
end
