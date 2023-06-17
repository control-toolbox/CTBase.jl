# onepass
# todo:
# - doc: explain projections wrt to t0, tf, t; (...x1...x2...)(t) -> ...gensym1...gensym2...
#   (most internal first)
# - test non autonomous cases
# - robustify repl
# - additional checks:
# (i) when generating functions, there should not be any x or u left
# (ii) in boundary and mayer, there should not be any left
# in both cases, has(ee, x/u/t) must be false (postcondition)
# - tests exceptions (parsing and semantics/runtime)
# - add assert for pre/post conditions and invariants
# - add tests on ParsingError + run time errors (wrapped in try ... catch's - use string to be precise)

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
    aliases::OrderedDict{Symbol, Union{Real, Symbol, Expr}}=__init_aliases()
    lnum::Integer=0
    line::String=""
    t_dep::Bool=false
end

__init_aliases() = begin
    al = OrderedDict{Symbol, Union{Real, Symbol, Expr}}()
    for i ∈ 1:9  al[Symbol(:R, ctupperscripts(i))] = :( R^$i  ) end
    al
end

__throw(ex, n, line) = begin
    quote
        info = string("\nLine ", $n, ": ", $line)
        throw(ParsingError(info * "\n" * $ex))
    end
end

__wrap(e, n, line) = quote
    try
        $e
    catch ex
        println("Line ", $n, ": ", $line)
        throw(ex)
    end
end

__t_dep(p) = p.t_dep

__v_dep(p) = !isnothing(p.v)

"""
$(TYPEDSIGNATURES)

Foo

# Example
```jldoctest
Foo
```
"""
parse!(p, ocp, e; log=false) = begin
    p.lnum = p.lnum + 1
    p.line = string(e)
    for a ∈ keys(p.aliases)
        e = subs(e, a, p.aliases[a])
    end
    @match e begin
        :( $v ∈ R^$q, variable       ) => p_variable!(p, ocp, v, q; log)
        :( $v ∈ R   , variable       ) => p_variable!(p, ocp, v   ; log)
        :( $v       , variable       ) => p_variable!(p, ocp, v   ; log) # todo: remove
        :( $t ∈ [ $t0, $tf ], time   ) => p_time!(p, ocp, t, t0, tf; log)
        :( $x ∈ R^$n, state          ) => p_state!(p, ocp, x, n; log)
        :( $x ∈ R   , state          ) => p_state!(p, ocp, x   ; log)
        :( $x       , state          ) => p_state!(p, ocp, x   ; log) # todo: remove
        :( $u ∈ R^$m, control        ) => p_control!(p, ocp, u, m; log)
        :( $u ∈ R   , control        ) => p_control!(p, ocp, u   ; log)
        :( $u       , control        ) => p_control!(p, ocp, u   ; log) # todo: remove
        :( $a = $e1                  ) => p_alias!(p, ocp, a, e1; log)
        :( ∂($x)($t) == $e1          ) => p_dynamics!(p, ocp, x, t, e1       ; log)
        :( ∂($x)($t) == $e1, $label  ) => p_dynamics!(p, ocp, x, t, e1, label; log)
        :( $e1 == $e2                ) => p_constraint!(p, ocp, e2     , e1, e2       ; log)
        :( $e1 == $e2, $label        ) => p_constraint!(p, ocp, e2     , e1, e2, label; log)
        :( $e1 ≤  $e2 ≤  $e3         ) => p_constraint!(p, ocp, e1     , e2, e3            ; log)
        :( $e1 ≤  $e2 ≤  $e3, $label ) => p_constraint!(p, ocp, e1     , e2, e3     , label; log)
        :(        $e2 ≤  $e3         ) => p_constraint!(p, ocp, nothing, e2, e3            ; log)
        :(        $e2 ≤  $e3, $label ) => p_constraint!(p, ocp, nothing, e2, e3     , label; log)
        :( $e3 ≥  $e2 ≥  $e1         ) => p_constraint!(p, ocp, e1     , e2, e3            ; log)
        :( $e3 ≥  $e2 ≥  $e1, $label ) => p_constraint!(p, ocp, e1     , e2, e3     , label; log)
        :( $e2 ≥  $e1                ) => p_constraint!(p, ocp, e1     , e2, nothing       ; log)
        :( $e2 ≥  $e1,        $label ) => p_constraint!(p, ocp, e1     , e2, nothing, label; log)
        :(       ∫($e1) → min        ) => p_lagrange!(p, ocp, e1, :min; log)
        :(       ∫($e1) → max        ) => p_lagrange!(p, ocp, e1, :max; log)
        :( $e1 + ∫($e2) → min        ) => p_bolza!(p, ocp,      e1,      e2  , :min; log)
        :( $e1 - ∫($e2) → min        ) => p_bolza!(p, ocp,      e1, :( -$e2 ), :min; log)
        :( $e1 + ∫($e2) → max        ) => p_bolza!(p, ocp,      e1,      e2  , :max; log)
        :( $e1 - ∫($e2) → max        ) => p_bolza!(p, ocp,      e1, :( -$e2 ), :max; log)
        :( ∫($e2) + $e1 → min        ) => p_bolza!(p, ocp,      e1,      e2  , :min; log)
        :( ∫($e2) - $e1 → min        ) => p_bolza!(p, ocp, :( -$e1 ),    e2  , :min; log)
        :( ∫($e2) + $e1 → max        ) => p_bolza!(p, ocp,      e1,      e2  , :max; log)
        :( ∫($e2) - $e1 → max        ) => p_bolza!(p, ocp, :( -$e1 ),    e2  , :max; log)
        :( $e1          → min        ) => p_mayer!(p, ocp, e1, :min; log)
        :( $e1          → max        ) => p_mayer!(p, ocp, e1, :max; log)
        _ => begin
            if e isa LineNumberNode
                p.lnum = p.lnum - 1
                e
            elseif e isa Expr && e.head == :block
                p.lnum = p.lnum - 1
                Expr(:block, map(e -> parse!(p, ocp, e; log), e.args)...)
		# !!! assumes that map is done sequentially for side effects on p
            else
                return __throw("unknown syntax", p.lnum, p.line)
            end end
    end
end

p_variable!(p, ocp, v, q=1; log=false) = begin
    log && println("variable: $v, dim: $q")
    v isa Symbol || return __throw("forbidden variable name: $v", p.lnum, p.line)
    p.v = v
    vv = QuoteNode(v)
    qq = q isa Integer ? q : 9
    for i ∈ 1:qq p.aliases[Symbol(v, ctindices(i))] = :( $v[$i] ) end
    for i ∈ 1:9  p.aliases[Symbol(v, ctupperscripts(i))] = :( $v^$i  ) end
    __wrap(:( variable!($ocp, $q, $vv) ), p.lnum, p.line)
end

p_alias!(p, ocp, a, e; log=false) = begin
    log && println("alias: $a = $e")
    a isa Symbol || return __throw("forbidden alias name: $a", p.lnum, p.line)
    aa = QuoteNode(a)
    ee = QuoteNode(e)
    for i ∈ 1:9 p.aliases[Symbol(a, ctupperscripts(i))] = :( $a^$i  ) end
    p.aliases[a] = e
    __wrap(:( LineNumberNode(0, "alias: " * string($aa) * " = " * string($ee)) ), p.lnum, p.line)
end

p_time!(p, ocp, t, t0, tf; log=false) = begin
    log && println("time: $t, initial time: $t0, final time: $tf")
    t isa Symbol || return __throw("forbidden time name: $t", p.lnum, p.line)
    p.t = t
    p.t0 = t0
    p.tf = tf
    tt = QuoteNode(t)
    code = @match (has(t0, p.v), has(tf, p.v)) begin
        (false, false) => :( time!($ocp, $t0, $tf, $tt) )
        (true , false) => @match t0 begin
            :( $v1[$i] ) && if (v1 == p.v) end => :( time!($ocp, Index($i), $tf, $tt) )
            :( $v1     ) && if (v1 == p.v) end => quote
                ($ocp.variable_dimension ≠ 1) &&
		throw(IncorrectArgument("variable must be of dimension one for a time"))
                time!($ocp, Index(1), $tf, $tt) end
            _                                  =>
	        return __throw("bad time declaration", p.lnum, p.line) end
        (false, true ) => @match tf begin
            :( $v1[$i] ) && if (v1 == p.v) end => :( time!($ocp, $t0, Index($i), $tt) )
            :( $v1     ) && if (v1 == p.v) end => quote
                ($ocp.variable_dimension ≠ 1) &&
		throw(IncorrectArgument("variable must be of dimension one for a time"))
                time!($ocp, $t0, Index(1), $tt) end
            _                                  =>
	        return __throw("bad time declaration", p.lnum, p.line) end
        _              => @match (t0, tf) begin
            (:( $v1[$i] ), :( $v2[$j] )) && if (v1 == v2 == p.v) end => 
                :( time!($ocp, Index($i), Index($j), $tt) )
            _                                                        =>
	        return __throw("bad time declaration", p.lnum, p.line) end
    end
    __wrap(code, p.lnum, p.line)
end

p_state!(p, ocp, x, n=1; log=false) = begin
    log && println("state: $x, dim: $n")
    x isa Symbol || return __throw("forbidden state name: $x", p.lnum, p.line)
    p.x = x
    xx = QuoteNode(x)
    nn = n isa Integer ? n : 9
    for i ∈ 1:nn p.aliases[Symbol(x, ctindices(i))] = :( $x[$i] ) end
    for i ∈ 1:9  p.aliases[Symbol(x, ctupperscripts(i))] = :( $x^$i  ) end
    p.aliases[Symbol(Unicode.normalize(string(x,"̇")))] = :( ∂($x) )
    __wrap(:( state!($ocp, $n, $xx) ), p.lnum, p.line)
end

p_control!(p, ocp, u, m=1; log=false) = begin
    log && println("control: $u, dim: $m")
    u isa Symbol || return __throw("forbidden control name: $u", p.lnum, p.line)
    p.u = u
    uu = QuoteNode(u)
    mm =  m isa Integer ? m : 9
    for i ∈ 1:mm p.aliases[Symbol(u, ctindices(i))] = :( $u[$i] ) end
    for i ∈ 1:9  p.aliases[Symbol(u, ctupperscripts(i))] = :( $u^$i  ) end
    __wrap(:( control!($ocp, $m, $uu) ), p.lnum, p.line)
end

p_constraint!(p, ocp, e1, e2, e3, label=gensym(); log=false) = begin
    log && println("constraint: $e1 ≤ $e2 ≤ $e3,    ($label)")
    label isa Integer && ( label = Symbol(:eq, label) )
    label isa Symbol || return __throw("forbidden label: $label", p.lnum, p.line)
    llabel = QuoteNode(label)
    code = @match constraint_type(e2, p.t, p.t0, p.tf, p.x, p.u, p.v) begin
        (:initial, rg) => :( constraint!($ocp, :initial; rg=$rg, lb=$e1, ub=$e3, label=$llabel) )
        (:final  , rg) => :( constraint!($ocp, :final  ; rg=$rg, lb=$e1, ub=$e3, label=$llabel) )
        (:boundary, _) => begin
            gs = gensym()
            x0 = gensym()
            xf = gensym()
	    ee2 = replace_call(e2 , p.x, p.t0, x0)
	    ee2 = replace_call(ee2, p.x, p.tf, xf)
	    args = [ x0, xf ]; __v_dep(p) && push!(args, p.v);
            quote
                function $gs($(args...))
                    $ee2
                end
                constraint!($ocp, :boundary; f=$gs, lb=$e1, ub=$e3, label=$llabel)
            end end
        (:control_range, rg) => :( constraint!($ocp, :control; rg=$rg, lb=$e1, ub=$e3, label=$llabel) )
        (:control_fun  , _ ) => begin
            gs = gensym()
            ut = gensym()
	    ee2 = replace_call(e2, p.u, p.t, ut)
            p.t_dep = p.t_dep || has(ee2, p.t)
	    args = [ ]; __t_dep(p) && push!(args, p.t); push!(args, ut); __v_dep(p) && push!(args, p.v)
            quote
                function $gs($(args...))
                    $ee2
                end
                constraint!($ocp, :control; f=$gs, lb=$e1, ub=$e3, label=$llabel)
            end end
        (:state_range, rg) => :( constraint!($ocp, :state; rg=$rg, lb=$e1, ub=$e3, label=$llabel) )
        (:state_fun  , _ ) => begin
            gs = gensym()
            xt = gensym()
	    ee2 = replace_call(e2, p.x, p.t, xt)
            p.t_dep = p.t_dep || has(ee2, p.t)
	    args = [ ]; __t_dep(p) && push!(args, p.t); push!(args, xt); __v_dep(p) && push!(args, p.v)
            quote
                function $gs($(args...))
                    $ee2
                end
                constraint!($ocp, :state; f=$gs, lb=$e1, ub=$e3, label=$llabel)
            end end
        (:variable_range, rg) => :( constraint!($ocp, :variable; rg=$rg, lb=$e1, ub=$e3, label=$llabel) )
        (:variable_fun  , _ ) => begin
            gs = gensym()
	    args = [ p.v ]
            quote
                function $gs($(args...))
                    $e2
                end
                constraint!($ocp, :variable; f=$gs, lb=$e1, ub=$e3, label=$llabel)
            end end
        (:mixed, _) => begin
            gs = gensym()
            xt = gensym()
            ut = gensym()
	    ee2 = replace_call(e2, [ p.x, p.u ], p.t, [ xt, ut ])
            p.t_dep = p.t_dep || has(ee2, p.t)
	    args = [ ]; __t_dep(p) && push!(args, p.t); push!(args, xt, ut); __v_dep(p) && push!(args, p.v)
            quote
                function $gs($(args...))
                    $ee2
                end
                constraint!($ocp, :mixed; f=$gs, lb=$e1, ub=$e3, label=$llabel)
            end end
        _ => return __throw("bad constraint declaration", p.lnum, p.line)
    end
    __wrap(code, p.lnum, p.line)
end

p_dynamics!(p, ocp, x, t, e, label=nothing; log=false) = begin
    ẋ = Symbol(x, "̇") 
    log && println("dynamics: $ẋ($t) == $e")
    isnothing(label) || return __throw("dynamics cannot be labelled", p.lnum, p.line)
    isnothing(p.x) && return __throw("state not yet declared", p.lnum, p.line)
    isnothing(p.u) && return __throw("control not yet declared", p.lnum, p.line)
    isnothing(p.t) && return __throw("time not yet declared", p.lnum, p.line)
    x ≠ p.x && return __throw("wrong state for dynamics", p.lnum, p.line)
    t ≠ p.t && return __throw("wrong time for dynamics", p.lnum, p.line)
    xt = gensym()
    ut = gensym()
    e = replace_call(e, [ p.x, p.u ], p.t, [ xt, ut ])
    p.t_dep = p.t_dep || has(e, t)
    gs = gensym()
    args = [ ]; __t_dep(p) && push!(args, p.t); push!(args, xt, ut); __v_dep(p) && push!(args, p.v)
    __wrap(quote
        function $gs($(args...))
            $e
        end
        dynamics!($ocp, $gs)
    end, p.lnum, p.line)
end

p_lagrange!(p, ocp, e, type; log=false) = begin
    log && println("objective: ∫($e) → $type")
    isnothing(p.x) && return __throw("state not yet declared", p.lnum, p.line)
    isnothing(p.u) && return __throw("control not yet declared", p.lnum, p.line)
    isnothing(p.t) && return __throw("time not yet declared", p.lnum, p.line)
    xt = gensym()
    ut = gensym()
    e = replace_call(e, [ p.x, p.u ], p.t, [ xt, ut ])
    p.t_dep = p.t_dep || has(e, p.t)
    ttype = QuoteNode(type)
    gs = gensym()
    args = [ ]; __t_dep(p) && push!(args, p.t); push!(args, xt, ut); __v_dep(p) && push!(args, p.v)
    __wrap(quote
        function $gs($(args...))
            $e
        end
        objective!($ocp, :lagrange, $gs, $ttype)
    end, p.lnum, p.line)
end

p_mayer!(p, ocp, e, type; log=false) = begin
    log && println("objective: $e → $type")
    isnothing(p.x) && return __throw("state not yet declared", p.lnum, p.line)
    isnothing(p.t0) && return __throw("time not yet declared", p.lnum, p.line)
    isnothing(p.tf) && return __throw("time not yet declared", p.lnum, p.line)
    gs = gensym()
    x0 = gensym()
    xf = gensym()
    e = replace_call(e, p.x, p.t0, x0)
    e = replace_call(e, p.x, p.tf, xf)
    ttype = QuoteNode(type)
    args = [ x0, xf ]; __v_dep(p) && push!(args, p.v)
    __wrap(quote
        function $gs($(args...))
            $e
        end
        objective!($ocp, :mayer, $gs, $ttype)
    end, p.lnum, p.line)
end

p_bolza!(p, ocp, e1, e2, type; log=false) = begin
    log && println("objective: $e1 + ∫($e2) → $type")
    isnothing(p.x) && return __throw("state not yet declared", p.lnum, p.line)
    isnothing(p.t0) && return __throw("time not yet declared", p.lnum, p.line)
    isnothing(p.tf) && return __throw("time not yet declared", p.lnum, p.line)
    isnothing(p.u) && return __throw("control not yet declared", p.lnum, p.line)
    isnothing(p.t) && return __throw("time not yet declared", p.lnum, p.line)
    gs1 = gensym()
    x0 = gensym()
    xf = gensym()
    e1 = replace_call(e1, p.x, p.t0, x0)
    e1 = replace_call(e1, p.x, p.tf, xf)
    args1 = [ x0, xf ]; __v_dep(p) && push!(args1, p.v)
    gs2 = gensym()
    xt = gensym()
    ut = gensym()
    e2 = replace_call(e2, [ p.x, p.u ], p.t, [ xt, ut ])
    p.t_dep = p.t_dep || has(e2, p.t)
    args2 = [ ]; __t_dep(p) && push!(args2, p.t); push!(args2, xt, ut); __v_dep(p) && push!(args2, p.v)
    ttype = QuoteNode(type)
    __wrap(quote
        function $gs1($(args1...))
            $e1
        end
        function $gs2($(args2...))
            $e2
        end
        objective!($ocp, :bolza, $gs1, $gs2, $ttype)
    end, p.lnum, p.line)
end

"""
$(TYPEDSIGNATURES)

Define an optimal control problem. One pass parsing of the definition.

# Example
```jldoctest
@def ocp begin
    tf ∈ R, variable
    t ∈ [ 0, tf ], time
    x ∈ R², state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    q = x₁
    v = x₂
    q(0) == 1,    (1)
    v(0) == 2,    (2)
    q(tf) == 0
    v(tf) == 0
    ẋ(t) == [ v(t), u(t) ]
    tf → min
end
```
"""
macro def(ocp, e, log=false)
    try
        p0 = ParsingInfo()
	    parse!(p0, ocp, e; log=false)
        p = ParsingInfo(); p.t_dep = p0.t_dep; p.v = p0.v
	    code = parse!(p, ocp, e; log=log)
	    init = @match (__t_dep(p), __v_dep(p)) begin
            (false, false) => :( $ocp = Model() )
            (true , false) => :( $ocp = Model(autonomous=false) )
            (false, true ) => :( $ocp = Model(variable=true) )
            _              => :( $ocp = Model(autonomous=false, variable=true) )
	    end
        ee = QuoteNode(e)
        code = Expr(:block, init, code, :( $ocp.model_expression=$ee ), :( $ocp ))
        esc(code)
    catch ex
        :( throw($ex) ) # can be caught by user
    end
end
    
    
