# todo: use design pattern to generate functions in nlp_constraints!
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
function Model(; 
    autonomous::Bool=true, 
    variable::Bool=false)

    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed

    return OptimalControlModel{time_dependence, variable_dependence}()

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
function Model(dependencies::DataType...)::OptimalControlModel{<:TimeDependence, <:VariableDependence}
    # some checkings: 
    __check_dependencies(dependencies)
    time_dependence = NonAutonomous ∈ dependencies ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependencies ? NonFixed : Fixed
    return OptimalControlModel{time_dependence, variable_dependence}()
end

"""
$(TYPEDSIGNATURES)

Return `true` if the model is autonomous.
"""
is_autonomous(ocp::OptimalControlModel{Autonomous, <: VariableDependence}) = true
is_autonomous(ocp::OptimalControlModel{NonAutonomous, <: VariableDependence}) = false

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
is_min(ocp::OptimalControlModel) = ocp.criterion == :min

"""
$(TYPEDSIGNATURES)

Return `true` if the criterion type of `ocp` is `:max`.
"""
is_max(ocp::OptimalControlModel) = !is_min(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if the model is fixed (= has no variable).
"""
is_fixed(ocp::OptimalControlModel{<: TimeDependence, Fixed}) = true
is_fixed(ocp::OptimalControlModel{<: TimeDependence, NonFixed}) = false

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
###

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with free initial time.
"""
has_free_initial_time(ocp::OptimalControlModel) = (typeof(ocp.initial_time)==Index)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with free final time.
"""
has_free_final_time(ocp::OptimalControlModel) = (typeof(ocp.final_time)==Index)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with lagrange cost.
"""
has_lagrange_cost(ocp::OptimalControlModel) = !isnothing(ocp.lagrange)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined with mayer cost.
"""
has_mayer_cost(ocp::OptimalControlModel) = !isnothing(ocp.mayer)


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
    name::String=__variable_name(), 
    components_names::Vector{String}=__variable_components_names(q, name))

    # checkings
    is_fixed(ocp) && throw(UnauthorizedCall("the ocp has no variable, you cannot use variable! function."))
    __is_variable_set(ocp) && throw(UnauthorizedCall("the variable has already been set. Use variable! once."))
    (q  > 1) && (size(components_names, 1) ≠ q) && throw(IncorrectArgument("the number of variable names must be equal to the variable dimension"))
    
    ocp.variable_dimension = q
    ocp.variable_components_names = components_names
    ocp.variable_name = name
    return nothing
end

function variable!(
    ocp::OptimalControlModel, 
    q::Dimension, 
    name::Symbol, 
    components_names::Vector{Symbol})
    variable!(ocp, q, string(name), string.(components_names))
end

function variable!(
    ocp::OptimalControlModel, 
    q::Dimension, 
    name::Symbol, 
    components_names::Vector{String})
    variable!(ocp, q, string(name), components_names)
end

function variable!(
    ocp::OptimalControlModel, 
    q::Dimension, 
    name::Symbol)
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
julia> ocp.state_dimension
1
julia> ocp.state_components_names
["x"]

julia> state!(ocp, 1, "y")
julia> ocp.state_dimension
1
julia> ocp.state_components_names
["y"]

julia> state!(ocp, 2)
julia> ocp.state_dimension
2
julia> ocp.state_components_names
["x₁", "x₂"]

julia> state!(ocp, 2, :y)
julia> ocp.state_dimension
2
julia> ocp.state_components_names
["y₁", "y₂"]

julia> state!(ocp, 2, "y")
julia> ocp.state_dimension
2
julia> ocp.state_components_names
["y₁", "y₂"]
```
"""
function state!(
    ocp::OptimalControlModel, 
    n::Dimension, 
    name::String=__state_name(), 
    components_names::Vector{String}=__state_components_names(n, name))

    # checkings
    __is_state_set(ocp) && throw(UnauthorizedCall("the state has already been set. Use state! once."))
    (n  > 1) && (size(components_names, 1) ≠ n) && throw(IncorrectArgument("the number of state names must be equal to the state dimension"))

    ocp.state_dimension = n
    ocp.state_components_names = components_names
    ocp.state_name = name
    return nothing

end

function state!(
    ocp::OptimalControlModel, 
    n::Dimension, 
    name::Symbol, 
    components_names::Vector{Symbol})

    state!(ocp, n, string(name), string.(components_names))
end

function state!(
    ocp::OptimalControlModel, 
    n::Dimension, 
    name::Symbol, 
    components_names::Vector{String})

    state!(ocp, n, string(name), components_names)
end

function state!(
    ocp::OptimalControlModel, 
    n::Dimension, 
    name::Symbol)

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
julia> ocp.control_dimension
1
julia> ocp.control_components_names
["u"]

julia> control!(ocp, 1, "v")
julia> ocp.control_dimension
1
julia> ocp.control_components_names
["v"]

julia> control!(ocp, 2)
julia> ocp.control_dimension
2
julia> ocp.control_components_names
["u₁", "u₂"]

julia> control!(ocp, 2, :v)
julia> ocp.control_dimension
2
julia> ocp.control_components_names
["v₁", "v₂"]

julia> control!(ocp, 2, "v")
julia> ocp.control_dimension
2
julia> ocp.control_components_names
["v₁", "v₂"]
```
"""
function control!(
    ocp::OptimalControlModel, 
    m::Dimension, 
    name::String=__control_name(), 
    components_names::Vector{String}=__control_components_names(m, name))

    # checkings
    __is_control_set(ocp) && throw(UnauthorizedCall("the control has already been set. Use control! once."))
    (m  > 1) && (size(components_names, 1) ≠ m) && throw(IncorrectArgument("the number of control names must be equal to the control dimension"))

    ocp.control_dimension = m
    ocp.control_components_names = components_names
    ocp.control_name = name
    return nothing

end

function control!(
    ocp::OptimalControlModel, 
    m::Dimension, 
    name::Symbol, 
    components_names::Vector{Symbol})

    control!(ocp, m, string(name), string.(components_names))
end

function control!(
    ocp::OptimalControlModel, 
    m::Dimension, 
    name::Symbol, 
    components_names::Vector{String})

    control!(ocp, m, string(name), components_names)
end

function control!(
    ocp::OptimalControlModel, 
    m::Dimension, 
    name::Symbol)

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
    ocp::OptimalControlModel{<: TimeDependence, VT};
    t0::Union{Time, Nothing}=nothing,
    tf::Union{Time, Nothing}=nothing,
    ind0::Union{Integer, Nothing}=nothing, 
    indf::Union{Integer, Nothing}=nothing, 
    name::Union{String, Symbol}=__time_name()) where VT

    # check if the problem has been set to Variable or NonVariable
    VT == NonFixed && (!isnothing(ind0) || !isnothing(indf)) && __check_variable_set(ocp)

    # check if indices are in 1:q
    q = ocp.variable_dimension
    !isnothing(ind0) && !(1 ≤ ind0 ≤ q) && throw(IncorrectArgument("the index of t0 variable must be contained in 1:$q"))
    !isnothing(indf) && !(1 ≤ indf ≤ q) && throw(IncorrectArgument("the index of tf variable must be contained in 1:$q"))

    # check if the function has been already called
    __is_time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))

    # check consistency
    !isnothing(t0) && !isnothing(ind0) && throw(IncorrectArgument("Providing t0 and ind0 has no sense. The initial time cannot be fixed and free."))
     isnothing(t0) &&  isnothing(ind0) && throw(IncorrectArgument("Please either provide the value of the initial time t0 (if fixed) or its index in the variable of ocp (if free)."))
    !isnothing(tf) && !isnothing(indf) && throw(IncorrectArgument("Providing tf and indf has no sense. The final time cannot be fixed and free."))
     isnothing(tf) &&  isnothing(indf) && throw(IncorrectArgument("Please either provide the value of the final time tf (if fixed) or its index in the variable of ocp (if free)."))

    VT == Fixed && !isnothing(ind0) && throw(IncorrectArgument("You cannot have the initial time free (ind0 is provided) and the ocp non variable."))
    VT == Fixed && !isnothing(indf) && throw(IncorrectArgument("You cannot have the final time free (indf is provided) and the ocp non variable."))

    #
    name = name isa String ? name : string(name)

    # core
    @match (t0, ind0, tf, indf) begin
        (::Time, ::Nothing, ::Time, ::Nothing) => begin # (t0, tf)
            ocp.initial_time      = t0
            ocp.final_time        = tf
            ocp.time_name         = name
            ocp.initial_time_name = t0 isa Integer ? string(t0) : string(round(t0, digits=2))
            ocp.final_time_name   = tf isa Integer ? string(tf) : string(round(tf, digits=2))
        end
        (::Nothing, ::Integer, ::Time, ::Nothing) => begin # (ind0, tf)
            ocp.initial_time      = Index(ind0)
            ocp.final_time        = tf
            ocp.time_name         = name
            ocp.initial_time_name = ocp.variable_components_names[ind0]
            ocp.final_time_name   = tf isa Integer ? string(tf) : string(round(tf, digits=2))
        end
        (::Time, ::Nothing, ::Nothing, ::Integer) => begin # (t0, indf)
            ocp.initial_time      = t0
            ocp.final_time        = Index(indf)
            ocp.time_name         = name
            ocp.initial_time_name = t0 isa Integer ? string(t0) : string(round(t0, digits=2))
            ocp.final_time_name   = ocp.variable_components_names[indf]
        end
        (::Nothing, ::Integer, ::Nothing, ::Integer) => begin # (ind0, indf)
            ocp.initial_time      = Index(ind0)
            ocp.final_time        = Index(indf)
            ocp.time_name         = name
            ocp.initial_time_name = ocp.variable_components_names[ind0]
            ocp.final_time_name   = ocp.variable_components_names[indf]
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
    rg::Union{OrdinalRange{<:Integer}, Index, Integer, Nothing}=nothing, 
    f::Union{Function, Nothing}=nothing, 
    lb::Union{ctVector, Nothing}=nothing, 
    ub::Union{ctVector, Nothing}=nothing, 
    label::Symbol=__constraint_label()) where {T <: TimeDependence, V <: VariableDependence}

    __check_all_set(ocp)
    type == :variable && is_fixed(ocp) && throw(UnauthorizedCall("the ocp has no variable" * ", you cannot use constraint! function with type=:variable."))
    label ∈ constraints_labels(ocp) && throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    isnothing(lb) && isnothing(ub) && throw(UnauthorizedCall("Calling the constraint! function without any bounds is not authorized."))

    # bounds
    isnothing(lb) && (lb = -Inf*(size(ub,1) == 1 ? 1 : ones(eltype(ub), size(ub,1))))
    isnothing(ub) && (ub =  Inf*(size(lb,1) == 1 ? 1 : ones(eltype(lb), size(lb,1))))

    # dimensions
    n = ocp.state_dimension
    m = ocp.control_dimension
    q = ocp.variable_dimension
    
    # range
    (typeof(rg) <: Int) && (rg = Index(rg))
    
    # core
    @match (rg, f, lb, ub) begin
        (::Nothing, ::Nothing, ::ctVector, ::ctVector) => begin
            if type ∈ [:initial, :final, :state]
                rg = n == 1 ? Index(1) : 1:n
                txt = "the lower bound `lb` and the upper bound `ub` must be of dimension $n"
            elseif type == :control
                rg = m == 1 ? Index(1) : 1:m
                txt = "the lower bound `lb` and the upper bound `ub` must be of dimension $m"
            elseif type == :variable
                rg = q == 1 ? Index(1) : 1:q
                txt = "the lower bound `lb` and the upper bound `ub` must be of dimension $q"
            else
                throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
                ". Please choose in [ :initial, :final, :control, :state, :variable ] or check the arguments of the constraint! method."))
            end
            (length(rg) != length(lb)) && throw(IncorrectArgument(txt))
            (length(rg) != length(ub)) && throw(IncorrectArgument(txt))
            constraint!(ocp, type; rg=rg, lb=lb, ub=ub, label=label) end

        (::RangeConstraint, ::Nothing, ::ctVector, ::ctVector) => begin
            txt = "the range `rg`, the lower bound `lb` and the upper bound `ub` must have the same dimension"
            (length(rg) != length(lb)) && throw(IncorrectArgument(txt))
            (length(rg) != length(ub)) && throw(IncorrectArgument(txt))
            # check if the range is valid
            if type == :initial        
                !all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range of the initial state constraint must be contained in 1:$n"))
            elseif type == :final
                !all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range of the final state constraint must be contained in 1:$n"))
            elseif type == :control
                !all(1 .≤ rg .≤ m) && throw(IncorrectArgument("the range of the control constraint must be contained in 1:$m"))
            elseif type == :state
                !all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range of the state constraint must be contained in 1:$n"))
            elseif type == :variable
                !all(1 .≤ rg .≤ q) && throw(IncorrectArgument("the range of the variable constraint must be contained in 1:$q"))
            end
            # set the constraint
            fun_rg = @match type begin
                :initial => V == Fixed ? BoundaryConstraint((x0, xf   ) -> x0[rg], V) : BoundaryConstraint((x0, xf, v) -> x0[rg], V)
                :final   => V == Fixed ? BoundaryConstraint((x0, xf   ) -> xf[rg], V) : BoundaryConstraint((x0, xf, v) -> xf[rg], V)
                :control || :state || :variable => rg
                _  => throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
                ". Please choose in [ :initial, :final, :control, :state, :variable ] or check the arguments of the constraint! method."))
            end
            ocp.constraints[label] = (type, fun_rg, lb, ub) end
        
        (::Nothing, ::Function, ::ctVector, ::ctVector) => begin
            # set the constraint
            if type == :boundary
                ocp.constraints[label] = (type, BoundaryConstraint(f, V), lb, ub)
            elseif type == :control
                ocp.constraints[label] = (type, ControlConstraint(f, T, V), lb, ub)
            elseif type == :state
                ocp.constraints[label] = (type, StateConstraint(f, T, V), lb, ub)
            elseif type == :mixed
                ocp.constraints[label] = (type, MixedConstraint(f, T, V), lb, ub)
            elseif type == :variable
                ocp.constraints[label] = (type, VariableConstraint(f), lb, ub)
            else
                throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
                ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method."))
            end end

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
function dynamics!(ocp::OptimalControlModel{T, V}, f::Function) where {T <: TimeDependence, V <: VariableDependence}

    # we check if the dimensions and times have been set
    __check_all_set(ocp)
    __is_dynamics_set(ocp) && throw(UnauthorizedCall("the dynamics has already been set. Use dynamics! once."))

    ocp.dynamics = Dynamics(f, T, V)

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
function objective!(ocp::OptimalControlModel{T, V}, type::Symbol, f::Function, 
        criterion::Symbol=__criterion_type()) where {T <: TimeDependence, V <: VariableDependence}

    # we check if the dimensions and times have been set
    __check_all_set(ocp)
    __is_objective_set(ocp) && throw(UnauthorizedCall("the objective has already been set. Use objective! once."))

    # check the validity of the criterion
    !__is_criterion_valid(criterion) && throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    ocp.criterion = criterion

    # set the objective
    if type == :mayer
        ocp.mayer = Mayer(f, V)
    elseif type == :lagrange
        ocp.lagrange = Lagrange(f, T, V)
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose in [ :mayer, :lagrange ]."))
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
function objective!(ocp::OptimalControlModel{T, V}, type::Symbol, g::Function, f⁰::Function, 
        criterion::Symbol=__criterion_type()) where {T <: TimeDependence, V <: VariableDependence}

    # we check if the dimensions and times have been set
    __check_all_set(ocp)
    __is_objective_set(ocp) && throw(UnauthorizedCall("the objective has already been set. Use objective! once."))

    # check the validity of the criterion
    !__is_criterion_valid(criterion) && throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    ocp.criterion = criterion

    # set the objective
    if type == :bolza
        ocp.mayer = Mayer(g, V)
        ocp.lagrange = Lagrange(f⁰, T, V)
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose :bolza."))
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
        throw(IncorrectArgument("the following constraint does not exist: " * String(label) *
        ". Please check the list of constraints: ocp.constraints."))
    end
    delete!(ocp.constraints, label)
    return nothing
end

"""
$(TYPEDSIGNATURES)

Return the labels of the constraints as a `Base.keys`.

# Example

```@example
julia> constraints_labels(ocp)
```
"""
function constraints_labels(ocp::OptimalControlModel)
    return keys(ocp.constraints)
end

#
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
function constraint(ocp::OptimalControlModel{T, V}, label::Symbol) where {T <: TimeDependence, V <: VariableDependence}
    con = ocp.constraints[label]
    @match con begin
        (:initial , f::BoundaryConstraint, _, _) => return f
        (:final   , f::BoundaryConstraint, _, _) => return f
        (:boundary, f::BoundaryConstraint, _, _) => return f
        (:control , f::ControlConstraint,  _, _) => return f
        (:control , rg,   _, _) => begin
            C = @match ocp begin
                ::OptimalControlModel{Autonomous, Fixed} => ControlConstraint(u         -> u[rg], T, V)
                ::OptimalControlModel{Autonomous, NonFixed} => ControlConstraint((u, v)    -> u[rg], T, V)
                ::OptimalControlModel{NonAutonomous, Fixed} => ControlConstraint((t, u)    -> u[rg], T, V)
                ::OptimalControlModel{NonAutonomous, NonFixed} => ControlConstraint((t, u, v) -> u[rg], T, V)
                _ => nothing
                end
            return C
        end
        (:state   , f::StateConstraint,    _, _) => return f
        (:state   , rg,   _, _) => begin
            S = @match ocp begin
                ::OptimalControlModel{Autonomous, Fixed} => StateConstraint(x         -> x[rg], T, V)
                ::OptimalControlModel{Autonomous, NonFixed} => StateConstraint((x, v)    -> x[rg], T, V)
                ::OptimalControlModel{NonAutonomous, Fixed} => StateConstraint((t, x)    -> x[rg], T, V)
                ::OptimalControlModel{NonAutonomous, NonFixed} => StateConstraint((t, x, v) -> x[rg], T, V)
                _ => nothing
                end
            return S
        end
        (:mixed   , f::MixedConstraint,    _, _) => return f
        (:variable, f::VariableConstraint, _, _) => return f
        (:variable, rg, _, _) => return VariableConstraint(v -> v[rg])
        _ => error("Internal error")
    end
end

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

and update information about constraints dimensions of  `ocp`.

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
    
    #
    constraints = ocp.constraints

    ξf = Vector{ControlConstraint}(); ξl = Vector{ctNumber}(); ξu = Vector{ctNumber}()
    ηf = Vector{StateConstraint}(); ηl = Vector{ctNumber}(); ηu = Vector{ctNumber}()
    ψf = Vector{MixedConstraint}(); ψl = Vector{ctNumber}(); ψu = Vector{ctNumber}()
    ϕf = Vector{BoundaryConstraint}(); ϕl = Vector{ctNumber}(); ϕu = Vector{ctNumber}()
    θf = Vector{VariableConstraint}(); θl = Vector{ctNumber}(); θu = Vector{ctNumber}()
    uind = Vector{Int}(); ul = Vector{ctNumber}(); uu = Vector{ctNumber}()
    xind = Vector{Int}(); xl = Vector{ctNumber}(); xu = Vector{ctNumber}()
    vind = Vector{Int}(); vl = Vector{ctNumber}(); vu = Vector{ctNumber}()

    for (_, c) ∈ constraints
        @match c begin
        (type, f::BoundaryConstraint, lb, ub) && if type ∈ [:initial, :final, :boundary] end => begin
            push!(ϕf, f)
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:control, f::ControlConstraint, lb, ub) => begin
            push!(ξf, f)
            append!(ξl, lb)
            append!(ξu, ub) end
        (:control, rg, lb, ub) => begin
            append!(uind, rg)
            append!(ul, lb)
            append!(uu, ub) end
        (:state, f::StateConstraint, lb, ub) => begin
            push!(ηf, f)
            append!(ηl, lb)
            append!(ηu, ub) end
        (:state, rg, lb, ub) => begin
            append!(xind, rg)
            append!(xl, lb)
            append!(xu, ub) end
        (:mixed, f::MixedConstraint, lb, ub) => begin
            push!(ψf, f)
            append!(ψl, lb)
            append!(ψu, ub) end
        (:variable, f::VariableConstraint, lb, ub) => begin
            push!(θf, f)
            append!(θl, lb)
            append!(θu, ub) end
        (:variable, rg, lb, ub) => begin
            append!(vind, rg)
            append!(vl, lb)
            append!(vu, ub) end
        _ => error("Internal error") end
    end

    @assert length(ξl) == length(ξu)
    @assert length(ηl) == length(ηu)
    @assert length(ψl) == length(ψu)
    @assert length(ϕl) == length(ϕu)
    @assert length(θl) == length(θu)
    @assert length(ul) == length(uu)
    @assert length(xl) == length(xu)
    @assert length(vl) == length(vu)

    function ξ(t, u, v) # nonlinear control constraints
        dim = length(ξl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ξf)
            vali = ξf[i](t, u, v)
            li = length(vali)
            val[j:j+li-1] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function η(t, x, v) # nonlinear state constraints
        dim = length(ηl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ηf)
            vali = ηf[i](t, x, v)
            li = length(vali)
            val[j:j+li-1] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function ψ(t, x, u, v) # nonlinear mixed constraints
        dim = length(ψl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ψf)
            vali = ψf[i](t, x, u, v)
            li = length(vali)
            val[j:j+li-1] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function ϕ(x0, xf, v) # nonlinear boundary constraints
        dim = length(ϕl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(ϕf)
            vali = ϕf[i](x0, xf, v)
            li = length(vali)
            val[j:j+li-1] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    function θ(v) # nonlinear variable constraints
        dim = length(θl)
        val = zeros(ctNumber, dim)
        j = 1
        for i ∈ 1:length(θf)
            vali = θf[i](v)
            li = length(vali)
            val[j:j+li-1] .= vali # .= also allows scalar value for vali
            j = j + li
        end
        return val
    end

    ocp.dim_control_constraints = length(ξl)
    ocp.dim_state_constraints = length(ηl)
    ocp.dim_mixed_constraints = length(ψl)
    ocp.dim_boundary_constraints = length(ϕl)
    ocp.dim_variable_constraints = length(θl)
    ocp.dim_control_range = length(ul)
    ocp.dim_state_range = length(xl) 
    ocp.dim_variable_range = length(vl)

    return (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (θl, θ, θu), (ul, uind, uu), (xl, xind, xu), (vl, vind, vu)

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
dim_state_box = dim_state_range # alias, CTDirect.jl compatibility

"""
$(TYPEDSIGNATURES)

Return the dimension of range constraints on control (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_control_range(ocp::OptimalControlModel) = ocp.dim_control_range 
dim_control_box = dim_control_range # alias, CTDirect.jl compatibility

"""
$(TYPEDSIGNATURES)

Return the dimension of range constraints on variable (`nothing` if not knonw).
Information is updated after `nlp_constraints!` is called.
"""
dim_variable_range(ocp::OptimalControlModel) = ocp.dim_variable_range
dim_variable_box = dim_variable_range # alias, CTDirect.jl compatibility