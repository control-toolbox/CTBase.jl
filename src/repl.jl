const ModelRepl = Dict{Symbol, Union{Expr, Vector{Expr}}}

@with_kw mutable struct CTRepl
    model::ModelRepl = __init_model_repl()
    ocp_name::Symbol = gensym(:ocp)
    solution::Union{OptimalControlSolution, Nothing} = nothing
    debug::Bool = false
    display_code::Bool = false
    display_ocp::Bool = false
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
        __add!(history, ct_repl)          # update history
        ct_repl.debug && (println("debug> expression valid, model updated."))
    catch ex
        println("\nThe model can't be updated. The expression is not valid.")
        ct_repl.debug && (println("debug> exception thrown: ", ex))
    end
end

function __init_repl(; debug=false)

    # init
    ct_repl = CTRepl()
    ct_repl.debug = debug
    history::HistoryRepl = HistoryRepl(0, Vector{ModelRepl}())

    # add initial model to history
    __add!(history, ct_repl)

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
                command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl, a, history))
            end
            :( $command ) => begin
                command = __get_command(command)
                ct_repl.debug && println("debug> command: ", command)
                command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl, history))
            end
            _ => nothing
        end

        # parse expression and update model
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
            _ => (print("\nct parsing error. Type HELP to see the list of commands or enter a valid expression to update the model."); return :())
        end

        #
        ct_repl.display_code && ( ct_repl.display_ocp ? __println_code(ct_repl) : __print_code(ct_repl) )

        if ct_repl.display_ocp
            ocp_q = __quote_ocp(ct_repl)
            return ocp_q
        else
            return :()
        end

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
# ----------------------------------------------------------------

COMMANDS_ACTIONS = Dict{Symbol, Function}(
    :SOLVE => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl.solution = __solve()
        print("\n solved.")
        __add!(history, ct_repl) # update history
        return :()
    end,
    :PLOT => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        return !isnothing(ct_repl.solution) ? :(plot($(ct_repl.solution), size=(700, 600))) : :(println("\nNo solution available."))
    end,
    :DEBUG => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl.debug = !ct_repl.debug
        print("\n debug mode: " * (ct_repl.debug ? "on" : "off"))
        __add!(history, ct_repl) # update history
        return :()
    end,
    :SHOW => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl.display_ocp  = !ct_repl.display_ocp
        ct_repl.display_code = !ct_repl.display_code
        print("\n display ocp: " * (ct_repl.display_ocp ? "on" : "off"))
        print("\n display code: " * (ct_repl.display_code ? "on" : "off"))
        __add!(history, ct_repl) # update history
        return :()
    end,
    :SHOW_OCP => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl.display_ocp = !ct_repl.display_ocp
        print("\n display ocp: " * (ct_repl.display_ocp ? "on" : "off"))
        __add!(history, ct_repl) # update history
        return :()
    end,
    :SHOW_CODE => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl.display_code = !ct_repl.display_code
        print("\n display code: " * (ct_repl.display_code ? "on" : "off"))
        __add!(history, ct_repl) # update history
        return :()
    end,
    :NAME => (ct_repl::CTRepl, name::Symbol, history::HistoryRepl) -> begin
        ct_repl.ocp_name = name
        print("\n ocp name: ", ct_repl.ocp_name)
        __add!(history, ct_repl) # update history
        ocp_q = __quote_ocp(ct_repl)
        return ocp_q
    end,
    :UNDO => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl_ = __undo!(history)
        __copy!(ct_repl, ct_repl_)
        #ct_repl.display_code && __print_code(ct_repl)
        return :()
    end,
    :REDO => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ct_repl_ = __redo!(history)
        __copy!(ct_repl, ct_repl_)
        #ct_repl.display_code && __print_code(ct_repl)
        return :()
    end,
    :HELP => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        l = 11
        println("\nCommands:\n")
        dict = sort(collect(COMMANDS_HELPS), by = x->x[1])
        for (k, v) ∈ dict
            m = length(string(k))
            s = " "^max((l-m), 0)
            printstyled("  ", k, s, color=:magenta)
            printstyled(": ", v, "\n")
        end
        return :()
    end,
    :REPL => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        return :($ct_repl)
    end,
    :CODE => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        __print_code(ct_repl)
        return :()
    end,
    :OCP => (ct_repl::CTRepl, history::HistoryRepl) -> begin
        ocp_q = __quote_ocp(ct_repl)
        return ocp_q
    end,
)

COMMANDS_HELPS = Dict{Symbol, String}(
    :SOLVE => "solve the optimal control problem",
    :PLOT => "plot the solution",
    :DEBUG => "toggle debug mode",
    :SHOW => "toggle display ocp and code",
    :SHOW_OCP => "toggle display ocp model",
    :SHOW_CODE => "toggle display code",
    :NAME => "change ocp name",
    :UNDO => "undo",
    :REDO => "redo",
    :HELP => "help",
    :REPL => "return the current ct repl",
    :CODE => "print code",
    :OCP  => "print ocp",
)

COMMANDS_KEYS = Dict{Symbol, Symbol}(
    :£s => :SOLVE,
    :£p => :PLOT,
    :£d => :DEBUG,
    :£w => :SHOW,
    :£wo => :SHOW_OCP,
    :£wc => :SHOW_CODE,
    :£n => :NAME,
    :£u => :UNDO,
    :£r => :REDO,
    :£h => :HELP,
    :£re => :REPL,
    :£c => :CODE,
    :£o => :OCP,
)

__non_existing_command() = :not_a_command_at_all

function __get_command(c::Symbol)::Symbol

    # split c in parts
    v = split(string(c), "£")
    
    if v[1] == ""
        # if c start with £ and has only one or two more characters, use COMMANDS_KEYS
        ((length(v[2]) == 1) || (length(v[2]) == 2)) && begin
            c ∈ keys(COMMANDS_KEYS) && return COMMANDS_KEYS[c]
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

function __get_command(e::Expr)::Symbol
    return __non_existing_command()
end

function __quote_ocp(ct_repl::CTRepl)
    code  = __code(ct_repl.model)
    ocp_q = (quote @def $(ct_repl.ocp_name) $(code) end)
    ct_repl.debug && println("debug> code: ", code)
    ct_repl.debug && println("debug> quote code: ", ocp_q)
    return ocp_q
end

function __eval_ocp(ct_repl::CTRepl)
    ocp_q = __quote_ocp(ct_repl)
    eval(ocp_q)
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
    print("\n $(ct_repl.ocp_name) = ", code)
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
    ct_repl.solution = deepcopy(ct_repl_to_copy.solution)
    ct_repl.debug = ct_repl_to_copy.debug
    ct_repl.display_code = ct_repl_to_copy.display_code
    ct_repl.display_ocp = ct_repl_to_copy.display_ocp
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
    println(io, "debug: ", ct_repl.debug)
    println(io, "display_code: ", ct_repl.display_code)
    println(io, "display_ocp: ", ct_repl.display_ocp)
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