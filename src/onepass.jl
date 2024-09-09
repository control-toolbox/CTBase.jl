# onepass
# todo:
# - cannot call solve if problem not fully defined (dynamics not defined...)
# - doc: explain projections wrt to t0, tf, t; (...x1...x2...)(t) -> ...gensym1...gensym2... (most internal first)
# - test non autonomous cases
# - robustify repl
# - additional checks: when generating functions (constraints, dynamics, costs), there should not be any x or u left
#   (but the user might indeed do so); meaning that has(ee, x/u/t) must be false (postcondition)
# - tests exceptions (parsing and semantics/runtime)
# - add assert for pre/post conditions and invariants
# - add tests on ParsingError + run time errors (wrapped in try ... catch's - use string to be precise)
# - currently "t ∈ [ 0+0, 1 ], time" is allowed, and compels to declare "x(0+0) == ..."

"""
$(TYPEDEF)

**Fields**

"""
@with_kw mutable struct ParsingInfo
    v::Union{Symbol, Nothing} = nothing
    t::Union{Symbol, Nothing} = nothing
    t0::Union{Real, Symbol, Expr, Nothing} = nothing
    tf::Union{Real, Symbol, Expr, Nothing} = nothing
    x::Union{Symbol, Nothing} = nothing
    u::Union{Symbol, Nothing} = nothing
    aliases::OrderedDict{Symbol, Union{Real, Symbol, Expr}} = __init_aliases()
    lnum::Integer = 0
    line::String = ""
    t_dep::Bool = false
end

__init_aliases(; max_dim = 20) = begin
    al = OrderedDict{Symbol, Union{Real, Symbol, Expr}}()
    for i ∈ 1:max_dim
        al[Symbol(:R, ctupperscripts(i))] = :(R^$i)
    end
    al[:<=] = :≤
    al[:>=] = :≥
    al[:derivative] = :∂
    al[:integral] = :∫
    al[:(=>)] = :→
    al[:in] = :∈
    al
end

__throw(ex, n, line) = quote
    local info
    info = string("\nLine ", $n, ": ", $line)
    throw(ParsingError(info * "\n" * $ex))
end

__wrap(e, n, line) = quote
    local ex
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

Parse the expression `e` and update the `ParsingInfo` structure `p`.

# Example
```@example
parse!(p, :ocp, :(v ∈ R, variable))
```
"""
parse!(p, ocp, e; log = false) = begin
    #
    p.lnum = p.lnum + 1
    p.line = string(e)
    for a ∈ keys(p.aliases)
        e = subs(e, a, p.aliases[a])
    end
    #
    @match e begin
        # aliases
        :($a = $e1) => @match e1 begin
            :(($names) ∈ R^$q, variable) => p_variable!(p, ocp, a, q; components_names = names, log)
            :([$names] ∈ R^$q, variable) =>
                p_variable!(p, ocp, a, q; components_names = names, log)
            :(($names) ∈ R^$n, state) => p_state!(p, ocp, a, n; components_names = names, log)
            :([$names] ∈ R^$n, state) => p_state!(p, ocp, a, n; components_names = names, log)
            :(($names) ∈ R^$m, control) =>
                p_control!(p, ocp, a, m; components_names = names, log)
            :([$names] ∈ R^$m, control) =>
                p_control!(p, ocp, a, m; components_names = names, log)
            _ => p_alias!(p, ocp, a, e1; log) # alias
        end
        # variable                    
        :($v ∈ R^$q, variable) => p_variable!(p, ocp, v, q; log)
        :($v ∈ R, variable) => p_variable!(p, ocp, v, 1; log)
        # time                        
        :($t ∈ [$t0, $tf], time) => p_time!(p, ocp, t, t0, tf; log)
        # state                       
        :($x ∈ R^$n, state) => p_state!(p, ocp, x, n; log)
        :($x ∈ R, state) => p_state!(p, ocp, x, 1; log)
        # control                     
        :($u ∈ R^$m, control) => p_control!(p, ocp, u, m; log)
        :($u ∈ R, control) => p_control!(p, ocp, u, 1; log)
        # dynamics                    
        :(∂($x)($t) == $e1) => p_dynamics!(p, ocp, x, t, e1; log)
        :(∂($x)($t) == $e1, $label) => p_dynamics!(p, ocp, x, t, e1, label; log)
        # constraints                 
        :($e1 == $e2) => p_constraint!(p, ocp, e2, e1, e2; log)
        :($e1 == $e2, $label) => p_constraint!(p, ocp, e2, e1, e2, label; log)
        :($e1 ≤ $e2 ≤ $e3) => p_constraint!(p, ocp, e1, e2, e3; log)
        :($e1 ≤ $e2 ≤ $e3, $label) => p_constraint!(p, ocp, e1, e2, e3, label; log)
        :($e2 ≤ $e3) => p_constraint!(p, ocp, nothing, e2, e3; log)
        :($e2 ≤ $e3, $label) => p_constraint!(p, ocp, nothing, e2, e3, label; log)
        :($e3 ≥ $e2 ≥ $e1) => p_constraint!(p, ocp, e1, e2, e3; log)
        :($e3 ≥ $e2 ≥ $e1, $label) => p_constraint!(p, ocp, e1, e2, e3, label; log)
        :($e2 ≥ $e1) => p_constraint!(p, ocp, e1, e2, nothing; log)
        :($e2 ≥ $e1, $label) => p_constraint!(p, ocp, e1, e2, nothing, label; log)
        # lagrange cost
        :(∫($e1) → min) => p_lagrange!(p, ocp, e1, :min; log)
        :(-∫($e1) → min) => p_lagrange!(p, ocp, :(-$e1), :min; log)
        :($e1 * ∫($e2) → min) =>
            has(e1, p.t) ?
            (return __throw("time $(p.t) must not appear in $e1", p.lnum, p.line)) :
            p_lagrange!(p, ocp, :($e1 * $e2), :min; log)
        :(∫($e1) → max) => p_lagrange!(p, ocp, e1, :max; log)
        :(-∫($e1) → max) => p_lagrange!(p, ocp, :(-$e1), :max; log)
        :($e1 * ∫($e2) → max) =>
            has(e1, p.t) ?
            (return __throw("time $(p.t) must not appear in $e1", p.lnum, p.line)) :
            p_lagrange!(p, ocp, :($e1 * $e2), :max; log)
        # bolza cost
        :($e1 + ∫($e2) → min) => p_bolza!(p, ocp, e1, e2, :min; log)
        :($e1 + $e2 * ∫($e3) → min) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, e1, :($e2 * $e3), :min; log)
        :($e1 - ∫($e2) → min) => p_bolza!(p, ocp, e1, :(-$e2), :min; log)
        :($e1 - $e2 * ∫($e3) → min) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, e1, :(-$e2 * $e3), :min; log)
        :($e1 + ∫($e2) → max) => p_bolza!(p, ocp, e1, e2, :max; log)
        :($e1 + $e2 * ∫($e3) → max) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, e1, :($e2 * $e3), :max; log)
        :($e1 - ∫($e2) → max) => p_bolza!(p, ocp, e1, :(-$e2), :max; log)
        :($e1 - $e2 * ∫($e3) → max) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, e1, :(-$e2 * $e3), :max; log)
        :(∫($e2) + $e1 → min) => p_bolza!(p, ocp, e1, e2, :min; log)
        :($e2 * ∫($e3) + $e1 → min) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, e1, :($e2 * $e3), :min; log)
        :(∫($e2) - $e1 → min) => p_bolza!(p, ocp, :(-$e1), e2, :min; log)
        :($e2 * ∫($e3) - $e1 → min) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, :(-$e1), :($e2 * $e3), :min; log)
        :(∫($e2) + $e1 → max) => p_bolza!(p, ocp, e1, e2, :max; log)
        :($e2 * ∫($e3) + $e1 → max) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, e1, :($e2 * $e3), :max; log)
        :(∫($e2) - $e1 → max) => p_bolza!(p, ocp, :(-$e1), e2, :max; log)
        :($e2 * ∫($e3) - $e1 → max) =>
            has(e2, p.t) ?
            (return __throw("time $(p.t) must not appear in $e2", p.lnum, p.line)) :
            p_bolza!(p, ocp, :(-$e1), :($e2 * $e3), :max; log)
        # mayer cost
        :($e1 → min) => p_mayer!(p, ocp, e1, :min; log)
        :($e1 → max) => p_mayer!(p, ocp, e1, :max; log)
        #
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
            end
        end
    end
end

p_variable!(p, ocp, v, q; components_names = nothing, log = false) = begin
    log && println("variable: $v, dim: $q")
    v isa Symbol || return __throw("forbidden variable name: $v", p.lnum, p.line)
    p.v = v
    vv = QuoteNode(v)
    qq = q isa Integer ? q : 9
    for i ∈ 1:qq
        p.aliases[Symbol(v, ctindices(i))] = :($v[$i])
    end # make: v₁, v₂... if the variable is named v
    for i ∈ 1:qq
        p.aliases[Symbol(v, i)] = :($v[$i])
    end # make: v1, v2... if the variable is named v
    for i ∈ 1:9
        p.aliases[Symbol(v, ctupperscripts(i))] = :($v^$i)
    end # make: v¹, v²... if the variable is named v
    if (isnothing(components_names))
        code = :( variable!($ocp, $q, $vv) )
    else
        qq == length(components_names.args) ||
            return __throw("the number of variable components must be $qq", p.lnum, p.line)
        for i ∈ 1:qq
            p.aliases[components_names.args[i]] = :($v[$i])
        end # aliases from names given by the user
        ss = QuoteNode(string.(components_names.args))
        code = :( variable!($ocp, $q, $vv, $ss) )
    end
    return __wrap(code, p.lnum, p.line) 
end

p_alias!(p, ocp, a, e; log = false) = begin
    log && println("alias: $a = $e")
    a isa Symbol || return __throw("forbidden alias name: $a", p.lnum, p.line)
    aa = QuoteNode(a)
    ee = QuoteNode(e)
    for i ∈ 1:9
        p.aliases[Symbol(a, ctupperscripts(i))] = :($a^$i)
    end
    p.aliases[a] = e
    code = :( LineNumberNode(0, "alias: " * string($aa) * " = " * string($ee)) )
    return __wrap(code, p.lnum, p.line)
end

p_time!(p, ocp, t, t0, tf; log = false) = begin
    log && println("time: $t, initial time: $t0, final time: $tf")
    t isa Symbol || return __throw("forbidden time name: $t", p.lnum, p.line)
    p.t = t
    p.t0 = t0
    p.tf = tf
    tt = QuoteNode(t)
    code = @match (has(t0, p.v), has(tf, p.v)) begin
        (false, false) => :(time!($ocp; t0 = $t0, tf = $tf, name = $tt))
        (true, false) => @match t0 begin
            :($v1[$i]) && if (v1 == p.v)
            end => :(time!($ocp; ind0 = $i, tf = $tf, name = $tt))
            :($v1) && if (v1 == p.v)
            end => quote
                ($ocp.variable_dimension ≠ 1) && throw(
                    IncorrectArgument("variable must be of dimension one for a time"),
                )
                time!($ocp; ind0 = 1, tf = $tf, name = $tt)
            end
            _ => return __throw("bad time declaration", p.lnum, p.line)
        end
        (false, true) => @match tf begin
            :($v1[$i]) && if (v1 == p.v)
            end => :(time!($ocp; t0 = $t0, indf = $i, name = $tt))
            :($v1) && if (v1 == p.v)
            end => quote
                ($ocp.variable_dimension ≠ 1) && throw(
                    IncorrectArgument("variable must be of dimension one for a time"),
                )
                time!($ocp; t0 = $t0, indf = 1, name = $tt)
            end
            _ => return __throw("bad time declaration", p.lnum, p.line)
        end
        _ => @match (t0, tf) begin
            (:($v1[$i]), :($v2[$j])) && if (v1 == v2 == p.v)
            end => :(time!($ocp; ind0 = $i, indf = $j, name = $tt))
            _ => return __throw("bad time declaration", p.lnum, p.line)
        end
    end
    return __wrap(code, p.lnum, p.line)
end

p_state!(p, ocp, x, n; components_names = nothing, log = false) = begin
    log && println("state: $x, dim: $n")
    x isa Symbol || return __throw("forbidden state name: $x", p.lnum, p.line)
    p.x = x
    xx = QuoteNode(x)
    nn = n isa Integer ? n : 9
    for i ∈ 1:nn
        p.aliases[Symbol(x, ctindices(i))] = :($x[$i])
    end # Make x₁, x₂... if the state is named x
    for i ∈ 1:nn
        p.aliases[Symbol(x, i)] = :($x[$i])
    end # Make x1, x2... if the state is named x
    for i ∈ 1:9
        p.aliases[Symbol(x, ctupperscripts(i))] = :($x^$i)
    end # Make x¹, x²... if the state is named x
    p.aliases[Symbol(Unicode.normalize(string(x, "̇")))] = :(∂($x))
    if (isnothing(components_names))
        code = :( state!($ocp, $n, $xx) )
    else
        nn == length(components_names.args) ||
            return __throw("the number of state components must be $nn", p.lnum, p.line)
        for i ∈ 1:nn
            p.aliases[components_names.args[i]] = :($x[$i])
            # todo: add aliases for state components (scalar) derivatives
        end # Aliases from names given by the user
        ss = QuoteNode(string.(components_names.args))
        code = :( state!($ocp, $n, $xx, $ss) )
    end
    return __wrap(code, p.lnum, p.line)
end

p_control!(p, ocp, u, m; components_names = nothing, log = false) = begin
    log && println("control: $u, dim: $m")
    u isa Symbol || return __throw("forbidden control name: $u", p.lnum, p.line)
    p.u = u
    uu = QuoteNode(u)
    mm = m isa Integer ? m : 9
    for i ∈ 1:mm
        p.aliases[Symbol(u, ctindices(i))] = :($u[$i])
    end # make: u₁, u₂... if the control is named u
    for i ∈ 1:mm
        p.aliases[Symbol(u, i)] = :($u[$i])
    end # make: u1, u2... if the control is named u
    for i ∈ 1:9
        p.aliases[Symbol(u, ctupperscripts(i))] = :($u^$i)
    end # make: u¹, u²... if the control is named u
    if (isnothing(components_names))
        code = :( control!($ocp, $m, $uu) )
    else
        mm == length(components_names.args) ||
            return __throw("the number of control components must be $mm", p.lnum, p.line)
        for i ∈ 1:mm
            p.aliases[components_names.args[i]] = :($u[$i])
        end # aliases from names given by the user
        ss = QuoteNode(string.(components_names.args))
        code = :( control!($ocp, $m, $uu, $ss) )
    end
    return __wrap(code, p.lnum, p.line)
end

p_constraint!(p, ocp, e1, e2, e3, label = gensym(); log = false) = begin
    c_type = constraint_type(e2, p.t, p.t0, p.tf, p.x, p.u, p.v)
    log && println("constraint ($c_type): $e1 ≤ $e2 ≤ $e3,    ($label)")
    label isa Integer && (label = Symbol(:eq, label))
    label isa Symbol || return __throw("forbidden label: $label", p.lnum, p.line)
    llabel = QuoteNode(label)
    code = @match c_type begin
        (:initial, rg) =>
            :(constraint!($ocp, :initial; rg = $rg, lb = $e1, ub = $e3, label = $llabel))
        (:final, rg) =>
            :(constraint!($ocp, :final; rg = $rg, lb = $e1, ub = $e3, label = $llabel))
        :boundary => begin
            gs = gensym()
            x0 = gensym()
            xf = gensym()
            r = gensym()
            ee2 = replace_call(e2, p.x, p.t0, x0)
            ee2 = replace_call(ee2, p.x, p.tf, xf)
            args = [r, x0, xf]
            __v_dep(p) && push!(args, p.v)
            quote
                function $gs($(args...))
                    @views $r[:] .= $ee2
                    return nothing
                end
                constraint!($ocp, :boundary; f = $gs, lb = $e1, ub = $e3, label = $llabel)
            end
        end
        (:control_range, rg) =>
            :(constraint!($ocp, :control; rg = $rg, lb = $e1, ub = $e3, label = $llabel))
        :control_fun => begin
            gs = gensym()
            ut = gensym()
            r = gensym()
            ee2 = replace_call(e2, p.u, p.t, ut)
            p.t_dep = p.t_dep || has(ee2, p.t)
            args = [r]
            __t_dep(p) && push!(args, p.t)
            push!(args, ut)
            __v_dep(p) && push!(args, p.v)
            quote
                function $gs($(args...))
                    @views $r[:] .= $ee2
                    return nothing
                end
                constraint!($ocp, :control; f = $gs, lb = $e1, ub = $e3, label = $llabel)
            end
        end
        (:state_range, rg) =>
            :(constraint!($ocp, :state; rg = $rg, lb = $e1, ub = $e3, label = $llabel))
        :state_fun => begin
            gs = gensym()
            xt = gensym()
            r = gensym()
            ee2 = replace_call(e2, p.x, p.t, xt)
            p.t_dep = p.t_dep || has(ee2, p.t)
            args = [r]
            __t_dep(p) && push!(args, p.t)
            push!(args, xt)
            __v_dep(p) && push!(args, p.v)
            quote
                function $gs($(args...))
                    @views $r[:] .= $ee2
                    return nothing
                end
                constraint!($ocp, :state; f = $gs, lb = $e1, ub = $e3, label = $llabel)
            end
        end
        (:variable_range, rg) =>
            :(constraint!($ocp, :variable; rg = $rg, lb = $e1, ub = $e3, label = $llabel))
        :variable_fun => begin
            gs = gensym()
            r = gensym()
            args = [r, p.v]
            quote
                function $gs($(args...))
                    @views $r[:] .= $e2
                    return nothing
                end
                constraint!($ocp, :variable; f = $gs, lb = $e1, ub = $e3, label = $llabel)
            end
        end
        :mixed => begin
            gs = gensym()
            xt = gensym()
            ut = gensym()
            r = gensym()
            ee2 = replace_call(e2, [p.x, p.u], p.t, [xt, ut])
            p.t_dep = p.t_dep || has(ee2, p.t)
            args = [r]
            __t_dep(p) && push!(args, p.t)
            push!(args, xt, ut)
            __v_dep(p) && push!(args, p.v)
            quote
                function $gs($(args...))
                    @views $r[:] .= $ee2
                    return nothing
                end
                constraint!($ocp, :mixed; f = $gs, lb = $e1, ub = $e3, label = $llabel)
            end
        end
        _ => return __throw("bad constraint declaration", p.lnum, p.line)
    end
    return __wrap(code, p.lnum, p.line)
end

p_dynamics!(p, ocp, x, t, e, label = nothing; log = false) = begin
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
    e = replace_call(e, [p.x, p.u], p.t, [xt, ut])
    p.t_dep = p.t_dep || has(e, t)
    gs = gensym()
    r = gensym()
    args = [r]; __t_dep(p) && push!(args, p.t); push!(args, xt, ut); __v_dep(p) && push!(args, p.v)
    code = quote
        function $gs($(args...))
            @views $r[:] .= $e
            return nothing
        end
        dynamics!($ocp, $gs)
    end
    return __wrap(code, p.lnum, p.line)
end

p_lagrange!(p, ocp, e, type; log = false) = begin
    log && println("objective (Lagrange): ∫($e) → $type")
    isnothing(p.x) && return __throw("state not yet declared", p.lnum, p.line)
    isnothing(p.u) && return __throw("control not yet declared", p.lnum, p.line)
    isnothing(p.t) && return __throw("time not yet declared", p.lnum, p.line)
    xt = gensym()
    ut = gensym()
    e = replace_call(e, [p.x, p.u], p.t, [xt, ut])
    p.t_dep = p.t_dep || has(e, p.t)
    ttype = QuoteNode(type)
    gs = gensym()
    r = gensym()
    args = [r]; __t_dep(p) && push!(args, p.t); push!(args, xt, ut); __v_dep(p) && push!(args, p.v)
    code = quote
        function $gs($(args...))
            @views $r[:] .= $e
            return nothing
        end
        objective!($ocp, :lagrange, $gs, $ttype)
    end
    return __wrap(code, p.lnum, p.line)
end

p_mayer!(p, ocp, e, type; log = false) = begin
    log && println("objective (Mayer): $e → $type")
    isnothing(p.x) && return __throw("state not yet declared", p.lnum, p.line)
    isnothing(p.t0) && return __throw("time not yet declared", p.lnum, p.line)
    isnothing(p.tf) && return __throw("time not yet declared", p.lnum, p.line)
    has(e, :∫) && return __throw(
        "bad objective declaration resulting in a Mayer term with trailing ∫",
        p.lnum,
        p.line,
    )
    gs = gensym()
    x0 = gensym()
    xf = gensym()
    r = gensym()
    e = replace_call(e, p.x, p.t0, x0)
    e = replace_call(e, p.x, p.tf, xf)
    ttype = QuoteNode(type)
    args = [r, x0, xf]; __v_dep(p) && push!(args, p.v)
    code = quote
        function $gs($(args...))
            @views $r[:] .= $e
            return nothing
        end
        objective!($ocp, :mayer, $gs, $ttype)
    end
    return __wrap(code, p.lnum, p.line)
end

p_bolza!(p, ocp, e1, e2, type; log = false) = begin
    log && println("objective (Bolza): $e1 + ∫($e2) → $type")
    isnothing(p.x) && return __throw("state not yet declared", p.lnum, p.line)
    isnothing(p.t0) && return __throw("time not yet declared", p.lnum, p.line)
    isnothing(p.tf) && return __throw("time not yet declared", p.lnum, p.line)
    isnothing(p.u) && return __throw("control not yet declared", p.lnum, p.line)
    isnothing(p.t) && return __throw("time not yet declared", p.lnum, p.line)
    gs1 = gensym()
    x0 = gensym()
    xf = gensym()
    r1 = gensym()
    e1 = replace_call(e1, p.x, p.t0, x0)
    e1 = replace_call(e1, p.x, p.tf, xf)
    args1 = [r1, x0, xf]
    __v_dep(p) && push!(args1, p.v)
    gs2 = gensym()
    xt = gensym()
    ut = gensym()
    r2 = gensym()
    e2 = replace_call(e2, [p.x, p.u], p.t, [xt, ut])
    p.t_dep = p.t_dep || has(e2, p.t)
    args2 = [r2]
    __t_dep(p) && push!(args2, p.t)
    push!(args2, xt, ut)
    __v_dep(p) && push!(args2, p.v)
    ttype = QuoteNode(type)
    code = quote
        function $gs1($(args1...))
            $r1[:] .= $e1
            return nothing
        end
        function $gs2($(args2...))
            $r2[:] .= $e2
            return nothing
        end
        objective!($ocp, :bolza, $gs1, $gs2, $ttype)
    end
    return __wrap(code, p.lnum, p.line)
end

"""
$(TYPEDSIGNATURES)

Redirection to [`Model`](@ref) to avoid confusion with other functions Model from other packages
if imported. This function is used by [`@def`](@ref).

"""
function __OCPModel(args...; kwargs...)
    return CTBase.Model(args...; kwargs...)
end

"""
$(TYPEDSIGNATURES)

Define an optimal control problem. One pass parsing of the definition. Can be used writing either
`ocp = @def begin ... end` or `@def ocp begin ... end`. In the second case, setting `log` to `true`
will display the parsing steps.

# Example
```@example
ocp = @def begin
    tf ∈ R, variable
    t ∈ [ 0, tf ], time
    x ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1
    q = x₁
    v = x₂
    q(0) == 1
    v(0) == 2
    q(tf) == 0
    v(tf) == 0
    0 ≤ q(t) ≤ 5,       (1)
    -2 ≤ v(t) ≤ 3,      (2)
    ẋ(t) == [ v(t), u(t) ]
    tf → min
end

@def ocp begin
    tf ∈ R, variable
    t ∈ [ 0, tf ], time
    x ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1
    q = x₁
    v = x₂
    q(0) == 1
    v(0) == 2
    q(tf) == 0
    v(tf) == 0
    0 ≤ q(t) ≤ 5,       (1)
    -2 ≤ v(t) ≤ 3,      (2)
    ẋ(t) == [ v(t), u(t) ]
    tf → min
end true # final boolean to show parsing log
```
"""
macro def(e)
    ocp = gensym()
    code = quote
        @def $ocp $e
        $ocp
    end
    esc(code)
end

macro def(ocp, e, log = false)
    try
        p0 = ParsingInfo()
        parse!(p0, ocp, e; log = false) # initial pass to get the dependencies (time and variable)
        p = ParsingInfo()
        p.t_dep = p0.t_dep
        p.v = p0.v
        code = parse!(p, ocp, e; log = log)
        in_place = true # todo: remove?
        init = @match (__t_dep(p), __v_dep(p)) begin
            (false, false) => :($ocp = __OCPModel(; in_place = $in_place))
            (true, false) => :($ocp = __OCPModel(autonomous = false; in_place = $in_place))
            (false, true) => :($ocp = __OCPModel(variable = true; in_place = $in_place))
            _ => :($ocp = __OCPModel(autonomous = false, variable = true; in_place = $in_place))
        end
        ee = QuoteNode(e)
        code = Expr(:block, init, code, :($ocp.model_expression = $ee; $ocp))
        esc(code)
    catch ex
        :(throw($ex)) # can be caught by user
    end
end