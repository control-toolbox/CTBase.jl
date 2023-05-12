const ModelRepl = Dict{Symbol, Union{Expr, Vector{Expr}}}

function __init_model_repl()

    #
    model = ModelRepl()
    model[:time] = :()
    model[:state] = :()
    model[:control] = :()
    model[:variable] = :()
    model[:dynamics] = :()
    model[:objective] = :()
    model[:constraints] = Expr[]
    model[:alias] = Expr[]
    #model[:others] = Expr[]

    #
    history = Symbol[]

    return model, history

end

# update model with a new expression
function __update!(model::ModelRepl, type::Symbol, e::Expr)
    @match type begin
        :alias       => (push!(model[type], e))
        :constraints => (push!(model[type], e))
        _            => (model[type] = e)
    end
end

# update model and history with a new expression
function __update!(model::ModelRepl, history::Vector{Symbol}, type::Symbol, e::Expr)

    # update history
    if type ∈ [:time, :state, :control, :variable, :dynamics, :objective]
        type ∉ history && push!(history, type)
    elseif type == :alias
        @match e begin
            :( $e1 = $e2 ) => begin
                for i ∈ 1:length(model[:alias])
                    a = model[:alias][i]
                    @match a begin
                        :( $e1 = $a2 ) => (model[:alias][i] = e; return)
                        _ => (println("\n Internal error, invalid alias: ", e); return)
                    end
                end
            end
            _ => (println("\n Internal error, invalid alias: ", e); return)
        end
        push!(history, type)
    else
        push!(history, type)
    end

    # update model
    __update!(model, type, e)

end

# current code
function __code(model::ModelRepl, history::Vector{Symbol})
    i_alias = 1
    i_constraints = 1
    m = Expr[]
    for type ∈ history
        @match type begin
            :time        => (push!(m, model[type]))
            :state       => (push!(m, model[type]))
            :control     => (push!(m, model[type]))
            :variable    => (push!(m, model[type]))
            :dynamics    => (push!(m, model[type]))
            :objective   => (push!(m, model[type]))
            :alias       => (push!(m, model[type][i_alias]); i_alias += 1)
            :constraints => (push!(m, model[type][i_constraints]); i_constraints += 1)
            _            => ()
        end
    end
    return Expr(:block, m...)
end

# code with a new expression
function __code(model::ModelRepl, history::Vector{Symbol}, type::Symbol, e::Expr)
    model_ = deepcopy(model) # copy model
    __update!(model_, type, e) # update model_
    return __code(model_, history) # get code
end

# add to model and history the new expression if it is valid
function __add!(model::ModelRepl, history::Vector{Symbol}, type::Symbol, e::Expr, debug=false)
    try 
        code = __code(model, history, type, e) # get code
        eval(quote @def ocp $code end) # check code
        __update!(model, history, type, e) # update model if code is valid
    catch ex
        println("\nParsing error: ", e)
        debug && (println("\nException: ", ex))
    end
end

function __print_code(code)
    print("\nocp = ", code)
end

function __println_code(code)
    println("\nocp = ", code)
end

function __init_repl()

    model, history = __init_model_repl()
    solution = nothing
    debug = false

    display_code = false
    display_model = false

    function parse_to_expr(s::AbstractString)
        if s == "clear"
            model, history = __init_model_repl()
            c = __code(model, history)
            return display_model ? :(@def ocp $c) : :()
        else
            e = Meta.parse(s)
            if e isa Symbol
                e ∈ [:history, :h] && ( println("\nhistory = ", history); return :() )
                e ∈ [:debug, :d] && ( debug = !debug; return :() )
                e ∈ [:ocp, :model] && ( code = __code(model, history); return :(@def ocp $code) )
                e ∈ [:code, :c] && ( code = __code(model, history); __print_code(code); return :())
                e ∈ [:solve, :s] && ( solution = __solve(); print("\nsolved.") ;return :($solution) )
                e ∈ [:solution, :sol, :plot] && ( return !isnothing(solution) ? :(plot($solution)) : :(println("\nNo solution available.")))
                return e
            else
                @match e begin
                    :( display = $e_             ) => begin
                        if hasproperty(e_, :value)
                            e_.value == :all   && (display_model = true; display_code = true)
                            e_.value == :model && (display_model = true; display_code = false)
                            e_.value == :code  && (display_model = false; display_code = true)
                            e_.value == :none  && (display_model = false; display_code = false)
                            e_.value ∉ [:all, :model, :code, :none] && print("Invalid display option: ", e_.value, ". Use one of: all, model, code, none.")
                        end
                        return :()
                    end
                    :( $e_, time                 ) => __add!(model, history, :time, e, debug)
                    :( $t ∈ [$a, $b]             ) => __add!(model, history, :time, :($t ∈ [$a, $b], time), debug)
                    :( $e_, state                ) => __add!(model, history, :state, e, debug)
                    :( $e_, control              ) => __add!(model, history, :control, e, debug)
                    :( $x, $u ∈ $X, $U ) || :( ($x, $u) ∈ $X × $U ) || :( ($x, $u) ∈ $X * $U )=> begin
                        __add!(model, history, :state, :($x ∈ $X, state), debug)
                        __add!(model, history, :control, :($u ∈ $U, control), debug)
                    end
                    :( $e_, variable             ) => __add!(model, history, :variable, e, debug)
                    :( $x, $u, $v ∈ $X, $U, $V ) || :( ($x, $u, $v) ∈ $X × $U × $V ) || :( ($x, $u, $v) ∈ $X * $U * $V )=> begin
                        __add!(model, history, :state, :($x ∈ $X, state), debug)
                        __add!(model, history, :control, :($u ∈ $U, control), debug)
                        __add!(model, history, :variable, :($v ∈ $V, variable), debug)
                    end
                    :( $a = $e1                  ) => __add!(model, history, :alias, e, debug)
                    :( ∂($x)($t) == $e1          ) => __add!(model, history, :dynamics, e, debug)
                    :( ∂($x)($t) == $e1, $label  ) => __add!(model, history, :dynamics, e, debug)
                    :( $x'($t) == $e1            ) => __add!(model, history, :dynamics, e, debug)
                    :( $x'($t) == $e1, $label    ) => __add!(model, history, :dynamics, e, debug)
                    :( $e1 == $e2                ) => __add!(model, history, :constraints, e, debug)
                    :( $e1 == $e2, $label        ) => __add!(model, history, :constraints, e, debug)
                    :( $e1 ≤  $e2 ≤  $e3         ) => __add!(model, history, :constraints, e, debug)
                    :( $e1 ≤  $e2 ≤  $e3, $label ) => __add!(model, history, :constraints, e, debug)
                    :( $e_ → min                 ) => __add!(model, history, :objective, e, debug)
                    :( $e_ → max                 ) => __add!(model, history, :objective, e, debug)
                    _ => (return e)
                end
                code = __code(model, history)
                display_code && (display_model ? __println_code(code) : __print_code(code))
                eval(quote @def ocp $code end)
                return display_model ? :(ocp) : :()
            end
        end
    end

    initrepl(parse_to_expr,
            prompt_text="ct> ",
            prompt_color = :magenta,
            start_key=')',
            mode_name="ct_mode",
            valid_input_checker=complete_julia,
            startup_text=false)

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

    return sol

end

__init_repl()