# ----------------------------------------------------------------------
#
# Interaction with the Model that affect it. Setters / Constructors.
#
# todo: use copyto! instead of r[:] = view(x0, rg)
#

"""
$(TYPEDSIGNATURES)

Set the model expression of the optimal control problem or `nothing`.

"""
model_expression!(ocp::OptimalControlModel, model_expression::Expr) =
    (ocp.model_expression = model_expression; nothing)

"""
$(TYPEDSIGNATURES)

Return a new `OptimalControlModel` instance, that is a model of an optimal control problem.

The model is defined by the following optional keyword argument:

- `autonomous`: either `true` or `false`. Default is `true`.
- `variable`: either `true` or `false`. Default is `false`.

# Examples

```@example
julia> ocp = Model()
julia> ocp = Model(autonomous=false)
julia> ocp = Model(autonomous=false, variable=true)
```

!!! note

    - If the time dependence of the model is defined as nonautonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of time and state, and possibly control. If the model is defined as autonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of state, and possibly control.

"""
function Model(; autonomous::Bool = true, variable::Bool = false, in_place::Bool = false)
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    ocp = OptimalControlModel{time_dependence, variable_dependence}()
    ocp.in_place = in_place

    return ocp
end

"""
$(TYPEDSIGNATURES)

Return a new `OptimalControlModel` instance, that is a model of an optimal control problem.

The model is defined by the following argument:

- `dependencies`: either `Autonomous` or `NonAutonomous`. Default is `Autonomous`. And either `NonFixed` or `Fixed`. Default is `Fixed`.

# Examples

```@example
julia> ocp = Model()
julia> ocp = Model(NonAutonomous)
julia> ocp = Model(Autonomous, NonFixed)
```

!!! note

    - If the time dependence of the model is defined as nonautonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of time and state, and possibly control. If the model is defined as autonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of state, and possibly control.

"""
function Model(
    dependencies::DataType...; in_place::Bool = false,
)::OptimalControlModel{<:TimeDependence, <:VariableDependence}
    # some checkings: 
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return OptimalControlModel{time_dependence, variable_dependence}(; in_place = in_place)
end

"""
$(TYPEDSIGNATURES)

Define the variable dimension and possibly the names of each component.

!!! note

    You can use variable! once to set the variable dimension when the model is `NonFixed`.

# Examples
```@example
julia> variable!(ocp, 1, "v")
julia> variable!(ocp, 2, "v", [ "v₁", "v₂" ])
```
"""
function variable!(
    ocp::OptimalControlModel,
    q::Dimension,
    name::String = __variable_name(),
    components_names::Vector{String} = __variable_components_names(q, name),
)

    # checkings
    is_fixed(ocp) &&
        throw(UnauthorizedCall("the ocp has no variable, you cannot use variable! function."))
    __is_variable_set(ocp) && throw(UnauthorizedCall("the variable has already been set."))
    (q > 1) &&
        (size(components_names, 1) ≠ q) &&
        throw(
            IncorrectArgument(
                "the number of variable names must be equal to the variable dimension",
            ),
        )

    ocp.variable_dimension = q
    ocp.variable_components_names = components_names
    ocp.variable_name = name
    return nothing
end

function variable!(
    ocp::OptimalControlModel,
    q::Dimension,
    name::Symbol,
    components_names::Vector{Symbol},
)
    variable!(ocp, q, string(name), string.(components_names))
end

function variable!(
    ocp::OptimalControlModel,
    q::Dimension,
    name::Symbol,
    components_names::Vector{String},
)
    variable!(ocp, q, string(name), components_names)
end

function variable!(ocp::OptimalControlModel, q::Dimension, name::Symbol)
    variable!(ocp, q, string(name))
end

"""
$(TYPEDSIGNATURES)

Define the state dimension and possibly the names of each component.

!!! note

    You must use state! only once to set the state dimension.

# Examples

```@example
julia> state!(ocp, 1)
julia> state_dimension(ocp)
1
julia> state_components_names(ocp)
["x"]

julia> state!(ocp, 1, "y")
julia> state_dimension(ocp)
1
julia> state_components_names(ocp)
["y"]

julia> state!(ocp, 2)
julia> state_dimension(ocp)
2
julia> state_components_names(ocp)
["x₁", "x₂"]

julia> state!(ocp, 2, :y)
julia> state_dimension(ocp)
2
julia> state_components_names(ocp)
["y₁", "y₂"]

julia> state!(ocp, 2, "y")
julia> state_dimension(ocp)
2
julia> state_components_names(ocp)
["y₁", "y₂"]
```
"""
function state!(
    ocp::OptimalControlModel,
    n::Dimension,
    name::String = __state_name(),
    components_names::Vector{String} = __state_components_names(n, name),
)

    # checkings
    __is_state_set(ocp) && throw(UnauthorizedCall("the state has already been set."))
    (n > 1) &&
        (size(components_names, 1) ≠ n) &&
        throw(IncorrectArgument("the number of state names must be equal to the state dimension"))

    ocp.state_dimension = n
    ocp.state_components_names = components_names
    ocp.state_name = name
    return nothing
end

function state!(
    ocp::OptimalControlModel,
    n::Dimension,
    name::Symbol,
    components_names::Vector{Symbol},
)
    state!(ocp, n, string(name), string.(components_names))
end

function state!(
    ocp::OptimalControlModel,
    n::Dimension,
    name::Symbol,
    components_names::Vector{String},
)
    state!(ocp, n, string(name), components_names)
end

function state!(ocp::OptimalControlModel, n::Dimension, name::Symbol)
    state!(ocp, n, string(name))
end

"""
$(TYPEDSIGNATURES)

Define the control dimension and possibly the names of each coordinate.

!!! note

    You must use control! only once to set the control dimension.

# Examples

```@example
julia> control!(ocp, 1)
julia> control_dimension(ocp)
1
julia> control_components_names(ocp)
["u"]

julia> control!(ocp, 1, "v")
julia> control_dimension(ocp)
1
julia> control_components_names(ocp)
["v"]

julia> control!(ocp, 2)
julia> control_dimension(ocp)
2
julia> control_components_names(ocp)
["u₁", "u₂"]

julia> control!(ocp, 2, :v)
julia> control_dimension(ocp)
2
julia> control_components_names(ocp)
["v₁", "v₂"]

julia> control!(ocp, 2, "v")
julia> control_dimension(ocp)
2
julia> control_components_names(ocp)
["v₁", "v₂"]
```
"""
function control!(
    ocp::OptimalControlModel,
    m::Dimension,
    name::String = __control_name(),
    components_names::Vector{String} = __control_components_names(m, name),
)

    # checkings
    __is_control_set(ocp) && throw(UnauthorizedCall("the control has already been set."))
    (m > 1) &&
        (size(components_names, 1) ≠ m) &&
        throw(
            IncorrectArgument("the number of control names must be equal to the control dimension"),
        )

    ocp.control_dimension = m
    ocp.control_components_names = components_names
    ocp.control_name = name
    return nothing
end

function control!(
    ocp::OptimalControlModel,
    m::Dimension,
    name::Symbol,
    components_names::Vector{Symbol},
)
    control!(ocp, m, string(name), string.(components_names))
end

function control!(
    ocp::OptimalControlModel,
    m::Dimension,
    name::Symbol,
    components_names::Vector{String},
)
    control!(ocp, m, string(name), components_names)
end

function control!(ocp::OptimalControlModel, m::Dimension, name::Symbol)
    control!(ocp, m, string(name))
end

"""
$(TYPEDSIGNATURES)

Set the initial and final times. We denote by t0 the initial time and tf the final time.
The optimal control problem is denoted ocp.
When a time is free, then one must provide the corresponding index of the ocp variable.

!!! note

    You must use time! only once to set either the initial or the final time, or both.

# Examples

```@example
julia> time!(ocp, t0=0,   tf=1  ) # Fixed t0 and fixed tf
julia> time!(ocp, t0=0,   indf=2) # Fixed t0 and free  tf
julia> time!(ocp, ind0=2, tf=1  ) # Free  t0 and fixed tf
julia> time!(ocp, ind0=2, indf=3) # Free  t0 and free  tf
```

When you plot a solution of an optimal control problem, the name of the time variable appears.
By default, the name is "t".
Consider you want to set the name of the time variable to "s".

```@example
julia> time!(ocp, t0=0, tf=1, name="s") # name is a String
# or
julia> time!(ocp, t0=0, tf=1, name=:s ) # name is a Symbol  
```
"""
function time!(
    ocp::OptimalControlModel{<:TimeDependence, VT};
    t0::Union{Time, Nothing} = nothing,
    tf::Union{Time, Nothing} = nothing,
    ind0::Union{Integer, Nothing} = nothing,
    indf::Union{Integer, Nothing} = nothing,
    name::Union{String, Symbol} = __time_name(),
) where {VT}

    # check if the problem has been set to Variable or NonVariable
    (VT == NonFixed) && (!isnothing(ind0) || !isnothing(indf)) && __check_variable_set(ocp)

    # check if indices are in 1:q
    q = variable_dimension(ocp)
    !isnothing(ind0) &&
        !(1 ≤ ind0 ≤ q) &&
        throw(IncorrectArgument("the index of t0 variable must be contained in 1:$q"))
    !isnothing(indf) &&
        !(1 ≤ indf ≤ q) &&
        throw(IncorrectArgument("the index of tf variable must be contained in 1:$q"))

    # check if the function has been already called
    __is_time_set(ocp) && throw(UnauthorizedCall("the time has already been set."))

    # check consistency
    !isnothing(t0) &&
        !isnothing(ind0) &&
        throw(
            IncorrectArgument(
                "Providing t0 and ind0 has no sense. The initial time cannot be fixed and free.",
            ),
        )
    isnothing(t0) &&
        isnothing(ind0) &&
        throw(
            IncorrectArgument(
                "Please either provide the value of the initial time t0 (if fixed) or its index in the variable of ocp (if free).",
            ),
        )
    !isnothing(tf) &&
        !isnothing(indf) &&
        throw(
            IncorrectArgument(
                "Providing tf and indf has no sense. The final time cannot be fixed and free.",
            ),
        )
    isnothing(tf) &&
        isnothing(indf) &&
        throw(
            IncorrectArgument(
                "Please either provide the value of the final time tf (if fixed) or its index in the variable of ocp (if free).",
            ),
        )

    VT == Fixed &&
        !isnothing(ind0) &&
        throw(
            IncorrectArgument(
                "You cannot have the initial time free (ind0 is provided) and the ocp non variable.",
            ),
        )
    VT == Fixed &&
        !isnothing(indf) &&
        throw(
            IncorrectArgument(
                "You cannot have the final time free (indf is provided) and the ocp non variable.",
            ),
        )

    #
    name = name isa String ? name : string(name)

    # core
    @match (t0, ind0, tf, indf) begin
        (::Time, ::Nothing, ::Time, ::Nothing) => begin # (t0, tf)
            ocp.initial_time = t0
            ocp.final_time = tf
            ocp.time_name = name
            ocp.initial_time_name = t0 isa Integer ? string(t0) : string(round(t0, digits = 2))
            ocp.final_time_name = tf isa Integer ? string(tf) : string(round(tf, digits = 2))
        end
        (::Nothing, ::Integer, ::Time, ::Nothing) => begin # (ind0, tf)
            ocp.initial_time = Index(ind0)
            ocp.final_time = tf
            ocp.time_name = name
            ocp.initial_time_name = variable_components_names(ocp)[ind0]
            ocp.final_time_name = tf isa Integer ? string(tf) : string(round(tf, digits = 2))
        end
        (::Time, ::Nothing, ::Nothing, ::Integer) => begin # (t0, indf)
            ocp.initial_time = t0
            ocp.final_time = Index(indf)
            ocp.time_name = name
            ocp.initial_time_name = t0 isa Integer ? string(t0) : string(round(t0, digits = 2))
            ocp.final_time_name = variable_components_names(ocp)[indf]
        end
        (::Nothing, ::Integer, ::Nothing, ::Integer) => begin # (ind0, indf)
            ocp.initial_time = Index(ind0)
            ocp.final_time = Index(indf)
            ocp.time_name = name
            ocp.initial_time_name = variable_components_names(ocp)[ind0]
            ocp.final_time_name = variable_components_names(ocp)[indf]
        end
        _ => throw(IncorrectArgument("Provided arguments are inconsistent."))
    end

    return nothing
end

"""
$(TYPEDSIGNATURES)

Add a constraint to an optimal control problem, denoted `ocp`.

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The initial and final times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

You can add an `:initial`, `:final`, `:control`, `:state` or `:variable` box constraint (whole range). 

# Range constraint on the state, control or variable

You can add an `:initial`, `:final`, `:control`, `:state` or `:variable` box constraint on a range of it, that is only on some components. If not range is specified, then the constraint is on the whole range.
We denote by `x`, `u` and `v` respectively the state, control and variable.
We denote by `n`, `m` and `q` respectively the dimension of the state, control and variable. The range of the constraint must be contained in 1:n if the constraint is on the state, or 1:m if the constraint is on the control, or 1:q if the constraint is on the variable.

## Examples

```@example
julia> constraint!(ocp, :initial; rg=1:2:5, lb=[ 0, 0, 0 ], ub=[ 1, 2, 1 ])
julia> constraint!(ocp, :initial; rg=2:3, lb=[ 0, 0 ], ub=[ 1, 2 ])
julia> constraint!(ocp, :final; rg=1, lb=0, ub=2)
julia> constraint!(ocp, :control; rg=1, lb=0, ub=2)
julia> constraint!(ocp, :state; rg=2:3, lb=[ 0, 0 ], ub=[ 1, 2 ])
julia> constraint!(ocp, :variable; rg=1:2, lb=[ 0, 0 ], ub=[ 1, 2 ])
julia> constraint!(ocp, :initial; lb=[ 0, 0, 0 ])                 # [ 0, 0, 0 ] ≤ x(t0),                          dim(x) = 3
julia> constraint!(ocp, :initial; lb=[ 0, 0, 0 ], ub=[ 1, 2, 1 ]) # [ 0, 0, 0 ] ≤ x(t0) ≤ [ 1, 2, 1 ],            dim(x) = 3
julia> constraint!(ocp, :final; lb=-1, ub=1)                      #          -1 ≤ x(tf) ≤ 1,                      dim(x) = 1
julia> constraint!(ocp, :control; lb=0, ub=2)                     #           0 ≤ u(t)  ≤ 2,        t ∈ [t0, tf], dim(u) = 1
julia> constraint!(ocp, :state; lb=[ 0, 0 ], ub=[ 1, 2 ])         #    [ 0, 0 ] ≤ x(t)  ≤ [ 1, 2 ], t ∈ [t0, tf], dim(x) = 2
julia> constraint!(ocp, :variable; lb=[ 0, 0 ], ub=[ 1, 2 ])      #    [ 0, 0 ] ≤    v  ≤ [ 1, 2 ],               dim(v) = 2
```

# Functional constraint

You can add a `:boundary`, `:control`, `:state`, `:mixed` or `:variable` box functional constraint.

## Examples

```@example
# variable independent ocp
julia> constraint!(ocp, :boundary; f = (x0, xf) -> x0[3]+xf[2], lb=0, ub=1)

# variable dependent ocp
julia> constraint!(ocp, :boundary; f = (x0, xf, v) -> x0[3]+xf[2]*v[1], lb=0, ub=1)

# time independent and variable independent ocp
julia> constraint!(ocp, :control; f = u -> 2u, lb=0, ub=1)
julia> constraint!(ocp, :state; f = x -> x-1, lb=[ 0, 0, 0 ], ub=[ 1, 2, 1 ])
julia> constraint!(ocp, :mixed; f = (x, u) -> x[1]-u, lb=0, ub=1)

# time dependent and variable independent ocp
julia> constraint!(ocp, :control; f = (t, u) -> 2u, lb=0, ub=1)
julia> constraint!(ocp, :state; f = (t, x) -> t * x, lb=[ 0, 0, 0 ], ub=[ 1, 2, 1 ])
julia> constraint!(ocp, :mixed; f = (t, x, u) -> x[1]-u, lb=0, ub=1)

# time independent and variable dependent ocp
julia> constraint!(ocp, :control; f = (u, v) -> 2u * v[1], lb=0, ub=1)
julia> constraint!(ocp, :state; f = (x, v) -> x * v[1], lb=[ 0, 0, 0 ], ub=[ 1, 2, 1 ])
julia> constraint!(ocp, :mixed; f = (x, u, v) -> x[1]-v[2]*u, lb=0, ub=1)

# time dependent and variable dependent ocp
julia> constraint!(ocp, :control; f = (t, u, v) -> 2u+v[2], lb=0, ub=1)
julia> constraint!(ocp, :state; f = (t, x, v) -> x-t*v[1], lb=[ 0, 0, 0 ], ub=[ 1, 2, 1 ])
julia> constraint!(ocp, :mixed; f = (t, x, u, v) -> x[1]*v[2]-u, lb=0, ub=1)
```

"""
function constraint!(
    ocp::OptimalControlModel{T, V},
    type::Symbol;
    rg::Union{OrdinalRange{<:Integer}, Index, Integer, Nothing} = nothing,
    f::Union{Function, Nothing} = nothing,
    lb::Union{ctVector, Nothing} = nothing,
    ub::Union{ctVector, Nothing} = nothing,
    val::Union{ctVector, Nothing} = nothing,
    label::Symbol = __constraint_label(),
) where {T <: TimeDependence, V <: VariableDependence}
    __check_all_set(ocp)
    type == :variable &&
        is_fixed(ocp) &&
        throw(
            UnauthorizedCall(
                "the ocp has no variable" *
                ", you cannot use constraint! function with type=:variable.",
            ),
        )
    label ∈ constraints_labels(ocp) &&
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    isnothing(val) &&
        isnothing(lb) &&
        isnothing(ub) &&
        throw(
            UnauthorizedCall(
                "Calling the constraint! function without any bounds is not authorized.",
            ),
        )

    # value for equality constraint
    # if val is not nothing then lb and ub should be nothing
    !isnothing(val) &&
        (!isnothing(lb) || !isnothing(ub)) &&
        throw(UnauthorizedCall("If val is provided then lb and ub must not be given."))
    if !isnothing(val)
        lb = val
        ub = val
    end

    # bounds
    isnothing(lb) && (lb = -Inf * (size(ub, 1) == 1 ? 1 : ones(eltype(ub), size(ub, 1))))
    isnothing(ub) && (ub = Inf * (size(lb, 1) == 1 ? 1 : ones(eltype(lb), size(lb, 1))))

    # dimensions
    n = state_dimension(ocp)
    m = control_dimension(ocp)
    q = variable_dimension(ocp)

    # range
    (typeof(rg) <: Int) && (rg = Index(rg)) # todo: scalar range

    # core
    BoundaryConstraint_ = is_in_place(ocp) ? BoundaryConstraint! : BoundaryConstraint
    ControlConstraint_ = is_in_place(ocp) ? ControlConstraint! : ControlConstraint
    StateConstraint_ = is_in_place(ocp) ? StateConstraint! : StateConstraint
    MixedConstraint_ = is_in_place(ocp) ? MixedConstraint! : MixedConstraint
    VariableConstraint_ = is_in_place(ocp) ? VariableConstraint! : VariableConstraint

    @match (rg, f, lb, ub) begin
        (::Nothing, ::Nothing, ::ctVector, ::ctVector) => begin
            if type ∈ [:initial, :final, :state]
                rg = n == 1 ? Index(1) : 1:n # todo: scalar range
                txt = "the lower bound `lb`, the upper bound `ub` and the value `val` must be of dimension $n"
            elseif type == :control
                rg = m == 1 ? Index(1) : 1:m
                txt = "the lower bound `lb`, the upper bound `ub` and the value `val` must be of dimension $m"
            elseif type == :variable
                rg = q == 1 ? Index(1) : 1:q
                txt = "the lower bound `lb`, the upper bound `ub` and the value `val` must be of dimension $q"
            else
                throw(
                    IncorrectArgument(
                        "the following type of constraint is not valid: " *
                        String(type) *
                        ". Please choose in [ :initial, :final, :control, :state, :variable ] or check the arguments of the constraint! method.",
                    ),
                )
            end
            (length(rg) != length(lb)) && throw(IncorrectArgument(txt))
            (length(rg) != length(ub)) && throw(IncorrectArgument(txt))
            constraint!(ocp, type; rg = rg, lb = lb, ub = ub, label = label)
        end

        (::RangeConstraint, ::Nothing, ::ctVector, ::ctVector) => begin
            txt = "the range `rg`, the lower bound `lb`, the upper bound `ub` and the value `val` must have the same dimension"
            (length(rg) != length(lb)) && throw(IncorrectArgument(txt))
            (length(rg) != length(ub)) && throw(IncorrectArgument(txt))
            # check if the range is valid
            if type == :initial
                !all(1 .≤ rg .≤ n) && throw(
                    IncorrectArgument(
                        "the range of the initial state constraint must be contained in 1:$n",
                    ),
                )
            elseif type == :final
                !all(1 .≤ rg .≤ n) && throw(
                    IncorrectArgument(
                        "the range of the final state constraint must be contained in 1:$n",
                    ),
                )
            elseif type == :control
                !all(1 .≤ rg .≤ m) && throw(
                    IncorrectArgument(
                        "the range of the control constraint must be contained in 1:$m",
                    ),
                )
            elseif type == :state
                !all(1 .≤ rg .≤ n) && throw(
                    IncorrectArgument(
                        "the range of the state constraint must be contained in 1:$n",
                    ),
                )
            elseif type == :variable
                !all(1 .≤ rg .≤ q) && throw(
                    IncorrectArgument(
                        "the range of the variable constraint must be contained in 1:$q",
                    ),
                )
            end

            # set the constraint
            fun_rg = @match type begin
                :initial =>
                    if is_in_place(ocp)
                        V == Fixed ? BoundaryConstraint!((r, x0, xf) -> (r[:] = view(x0, rg); nothing), V) :
                        BoundaryConstraint!((r, x0, xf, v) -> (r[:] = view(x0, rg); nothing), V)
                    else
                        V == Fixed ? BoundaryConstraint((x0, xf) -> x0[rg], V) :
                        BoundaryConstraint((x0, xf, v) -> x0[rg], V)
                    end
                :final =>
                    if is_in_place(ocp)
                        V == Fixed ? BoundaryConstraint!((r, x0, xf) -> (r[:] = view(xf, rg); nothing), V) :
                        BoundaryConstraint!((r, x0, xf, v) -> (r[:] = view(xf, rg); nothing), V)
                    else
                        V == Fixed ? BoundaryConstraint((x0, xf) -> xf[rg], V) :
                        BoundaryConstraint((x0, xf, v) -> xf[rg], V)
                    end
                :control || :state || :variable => rg
                _ => throw(
                    IncorrectArgument(
                        "the following type of constraint is not valid: " *
                        String(type) *
                        ". Please choose in [ :initial, :final, :control, :state, :variable ] or check the arguments of the constraint! method.",
                    ),
                )
            end
            ocp.constraints[label] = (type, fun_rg, lb, ub)
        end

        (::Nothing, ::Function, ::ctVector, ::ctVector) => begin 
                       # set the constraint
            if type == :boundary
                ocp.constraints[label] = (type, BoundaryConstraint_(f, V), lb, ub)
            elseif type == :control
                  ocp.constraints[label] = (type, ControlConstraint_(f, T, V), lb, ub)
            elseif type == :state
                ocp.constraints[label] = (type, StateConstraint_(f, T, V), lb, ub)
            elseif type == :mixed
                ocp.constraints[label] = (type, MixedConstraint_(f, T, V), lb, ub)
            elseif type == :variable
                ocp.constraints[label] = (type, VariableConstraint_(f), lb, ub)
            else
                throw(
                    IncorrectArgument(
                        "the following type of constraint is not valid: " *
                        String(type) *
                        ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method.",
                    ),
                )
            end
        end

        _ => throw(IncorrectArgument("Provided arguments are inconsistent."))
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Set the dynamics.

!!! note

    You can use dynamics! only once to define the dynamics.
    
    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Example

```@example
julia> dynamics!(ocp, f)
```
"""
function dynamics!(
    ocp::OptimalControlModel{T, V},
    f::Function,
) where {T <: TimeDependence, V <: VariableDependence}

    # we check if the dimensions and times have been set
    __check_all_set(ocp)
    __is_dynamics_set(ocp) && throw(UnauthorizedCall("the dynamics has already been set."))

    Dynamics_ = is_in_place(ocp) ? Dynamics! : Dynamics
    ocp.dynamics = Dynamics_(f, T, V)

    return nothing
end

"""
$(TYPEDSIGNATURES)

Set the criterion to the function `f`. Type can be `:mayer` or `:lagrange`. Criterion is `:min` or `:max`.

!!! note

    You can use objective! only once to define the objective.

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Examples

```@example
julia> objective!(ocp, :mayer, (x0, xf) -> x0[1] + xf[2])
julia> objective!(ocp, :lagrange, (x, u) -> x[1]^2 + u^2) # the control is of dimension 1
```

!!! warning

    If you set twice the objective, only the last one will be taken into account.
"""
function objective!(
    ocp::OptimalControlModel{T, V},
    type::Symbol,
    f::Function,
    criterion::Symbol = __criterion_type(),
) where {T <: TimeDependence, V <: VariableDependence}

    # we check if the dimensions and times have been set
    __check_all_set(ocp)
    __is_objective_set(ocp) && throw(UnauthorizedCall("the objective has already been set."))

    # check the validity of the criterion
    !__is_criterion_valid(criterion) && throw(
        IncorrectArgument(
            "the following criterion is not valid: " *
            String(criterion) *
            ". Please choose in [ :min, :max ].",
        ),
    )
    ocp.criterion = criterion

    # set the objective
    Mayer_ = is_in_place(ocp) ? Mayer! : Mayer
    Lagrange_ = is_in_place(ocp) ? Lagrange! : Lagrange
    if type == :mayer
        ocp.mayer = Mayer_(f, V)
    elseif type == :lagrange
        ocp.lagrange = Lagrange_(f, T, V)
    else
        throw(
            IncorrectArgument(
                "the following objective is not valid: " *
                String(objective) *
                ". Please choose in [ :mayer, :lagrange ].",
            ),
        )
    end

    return nothing
end

"""
$(TYPEDSIGNATURES)

Set the criterion to the function `g` and `f⁰`. Type can be `:bolza`. Criterion is `:min` or `:max`.

!!! note

    You can use objective! only once to define the objective.

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Example

```@example
julia> objective!(ocp, :bolza, (x0, xf) -> x0[1] + xf[2], (x, u) -> x[1]^2 + u^2) # the control is of dimension 1
```
"""
function objective!(
    ocp::OptimalControlModel{T, V},
    type::Symbol,
    g::Function,
    f⁰::Function,
    criterion::Symbol = __criterion_type(),
) where {T <: TimeDependence, V <: VariableDependence}

    # we check if the dimensions and times have been set
    __check_all_set(ocp)
    __is_objective_set(ocp) && throw(UnauthorizedCall("the objective has already been set."))

    # check the validity of the criterion
    !__is_criterion_valid(criterion) && throw(
        IncorrectArgument(
            "the following criterion is not valid: " *
            String(criterion) *
            ". Please choose in [ :min, :max ].",
        ),
    )
    ocp.criterion = criterion

    # set the objective
    Mayer_ = is_in_place(ocp) ? Mayer! : Mayer
    Lagrange_ = is_in_place(ocp) ? Lagrange! : Lagrange
    if type == :bolza
        ocp.mayer = Mayer_(g, V) 
        ocp.lagrange = Lagrange_(f⁰, T, V)
    else
        throw(
            IncorrectArgument(
                "the following objective is not valid: " *
                String(objective) *
                ". Please choose :bolza.",
            ),
        )
    end

    return nothing
end

"""
$(TYPEDSIGNATURES)

Remove a labeled constraint.

# Example

```@example
julia> remove_constraint!(ocp, :con)
```
"""
function remove_constraint!(ocp::OptimalControlModel, label::Symbol)
    if !haskey(ocp.constraints, label)
        throw(
            IncorrectArgument(
                "the following constraint does not exist: " *
                String(label) *
                ". Please check the list of constraints: ocp.constraints.",
            ),
        )
    end
    delete!(ocp.constraints, label)
    return nothing
end
