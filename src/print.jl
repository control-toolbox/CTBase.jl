# --------------------------------------------------------------------------------------------------
# Display: text/html ?  
# Base.show, Base.print
# pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
function Base.show(io::IO, ::MIME"text/plain", ocp::OptimalControlModel{time_dependence, dimension_usage}) where {time_dependence, dimension_usage}

    if  isnothing(ocp.initial_time) &&
        isnothing(ocp.final_time) &&
        isnothing(ocp.time_label) &&
        isnothing(ocp.lagrange) &&
        isnothing(ocp.mayer) && 
        isnothing(ocp.criterion) &&
        isnothing(ocp.dynamics) &&
        isnothing(ocp.dynamics!) &&
        isnothing(ocp.state_dimension) &&
        isempty(ocp.state_labels)  &&
        isnothing(ocp.control_dimension) &&
        isempty(ocp.control_labels)
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

    # construct J
    sJ = "J("
    is_t0_free ? sJ = sJ * "t0, " : nothing
    is_tf_free ? sJ = sJ * "tf, " : nothing
    sJ = sJ * "x, u)"
    printstyled(io, "    minimize  ", color=:blue); print(io, sJ * " = ")

    # Mayer
    if !isnothing(ocp.mayer)
        sg = "g("
        is_t0_free ? sg = sg * "t0, " : nothing
        sg = sg * "x(t0), "
        is_tf_free ? sg = sg * "tf, " : nothing
        sg = sg * "x(tf))"
        print(io, sg)
    end

    #
    if !isnothing(ocp.mayer) && !isnothing(ocp.lagrange)
        print(io, " +")
    end

    # Lagrange
    if !isnothing(ocp.lagrange)
        isnonautonomous(ocp) ? 
        println(io, '\u222B', " f⁰(t, x(t), u(t)) dt, over [t0, tf]") : 
        println(io, '\u222B', " f⁰(x(t), u(t)) dt, over [t0, tf]")
    end

    # constraints
    println(io, "")
    printstyled(io, "    subject to\n", color=:blue)
    println(io, "")

    # dynamics
    isnonautonomous(ocp) ? 
    println(io, "        x", '\u0307', "(t) = f(t, x(t), u(t)), t in [t0, tf] a.e.,") : 
    println(io, "        x", '\u0307', "(t) = f(x(t), u(t)), t in [t0, tf] a.e.,")
    println(io, "")

    # other constraints: control, state, mixed, boundary, bounds on u, bounds on x
    (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)
    has_constraints = false
    if !isempty(ξl) || !isempty(ulb)
        has_constraints = true
        isnonautonomous(ocp) ? 
        println(io, "        ξl ≤ ξ(t, u(t)) ≤ ξu, ") :
        println(io, "        ξl ≤ ξ(u(t)) ≤ ξu, ") 
    end
    if !isempty(ηl) || !isempty(xlb)
        has_constraints = true
        isnonautonomous(ocp) ? 
        println(io, "        ηl ≤ η(t, x(t)) ≤ ηu, ") :
        println(io, "        ηl ≤ η(x(t)) ≤ ηu, ") 
    end
    if !isempty(ψl)
        has_constraints = true
        isnonautonomous(ocp) ? 
        println(io, "        ψl ≤ ψ(t, x(t), u(t)) ≤ ψu, ") :
        println(io, "        ψl ≤ ψ(x(t), u(t)) ≤ ψu, ") 
    end
    if !isempty(ϕl)
        has_constraints = true
        sϕ = "ϕ("
        is_t0_free ? sϕ = sϕ * "t0, " : nothing
        sϕ = sϕ * "x(t0), "
        is_tf_free ? sϕ = sϕ * "tf, " : nothing
        sϕ = sϕ * "x(tf))"
        println(io, "        ϕl ≤ ", sϕ, " ≤ ϕu, ")
    end
    has_constraints ? println(io, "") : nothing
    print(io, "    where x(t) ", '\u2208', " R", dimx == 1 ? "" : Base.string("^", dimx))
    print(io, " and u(t) ", '\u2208', " R", dimu == 1 ? "" : Base.string("^", dimu), ".")
    println(io, "")
    println(io, "")
    nb_fixed = 0
    s = ""
    if !is_t0_free # t0 is fixed
        s = s * "t0"
        nb_fixed += 1
    end
    if !is_tf_free # tf is fixed
        s == "" ? s = s * "tf" : s = s * ", tf"
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
