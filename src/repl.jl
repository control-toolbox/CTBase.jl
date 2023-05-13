const ModelRepl = Dict{Symbol, Union{Expr, Vector{Expr}}}

@with_kw mutable struct HistoryRepl
    index::Int=0
    models::Vector{ModelRepl}=Vector{ModelRepl}()
end

@with_kw mutable struct CTRepl
    model::ModelRepl = __init_model_repl()
    history::HistoryRepl = __init_history_repl()
    solution::Union{OptimalControlSolution, Nothing} = nothing
    debug::Bool = false
    display_code::Bool = false
    display_model::Bool = false
    ocp_name::Symbol = gensym(:ocp)
    ocp::Union{OptimalControlModel, Nothing} = nothing
    code::Expr = :()
end

# update the model with a new expression of nature type
function __update!(model::ModelRepl, type::Symbol, e::Expr)
    @match type begin
        :alias => begin
            to_add = true
            @match e begin  # check if the alias is already defined
                :( $e1 = $e2 ) => begin
                    for i ∈ eachindex(model[:alias])
                        a = model[:alias][i]
                        @match a begin
                            :( $a1 = $a2 ) => ((a1 == e1) && ((model[:alias][i] = e); to_add = false))
                            _ => (println("\n Internal error, invalid alias: ", e); return)
                        end
                    end
                end
                _ => (println("\n Internal error, invalid alias: ", e); return)
            end
            to_add && push!(model[:alias], e) # add alias if it is not already defined
        end
        :constraints => (push!(model[type], e))
        :time || :state || :control || :variable || :dynamics || :objective => (model[type] = e)
        _ => (println("\n Internal error, invalid type: ", type); return)
    end
end

# split alias in two vectors: one for those appearing in model[:time] and the others
function __split_alias(model::ModelRepl)
    alias_time  = Expr[]
    alias_other = Expr[]
    for a ∈ model[:alias]
        @match a begin
            :( $a1 = $a2 ) => begin
                inexpr(model[:time], a1) ? push!(alias_time, a) : push!(alias_other, a)
            end
            _ => (println("\n Internal error, invalid alias: ", a); return)
        end
    end
    return alias_time, alias_other
end

# get code from model
function __code(model::ModelRepl)::Expr
    m = Expr[]
    alias_time, alias_other = __split_alias(model)
    !isempty(alias_time)       && push!(m, alias_time...)
    model[:time]        != :() && push!(m, model[:time])
    model[:state]       != :() && push!(m, model[:state])
    model[:control]     != :() && push!(m, model[:control])
    model[:variable]    != :() && push!(m, model[:variable])
    !isempty(alias_other)      && push!(m, alias_other...)
    model[:constraints] != []  && push!(m, model[:constraints]...)
    model[:dynamics]    != :() && push!(m, model[:dynamics])
    model[:objective]   != :() && push!(m, model[:objective])
    return Expr(:block, m...)
end

# add to model the new expression if it is valid, and then, update history
function __add!(ct_repl::CTRepl, type::Symbol, e::Expr)
    ct_repl.debug && (println("\ndebug> adding expression: ", e, " of type: ", type))
    try 
        ct_repl.code = __code(ct_repl.model, type, e)   # get code
        eval(quote @def $(ct_repl.ocp_name) $code end)  # test if code is valid: if not, an exception is thrown
        ct_repl.ocp = eval(ct_repl.ocp_name)            # get ocp
        __update!(ct_repl.model, type, e)               # update model if code is valid
        __add!(ct_repl.history, ct_repl.model)          # update history: model
        ct_repl.debug && (println("\ndebug> expression valid, model updated."))
    catch ex
        println("\nThe model can't be updated. The expression is not valid.")
        ct_replo.debug && (println("\ndebug> exception thrown: ", ex))
    end
end

function __init_repl(; debug=false)

    # init
    ct_repl = CTRepl()
    ct_repl.debug = debug

    # add initial model to history
    __add!(ct_repl.history, ct_repl.model)

    function parse_to_expr(s::AbstractString)

        # parse string
        e = Meta.parse(s)

        #
        ct_repl.debug && println("\ndebug> parsing string: ", s)
        ct_repl.debug && println("debug> expression parsed: ", e)

        # test if command
        @match e begin
            :( $command = $a ) => begin
                command = __get_command(command)
                ct_repl.debug && println("debug> command: ", command, " and argument: ", a)
                command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl, a))
            end
            :( $command ) => begin
                command = __get_command(command)
                ct_repl.debug && println("debug> command: ", command)
                command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl))
            end
            _ => nothing
        end

        # parse expression and update model
        @match e begin
            :( $e_, time                 ) => __add!(ct_repl, :time, e)
            :( $t ∈ [$a, $b]             ) => __add!(ct_repl, :time, :($t ∈ [$a, $b], time))
            :( $e_, state                ) => __add!(ct_repl, :state, e)
            :( $e_, control              ) => __add!(ct_repl, :control, e)
            :( $x, $u ∈ $X, $U ) || :( ($x, $u) ∈ $X × $U ) || :( ($x, $u) ∈ $X * $U )=> begin
                __add!(ct_repl, :state, :($x ∈ $X, state))
                __add!(ct_repl, :control, :($u ∈ $U, control))
            end
            :( $e_, variable             ) => __add!(ct_repl, :variable, e)
            :( $x, $u, $v ∈ $X, $U, $V ) || :( ($x, $u, $v) ∈ $X × $U × $V ) || :( ($x, $u, $v) ∈ $X * $U * $V )=> begin
                __add!(ct_repl, :state, :($x ∈ $X, state))
                __add!(ct_repl, :control, :($u ∈ $U, control))
                __add!(ct_repl, :variable, :($v ∈ $V, variable))
            end
            :( $a = $e1                  ) => __add!(ct_repl, :alias, e)
            :( ∂($x)($t) == $e1          ) => __add!(ct_repl, :dynamics, e)
            :( ∂($x)($t) == $e1, $label  ) => __add!(ct_repl, :dynamics, e)
            :( $e1 == $e2                ) => __add!(ct_repl, :constraints, e)
            :( $e1 == $e2, $label        ) => __add!(ct_repl, :constraints, e)
            :( $e1 ≤  $e2 ≤  $e3         ) => __add!(ct_repl, :constraints, e)
            :( $e1 ≤  $e2 ≤  $e3, $label ) => __add!(ct_repl, :constraints, e)
            :( $e_ → min                 ) => __add!(ct_repl, :objective, e)
            :( $e_ → max                 ) => __add!(ct_repl, :objective, e)
            _ => (println("ct parsing error."); return :())
        end

        ct_repl.display_code && ( ct_repl.display_model ? __println_code(ct_repl.code) : __print_code(ct_repl.code) )
        return ct_repl.display_model ? ct_repl.code : :()

    end

    initrepl(parse_to_expr,
            prompt_text="ct> ",
            prompt_color = :magenta,
            start_key='>',
            mode_name="ct_mode",
            valid_input_checker=complete_julia,
            startup_text=false)

end

# ----------------------------------------------------------------  
# utils functions

function __get_command(c::Symbol)::Symbol

    # split c in parts
    v = split(string(c), "£")
    
    if v[1] == ""
        # if c start with £ and has only one more character, use COMMANDS_KEYS
        length(v[2]) == 1 && return COMMANDS_KEYS[c]
        # if c start with £ and has more than one character, returns the associated command
        length(v[2]) > 1 && return Symbol(uppercase(v[2]))
    else
        # if c does not start with £, returns c
        return c
    end

end

COMMANDS_KEYS = Dict{Symbol, Symbol}(
    :£s => :SOLVE,
    :£p => :PLOT,
    :£d => :DEBUG,
    :£h => :SHOW,
    :£m => :SHOW_MODEL,
    :£c => :SHOW_CODE,
    :£n => :NAME,
    :£u => :UNDO,
    :£r => :REDO,
    :£h => :HELP
)

#
COMMANDS_ACTIONS = Dict{Symbol, Function}(
    :SOLVE => (ct_repl::CTRepl) -> begin
        ct_repl.solution = __solve()
        print("\n solved.")
        return :($ct_repl.solution)
    end,
    :PLOT => (ct_repl::CTRepl) -> begin
        return !isnothing(ct_repl.solution) ? :(plot($ct_repl.solution, size=(700, 600))) : :(println("\nNo solution available."))
    end,
    :DEBUG => (ct_repl::CTRepl) -> begin
        ct_repl.debug = !ct_repl.debug
        print("\n debug mode: " * (ct_repl.debug ? "on" : "off"))
        return :()
    end,
    :SHOW => (ct_repl::CTRepl) -> begin
        ct_repl.display_model = !ct_repl.display_model
        ct_repl.display_code = !ct_repl.display_code
        print("\n display model: " * (ct_repl.display_model ? "on" : "off"))
        print("\n display code:  " * (ct_repl.display_code ? "on" : "off"))
        return :()
    end,
    :SHOW_MODEL => (ct_repl::CTRepl) -> begin
        ct_repl.display_model = !ct_repl.display_model
        print("\n display model: " * (ct_repl.display_model ? "on" : "off"))
        return :()
    end,
    :SHOW_CODE => (ct_repl::CTRepl) -> begin
        ct_repl.display_code = !ct_repl.display_code
        print("\n display code: " * (ct_repl.display_code ? "on" : "off"))
        return :()
    end,
    :NAME => (ct_repl::CTRepl, name::Symbol) -> begin
        ct_repl.ocp_name = name
        print("\n ocp name: ", ct_repl.ocp_name)
        return :()
    end,
    :UNDO => (ct_repl::CTRepl) -> begin
        ct_repl.model = __undo!(ct_repl.history)
        ct_repl.display_code && __print_code(__code(ct_repl.model))
        return :()
    end,
    :REDO => (ct_repl::CTRepl) -> begin
        ct_repl.model = __redo!(ct_repl.history)
        ct_repl.display_code && __print_code(__code(ct_repl.model))
        return :()
    end,
    :HELP => (ct_repl::CTRepl) -> begin
        println("\nCommands:\n")
        dict = sort(collect(COMMANDS_HELPS), by = x->x[1])
        for (k, v) ∈ dict
            println("  ", k, ": ", v)
        end
        return :()
    end,
)

COMMANDS_HELPS = Dict{Symbol, String}(
    :SOLVE => "solve the optimal control problem",
    :PLOT => "plot the solution",
    :DEBUG => "toggle debug mode",
    :SHOW => "toggle display mode",
    :SHOW_MODEL => "toggle display model",
    :SHOW_CODE => "toggle display code",
    :NAME => "set the name of the optimal control problem",
    :UNDO => "undo the last command",
    :REDO => "redo the last command",
    :HELP => "show this help"
)

# print code
function __print_code(code)
    print("\nocp = ", code)
end

# print code and add a new line
function __println_code(code)
    __print_code(code)
    println()
end

# create an empty model
function __init_model_repl()
    model = ModelRepl()
    model[:time]        = :()
    model[:state]       = :()
    model[:control]     = :()
    model[:variable]    = :()
    model[:dynamics]    = :()
    model[:objective]   = :()
    model[:constraints] = Expr[]
    model[:alias]       = Expr[]
    return model
end

# create an empty history
__init_history_repl() = HistoryRepl(0, Vector{ModelRepl}())

# get code from model and an expression
function __code(model::ModelRepl, type::Symbol, e::Expr)
    model_ = deepcopy(model)    # copy model
    __update!(model_, type, e)  # update model_
    return __code(model_)       # get code
end

# add model to history
function __add!(history::HistoryRepl, model::ModelRepl)
    push!(history.models, deepcopy(model))
    history.index += 1
end

# go to previous model in history
function __undo!(history::HistoryRepl)
    history.index > 1 && (history.index -= 1)
    return history.models[history.index]
end

# go to next model in history
function __redo!(history::HistoryRepl)
    history.index < length(history.models) && (history.index += 1)
    return history.models[history.index]
end

function __solve()

    # create a solution
    n=2
    m=1
    t0=0.0
    tf=1.0
    x0=[-1.0, 0.0]
    xf=[0.0, 0.0]
    a = x0[1]
    b = x0[2]
    C = [-(tf-t0)^3/6.0 (tf-t0)^2/2.0
        -(tf-t0)^2/2.0 (tf-t0)]
    D = [-a-b*(tf-t0), -b]+xf
    p0 = C\D
    α = p0[1]
    β = p0[2]
    x(t) = [a+b*(t-t0)+β*(t-t0)^2/2.0-α*(t-t0)^3/6.0, b+β*(t-t0)-α*(t-t0)^2/2.0]
    p(t) = [α, -α*(t-t0)+β]
    u(t) = [p(t)[2]]
    objective = 0.5*(α^2*(tf-t0)^3/3+β^2*(tf-t0)-α*β*(tf-t0)^2)
    #
    N=201
    times = range(t0, tf, N)
    #

    sol = OptimalControlSolution()
    sol.state_dimension = n
    sol.control_dimension = m
    sol.times = times
    sol.time_name="t"
    sol.state = x
    sol.state_name = "x"
    sol.state_components_names = [ "x" * ctindices(i) for i ∈ range(1, n)]
    sol.costate = p
    sol.control = u
    sol.control_name = "u"
    sol.control_components_names = [ "u" ]
    sol.objective = objective
    sol.iterations = 0
    sol.stopping = :dummy
    sol.message = "ceci est un test"
    sol.success = true

    sleep(4)

    return sol

end