const ModelRepl = Vector{Expr}

@with_kw mutable struct CTRepl
    model::ModelRepl = ModelRepl()
    ocp_name::Symbol = gensym(:ocp)
    sol_name::Symbol = gensym(:sol)
    debug::Bool = false
    __demo::Union{Nothing, Bool} = nothing
end

@with_kw mutable struct HistoryRepl
    index::Int=0
    ct_repl_datas_data::Vector{CTRepl}=Vector{CTRepl}()
end

ct_repl_is_set = false

"""
$(TYPEDSIGNATURES)

Create a ct REPL.
"""
function ct_repl(; debug=false, demo=false, verbose=false)

    if !ct_repl_is_set

        #
        global ct_repl_is_set = true

        # init: ct_repl_data, history
        ct_repl_data = CTRepl()
        ct_repl_data.debug = debug
        ct_repl_data.__demo = demo
        history::HistoryRepl = HistoryRepl(0, Vector{ModelRepl}())

        # if demo, print a message
        demo && println("\nWelcome to the demo of the ct REPL.\n")

        # advice to start by setting the name of the ocp and the solution
        println("To start, you should set the name of the optimal control problem and the name of the solution.")
        println("For example, you can type:\n")
        println("    ct> NAME=(ocp, sol)\n")

        # add initial ct_repl_data to history
        __add!(history, ct_repl_data)

        # text invalid
        txt_invalid = "\nInvalid expression.\n\nType HELP to see the list of commands or enter a " *
                        "valid expression to update the model."

        function parse_to_expr(s::AbstractString)
            
            # remove spaces from s at the beginning and at the end
            s = strip(s)

            # check if it is a comment
            startswith(s, "#") && return nothing

            # parse string
            e = Meta.parse(s)

            #
            ct_repl_data.debug && println("\ndebug> parsing string: ", s)
            ct_repl_data.debug && println("debug> expression parsed: ", e)
            ct_repl_data.debug && println("debug> expression type: ", typeof(e))
            ct_repl_data.debug && println("debug> dump of expression: ", dump(e))

            # test if e is a command
            @match e begin
                :( $c = $a ) => begin
                    command = __transform_to_command(c)
                    ct_repl_data.debug && println("debug> command: ", command, " and argument: ", a)
                    command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl_data, a, history))
                end
                :( $c ) => begin
                    command = __transform_to_command(c)
                    ct_repl_data.debug && println("debug> command: ", command)
                    command ∈ keys(COMMANDS_ACTIONS) && (return COMMANDS_ACTIONS[command](ct_repl_data, history))
                end
                _ => nothing
            end

            # check if s finishes with a ";". If yes then remove it and return nothing at the end
            return_nothing = endswith(s, ";") ? true : false
            return_nothing && (s = s[1:end-1])
            e = Meta.parse(s)

            #
            return_nothing && ct_repl_data.debug && println("\ndebug> new parsing string: ", s)
            return_nothing && ct_repl_data.debug && println("debug> new expression parsed: ", e)
            
            if e isa Expr

                # eval ocp to test if the expression is valid
                ct_repl_data.debug && (println("debug> try to add expression: ", e))
                try 
                    __eval_ocp(ct_repl_data, e)      # test if code is valid: if not, an exception is thrown
                catch ex
                    ct_repl_data.debug && (println("debug> exception thrown: ", ex))
                    println(txt_invalid)
                    return nothing
                end
                
                # update model
                __update!(ct_repl_data.model, e)
                ct_repl_data.debug && (println("debug> expression valid, model updated."))

                # add ct_repl_data to history
                __add!(history, ct_repl_data)

                #
                return return_nothing ? nothing : __quote_ocp(ct_repl_data)

            else

                println(txt_invalid)
                return nothing

            end

        end # parse_to_expr

        # makerepl command
        initrepl(parse_to_expr,
                prompt_text="ct> ",
                prompt_color = :magenta,
                start_key='>',
                mode_name="ct_mode",
                valid_input_checker=complete_julia,
                startup_text=false)
            
    else
        if verbose
            println("ct repl is already set.")
        end
    end

end

# ----------------------------------------------------------------  
# utils functions
# ----------------------------------------------------------------

function NAME_ACTION_FUNCTION(ct_repl_data::CTRepl, history::HistoryRepl)
    println("")
    println("Optimal control problem name: ", ct_repl_data.ocp_name)
    println("Solution name: ", ct_repl_data.sol_name)
end

function NAME_ACTION_FUNCTION(ct_repl_data::CTRepl, name::Union{Symbol, Expr}, history::HistoryRepl)
    ocp_name = ct_repl_data.ocp_name
    sol_name = ct_repl_data.sol_name
    if isa(name, Symbol)
        name = (name, Symbol(string(name, "_sol")))
    elseif isa(name, Expr)
        name = (name.args[1], name.args[2])
    else
        println("\nname error\n\nType HELP to see the list of commands or enter a valid expression to update the model.")
        return nothing
    end
    ct_repl_data.ocp_name = name[1]
    ct_repl_data.sol_name = name[2]
    ct_repl_data.debug && println("debug> ocp name: ", ct_repl_data.ocp_name)
    ct_repl_data.debug && println("debug> sol name: ", ct_repl_data.sol_name)
    __add!(history, ct_repl_data) # update history
    qo1 = ct_repl_data.ocp_name ≠ ocp_name ? :($(ct_repl_data.ocp_name) = "no optimal control") : :()
    qs1 = ct_repl_data.sol_name ≠ sol_name ? :($(ct_repl_data.sol_name) = "no solution") : :()
    qo2 = ct_repl_data.ocp_name ≠ ocp_name ? :($(ct_repl_data.ocp_name) = $(ocp_name)) : :()
    qs2 = ct_repl_data.sol_name ≠ sol_name ? :($(ct_repl_data.sol_name) = $(sol_name)) : :()
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
    ct_repl_data.debug && println("debug> new name quote: ", name_q)
    return name_q
end

# dict of actions associated to ct repl commands
COMMANDS_ACTIONS = Dict{Symbol, Function}(
    :SHOW => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        return __quote_ocp(ct_repl_data)
    end,
    :SOLVE => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        return __quote_solve(ct_repl_data)
    end,
    :PLOT => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        return __quote_plot(ct_repl_data)
    end,
    :DEBUG => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        ct_repl_data.debug = !ct_repl_data.debug
        println("\n debug mode: " * (ct_repl_data.debug ? "on" : "off"))
        __add!(history, ct_repl_data) # update history
        return nothing
    end,
    :NAME => NAME_ACTION_FUNCTION,
    :UNDO => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        ct_repl_data_ = __undo!(history)
        __copy!(ct_repl_data, ct_repl_data_)
        return nothing
    end,
    :REDO => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        ct_repl_data_ = __redo!(history)
        __copy!(ct_repl_data, ct_repl_data_)
        return nothing
    end,
    :HELP => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
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
    :REPL => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        return :($ct_repl_data)
    end,
    :CLEAR => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        ct_repl_data.model = ModelRepl()
        __add!(history, ct_repl_data) # update history
        return COMMANDS_ACTIONS[:SHOW](ct_repl_data, history)
    end,
    :JLS => (ct_repl_data::CTRepl, history::HistoryRepl) -> begin
        println("\nhttps://youtu.be/HzRF2622m9A")
        return nothing
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
function __transform_to_command(c::Symbol)::Symbol

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

function __transform_to_command(e::Expr)::Symbol
    return __non_existing_command()
end

# get code from model
function __code(model::ModelRepl)::Expr
    return Expr(:block, model...)
end

# get code from model and an extra expression
function __code(model::ModelRepl, e::Expr)
    model_ = deepcopy(model)    # copy model
    __update!(model_, e)        # update model_
    return __code(model_)       # get code
end

function __update!(model::ModelRepl, e::Expr)
    push!(model, e)
end

# make @def ocp quote
function __quote_ocp(ct_repl_data::CTRepl)
    code  = __code(ct_repl_data.model)
    println("\n", ct_repl_data.ocp_name)
    ocp_q = quote @def $(ct_repl_data.ocp_name) $(code) end
    ct_repl_data.debug && println("debug> code: ", code)
    ct_repl_data.debug && println("debug> quote code: ", ocp_q)
    return ocp_q
end

# eval ocp
function __eval_ocp(ct_repl_data::CTRepl, e::Expr)
    code  = __code(ct_repl_data.model, e)
    ocp = gensym()
    ocp_q = quote @def $ocp $code end
    ct_repl_data.debug && println("debug> code: ", code)
    ct_repl_data.debug && println("debug> quote code: ", ocp_q)
    try 
        eval(ocp_q)
    catch ex
        throw(ex)
    end
    nothing
end

# quote solve: todo: update when using real solver
function __quote_solve(ct_repl_data::CTRepl)
    if ct_repl_data.__demo
        solve_q = (quote $(ct_repl_data.sol_name) = CTBase.__demo_solver(); nothing end)
        ct_repl_data.debug && println("debug> quote solve: ", solve_q)
        return solve_q
    else
        solve_q = (quote $(ct_repl_data.sol_name) = solve($(ct_repl_data.ocp_name)) end)
        ct_repl_data.debug && println("debug> quote solve: ", solve_q)
        return solve_q
    end
end

# quote plot: todo: update when handle correctly solution
function __quote_plot(ct_repl_data::CTRepl)
    plot_q = quote
        if @isdefined($(ct_repl_data.sol_name))
            plot($(ct_repl_data.sol_name), size=(600, 500))
        else
            println("\nNo solution available.")
        end
    end
    ct_repl_data.debug && println("debug> quote plot: ", plot_q)
    return plot_q
end

# add model to history
function __add!(history::HistoryRepl, ct_repl_data::CTRepl)
    push!(history.ct_repl_datas_data, deepcopy(ct_repl_data))
    history.index += 1
end

# go to previous model in history
function __undo!(history::HistoryRepl)
    history.index > 1 && (history.index -= 1)
    return history.ct_repl_datas_data[history.index]
end

# go to next model in history
function __redo!(history::HistoryRepl)
    history.index < length(history.ct_repl_datas_data) && (history.index += 1)
    return history.ct_repl_datas_data[history.index]
end

# copy a ct_repl_data
function __copy!(ct_repl_data::CTRepl, ct_repl_data_to_copy::CTRepl)
    ct_repl_data.model = deepcopy(ct_repl_data_to_copy.model)
    ct_repl_data.ocp_name = ct_repl_data_to_copy.ocp_name
    ct_repl_data.sol_name = ct_repl_data_to_copy.sol_name
    ct_repl_data.debug = ct_repl_data_to_copy.debug
end

function Base.show(io::IO, ::MIME"text/plain", ct_repl_data::CTRepl)
    print(io, "\n")
    println(io, "ct> ")
    println(io, "model: ", ct_repl_data.model)
    println(io, "ocp_name: ", ct_repl_data.ocp_name)
    println(io, "sol_name: ", ct_repl_data.sol_name)
    println(io, "debug: ", ct_repl_data.debug)
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
