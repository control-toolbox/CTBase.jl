# --------------------------------------------------------------------------------------------------
# model
#
# Display: text/html ?
# Base.show, Base.print
# pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing

__print(e::Expr, io::IO, l::Int) = begin
    @match e begin
        :(($a, $b)) => println(io, " "^l, a, ", ", b)
        _ => println(io, " "^l, e)
    end
end

"""
$(TYPEDSIGNATURES)

Print the optimal control problem.
"""
function Base.show(
    io::IO,
    ::MIME"text/plain",
    ocp::OptimalControlModel{<:TimeDependence,<:VariableDependence},
)

    # check if the problem is empty
    __is_empty(ocp) && return nothing

    #
    some_printing = false

    # print the code of the model if model_expression(ocp) is not nothing
    if !isnothing(model_expression(ocp))

        # some checks
        @assert hasproperty(model_expression(ocp), :head)

        #
        #println(io)
        if __is_complete(ocp)
            printstyled(io, "The "; bold=true)
            if is_time_dependent(ocp)
                printstyled(io, "(non autonomous) "; bold=true)
            else
                printstyled(io, "(autonomous) "; bold=true)
            end
            printstyled(io, "optimal control problem is given by:\n"; bold=true)
        else
            printstyled(
                io, "The optimal control problem is not complete but made of:\n"; bold=true
            )
        end
        println(io)

        # print the code
        tab = 4
        code = striplines(model_expression(ocp))
        @match code.head begin
            :block => [__print(code.args[i], io, tab) for i in eachindex(code.args)]
            _ => __print(code, io, tab)
        end

        some_printing = true
    end

    if __is_complete(ocp) # print the model if is is complete

        # dimensions
        x_dim = state_dimension(ocp)
        u_dim = control_dimension(ocp)
        v_dim = is_variable_dependent(ocp) ? variable_dimension(ocp) : -1

        # names
        t_name = time_name(ocp)
        t0_name = initial_time_name(ocp)
        tf_name = final_time_name(ocp)
        x_name = state_name(ocp)
        u_name = control_name(ocp)
        v_name = is_variable_dependent(ocp) ? variable_name(ocp) : ""
        xi_names = state_components_names(ocp)
        ui_names = control_components_names(ocp)
        vi_names = is_variable_dependent(ocp) ? variable_components_names(ocp) : []

        # dependencies
        t_ = is_time_dependent(ocp) ? t_name * ", " : ""
        _v = is_variable_dependent(ocp) ? ", " * v_name : ""

        # other names
        bounds_args_names =
            x_name * "(" * t0_name * "), " * x_name * "(" * tf_name * ")" * _v
        mixed_args_names =
            t_ * x_name * "(" * t_name * "), " * u_name * "(" * t_name * ")" * _v
        state_args_names = t_ * x_name * "(" * t_name * ")" * _v
        control_args_names = t_ * u_name * "(" * t_name * ")" * _v

        #
        some_printing && println(io)
        printstyled(io, "The "; bold=true)
        if is_time_dependent(ocp)
            printstyled(io, "(non autonomous) "; bold=true)
        else
            printstyled(io, "(autonomous) "; bold=true)
        end
        printstyled(io, "optimal control problem is of the form:\n"; bold=true)
        println(io)

        # J
        printstyled(io, "    minimize  "; color=:blue)
        print(io, "J(" * x_name * ", " * u_name * _v * ") = ")

        # Mayer
        !isnothing(mayer(ocp)) && print(io, "g(" * bounds_args_names * ")")
        (!isnothing(mayer(ocp)) && !isnothing(lagrange(ocp))) && print(io, " + ")

        # Lagrange
        if !isnothing(lagrange(ocp))
            println(
                io,
                '\u222B',
                " f⁰(" *
                mixed_args_names *
                ") d" *
                t_name *
                ", over [" *
                t0_name *
                ", " *
                tf_name *
                "]",
            )
        else
            println(io, "")
        end

        # constraints
        println(io, "")
        printstyled(io, "    subject to\n"; color=:blue)
        println(io, "")

        # dynamics
        println(
            io,
            "        " * x_name,
            '\u0307',
            "(" *
            t_name *
            ") = f(" *
            mixed_args_names *
            "), " *
            t_name *
            " in [" *
            t0_name *
            ", " *
            tf_name *
            "] a.e.,",
        )
        println(io, "")

        # other constraints: control, state, mixed, boundary, bounds on u, bounds on x
        (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints!(
            ocp
        )
        has_constraints = false
        if !isempty(ξl) || !isempty(ulb)
            has_constraints = true
            println(io, "        ξl ≤ ξ(" * control_args_names * ") ≤ ξu, ")
        end
        if !isempty(ηl) || !isempty(xlb)
            has_constraints = true
            println(io, "        ηl ≤ η(" * state_args_names * ") ≤ ηu, ")
        end
        if !isempty(ψl)
            has_constraints = true
            println(io, "        ψl ≤ ψ(" * mixed_args_names * ") ≤ ψu, ")
        end
        if !isempty(ϕl)
            has_constraints = true
            println(io, "        ϕl ≤ ϕ(" * bounds_args_names * ") ≤ ϕu, ")
        end
        has_constraints ? println(io, "") : nothing

        # spaces
        x_space = "R" * (x_dim == 1 ? "" : ctupperscripts(x_dim))
        u_space = "R" * (u_dim == 1 ? "" : ctupperscripts(u_dim))

        # state name and space
        if x_dim == 1
            x_name_space = x_name * "(" * t_name * ")"
        else
            x_name_space = x_name * "(" * t_name * ")"
            if xi_names != [x_name * ctindices(i) for i in range(1, x_dim)]
                x_name_space *= " = ("
                for i in 1:x_dim
                    x_name_space *= xi_names[i] * "(" * t_name * ")"
                    i < x_dim && (x_name_space *= ", ")
                end
                x_name_space *= ")"
            end
        end
        x_name_space *= " ∈ " * x_space

        # control name and space
        if u_dim == 1
            u_name_space = u_name * "(" * t_name * ")"
        else
            u_name_space = u_name * "(" * t_name * ")"
            if ui_names != [u_name * ctindices(i) for i in range(1, u_dim)]
                u_name_space *= " = ("
                for i in 1:u_dim
                    u_name_space *= ui_names[i] * "(" * t_name * ")"
                    i < u_dim && (u_name_space *= ", ")
                end
                u_name_space *= ")"
            end
        end
        u_name_space *= " ∈ " * u_space

        if is_variable_dependent(ocp)
            # space
            v_space = "R" * (v_dim == 1 ? "" : ctupperscripts(v_dim))
            # variable name and space
            if v_dim == 1
                v_name_space = v_name
            else
                v_name_space = v_name
                if vi_names != [v_name * ctindices(i) for i in range(1, v_dim)]
                    v_name_space *= " = ("
                    for i in 1:v_dim
                        v_name_space *= vi_names[i]
                        i < v_dim && (v_name_space *= ", ")
                    end
                    v_name_space *= ")"
                end
            end
            v_name_space *= " ∈ " * v_space
            # print
            print(
                io,
                "    where ",
                x_name_space,
                ", ",
                u_name_space,
                " and ",
                v_name_space,
                ".\n",
            )
        else
            # print
            print(io, "    where ", x_name_space, " and ", u_name_space, ".\n")
        end

        some_printing = true
    end

    #
    some_printing && println(io)
    printstyled(io, "Declarations "; bold=true)
    printstyled(io, "(* required):\n"; bold=false)
    #println(io)

    # print table of settings
    header = ["times*", "state*", "control*"]
    #is_variable_dependent(ocp) && push!(header, "variable")
    push!(header, "variable")
    push!(header, "dynamics*", "objective*", "constraints")
    data = hcat(
        __is_time_not_set(ocp) ? "X" : "V",
        __is_state_not_set(ocp) ? "X" : "V",
        __is_control_not_set(ocp) ? "X" : "V",
    )
    #is_variable_dependent(ocp) && 
    begin
        (data = hcat(data, __is_variable_not_set(ocp) ? "X" : "V"))
    end
    data = hcat(
        data,
        __is_dynamics_not_set(ocp) ? "X" : "V",
        __is_objective_not_set(ocp) ? "X" : "V",
        isempty(constraints(ocp)) ? "X" : "V",
    )
    println("")
    h1 = Highlighter((data, i, j) -> data[i, j] == "X"; bold=true, foreground=:red)
    h2 = Highlighter((data, i, j) -> data[i, j] == "V"; bold=true, foreground=:green)
    pretty_table(
        io,
        data;
        tf=tf_unicode_rounded,
        header=header,
        header_crayon=crayon"yellow",
        crop=:none,
        highlighters=(h1, h2),
        alignment=:c,
        compact_printing=true,
    )
    return nothing
end

function Base.show_default(io::IO, ocp::OptimalControlModel)
    return print(io, typeof(ocp))
    #show(io, MIME("text/plain"), ocp)
end

# --------------------------------------------------------------------------------------------------
# solution
#
# we get an error when a solution is printed so I add this function
# which has to be put in the package CTBase and has to be completed
"""
$(TYPEDSIGNATURES)

Prints the solution.
"""
function Base.show(io::IO, ::MIME"text/plain", sol::OptimalControlSolution)
    return print(io, typeof(sol))
end

function Base.show_default(io::IO, sol::OptimalControlSolution)
    return print(io, typeof(sol))
    #show(io, MIME("text/plain"), sol)
end
