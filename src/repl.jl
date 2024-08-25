const ModelRepl = Vector{Expr}

@with_kw mutable struct CTRepl
    model::ModelRepl = ModelRepl()
    ocp_name::Symbol = gensym(:ocp)
    sol_name::Symbol = gensym(:sol)
    debug::Bool = false
end

@with_kw mutable struct HistoryRepl
    index::Int = 0
    ct_repl_datas_data::Vector{CTRepl} = Vector{CTRepl}()
end

#
ct_repl_is_set::Bool = false
ct_repl_data::CTRepl = CTRepl()
ct_repl_history::HistoryRepl = HistoryRepl(0, Vector{ModelRepl}())

"""
$(TYPEDSIGNATURES)

Update the model adding the expression e. It must be public since in the ct repl, this function 
is quoted each time an expression is parsed and is valid. 
"""
function ct_repl_update_model(e::Expr)

    ct_repl_data.debug && (println("debug> expression to add: ", e))

    # update model
    __update!(ct_repl_data.model, e)
    ct_repl_data.debug && (println("debug> expression valid, model updated."))

    # add ct_repl_data to ct_repl_history
    __add!(ct_repl_history, ct_repl_data)

    #
    return nothing

end

"""
$(TYPEDSIGNATURES)

Create a ct REPL.
"""
function ct_repl(; debug = false, verbose = false)

    global ct_repl_is_set
    global ct_repl_data
    global ct_repl_history

    if !ct_repl_is_set

        #
        ct_repl_is_set = true

        #
        ct_repl_data.debug = debug

        # # advice to start by setting the name of the ocp and the solution
        # println("\nType > to enter into ct repl.\n")
        # println("For a start, you can set the names of the optimal control problem and its solution.")
        # println("In ct repl, type:\n")
        # println("    ct> NAME=(ocp, sol)")

        # add initial ct_repl_data to ct_repl_history
        __add!(ct_repl_history, ct_repl_data)

        # text invalid
        txt_invalid =
            "\nInvalid expression.\n\nType HELP to see the list of commands or enter a " *
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
                :($c = $a) => begin
                    command = __transform_to_command(c)
                    ct_repl_data.debug &&
                        println("debug> command: ", command, " and argument: ", a)
                    command ∈ keys(COMMANDS_ACTIONS) && (
                        return COMMANDS_ACTIONS[command](ct_repl_data, a, ct_repl_history)
                    )
                end
                :($c) => begin
                    command = __transform_to_command(c)
                    ct_repl_data.debug && println("debug> command: ", command)
                    command ∈ keys(COMMANDS_ACTIONS) && (
                        return COMMANDS_ACTIONS[command](ct_repl_data, ct_repl_history)
                    )
                end
                _ => nothing
            end

            # check if s finishes with a ";". If yes then remove it and return nothing at the end
            return_nothing = endswith(s, ";") ? true : false
            return_nothing && (s = s[1:end-1])
            e = Meta.parse(s)

            #
            return_nothing &&
                ct_repl_data.debug &&
                println("\ndebug> new parsing string: ", s)
            return_nothing &&
                ct_repl_data.debug &&
                println("debug> new expression parsed: ", e)

            if e isa Expr

                #
                ocp_q_for_test = __quote_anonym_ocp(ct_repl_data, e)  # test if code is valid: if not, an exception is thrown
                ocp_q = __quote_ocp(ct_repl_data, e)

                # to update the model if needed
                ee = QuoteNode(e)

                #
                ct_repl_data.debug && (println("debug> try to add expression: ", e))
                q = quote
                    try
                        $ocp_q_for_test # test if the expression is valid
                    catch ex
                        $(ct_repl_data.debug) && (println("debug> exception thrown: ", ex))
                        println($txt_invalid)
                        return
                    end
                    # test is ok
                    $(ct_repl_data.debug) && (println("debug> eval ocp quote ok "))
                    $(ct_repl_data.debug) && (println("debug> expr to add ", $ee))
                    # ----------------------------------------------------------------
                    # keep coherence between model and ocp variable
                    $ocp_q # define the ocp
                    ct_repl_update_model($ee) # add the expression in the model
                    # ----------------------------------------------------------------
                    $return_nothing ? nothing :
                    begin
                        println("\n", string($ct_repl_data.ocp_name))
                        $(ct_repl_data.ocp_name)
                    end
                end
                return q

            else

                println(txt_invalid)
                return nothing

            end

        end # parse_to_expr

        # makerepl command
        initrepl(
            parse_to_expr,
            prompt_text = "ct> ",
            prompt_color = :magenta,
            start_key = '>',
            mode_name = "ct_mode",
            valid_input_checker = complete_julia,
            startup_text = false,
        )

        return nothing

    else
        if verbose
            println("ct repl is already set.")
        end
    end

end

# ----------------------------------------------------------------  
# utils functions
# ----------------------------------------------------------------

function NAME_ACTION_FUNCTION(ct_repl_data::CTRepl, ct_repl_history::HistoryRepl)
    println("")
    println("Optimal control problem name: ", ct_repl_data.ocp_name)
    println("Solution name: ", ct_repl_data.sol_name)
end

function NAME_ACTION_FUNCTION(
    ct_repl_data::CTRepl,
    name::Union{Symbol,Expr},
    ct_repl_history::HistoryRepl,
)
    ocp_name = ct_repl_data.ocp_name
    sol_name = ct_repl_data.sol_name
    if isa(name, Symbol)
        name = (name, Symbol(string(name, "_sol")))
    elseif isa(name, Expr)
        name = (name.args[1], name.args[2])
    else
        println(
            "\nname error\n\nType HELP to see the list of commands or enter a valid expression to update the model.",
        )
        return nothing
    end
    ct_repl_data.ocp_name = name[1]
    ct_repl_data.sol_name = name[2]
    ct_repl_data.debug && println("debug> ocp name: ", ct_repl_data.ocp_name)
    ct_repl_data.debug && println("debug> sol name: ", ct_repl_data.sol_name)
    __add!(ct_repl_history, ct_repl_data) # update ct_repl_history
    qo1 =
        ct_repl_data.ocp_name ≠ ocp_name ?
        :($(ct_repl_data.ocp_name) = "no optimal control") : :()
    qs1 =
        ct_repl_data.sol_name ≠ sol_name ? :($(ct_repl_data.sol_name) = "no solution") : :()
    qo2 = ct_repl_data.ocp_name ≠ ocp_name ? :($(ct_repl_data.ocp_name) = $(ocp_name)) : :()
    qs2 = ct_repl_data.sol_name ≠ sol_name ? :($(ct_repl_data.sol_name) = $(sol_name)) : :()
    name_q = (
        quote
            $(qo1)
            $(qs1)
            try
                $(qo2)
                $(qs2)
                nothing
            catch e
                nothing
            end
        end
    )
    ct_repl_data.debug && println("debug> new name quote: ", name_q)
    return name_q
end

# dict of actions associated to ct repl commands
COMMANDS_ACTIONS = Dict{Symbol,Function}(
    :SHOW =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            q = quote
                println("\n", string($ct_repl_data.ocp_name))
                $(ct_repl_data.ocp_name)
            end
            return q
        end,
    :SOLVE =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            return __quote_solve(ct_repl_data)
        end,
    :PLOT =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            return __quote_plot(ct_repl_data)
        end,
    :DEBUG =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            ct_repl_data.debug = !ct_repl_data.debug
            println("\n debug mode: " * (ct_repl_data.debug ? "on" : "off"))
            __add!(ct_repl_history, ct_repl_data) # update ct_repl_history
            return nothing
        end,
    :NAME => NAME_ACTION_FUNCTION,
    :UNDO =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            ct_repl_data_ = __undo!(ct_repl_history)
            __copy!(ct_repl_data, ct_repl_data_)
            ocp_q = __quote_ocp(ct_repl_data)
            q = quote
                $ocp_q
                nothing
            end
            return q
        end,
    :REDO =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            ct_repl_data_ = __redo!(ct_repl_history)
            __copy!(ct_repl_data, ct_repl_data_)
            ocp_q = __quote_ocp(ct_repl_data)
            q = quote
                $ocp_q
                nothing
            end
            return q
        end,
    :HELP =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            l = 8 # 22
            n = 6
            println("\nSpecial commands to interact with the ct repl:\n")
            dict = sort(collect(COMMANDS_HELPS), by = x -> x[1])
            for (k, v) ∈ dict
                m = length(string(k))
                s = "  "
                s *= string(k) * " "^(n - m)
                r = length(s)
                s *= " "^(l - r)
                printstyled(s, color = :magenta)
                printstyled(": ", v, "\n")
            end
            return nothing
        end,
    :REPL =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            return :($ct_repl_data)
        end,
    :CLEAR =>
        (ct_repl_data::CTRepl, ct_repl_history::HistoryRepl) -> begin
            ct_repl_data.model = ModelRepl()
            __add!(ct_repl_history, ct_repl_data) # update ct_repl_history
            ocp_q = __quote_ocp(ct_repl_data)
            q = quote
                $ocp_q
                nothing
            end
            return q
        end,
)

# dict of help messages associated to ct repl commands
COMMANDS_HELPS = Dict{Symbol,String}(
    :SOLVE => "solve the optimal control problem",
    :PLOT => "plot the solution",
    #:DEBUG => "toggle debug mode",
    :NAME =>
        "print the name of the optimal control problem and the solution. To set them: \n\n" *
        "          ct> NAME=ocp\n" *
        "          ct> NAME=(ocp, sol)\n",
    :UNDO => "undo last command",
    :REDO => "redo last command",
    :HELP => "help",
    #:REPL => "return the current ct REPL",
    :SHOW => "show the optimal control problem",
    :CLEAR => "clear the optimal control problem",
)

# non existing command
__non_existing_command() = :non_existing_command

# transform to a command
__transform_to_command(c::Symbol)::Symbol = c
__transform_to_command(e::Expr)::Symbol = __non_existing_command()

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
    code = __code(ct_repl_data.model)
    ocp_q = quote
        @def $(ct_repl_data.ocp_name) $(code)
    end
    ct_repl_data.debug && println("debug> code: ", code)
    ct_repl_data.debug && println("debug> quote code: ", ocp_q)
    return ocp_q
end

function __quote_ocp(ct_repl_data::CTRepl, e::Expr)
    code = __code(ct_repl_data.model, e)
    ocp_q = quote
        @def $(ct_repl_data.ocp_name) $(code)
    end
    ct_repl_data.debug && println("debug> code: ", code)
    ct_repl_data.debug && println("debug> quote code: ", ocp_q)
    return ocp_q
end

# get ocp quote
function __quote_anonym_ocp(ct_repl_data::CTRepl, e::Expr)
    code = __code(ct_repl_data.model, e)
    ocp = gensym()
    ocp_q = quote
        @def $ocp $code
    end
    ct_repl_data.debug && println("debug> code: ", code)
    ct_repl_data.debug && println("debug> quote code: ", ocp_q)
    return ocp_q
end

# quote solve: todo: update when using real solver
function __quote_solve(ct_repl_data::CTRepl)
    solve_q = (
        quote
            $(ct_repl_data.sol_name) = solve($(ct_repl_data.ocp_name))
        end
    )
    ct_repl_data.debug && println("debug> quote solve: ", solve_q)
    return solve_q
end

# quote plot: todo: update when handle correctly solution
function __quote_plot(ct_repl_data::CTRepl)
    plot_q = quote
        if @isdefined($(ct_repl_data.sol_name))
            plot($(ct_repl_data.sol_name), size = (600, 500))
        else
            println("\nNo solution available.")
        end
    end
    ct_repl_data.debug && println("debug> quote plot: ", plot_q)
    return plot_q
end

# add model to ct_repl_history
function __add!(ct_repl_history::HistoryRepl, ct_repl_data::CTRepl)
    push!(ct_repl_history.ct_repl_datas_data, deepcopy(ct_repl_data))
    ct_repl_history.index += 1
end

# go to previous model in ct_repl_history
function __undo!(ct_repl_history::HistoryRepl)
    ct_repl_history.index > 1 && (ct_repl_history.index -= 1)
    return ct_repl_history.ct_repl_datas_data[ct_repl_history.index]
end

# go to next model in ct_repl_history
function __redo!(ct_repl_history::HistoryRepl)
    ct_repl_history.index < length(ct_repl_history.ct_repl_datas_data) &&
        (ct_repl_history.index += 1)
    return ct_repl_history.ct_repl_datas_data[ct_repl_history.index]
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
