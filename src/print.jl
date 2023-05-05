# --------------------------------------------------------------------------------------------------
# model
#
#
# Display: text/html ?  
# Base.show, Base.print
# pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
"""
$(TYPEDSIGNATURES)

Print the optimal control problem.
"""
function Base.show(io::IO, ::MIME"text/plain", ocp::OptimalControlModel{time_dependence, vd}) where {time_dependence, vd}

    if  isnothing(ocp.initial_time) &&
        isnothing(ocp.final_time) &&
        isnothing(ocp.time_name) &&
        isnothing(ocp.lagrange) &&
        isnothing(ocp.mayer) && 
        isnothing(ocp.criterion) &&
        isnothing(ocp.dynamics) &&
        isnothing(ocp.state_dimension) &&
        isnothing(ocp.state_names)  &&
        isnothing(ocp.control_dimension) &&
        isnothing(ocp.control_names)
        printstyled(io, "Empty optimal control problem", bold=true)
        return
    end

    # dimensions
    dimx = isnothing(ocp.state_dimension) ? "n" : ocp.state_dimension
    dimu = isnothing(ocp.control_dimension) ? "m" : ocp.control_dimension

    # 
    printstyled(io, "Optimal control problem of the form:\n", bold=true)
    println(io, "")

    is_t0_free = isnothing(ocp.initial_time)
    is_tf_free = isnothing(ocp.final_time)

    # time name
    t_name = isnothing(ocp.time_name) ? "t" : ocp.time_name

    # construct J
    sJ = "J("
    is_t0_free ? sJ = sJ * "t0, " : nothing
    is_tf_free ? sJ = sJ * "tf, " : nothing
    sJ = sJ * "x, u)"
    printstyled(io, "    minimize  ", color=:blue); print(io, sJ * " = ")

    # Mayer
    if !isnothing(ocp.mayer)
        sg = "g("
        is_t0_free ? sg = sg * t_name * "0, " : nothing
        sg = sg * "x(" * t_name * "0), "
        is_tf_free ? sg = sg * t_name * "f, " : nothing
        sg = sg * "x(" * t_name * "f))"
        print(io, sg)
    end

    #
    if !isnothing(ocp.mayer) && !isnothing(ocp.lagrange)
        print(io, " +")
    end

    # Lagrange
    if !isnothing(ocp.lagrange)
        is_time_dependent(ocp) ? 
        println(io, '\u222B', " f⁰(" * t_name * ", x(" * t_name * "), u(" * t_name * ")) d" * t_name * ", over [" * t_name * "0, " * t_name * "f]") : 
        println(io, '\u222B', " f⁰(x(" * t_name * "), u(" * t_name * ")) d" * t_name * ", over [" * t_name * "0, " * t_name * "f]")
    else
        println(io, "")
    end

    # constraints
    println(io, "")
    printstyled(io, "    subject to\n", color=:blue)
    println(io, "")

    # dynamics
    is_time_dependent(ocp) ? 
    println(io, "        x", '\u0307', "(" * t_name * ") = f(" * t_name * ", x(" * t_name * "), u(" * t_name * ")), " * t_name * " in [" * t_name * "0, " * t_name * "f] a.e.,") : 
    println(io, "        x", '\u0307', "(" * t_name * ") = f(x(" * t_name * "), u(" * t_name * ")), " * t_name * " in [" * t_name * "0, " * t_name * "f] a.e.,")
    println(io, "")

    # other constraints: control, state, mixed, boundary, bounds on u, bounds on x
    (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)
    has_constraints = false
    if !isempty(ξl) || !isempty(ulb)
        has_constraints = true
        is_time_dependent(ocp) ? 
        println(io, "        ξl ≤ ξ(" * t_name * ", u(" * t_name * ")) ≤ ξu, ") :
        println(io, "        ξl ≤ ξ(u(" * t_name * ")) ≤ ξu, ") 
    end
    if !isempty(ηl) || !isempty(xlb)
        has_constraints = true
        is_time_dependent(ocp) ? 
        println(io, "        ηl ≤ η(" * t_name * ", x(" * t_name * ")) ≤ ηu, ") :
        println(io, "        ηl ≤ η(x(" * t_name * ")) ≤ ηu, ") 
    end
    if !isempty(ψl)
        has_constraints = true
        is_time_dependent(ocp) ? 
        println(io, "        ψl ≤ ψ(" * t_name * ", x(" * t_name * "), u(" * t_name * ")) ≤ ψu, ") :
        println(io, "        ψl ≤ ψ(x(" * t_name * "), u(" * t_name * ")) ≤ ψu, ") 
    end
    if !isempty(ϕl)
        has_constraints = true
        sϕ = "ϕ("
        is_t0_free ? sϕ = sϕ * t_name * "0, " : nothing
        sϕ = sϕ * "x(" * t_name * "0), "
        is_tf_free ? sϕ = sϕ * t_name * "f, " : nothing
        sϕ = sϕ * "x(" * t_name * "f))"
        println(io, "        ϕl ≤ ", sϕ, " ≤ ϕu, ")
    end
    has_constraints ? println(io, "") : nothing
    x_space = "R" * (dimx isa Integer ? (dimx == 1 ? "" : ctupperscripts(dimx)) : Base.string("^", dimx))
    u_space = "R" * (dimu isa Integer ? (dimu == 1 ? "" : ctupperscripts(dimu)) : Base.string("^", dimu))
    state_name = "x(" * t_name * ")"
    if !isnothing(ocp.state_names) && dimx isa Integer && dimx > 1 && dimx == length(ocp.state_names)
        state_name = state_name * " = ("
        for i ∈ 1:dimx
            state_name = state_name * ocp.state_names[i] * "(" * t_name * ")"
            if i < dimx
                state_name = state_name * ", "
            end
        end
        state_name = state_name * ")"
    elseif !isnothing(ocp.state_names) && dimx isa Integer && dimx == 1 && dimx == length(ocp.state_names)
        if ocp.state_names[1] != "x"
            state_name = state_name * " = " * ocp.state_names[1] * "(" * t_name * ")"
        end
    end
    control_name = "u(" * t_name * ")"
    if !isnothing(ocp.control_names) && dimu isa Integer && dimu > 1 && dimu == length(ocp.control_names)
        control_name = control_name * " = ("
        for i ∈ 1:dimu
            control_name = control_name * ocp.control_names[i] * "(" * t_name * ")"
            if i < dimu
                control_name = control_name * ", "
            end
        end
        control_name = control_name * ")"
    elseif !isnothing(ocp.control_names) && dimu isa Integer && dimu == 1 && dimu == length(ocp.control_names)
        if ocp.control_names[1] != "u"
            control_name = control_name * " = " * ocp.control_names[1] * "(" * t_name * ")"
        end
    end
    print(io, "    where ", state_name," ∈ ", x_space)
    print(io, " and ", control_name," ∈ ", u_space, ".")
    println(io, "")
    println(io, "")
    nb_fixed = 0
    s = ""
    if !is_t0_free # t0 is fixed
        s = s * t_name * "0"
        nb_fixed += 1
    end
    if !is_tf_free # tf is fixed
        s == "" ? s = s * t_name * "f" : s = s * ", " * t_name * "f"
        nb_fixed += 1
    end
    if nb_fixed > 1
        s = s * " are fixed."
    elseif nb_fixed == 1
        s = s * " is fixed."
    end
    if nb_fixed > 0
        println(io, "    Besides, ", s)
    end

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
    nothing
end