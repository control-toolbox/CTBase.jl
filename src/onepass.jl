# onepass
# todo: unalias expressions (in constraints and cost,
# not declarations); add default unalias for x₁, etc.

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
    :( $a = $e1 ) => p_alias(ocp, a, e1; log)
    :( $y'($s) == $e1 ) => p_dynamics(ocp, y, s, e1; log)
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
    :( $ocp.parsed.vars[$vv] = $q )
end

p_time(ocp, t, t0, tf; log=false) = begin
    log && println("time: $t, initial time: $t0, final time: $tf")
    tt = QuoteNode(t)
    tt0 = QuoteNode(t0)
    ttf = QuoteNode(tf)
    quote
        $ocp.parsed.t = $tt )
        cond = ($tt0 ∈ keys($ocp.parsed.vars), $ttf ∈ keys($ocp.parsed.vars))
	println("cond = ", cond) # debug
        @match cond begin
            (false, false) => begin
                $ocp.parsed.t0 = $t0
                $ocp.parsed.tf = $tf
	        time!($ocp, [ $t0, $tf ] , String($tt)) end
            (false, true ) => begin
                $ocp.parsed.t0 = $t0
                $ocp.parsed.tf = nothing
	        time!($ocp, :initial, $t0, String($tt)) end
            (true , false) => begin
                $ocp.parsed.t0 = nothing
                $ocp.parsed.tf = $tf
	        time!($ocp, :final  , $tf, String($tt)) end
            _              => throw("parsing error: both initial and final time cannot be variable")
        end
    end
end

p_state(ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    xx = QuoteNode(x)
    quote
        $ocp.parsed.x = $xx
        state!($ocp, $n) # debug: add state name
    end
end

p_control(ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    uu = QuoteNode(u)
    quote
        $ocp.parsed.u = $uu
        control!($ocp, $m) # debug: add control name
    end
end

p_alias(ocp, a, e; log=false) = begin
    log && println("alias: $a = $e")
    aa = QuoteNode(a)
    ee = QuoteNode(e)
    :( $ocp.parsed.aliases[$aa] = $ee )
end

p_dynamics(ocp, y, e; log) = begin
    log && println("dynamics: $y'($s) = $e")
    yy = QuoteNode(y)
    ss = QuoteNode(s)
    quote
        ( $yy ≠ $ocp.parsed.x ) && throw("dynamics: wrong state")
        ( $ss ≠ $ocp.parsed.t ) && throw("dynamics: wrong time")
	($ocp.parsed.x, $ocp.parsed.u) -> $e
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
