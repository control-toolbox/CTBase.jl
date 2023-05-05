"""
$(TYPEDSIGNATURES)

Return a new `OptimalControlModel` instance, that is a model of an optimal control problem.

The model is defined by the following optional keyword argument:

- `time_dependence`: either `:t_indep` or `:t_dep`. Default is `:t_indep`.

# Examples

```jldoctest
julia> ocp = Model()
julia> ocp = Model(time_dependence=:t_dep)
```

!!! note

    - If the time dependence of the model is defined as nonautonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of time and state, and possibly control. If the model is defined as autonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of state, and possibly control.

"""
function Model(; time_dependence::Symbol=__ocp_time_dependence(), variable_dependence::Symbol=__ocp_variable_dependence())
    @check(time_dependence)
    @check(variable_dependence)
    return OptimalControlModel{time_dependence, variable_dependence}()
end

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as time dependent.
"""
is_time_dependent(ocp::OptimalControlModel{:t_dep, vd}) where {vd} = true
is_time_dependent(ocp::OptimalControlModel{:t_indep, vd}) where {vd} = false

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

Return `true` if the model has been defined as variable dependent.
"""
is_variable_dependent(ocp::OptimalControlModel{td, :v_dep}) where {td} = true
is_variable_dependent(ocp::OptimalControlModel{td, :v_indep}) where {td} = false

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as variable independent.
"""
is_variable_independent(ocp::OptimalControlModel) = !is_variable_dependent(ocp)

"""
$(TYPEDSIGNATURES)

Define the variable dimension and possibly the names of each coordinate.

# Examples
```jldoctest
julia> variable!(ocp, 1, "v")
julia> variable!(ocp, 2, [ "v₁", "v₂" ])
```
"""
function variable!(ocp::OptimalControlModel, q::Dimension, names::Union{String, Vector{String}}=__variable_names(q))
    is_variable_independent(ocp) && throw(UnauthorizedCall("the ocp is variable independent, you cannot use variable! function."))
    (q  > 1) && (names isa Vector{String}) && (length(names) ≠ q) && throw(IncorrectArgument("the number of variables names must be equal to the variable dimension"))
    (q == 1) && (names isa Vector{String}) && throw(IncorrectArgument("if the variable dimension is 1, then, the argument names must be a String"))
    (q  > 1) && (names isa String) && (names = [ names * ctindices(i) for i ∈ range(1, q)])
    ocp.variable_dimension = q
    ocp.variable_names = (q == 1) ? [names] : names
    nothing # to force to return nothing
end

function variable!(ocp::OptimalControlModel, q::Dimension, name::Symbol)
    variable!(ocp, q, string(name))
end

"""
$(TYPEDSIGNATURES)

Define the state dimension and possibly the names of each coordinate.

# Examples

```jldoctest
julia> state!(ocp, 1)
julia> ocp.state_dimension
1
julia> ocp.state_names
["x"]

julia> state!(ocp, 1, "y")
julia> ocp.state_dimension
1
julia> ocp.state_names
["y"]

julia> state!(ocp, 2)
julia> ocp.state_dimension
2
julia> ocp.state_names
["x₁", "x₂"]

julia> state!(ocp, 2, [ "y₁", "y₂" ])
julia> ocp.state_dimension
2
julia> ocp.state_names
["y₁", "y₂"]

julia> state!(ocp, 2, :y)
julia> ocp.state_dimension
2
julia> ocp.state_names
["y₁", "y₂"]

julia> state!(ocp, 2, "y")
julia> ocp.state_dimension
2
julia> ocp.state_names
["y₁", "y₂"]
```
"""
function state!(ocp::OptimalControlModel, n::Dimension, names::Union{String, Vector{String}}=__state_names(n))
    (n  > 1) && (names isa Vector{String}) && (length(names) ≠ n) && throw(IncorrectArgument("the number of state names must be equal to the state dimension"))
    (n == 1) && (names isa Vector{String}) && throw(IncorrectArgument("if the state dimension is 1, then, the argument names must be a String"))
    (n  > 1) && (names isa String) && (names = [ names * ctindices(i) for i ∈ range(1, n)])
    ocp.state_dimension = n
    ocp.state_names = (n == 1) ? [names] : names
    nothing # to force to return nothing
end
function state!(ocp::OptimalControlModel, n::Dimension, name::Symbol)
    state!(ocp, n, string(name))
end

"""
$(TYPEDSIGNATURES)

Define the control dimension and possibly the names of each coordinate.

# Examples

```jldoctest
julia> control!(ocp, 1)
julia> ocp.control_dimension
1
julia> ocp.control_names
["u"]

julia> control!(ocp, 1, "v")
julia> ocp.control_dimension
1
julia> ocp.control_names
["v"]

julia> control!(ocp, 2)
julia> ocp.control_dimension
2
julia> ocp.control_names
["u₁", "u₂"]

julia> control!(ocp, 2, [ "v₁", "v₂" ])
julia> ocp.control_dimension
2
julia> ocp.control_names
["v₁", "v₂"]

julia> control!(ocp, 2, :v)
julia> ocp.control_dimension
2
julia> ocp.control_names
["v₁", "v₂"]

julia> control!(ocp, 2, "v")
julia> ocp.control_dimension
2
julia> ocp.control_names
["v₁", "v₂"]
```
"""
function control!(ocp::OptimalControlModel, m::Dimension, names::Union{String, Vector{String}}=__control_names(m))
    (m  > 1) && (names isa Vector{String}) && (length(names) != m) && throw(IncorrectArgument("the number of control names must be equal to the control dimension"))
    (m == 1) && (names isa Vector{String}) && throw(IncorrectArgument("if the control dimension is 1, then, the argument names must be a String"))
    (m  > 1) && (names isa String) && (names = [ names * ctindices(i) for i ∈ range(1, m)])
    ocp.control_dimension = m
    ocp.control_names = (m == 1) ? [names] : names
    nothing # to force to return nothing
end

function control!(ocp::OptimalControlModel, m::Dimension, name::Symbol)
    control!(ocp, m, string(name))
end

"""
$(TYPEDSIGNATURES)

Fix initial time, final time is free and given by the variable at the provided index.

!!! note

    You can use time! once to set either the initial or the final time, or both.

# Examples

```jldoctest
julia> time!(ocp, 0, Index(2), "t")
```
"""
function time!(ocp::OptimalControlModel{td, :v_dep}, t0::Time, indf::Index, name::String=__time_name()) where {td}
    check_variable_set(ocp)
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    (indf.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    ocp.initial_time = t0
    ocp.final_time = indf
    ocp.time_name = name
    nothing # to force to return nothing
end

function time!(ocp::OptimalControlModel, t0::Time, indf::Index, name::Symbol)
    time!(ocp, t0, indf, string(name))
end

"""
$(TYPEDSIGNATURES)

Fix final time, initial time is free and given by the variable at the provided index.

# Examples
```jldoctest
julia> time!(ocp, Index(2), 1, "t")
```
"""
function time!(ocp::OptimalControlModel{td, :v_dep}, ind0::Index, tf::Time, name::String=__time_name()) where {td}
    check_variable_set(ocp)
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    (ind0.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    ocp.initial_time = ind0
    ocp.final_time = tf
    ocp.time_name = name
    nothing # to force to return nothing
end

function time!(ocp::OptimalControlModel, ind0::Index, tf::Time, name::Symbol)
    time!(ocp, ind0, tf, string(name))
end

"""
$(TYPEDSIGNATURES)

Initial and final times are free and given by the variable at the provided indices.

# Examples
```jldoctest
julia> time!(ocp, Index(2), Index(3), "t")
```
"""
function time!(ocp::OptimalControlModel{td, :v_dep}, ind0::Index, indf::Index, name::String=__time_name()) where {td}
    check_variable_set(ocp)
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    (ind0.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    (indf.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    ocp.initial_time = ind0
    ocp.final_time = indf
    ocp.time_name = name
    nothing # to force to return nothing
end

function time!(ocp::OptimalControlModel, ind0::Index, indf::Index, name::Symbol)
    time!(ocp, ind0, indf, string(name))
end

"""
$(TYPEDSIGNATURES)

Fix initial and final times to `times[1]` and `times[2]`, respectively.

# Examples

```jldoctest
julia> time!(ocp, [ 0, 1 ])
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"t"

julia> time!(ocp, [ 0, 1 ], "s")
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"

julia> time!(ocp, [ 0, 1 ], :s)
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"
```
"""
function time!(ocp::OptimalControlModel, times::Times, name::String=__time_name())
    (length(times) != 2) && throw(IncorrectArgument("times must be of dimension 2"))
    time!(ocp, times[1], times[2], name)
end

function time!(ocp::OptimalControlModel, times::Times, name::Symbol)
    time!(ocp, times, string(name))
end

"""
$(TYPEDSIGNATURES)

Fix initial and final times to `times[1]` and `times[2]`, respectively.

# Examples

```jldoctest
julia> time!(ocp, 0, 1)
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"t"

julia> time!(ocp, 0, 1, "s")
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"

julia> time!(ocp, 0, 1, :s)
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"
```
"""
function time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::String=__time_name())
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    ocp.initial_time=t0
    ocp.final_time=tf
    ocp.time_name = name
    nothing # to force to return nothing
end

function time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::Symbol)
    time!(ocp, t0, tf, string(name))
end

"""
$(TYPEDSIGNATURES)

Add an `:initial` or `:final` value constraint on a range of the state, or a value constraint on a range of the
`:variable`.

!!! note

    - The range of the constraint must be contained in 1:n if the constraint is on the state, or 1:q if the constraint is on the variable.
    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.

# Examples

```jldoctest
julia> constraint!(ocp, :initial, 1:2:5, [ 0, 0, 0 ])
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ])
julia> constraint!(ocp, :final, Index(2), 0)
julia> constraint!(ocp, :variable, 2:3, [ 0, 3 ])
```
"""
function constraint!(ocp::OptimalControlModel{td, vd}, type::Symbol, rg::RangeConstraint, val::ctVector, label::Symbol=__constraint_label()) where {td, vd}

    # we check if the dimensions and times have been set just to force the user to set them before
    @check(ocp)
    type == :variable && is_variable_independent(ocp) && throw(UnauthorizedCall("the ocp is variable independent" *
    ", you cannot use constraint! function with type=:variable."))

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # check if rg and val are consistent
    (length(rg) != length(val)) && throw(IncorrectArgument("the range `rg`` and the value `val` must have the same dimension"))

    # range
#    rg = rg isa Index ? rg.val : rg

    # dimensions
    n = ocp.state_dimension
    q = ocp.variable_dimension

    # check if the range is valid
    if type == :initial        
        !all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range $rg of the initial state constraint must be contained in 1:$n"))
    elseif type == :final
        !all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range $rg of the final state constraint must be contained in 1:$n"))
    elseif type == :variable
        !all(1 .≤ rg .≤ q) && throw(IncorrectArgument("the range $rg of the variable constraint must be contained in 1:$q"))
    end

    # set the constraint
    if type == :initial # not allowed for :control or :state (does not make sense)
        B = nothing
        (vd == :v_indep) && (B = BoundaryConstraint((x0, xf)       -> x0[rg], variable_dependence=vd))
        (vd == :v_dep  ) && (B = BoundaryConstraint((x0, xf, v)    -> x0[rg], variable_dependence=vd))
        ocp.constraints[label] = (type, B, val, val)
    elseif type == :final
        B = nothing
        (vd == :v_indep) && (B = BoundaryConstraint((x0, xf)       -> xf[rg], variable_dependence=vd))
        (vd == :v_dep  ) && (B = BoundaryConstraint((x0, xf, v)    -> xf[rg], variable_dependence=vd))
        ocp.constraints[label] = (type, B, val, val)
    elseif type == :variable
        ocp.constraints[label] = (type, rg, val, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :variable ] or check the arguments of the constraint! method."))
    end

    nothing # to force to return nothing

end

"""
$(TYPEDSIGNATURES)

Add an `:initial` or `:final` value constraint on the state, or a `:variable` value.

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Examples

```jldoctest
julia> constraint!(ocp, :initial, [ 0, 0 ])
julia> constraint!(ocp, :final, 2) # if the state is of dimension 1
julia> constraint!(ocp, :variable, [ 3, 0, 1 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, val::ctVector, label::Symbol=__constraint_label())
    # we use the constraint! defined before

    # we check if the dimensions and times have been set
    @check(ocp)
    type == :variable && is_variable_independent(ocp) && throw(UnauthorizedCall("the ocp is variable independent" *
        ", you cannot use constraint! function with type=:variable."))

    #
    rg = nothing

    # dimensions
    n = ocp.state_dimension
    q = ocp.variable_dimension

    #
    if type ∈ [:initial, :final]  # not allowed for :control or :state (does not make sense)
        rg = n == 1 ? Index(1) : 1:n 
        # check if rg and val are consistent
        (length(rg) != length(val)) && throw(IncorrectArgument("`val` must be of dimension $n"))
    elseif type == :variable
        rg = q == 1 ? Index(1) : 1:q
        (length(rg) != length(val)) && throw(IncorrectArgument("`val` must be of dimension $q"))
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :variable ] or check the arguments of the constraint! method."))
    end

    #
    constraint!(ocp, type, rg, val, label)

end

"""
$(TYPEDSIGNATURES)

Add an `:initial`, `:final`, `:control`, `:state` or `:variable` box constraint on a range.

!!! note

    - The range of the constraint must be contained in 1:n if the constraint is on the state, or 1:m if the constraint is on the control, or 1:q if the constraint is on the variable.
    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.

# Examples

```jldoctest
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :final, Index(1), 0, 2)
julia> constraint!(ocp, :control, Index(1), 0, 2)
julia> constraint!(ocp, :state, 2:3, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :initial, 1:2:5, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :variable, 1:2, [ 0, 0 ], [ 1, 2 ])
```
"""
function constraint!(ocp::OptimalControlModel{td, vd}, type::Symbol, rg::RangeConstraint, lb::ctVector, ub::ctVector, 
        label::Symbol=__constraint_label()) where {td, vd}

    # we check if the dimensions and times have been set
    @check(ocp)
    type == :variable && is_variable_independent(ocp) && throw(UnauthorizedCall("the ocp is variable independent" *
    ", you cannot use constraint! function with type=:variable."))

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # range
    rg = rg isa Index ? rg.val : rg

    # check that rg, lb and ub are consistent
    txt = "the range `rg`, the lower bound `lb` and the upper bound `ub` must have the same dimension"
    (length(rg) != length(lb)) && throw(IncorrectArgument(txt))
    (length(rg) != length(ub)) && throw(IncorrectArgument(txt))

    # dimensions
    n = ocp.state_dimension
    m = ocp.control_dimension
    q = ocp.variable_dimension

    # check if the range is valid
    if type == :initial        
        all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range of the initial state constraint must be contained in 1:n"))
    elseif type == :final
        all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range of the final state constraint must be contained in 1:n"))
    elseif type == :control
        all(1 .≤ rg .≤ m) && throw(IncorrectArgument("the range of the control constraint must be contained in 1:m"))
    elseif type == :state
        all(1 .≤ rg .≤ n) && throw(IncorrectArgument("the range of the state constraint must be contained in 1:n"))
    elseif type == :variable
        all(1 .≤ rg .≤ q) && throw(IncorrectArgument("the range of the variable constraint must be contained in 1:q"))
    end

    # set the constraint
    if type == :initial
        B = nothing
        (td, vd) == (:t_indep, :v_indep) && (B = BoundaryConstraint((x0, xf)       -> x0[rg], variable_dependence=vd))
        (td, vd) == (:t_indep, :v_dep)   && (B = BoundaryConstraint((x0, xf, v)    -> x0[rg], variable_dependence=vd))
        ocp.constraints[label] = (type, B, lb, ub)
    elseif type == :final
        B = nothing
        (td, vd) == (:t_indep, :v_indep) && (B = BoundaryConstraint((x0, xf)       -> xf[rg], variable_dependence=vd))
        (td, vd) == (:t_indep, :v_dep)   && (B = BoundaryConstraint((x0, xf, v)    -> xf[rg], variable_dependence=vd))
        ocp.constraints[label] = (type, B, lb, ub)
    elseif type == :control
        ocp.constraints[label] = (type, rg, lb, ub)
    elseif type == :state
        ocp.constraints[label] = (type, rg, lb, ub)
    elseif type == :variable
        ocp.constraints[label] = (type, rg, lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :control, :state, :variable ] or check the arguments of the constraint! method."))
    end

    nothing # to force to return nothing

end


"""
$(TYPEDSIGNATURES)

Add an `:initial`, `:final`, `:control`, `:state` or `:variable` box constraint (whole range).

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Examples

```jldoctest
julia> constraint!(ocp, :initial, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :final, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :control, [ 0, 0 ], [ 2, 3 ])
julia> constraint!(ocp, :state, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :variable, 0, 1) # the variable here is of dimension 1
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, lb::ctVector, ub::ctVector, 
        label::Symbol=__constraint_label()) # we use the constraint! defined before

    # we check if the dimensions and times have been set
    @check(ocp)
    type == :variable && is_variable_independent(ocp) && throw(UnauthorizedCall("the ocp is variable independent" *
    ", you cannot use constraint! function with type=:variable."))

    #
    rg = nothing

    # dimensions
    n = ocp.state_dimension
    m = ocp.control_dimension
    q = ocp.variable_dimension

    #
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
    
    #
    (length(rg) != length(lb)) && throw(IncorrectArgument(txt))
    (length(rg) != length(ub)) && throw(IncorrectArgument(txt))

    #
    constraint!(ocp, type, rg, lb, ub, label)

end

"""
$(TYPEDSIGNATURES)

Add a `:boundary`, `:control`, `:state`, `:mixed` or `:variable` box functional constraint.

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Examples

```@example
# variable independent ocp
julia> constraint!(ocp, :boundary, (x0, xf) -> x0[3]+xf[2], 0, 1)

# variable dependent ocp
julia> constraint!(ocp, :boundary, (x0, xf, v) -> x0[3]+xf[2]*v[1], 0, 1)

# time independent and variable independent ocp
julia> constraint!(ocp, :control, u -> 2u, 0, 1)
julia> constraint!(ocp, :state, x -> x-1, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :mixed, (x, u) -> x[1]-u, 0, 1)

# time dependent and variable independent ocp
julia> constraint!(ocp, :control, (t, u) -> 2u, 0, 1)
julia> constraint!(ocp, :state, (t, x) -> x-t, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :mixed, (t, x, u) -> x[1]-u, 0, 1)

# time independent and variable dependent ocp
julia> constraint!(ocp, :control, (u, v) -> 2u*v[1], 0, 1)
julia> constraint!(ocp, :state, (x, v) -> x-v[1], [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :mixed, (x, u, v) -> x[1]-v[2]*u, 0, 1)

# time dependent and variable dependent ocp
julia> constraint!(ocp, :control, (t, u, v) -> 2u+v[2], 0, 1)
julia> constraint!(ocp, :state, (t, x, v) -> x-t*v[1], [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :mixed, (t, x, u, v) -> x[1]*v[2]-u, 0, 1)
```
"""
function constraint!(ocp::OptimalControlModel{td, vd}, type::Symbol, f::Function, 
        lb::ctVector, ub::ctVector, label::Symbol=__constraint_label()) where {td, vd}

    # we check if the dimensions and times have been set
    @check(ocp)
    type == :variable && is_variable_independent(ocp) && throw(UnauthorizedCall("the ocp is variable independent" *
    ", you cannot use constraint! function with type=:variable."))

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # set the constraint
    if type == :boundary
        ocp.constraint[label] = (type, BoundaryConstraint(f, variable_dependence=vd), lb, ub)
    elseif type == :control
        ocp.constraint[label] = (type, ControlConstraint(f, time_dependence=td, variable_dependence=vd), lb, ub)
    elseif type == :state
        ocp.constraint[label] = (type, StateConstraint(f, time_dependence=td, variable_dependence=vd), lb, ub)
    elseif type == :mixed
        ocp.constraint[label] = (type, MixedConstraint(f, time_dependence=td, variable_dependence=vd), lb, ub)
    elseif type == :variable
        ocp.constraint[label] = (type, VariableConstraint(f), lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method."))
    end

    nothing # to force to return nothing

end

"""
$(TYPEDSIGNATURES)

Add a `:boundary`, `:control`, `:state`, `:mixed` or `:variable` value functional constraint.

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Examples

```@example
# variable independent ocp
julia> constraint!(ocp, :boundary, (x0, xf) -> x0[3]+xf[2], 0)

# variable dependent ocp
julia> constraint!(ocp, :boundary, (x0, xf, v) -> x0[3]+xf[2]*v[1], 0)

# time independent and variable independent ocp
julia> constraint!(ocp, :control, u -> 2u, 1)
julia> constraint!(ocp, :state, x -> x-1, [ 0, 0, 0 ])
julia> constraint!(ocp, :mixed, (x, u) -> x[1]-u, 0)

# time dependent and variable independent ocp
julia> constraint!(ocp, :control, (t, u) -> 2u, 1)
julia> constraint!(ocp, :state, (t, x) -> x-t, [ 0, 0, 0 ])
julia> constraint!(ocp, :mixed, (t, x, u) -> x[1]-u, 0)

# time independent and variable dependent ocp
julia> constraint!(ocp, :control, (u, v) -> 2u*v[1], 1)
julia> constraint!(ocp, :state, (x, v) -> x-v[2], [ 0, 0, 0 ])
julia> constraint!(ocp, :mixed, (x, u) -> x[1]-u+v[1], 0)

# time dependent and variable dependent ocp
julia> constraint!(ocp, :control, (t, u, v) -> 2u-t*v[2], 1)
julia> constraint!(ocp, :state, (t, x, v) -> x-t+v[1], [ 0, 0, 0 ])
julia> constraint!(ocp, :mixed, (t, x, u, v) -> x[1]-u*v[1], 0)
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, val::ctVector, 
        label::Symbol=__constraint_label()) # we use the constraint! defined before
    constraint!(ocp, type, f, val, val, label)
end

"""
$(TYPEDSIGNATURES)

Set the dynamics.

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Example

```jldoctest
julia> constraint!(ocp, :dynamics, f)
```
"""
function constraint!(ocp::OptimalControlModel{td, vd}, type::Symbol, f::Function) where {td, vd}

    # we check if the dimensions and times have been set
    @check(ocp)

    # set the dynamics
    if type ∈ [ :dynamics ]
        ocp.dynamics = Dynamics(f, time_dependence=td, variable_dependence=vd)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :dynamics ] or check the arguments of the constraint! method."))
    end

    nothing # to force to return nothing

end

"""
$(TYPEDSIGNATURES)

Set the criterion to the function `f`. Type can be `:mayer` or `:lagrange`. Criterion is `:min` or `:max`.

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Examples

```jldoctest
julia> objective!(ocp, :mayer, (x0, xf) -> x0[1] + xf[2])
julia> objective!(ocp, :lagrange, (x, u) -> x[1]^2 + u^2) # the control is of dimension 1
```

!!! warning

    If you set twice the objective, only the last one will be taken into account.
"""
function objective!(ocp::OptimalControlModel{td, vd}, type::Symbol, f::Function, 
        criterion::Symbol=__criterion_type()) where {td, vd}

    # we check if the dimensions and times have been set
    @check(ocp)

    # reset the objective
    if !isnothing(ocp.mayer) || !isnothing(ocp.lagrange)
        println("warning: The objective is already set. It will be replaced by the new one.")
    end
    ocp.mayer = nothing
    ocp.lagrange = nothing

    # check the validity of the criterion
    @check(criterion)
    ocp.criterion = criterion

    # set the objective
    if type == :mayer
        ocp.mayer = Mayer(f, variable_dependence=vd)
    elseif type == :lagrange
        ocp.lagrange = Lagrange(f, time_dependence=td, variable_dependence=vd)
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose in [ :mayer, :lagrange ]."))
    end

    nothing # to force to return nothing

end

"""
$(TYPEDSIGNATURES)

Set the criterion to the function `g` and `f⁰`. Type can be `:bolza`. Criterion is `:min` or `:max`.

!!! note

    - The state, control and variable dimensions must be set before. Use state!, control! and variable!.
    - The times must be set before. Use time!.
    - When an element is of dimension 1, consider it as a scalar.

# Example

```jldoctest
julia> objective!(ocp, :bolza, (x0, xf) -> x0[1] + xf[2], (x, u) -> x[1]^2 + u^2) # the control is of dimension 1
```
"""
function objective!(ocp::OptimalControlModel{td, vd}, type::Symbol, g::Function, f⁰::Function, 
        criterion::Symbol=__criterion_type()) where {td, vd}

    # we check if the dimensions and times have been set
    @check(ocp)

    # reset the objective
    if !isnothing(ocp.mayer) || !isnothing(ocp.lagrange)
        println("warning: The objective is already set. It will be replaced by the new one.")
    end
    ocp.mayer = nothing
    ocp.lagrange = nothing

    # check the validity of the criterion
    @check(criterion)
    ocp.criterion = criterion

    # set the objective
    if type == :bolza
        ocp.mayer = Mayer(g, variable_dependence=vd)
        ocp.lagrange = Lagrange(f⁰, time_dependence=td, variable_dependence=vd)
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose :bolza."))
    end

    nothing # to force to return nothing

end

"""
$(TYPEDSIGNATURES)

Remove a labeled constraint.

# Example

```jldoctest
julia> remove_constraint!(ocp, :con)
```
"""
function remove_constraint!(ocp::OptimalControlModel, label::Symbol)
    if !haskey(ocp.constraints, label)
        throw(IncorrectArgument("the following constraint does not exist: " * String(label) *
        ". Please check the list of constraints: ocp.constraints."))
    end
    delete!(ocp.constraints, label)
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

```jldoctest
julia> constraint!(ocp, :initial, 0, :c0)
julia> c = constraint(ocp, :c0)
julia> c(1)
1
```
"""
function constraint(ocp::OptimalControlModel{td, vd}, label::Symbol) where {td, vd}
    con = ocp.constraints[label]
    @match con begin
        (:initial , f::BoundaryConstraint, _, _) => return f
        (:final   , f::BoundaryConstraint, _, _) => return f
        (:boundary, f::BoundaryConstraint, _, _) => return f
        (:control , f::ControlConstraint,  _, _) => return f
        (:control , rg::RangeConstraint,   _, _) => begin
            C = nothing
            (td, vd) == (:t_indep, :v_indep) && (C = ControlConstraint(u         -> u[rg], time_dependence=td, variable_dependence=vd))
            (td, vd) == (:t_indep, :v_dep)   && (C = ControlConstraint((u, v)    -> u[rg], time_dependence=td, variable_dependence=vd))
            (td, vd) == (:t_dep, :v_indep)   && (C = ControlConstraint((t, u)    -> u[rg], time_dependence=td, variable_dependence=vd))
            (td, vd) == (:t_dep, :v_dep)     && (C = ControlConstraint((t, u, v) -> u[rg], time_dependence=td, variable_dependence=vd))
            return C
        end
        (:state   , f::StateConstraint,    _, _) => return f
        (:state   , rg::RangeConstraint,   _, _) => begin
            S = nothing
            (td, vd) == (:t_indep, :v_indep) && (S = StateConstraint(x         -> x[rg], time_dependence=td, variable_dependence=vd))
            (td, vd) == (:t_indep, :v_dep)   && (S = StateConstraint((x, v)    -> x[rg], time_dependence=td, variable_dependence=vd))
            (td, vd) == (:t_dep, :v_indep)   && (S = StateConstraint((t, x)    -> x[rg], time_dependence=td, variable_dependence=vd))
            (td, vd) == (:t_dep, :v_dep)     && (S = StateConstraint((t, x, v) -> x[rg], time_dependence=td, variable_dependence=vd))
            return S
        end
        (:mixed   , f::MixedConstraint,    _, _) => return f
        (:variable, f::VariableConstraint, _, _) => return f
        (:variable, rg::RangeConstraint, _, _) => return VariableConstraint(v -> v[rg])
        _ => throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
             ". Please choose within [ :initial, :final, :boundary, :control, :state, :mixed, :variable ]."))
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
- `(ulb, uind, uub)` are control linear constraints of a subset of indices
- `(xlb, xind, xub)` are state linear constraints of a subset of indices
- `(vlb, vind, vub)` are variable linear constraints of a subset of indices

!!! note

    - The dimensions of the state and control must be set before calling `nlp_constraints`.

# Example

```jldoctest
julia> (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu),
    (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)
```
"""
function nlp_constraints(ocp::OptimalControlModel{time_dependence}) where {time_dependence}

    # we check if the dimensions and times have been set
    @check(ocp)
    
    #
    constraints = ocp.constraints

    ξf = Vector{ControlConstraint}(); ξl = Vector{ctNumber}(); ξu = Vector{ctNumber}()
    ηf = Vector{StateConstraint}(); ηl = Vector{ctNumber}(); ηu = Vector{ctNumber}()
    ψf = Vector{MixedConstraint}(); ψl = Vector{ctNumber}(); ψu = Vector{ctNumber}()
    ϕf = Vector{BoundaryConstraint}(); ϕl = Vector{ctNumber}(); ϕu = Vector{ctNumber}()
    θf = Vector{VariableConstraint}(); θl = Vector{ctNumber}(); θu = Vector{ctNumber}()
    uind = Vector{Int}(); ulb = Vector{ctNumber}(); uub = Vector{ctNumber}()
    xind = Vector{Int}(); xlb = Vector{ctNumber}(); xub = Vector{ctNumber}()
    vind = Vector{Int}(); vlb = Vector{ctNumber}(); vub = Vector{ctNumber}()

    for (_, c) ∈ constraints
        @match c begin
        (:initial, f::BoundaryConstraint, lb, ub) => begin
            push!(ϕf, f)
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:final, f::BoundaryConstraint, lb, ub) => begin
            push!(ϕf, f)
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:boundary, f::BoundaryConstraint, lb, ub) => begin
            push!(ϕf, f)
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:control, f::ControlConstraint, lb, ub) => begin
            push!(ξf, f)
            append!(ξl, lb)
            append!(ξu, ub) end
        (:control, rg::RangeConstraint, lb, ub) => begin
            append!(uind, rg)
            append!(ulb, lb)
            append!(uub, ub) end
        (:state, f::StateConstraint, lb, ub) => begin
            push!(ηf, f)
            append!(ηl, lb)
            append!(ηu, ub) end
        (:state, rg::RangeConstraint, lb, ub) => begin
            append!(xind, rg)
            append!(xlb, lb)
            append!(xub, ub) end
        (:mixed, f::MixedConstraint, lb, ub) => begin
            push!(ψf, f)
            append!(ψl, lb)
            append!(ψu, ub) end
        (:variable, f::VariableConstraint, lb, ub) => begin
            push!(θf, f)
            append!(θl, lb)
            append!(θu, ub) end
        (:variable, rg::RangeConstraint, lb, ub) => begin
            append!(vind, rg)
            append!(vlb, lb)
            append!(vub, ub) end
        _ => throw(NotImplemented("dealing with this kind of constraint is not implemented")) end
    end

    function ξ(t, u, v)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ξf) append!(val, ξf[i](t, u)) end
        return val
    end

    function η(t, x, v)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ηf) append!(val, ηf[i](t, x)) end
        return val
    end

    function ψ(t, x, u, v)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ψf) append!(val, ψf[i](t, x, u)) end
        return val
    end

    function θ(v)
        val = Vector{ctNumber}()
        for i ∈ 1:length(θf) append!(val, θf[i](v)) end
        return val
    end

    function ϕ(x0, xf, v)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ϕf) append!(val, ϕf[i](x0, xf)) end
        return val
    end

    return (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (θl, θ, θu), (ulb, uind, uub), (xlb, xind, xub), (vlb, vind, vub)

end
