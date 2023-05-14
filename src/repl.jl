const ModelRepl = Dict{Symbol, Union{Expr, Vector{Expr}}}

@with_kw mutable struct CTRepl
    model::ModelRepl = __init_model_repl()
    ocp_name::Symbol = gensym(:ocp)
    sol_name::Symbol = gensym(:sol)
    debug::Bool = false
    __demo::Union{Nothing, Bool} = nothing
end

@with_kw mutable struct HistoryRepl
    index::Int=0
    ct_repls::Vector{CTRepl}=Vector{CTRepl}()
end

# add to model the new expression if it is valid, and then, update history
function __add!(ct_repl::CTRepl, type::Symbol, e::Expr, history::HistoryRepl)
    ct_repl.debug && (println("debug> adding expression: ", e, " of type: ", type))
    try 
        __eval_ocp(ct_repl)               # test if code is valid: if not, an exception is thrown
        __update!(ct_repl.model, type, e) # update model
        __add!(history, ct_repl)          # add ct_repl to history
        ct_repl.debug && (println("debug> expression valid, model updated."))
    catch ex
        println("\nThe model can't be updated. The expression is not valid.")
        ct_repl.debug && (println("debug> exception thrown: ", ex))
    end
end

function __init_repl(; debug=false, demo=false)

    # init: ct_repl, history
    ct_repl = CTRepl()
    ct_repl.debug = debug
    ct_repl.__demo = demo
    history::HistoryRepl = HistoryRepl(0, Vector{ModelRepl}())

    # if demo, print a message
    demo && println("\nWelcome to the demo of the ct REPL.\n")

    # advice to start by setting the name of the ocp and the solution
    println("To start, you should set the name of the optimal control problem and the name of the solution.")
    println("For example, you can type:\n")
    println("    ct> NAME=(ocp, sol)\n")

    # add initial ct_repl to history
    __add!(history, ct_repl)

    function parse_to_expr(s::AbstractString)
        
        # remove spaces from s at the beginning and at the end
        s = strip(s)

        # check if it is a comment
        startswith(s, "#") && return nothing

        # parse string
        e = Meta.parse(s)

        #
        ct_repl.debug && println("\ndebug> parsing string: ", s)
        ct_repl.debug && println("debug> expression parsed: ", e)
        ct_repl.debug && println("debug> expression type: ", typeof(e))
        ct_repl.debug && println("debug> dump of expression: ", dump(e))

        # test if e is a command
        @match e begin
            :( $c = $a ) => begin
                command = __transform_to_command_form(c)
                ct_repl.debug && println("debug> command: ", command, " and argument: ", a)
                command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl, a, history))
            end
            :( $c ) => begin
                command = __transform_to_command_form(c)
                ct_repl.debug && println("debug> command: ", command)
                command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl, history))
            end
            _ => nothing
        end

        # check if s finishes with a ";". If yes then remove it and return nothing at the end
        return_nothing = endswith(s, ";") ? true : false
        return_nothing && (s = s[1:end-1])
        e = Meta.parse(s)

        #
        return_nothing && ct_repl.debug && println("\ndebug> new parsing string: ", s)
        return_nothing && ct_repl.debug && println("debug> new expression parsed: ", e)

        # parse e and update ct_repl if needed
        @match e begin
            :( $e_, time                 ) => __add!(ct_repl, :time, e, history)
            :( $t ∈ [$a, $b]             ) => __add!(ct_repl, :time, :($t ∈ [$a, $b], time), history)
            :( $e_, state                ) => __add!(ct_repl, :state, e, history)
            :( $e_, control              ) => __add!(ct_repl, :control, e, history)
            :( $x, $u ∈ $X, $U ) || :( ($x, $u) ∈ $X × $U ) || :( ($x, $u) ∈ $X * $U )=> begin
                __add!(ct_repl, :state, :($x ∈ $X, state), history)
                __add!(ct_repl, :control, :($u ∈ $U, control), history)
            end
            :( $e_, variable             ) => __add!(ct_repl, :variable, e, history)
            :( $x, $u, $v ∈ $X, $U, $V ) || :( ($x, $u, $v) ∈ $X × $U × $V ) || :( ($x, $u, $v) ∈ $X * $U * $V )=> begin
                __add!(ct_repl, :state, :($x ∈ $X, state), history)
                __add!(ct_repl, :control, :($u ∈ $U, control), history)
                __add!(ct_repl, :variable, :($v ∈ $V, variable), history)
            end
            :( $a = $e1                  ) => __add!(ct_repl, :alias, e, history)
            :( ∂($x)($t) == $e1          ) => __add!(ct_repl, :dynamics, e, history)
            :( ∂($x)($t) == $e1, $label  ) => __add!(ct_repl, :dynamics, e, history)
            :( $e1 == $e2                ) => __add!(ct_repl, :constraints, e, history)
            :( $e1 == $e2, $label        ) => __add!(ct_repl, :constraints, e, history)
            :( $e1 ≤  $e2 ≤  $e3         ) => __add!(ct_repl, :constraints, e, history)
            :( $e1 ≤  $e2 ≤  $e3, $label ) => __add!(ct_repl, :constraints, e, history)
            :( $e_ → min                 ) => __add!(ct_repl, :objective, e, history)
            :( $e_ → max                 ) => __add!(ct_repl, :objective, e, history)
            _ => (println("\nct parsing error\n\nType HELP to see the list of commands or enter a valid expression to update the model."); return nothing)
        end

        # if we are here, e was part of ct dsl
        return_nothing ? nothing : __quote_ocp(ct_repl)

    end

    # makerepl command
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
# ----------------------------------------------------------------

# dict of actions associated to ct repl commands
COMMANDS_ACTIONS = Dict{Symbol, Function}(
    :SHOW => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        return __quote_ocp(ct_repl)
    end,
    :SOLVE => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        return __quote_solve(ct_repl)
    end,
    :PLOT => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        return __quote_plot(ct_repl)
    end,
    :DEBUG => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl.debug = !ct_repl.debug
        println("\n debug mode: " * (ct_repl.debug ? "on" : "off"))
        __add!(history, ct_repl) # update history
        return nothing
    end,
    :NAME => (ct_repl::CTRepl, name::Union{Symbol, Expr}, history::HistoryRepl) -> begin
        ocp_name = ct_repl.ocp_name
        sol_name = ct_repl.sol_name
        if isa(name, Symbol)
            name = (name, Symbol(string(name, "_sol")))
        elseif isa(name, Expr)
            name = (name.args[1], name.args[2])
        else
            println("\nname error\n\nType HELP to see the list of commands or enter a valid expression to update the model.")
            return nothing
        end
        ct_repl.ocp_name = name[1]
        ct_repl.sol_name = name[2]
        ct_repl.debug && println("debug> ocp name: ", ct_repl.ocp_name)
        ct_repl.debug && println("debug> sol name: ", ct_repl.sol_name)
        __add!(history, ct_repl) # update history
        qo1 = ct_repl.ocp_name ≠ ocp_name ? :($(ct_repl.ocp_name) = "no optimal control") : :()
        qs1 = ct_repl.sol_name ≠ sol_name ? :($(ct_repl.sol_name) = "no solution") : :()
        qo2 = ct_repl.ocp_name ≠ ocp_name ? :($(ct_repl.ocp_name) = $(ocp_name)) : :()
        qs2 = ct_repl.sol_name ≠ sol_name ? :($(ct_repl.sol_name) = $(sol_name)) : :()
        name_q = (quote
                    $(qo1)
                    $(qs1)
                    try 
                        $(qo2)
                        $(qs2)
                        nothing
                    catch e
                        nothing
                    end
                  end)
        ct_repl.debug && println("debug> new name quote: ", name_q)
        return name_q
    end,
    :UNDO => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl_ = __undo!(history)
        __copy!(ct_repl, ct_repl_)
        return nothing
    end,
    :REDO => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl_ = __redo!(history)
        __copy!(ct_repl, ct_repl_)
        return nothing
    end,
    :HELP => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        l = 22
        n = 6
        println("\nCommands:\n")
        dict = sort(collect(COMMANDS_HELPS), by = x->x[1])
        shortcuts = Dict(value => key for (key, value) in COMMANDS_SHORTCUTS)
        for (k, v) ∈ dict
            m = length(string(k))
            s = "  "
            s *= string(k) * " "^(n-m)
            s *= "(£" * lowercase(string(k)) * "," * " "^(n-m)
            s *= string(shortcuts[k]) * ")" 
            r = length(s)
            s *= " "^(l-r)
            printstyled(s, color=:magenta)
            printstyled(": ", v, "\n")
        end
        return nothing
    end,
    :REPL => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        return :($ct_repl)
    end,
    :CLEAR => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl.model = __init_model_repl()
        __add!(history, ct_repl) # update history
        return COMMANDS_ACTIONS[:SHOW](ct_repl, history)
    end,
)

# dict of help messages associated to ct repl commands
COMMANDS_HELPS = Dict{Symbol, String}(
    :SOLVE => "solve the optimal control problem",
    :PLOT => "plot the solution",
    :DEBUG => "toggle debug mode",
    :NAME => "NAME=ocp or NAME=(ocp, sol)",
    :UNDO => "undo",
    :REDO => "redo",
    :HELP => "help",
    :REPL => "return the current ct REPL",
    :SHOW => "show optimal control problem",
    :CLEAR => "clear optimal control problem",
)

# dict of shortcuts associated to ct repl commands
COMMANDS_SHORTCUTS = Dict{Symbol, Symbol}(
    :£sh => :SHOW,
    :£s => :SOLVE,
    :£p => :PLOT,
    :£n => :NAME,
    :£u => :UNDO,
    :£r => :REDO,
    :£h => :HELP,
    :£d => :DEBUG,
    :£re => :REPL,
    :£c => :CLEAR,
)

# non existing command
__non_existing_command() = :non_existing_command

# transform to a command
function __transform_to_command_form(c::Symbol)::Symbol

    # split c in parts
    v = split(string(c), "£")
    
    if v[1] == ""
        # if c start with £ and has only one or two more characters, use COMMANDS_SHORTCUTS
        ((length(v[2]) == 1) || (length(v[2]) == 2)) && begin
            c ∈ keys(COMMANDS_SHORTCUTS) && return COMMANDS_SHORTCUTS[c]
            println("\n Invalid command: ", c)
            return __non_existing_command()
        end
        # if c start with £ and has more than one character, returns the associated command
        length(v[2]) > 2 && return Symbol(uppercase(v[2]))
    else
        # if c does not start with £, returns c
        return c
    end

end

function __transform_to_command_form(e::Expr)::Symbol
    return __non_existing_command()
end

# make @def ocp quote
function __quote_ocp(ct_repl::CTRepl; print_ocp::Bool=true)
    print_ocp && __print_code(ct_repl)
    code  = __code(ct_repl.model)
    ocp_q = (quote @def $(ct_repl.ocp_name) $(code) end)
    ct_repl.debug && println("debug> code: ", code)
    ct_repl.debug && println("debug> quote code: ", ocp_q)
    return ocp_q
end

# eval ocp
function __eval_ocp(ct_repl::CTRepl)
    eval(__quote_ocp(ct_repl, print_ocp=false))
end

# quote solve: todo: update when using real solver
function __quote_solve(ct_repl::CTRepl)
    if ct_repl.__demo
        solve_q = (quote $(ct_repl.sol_name) = CTBase.__demo_solver(); nothing end)
        ct_repl.debug && println("debug> quote solve: ", solve_q)
        return solve_q
    else
        solve_q = (quote $(ct_repl.sol_name) = solve($(ct_repl.ocp_name)) end)
        ct_repl.debug && println("debug> quote solve: ", solve_q)
        return solve_q
    end
end

# quote plot: todo: update when handle correctly solution
function __quote_plot(ct_repl::CTRepl)
    return !isnothing(ct_repl.solution) ? :(plot($(ct_repl.solution), size=(700, 600))) : :(println("\nNo solution available."))
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

# print code
function __print_code(ct_repl::CTRepl)
    code = __code(ct_repl.model)
    s = "$(ct_repl.ocp_name) = "
    print("\n" * s)
    l = length(s)
    for i ∈ eachindex(code.args)
        e = code.args[i]
        print(i==1 ? "" : " "^l, e)
        print("\n")
    end
end

# print code and add a new line
function __println_code(ct_repl::CTRepl)
    __print_code(ct_repl)
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

function __copy!(ct_repl::CTRepl, ct_repl_to_copy::CTRepl)
    ct_repl.model = deepcopy(ct_repl_to_copy.model)
    ct_repl.ocp_name = ct_repl_to_copy.ocp_name
    ct_repl.sol_name = ct_repl_to_copy.sol_name
    ct_repl.debug = ct_repl_to_copy.debug
end

# get code from model and an expression
function __code(model::ModelRepl, type::Symbol, e::Expr)
    model_ = deepcopy(model)    # copy model
    __update!(model_, type, e)  # update model_
    return __code(model_)       # get code
end

# add model to history
function __add!(history::HistoryRepl, ct_repl::CTRepl)
    push!(history.ct_repls, deepcopy(ct_repl))
    history.index += 1
end

# go to previous model in history
function __undo!(history::HistoryRepl)
    history.index > 1 && (history.index -= 1)
    return history.ct_repls[history.index]
end

# go to next model in history
function __redo!(history::HistoryRepl)
    history.index < length(history.ct_repls) && (history.index += 1)
    return history.ct_repls[history.index]
end

function Base.show(io::IO, ::MIME"text/plain", ct_repl::CTRepl)
    print(io, "\n")
    println(io, "ct> ")
    println(io, "model: ", ct_repl.model)
    println(io, "ocp_name: ", ct_repl.ocp_name)
    println(io, "sol_name: ", ct_repl.sol_name)
    println(io, "debug: ", ct_repl.debug)
end

function __demo_solver()

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