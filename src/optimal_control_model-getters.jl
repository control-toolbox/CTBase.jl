# ----------------------------------------------------------------------
#
# Model getters.
#
# todo: use copyto! instead of r[:] = view(u, rg) in nlp_constraints!
#

"""
$(TYPEDSIGNATURES)

Return a 6-tuple of tuples:

- `(ξl, ξ, ξu)` are control constraints
- `(ηl, η, ηu)` are state constraints
- `(ψl, ψ, ψu)` are mixed constraints
- `(ϕl, ϕ, ϕu)` are boundary constraints
- `(θl, θ, θu)` are variable constraints
- `(ul, uind, uu)` are control linear constraints of a subset of indices
- `(xl, xind, xu)` are state linear constraints of a subset of indices
- `(vl, vind, vu)` are variable linear constraints of a subset of indices

and update information about constraints dimensions of  `ocp`. Functions `ξ`, `η`, `ψ`, `ϕ`, `θ` are used to evaluate the constraints at given time and state, control, or variable values. These functions are in place when the problem is
defined as in place, that is when `is_in_place(ocp)`.

!!! note

    - The dimensions of the state and control must be set before calling `nlp_constraints!`.
    - For a `Fixed` problem, dimensions associated with constraints on the variable are set to zero.

# Example

```@example
julia> (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (θl, θ, θu),
    (ul, uind, uu), (xl, xind, xu), (vl, vind, vu) = nlp_constraints!(ocp)
```
"""
function nlp_constraints!(ocp::OptimalControlModel)

    # we check if the dimensions and times have been set
    __check_all_set(ocp)

    ControlConstraint_ = is_in_place(ocp) ? ControlConstraint! : ControlConstraint
    StateConstraint_ = is_in_place(ocp) ? StateConstraint! : StateConstraint
    MixedConstraint_ = is_in_place(ocp) ? MixedConstraint! : MixedConstraint
    BoundaryConstraint_ = is_in_place(ocp) ? BoundaryConstraint! : BoundaryConstraint
    VariableConstraint_ = is_in_place(ocp) ? VariableConstraint! : VariableConstraint

    ξf = Vector{ControlConstraint_}()
    ξs = Vector{Int64}()
    ξl = Vector{ctNumber}()
    ξu = Vector{ctNumber}()

    ηf = Vector{StateConstraint_}()
    ηs = Vector{Int64}()
    ηl = Vector{ctNumber}()
    ηu = Vector{ctNumber}()

    ψf = Vector{MixedConstraint_}()
    ψs = Vector{Int64}()
    ψl = Vector{ctNumber}()
    ψu = Vector{ctNumber}()

    ϕf = Vector{BoundaryConstraint_}()
    ϕs = Vector{Int64}()
    ϕl = Vector{ctNumber}()
    ϕu = Vector{ctNumber}()

    θf = Vector{VariableConstraint_}()
    θs = Vector{Int64}()
    θl = Vector{ctNumber}()
    θu = Vector{ctNumber}()

    uind = Vector{Int}()
    ul = Vector{ctNumber}()
    uu = Vector{ctNumber}()

    xind = Vector{Int}()
    xl = Vector{ctNumber}()
    xu = Vector{ctNumber}()

    vind = Vector{Int}()
    vl = Vector{ctNumber}()
    vu = Vector{ctNumber}()

    for (_, c) ∈ constraints(ocp)
        @match c begin
            (type, f::BoundaryConstraint_, lb, ub) && if type ∈ [:initial, :final, :boundary] end => begin
                push!(ϕf, f)
                push!(ϕs, length(lb))
                append!(ϕl, lb)
                append!(ϕu, ub)
            end
            (:control, f::ControlConstraint_, lb, ub) => begin
                push!(ξf, f)
                push!(ξs, length(lb))
                append!(ξl, lb)
                append!(ξu, ub)
            end
            (:control, rg, lb, ub) => begin
                append!(uind, rg)
                append!(ul, lb)
                append!(uu, ub)
            end
            (:state, f::StateConstraint_, lb, ub) => begin
                push!(ηf, f)
                push!(ηs, length(lb))
                append!(ηl, lb)
                append!(ηu, ub)
            end
            (:state, rg, lb, ub) => begin
                append!(xind, rg)
                append!(xl, lb)
                append!(xu, ub)
            end
            (:mixed, f::MixedConstraint_, lb, ub) => begin
                push!(ψf, f)
                push!(ψs, length(lb))
                append!(ψl, lb)
                append!(ψu, ub)
            end
            (:variable, f::VariableConstraint_, lb, ub) => begin
                push!(θf, f)
                push!(θs, length(lb))
                append!(θl, lb)
                append!(θu, ub)
            end
            (:variable, rg, lb, ub) => begin
                append!(vind, rg)
                append!(vl, lb)
                append!(vu, ub)
            end
            _ => error("Internal error")
        end
    end

    @assert length(ξl) == length(ξu)
    @assert length(ξf) == length(ξs)
    @assert length(ηl) == length(ηu)
    @assert length(ηf) == length(ηs)
    @assert length(ψl) == length(ψu)
    @assert length(ψf) == length(ψs)
    @assert length(ϕl) == length(ϕu)
    @assert length(ϕf) == length(ϕs)
    @assert length(θl) == length(θu)
    @assert length(θf) == length(θs)
    @assert length(ul) == length(uu)
    @assert length(xl) == length(xu)
    @assert length(vl) == length(vu)

    function ξ(t, u, v) # nonlinear control constraints
        dim = length(ξl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ξf)
            li = ξs[i]
            vali = ξf[i](t, u, v)
            val[j:(j + li - 1)] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function ξ!(val, t, u, v) # nonlinear control constraints (in place)
        j = 1
        for i ∈ 1:length(ξf)
            li = ξs[i]
            ξf[i](view(val, j:(j + li - 1)), t, u, v)
            j = j + li
        end
        return nothing
    end

    function η(t, x, v) # nonlinear state constraints
        dim = length(ηl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ηf)
            li = ηs[i]
            vali = ηf[i](t, x, v)
            val[j:(j + li - 1)] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function η!(val, t, x, v) # nonlinear state constraints (in place)
        j = 1
        for i ∈ 1:length(ηf)
            li = ηs[i]
            ηf[i](view(val, j:(j + li - 1)), t, x, v)
            j = j + li
        end
        return nothing
    end

    function ψ(t, x, u, v) # nonlinear mixed constraints
        dim = length(ψl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ψf)
            li = ψs[i]
            vali = ψf[i](t, x, u, v)
            val[j:(j + li - 1)] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function ψ!(val, t, x, u, v) # nonlinear mixed constraints (in place)
        j = 1
        for i ∈ 1:length(ψf)
            li = ψs[i]
            ψf[i](view(val, j:(j + li - 1)), t, x, u, v)
            j = j + li
        end
        return nothing
    end

    function ϕ(x0, xf, v) # nonlinear boundary constraints
        dim = length(ϕl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ϕf)
            li = ϕs[i]
            vali = ϕf[i](x0, xf, v)
            val[j:(j + li - 1)] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function ϕ!(val, x0, xf, v) # nonlinear boundary constraints
        j = 1
        for i ∈ 1:length(ϕf)
            li = ϕs[i]
            ϕf[i](view(val, j:(j + li - 1)), x0, xf, v)
            j = j + li
        end
        return nothing
    end

    function θ(v) # nonlinear variable constraints
        dim = length(θl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(θf)
            li = θs[i]
            vali = θf[i](v)
            val[j:(j + li - 1)] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function θ!(val, v) # nonlinear variable constraints
        j = 1
        for i ∈ 1:length(θf)
            li = θs[i]
            θf[i](view(val, j:(j + li - 1)), v)
            j = j + li
        end
        return nothing
    end

    ocp.dim_control_constraints = length(ξl)
    ocp.dim_state_constraints = length(ηl)
    ocp.dim_mixed_constraints = length(ψl)
    ocp.dim_boundary_constraints = length(ϕl)
    ocp.dim_variable_constraints = length(θl)
    ocp.dim_control_range = length(ul)
    ocp.dim_state_range = length(xl)
    ocp.dim_variable_range = length(vl)

    ξ_ = is_in_place(ocp) ? ξ! : ξ
    η_ = is_in_place(ocp) ? η! : η
    ψ_ = is_in_place(ocp) ? ψ! : ψ
    ϕ_ = is_in_place(ocp) ? ϕ! : ϕ
    θ_ = is_in_place(ocp) ? θ! : θ

    return (ξl, ξ_, ξu),
           (ηl, η_, ηu),
           (ψl, ψ_, ψu),
           (ϕl, ϕ_, ϕu),
           (θl, θ_, θu),
           (ul, uind, uu),
           (xl, xind, xu),
           (vl, vind, vu)
end

"""
$(TYPEDSIGNATURES)

Return the constraints of the ocp or nothing.

"""
function constraints(ocp::OptimalControlModel)
    return ocp.constraints
end

"""
$(TYPEDSIGNATURES)

Return the labels of the constraints as a `Base.keys`.

"""
function constraints_labels(ocp::OptimalControlModel)
    return keys(ocp.constraints)
end

"""
$(TYPEDSIGNATURES)

Retrieve a labeled constraint. The result is a function associated with the constraint
computation (not taking into account provided value / bounds).

# Example

```@example
julia> constraint!(ocp, :initial, 0, :c0)
julia> c = constraint(ocp, :c0)
julia> c(1)
1
```
"""
function constraint(
    ocp::OptimalControlModel{T, V},
    label::Symbol,
) where {T <: TimeDependence, V <: VariableDependence}
    con = ocp.constraints[label]
    BoundaryConstraint_ = is_in_place(ocp) ? BoundaryConstraint! : BoundaryConstraint
    ControlConstraint_ = is_in_place(ocp) ? ControlConstraint! : ControlConstraint
    StateConstraint_ = is_in_place(ocp) ? StateConstraint! : StateConstraint
    MixedConstraint_ = is_in_place(ocp) ? MixedConstraint! : MixedConstraint
    VariableConstraint_ = is_in_place(ocp) ? VariableConstraint! : VariableConstraint

    @match con begin
        (:initial, f::BoundaryConstraint_, _, _) => return f
        (:final, f::BoundaryConstraint_, _, _) => return f
        (:boundary, f::BoundaryConstraint_, _, _) => return f
        (:control, f::ControlConstraint_, _, _) => return f
        (:control, rg, _, _) => begin
            C = @match ocp begin
                ::OptimalControlModel{Autonomous, Fixed} => is_in_place(ocp) ?
                    ControlConstraint!((r, u) -> (r[:] = view(u, rg); nothing), T, V) :
                    ControlConstraint(u -> u[rg], T, V)
                ::OptimalControlModel{Autonomous, NonFixed} => is_in_place(ocp) ?
                    ControlConstraint!((r, u, v) -> (r[:] = view(u, rg); nothing), T, V) :
                    ControlConstraint((u, v) -> u[rg], T, V)
                ::OptimalControlModel{NonAutonomous, Fixed} => is_in_place(ocp) ?
                    ControlConstraint!((r, t, u) -> (r[:] = view(u, rg); nothing), T, V) :
                    ControlConstraint((t, u) -> u[rg], T, V)
                ::OptimalControlModel{NonAutonomous, NonFixed} => is_in_place(ocp) ?
                    ControlConstraint!((r, t, u, v) -> (r[:] = view(u, rg); nothing), T, V) :
                    ControlConstraint((t, u, v) -> u[rg], T, V)
                _ => nothing
            end
            return C
        end
        (:state, f::StateConstraint_, _, _) => return f
        (:state, rg, _, _) => begin
            S = @match ocp begin
                ::OptimalControlModel{Autonomous, Fixed} => is_in_place(ocp) ?
                    StateConstraint!((r, x) -> (r[:] = view(x, rg); nothing), T, V) :
                    StateConstraint(x -> x[rg], T, V)
                ::OptimalControlModel{Autonomous, NonFixed} => is_in_place(ocp) ?
                    StateConstraint!((r, x, v) -> (r[:] = view(x, rg); nothing), T, V) :
                    StateConstraint((x, v) -> x[rg], T, V)
                ::OptimalControlModel{NonAutonomous, Fixed} => is_in_place(ocp) ?
                    StateConstraint!((r, t, x) -> (r[:] = view(x, rg); nothing), T, V) :
                    StateConstraint((t, x) -> x[rg], T, V)
                ::OptimalControlModel{NonAutonomous, NonFixed} => is_in_place(ocp) ?
                    StateConstraint!((r, t, x, v) -> (r[:] = view(x, rg); nothing), T, V) :
                    StateConstraint((t, x, v) -> x[rg], T, V)
                _ => nothing
            end
            return S
        end
        (:mixed, f::MixedConstraint_, _, _) => return f
        (:variable, f::VariableConstraint_, _, _) => return f
        (:variable, rg, _, _) => return ( is_in_place(ocp) ?
            VariableConstraint!((r, v) -> (r[:] = view(v, rg); nothing)) :
            VariableConstraint(v -> v[rg]) )
        _ => error("Internal error")
    end
end

"""
$(TYPEDSIGNATURES)

Return the dimension of nonlinear state constraints (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_state_constraints(ocp::OptimalControlModel) = ocp.dim_state_constraints

"""
$(TYPEDSIGNATURES)

Return the dimension of nonlinear control constraints (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_control_constraints(ocp::OptimalControlModel) = ocp.dim_control_constraints

"""
$(TYPEDSIGNATURES)

Return the dimension of nonlinear mixed constraints (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_mixed_constraints(ocp::OptimalControlModel) = ocp.dim_mixed_constraints

"""
$(TYPEDSIGNATURES)

Return the dimension of nonlinear path (state + control + mixed) constraints (`nothing` if one of them is not knonw).
Information is updated after `nlp_constraints!` is called.
"""
function dim_path_constraints(ocp::OptimalControlModel)
    isnothing(ocp.dim_control_constraints) && return nothing
    isnothing(ocp.dim_state_constraints) && return nothing
    isnothing(ocp.dim_mixed_constraints) && return nothing
    return ocp.dim_state_constraints + ocp.dim_control_constraints + ocp.dim_mixed_constraints
end

"""
$(TYPEDSIGNATURES)

Return the dimension of the boundary constraints (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_boundary_constraints(ocp::OptimalControlModel) = ocp.dim_boundary_constraints

"""
$(TYPEDSIGNATURES)

Return the dimension of nonlinear variable constraints (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_variable_constraints(ocp::OptimalControlModel) = ocp.dim_variable_constraints

"""
$(TYPEDSIGNATURES)

Return the dimension of range constraints on state (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_state_range(ocp::OptimalControlModel) = ocp.dim_state_range

"""
$(TYPEDSIGNATURES)

Return the dimension of range constraints on control (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_control_range(ocp::OptimalControlModel) = ocp.dim_control_range

"""
$(TYPEDSIGNATURES)

Return the dimension of range constraints on variable (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_variable_range(ocp::OptimalControlModel) = ocp.dim_variable_range

"""
$(TYPEDSIGNATURES)

Return the model expression of the optimal control problem or `nothing`.

"""
model_expression(ocp::OptimalControlModel) = ocp.model_expression

"""
$(TYPEDSIGNATURES)

Return the initial time of the optimal control problem or `nothing`.

"""
initial_time(ocp::OptimalControlModel) = ocp.initial_time

"""
$(TYPEDSIGNATURES)

Return the name of the initial time of the optimal control problem or `nothing`.

"""
initial_time_name(ocp::OptimalControlModel) = ocp.initial_time_name

"""
$(TYPEDSIGNATURES)

Return the final time of the optimal control problem or `nothing`.

"""
final_time(ocp::OptimalControlModel) = ocp.final_time

"""
$(TYPEDSIGNATURES)

Return the name of the final time of the optimal control problem or `nothing`.

"""
final_time_name(ocp::OptimalControlModel) = ocp.final_time_name

"""
$(TYPEDSIGNATURES)

Return the name of the time component of the optimal control problem or `nothing`.

"""
time_name(ocp::OptimalControlModel) = ocp.time_name

"""
$(TYPEDSIGNATURES)

Return the dimention of the control of the optimal control problem or `nothing`.

"""
control_dimension(ocp::OptimalControlModel) = ocp.control_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the control of the optimal control problem or `nothing`.

"""
control_components_names(ocp::OptimalControlModel) = ocp.control_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the control of the optimal control problem or `nothing`.

"""
control_name(ocp::OptimalControlModel) = ocp.control_name

"""
$(TYPEDSIGNATURES)

Return the dimension of the state of the optimal control problem or `nothing`.

"""
state_dimension(ocp::OptimalControlModel) = ocp.state_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the state of the optimal control problem or `nothing`.

"""
state_components_names(ocp::OptimalControlModel) = ocp.state_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the state of the optimal control problem or `nothing`.

"""
state_name(ocp::OptimalControlModel) = ocp.state_name

"""
$(TYPEDSIGNATURES)

Return the dimension of the variable of the optimal control problem or `nothing`.

"""
variable_dimension(ocp::OptimalControlModel) = ocp.variable_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the variable of the optimal control problem or `nothing`.

"""
variable_components_names(ocp::OptimalControlModel) = ocp.variable_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the variable of the optimal control problem or `nothing`.

"""
variable_name(ocp::OptimalControlModel) = ocp.variable_name

"""
$(TYPEDSIGNATURES)

Return the Lagrange part of the cost of the optimal control problem or `nothing`.

"""
lagrange(ocp::OptimalControlModel) = ocp.lagrange

"""
$(TYPEDSIGNATURES)

Return the Mayer part of the cost of the optimal control problem or `nothing`.

"""
mayer(ocp::OptimalControlModel) = ocp.mayer

"""
$(TYPEDSIGNATURES)

Return the criterion (`:min` or `:max`) of the optimal control problem or `nothing`.

"""
criterion(ocp::OptimalControlModel) = ocp.criterion

"""
$(TYPEDSIGNATURES)

Return the dynamics of the optimal control problem or `nothing`.

"""
dynamics(ocp::OptimalControlModel) = ocp.dynamics

"""
$(TYPEDSIGNATURES)

Return `true` if the model is autonomous.
"""
is_autonomous(ocp::OptimalControlModel{Autonomous, <:VariableDependence}) = true
is_autonomous(ocp::OptimalControlModel{NonAutonomous, <:VariableDependence}) = false

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as time dependent.
"""
is_time_dependent(ocp::OptimalControlModel) = !is_autonomous(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as time independent.
"""
is_time_independent(ocp::OptimalControlModel) = !is_time_dependent(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if the criterion type of `ocp` is `:min`.
"""
is_min(ocp::OptimalControlModel) = criterion(ocp) == :min

"""
$(TYPEDSIGNATURES)

Return `true` if the criterion type of `ocp` is `:max`.
"""
is_max(ocp::OptimalControlModel) = !is_min(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if the model is fixed (= has no variable).
"""
is_fixed(ocp::OptimalControlModel{<:TimeDependence, Fixed}) = true
is_fixed(ocp::OptimalControlModel{<:TimeDependence, NonFixed}) = false

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as variable dependent.
"""
is_variable_dependent(ocp::OptimalControlModel) = !is_fixed(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as variable independent.
"""
is_variable_independent(ocp::OptimalControlModel) = !is_variable_dependent(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if functions defining the ocp are in-place. Return nothing if this information has not yet been set.
"""
is_in_place(ocp::OptimalControlModel) = ocp.in_place

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with free initial time.
"""
has_free_initial_time(ocp::OptimalControlModel) = (typeof(initial_time(ocp)) == Index)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with free final time.
"""
has_free_final_time(ocp::OptimalControlModel) = (typeof(final_time(ocp)) == Index)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with lagrange cost.
"""
has_lagrange_cost(ocp::OptimalControlModel) = !isnothing(lagrange(ocp))

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with mayer cost.
"""
has_mayer_cost(ocp::OptimalControlModel) = !isnothing(mayer(ocp))
