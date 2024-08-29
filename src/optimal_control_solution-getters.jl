"""
$(TYPEDSIGNATURES)

Return the time grid of the optimal control solution or `nothing`.

"""
time_grid(sol::OptimalControlSolution)::TimesDisc = sol.time_grid

"""
$(TYPEDSIGNATURES)

Return the name of the initial time of the optimal control solution or `nothing`.

"""
initial_time_name(sol::OptimalControlSolution)::String = sol.initial_time_name

"""
$(TYPEDSIGNATURES)

Return the name of final time of the optimal control solution or `nothing`.

"""
final_time_name(sol::OptimalControlSolution)::String = sol.final_time_name

"""
$(TYPEDSIGNATURES)

Return the name of the time component of the optimal control solution or `nothing`.

"""
time_name(sol::OptimalControlSolution)::String = sol.time_name

"""
$(TYPEDSIGNATURES)

Return the dimension of the control of the optimal control solution or `nothing`.

"""
control_dimension(sol::OptimalControlSolution)::Dimension = sol.control_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the control of the optimal control solution or `nothing`.

"""
control_components_names(sol::OptimalControlSolution) = sol.control_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the control of the optimal control solution or `nothing`.

"""
control_name(sol::OptimalControlSolution)::String = sol.control_name

"""
$(TYPEDSIGNATURES)

Return the control (function of time) of the optimal control solution or `nothing`.

```@example
julia> t0 = time_grid(sol)[1]
julia> u  = control(sol)
julia> u0 = u(t0) # control at initial time
```
"""
control(sol::OptimalControlSolution)::Function = sol.control

"""
$(TYPEDSIGNATURES)

Return the control values at times `time_grid(sol)` of the optimal control solution or `nothing`.

```@example
julia> u  = control_discretized(sol)
julia> u0 = u[1] # control at initial time
```
"""
control_discretized(sol::OptimalControlSolution) = sol.control.(sol.time_grid)

"""
$(TYPEDSIGNATURES)

Return the dimension of the state of the optimal control solution or `nothing`.

"""
state_dimension(sol::OptimalControlSolution)::Dimension = sol.state_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the state of the optimal control solution or `nothing`.

"""
state_components_names(sol::OptimalControlSolution) = sol.state_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the state of the optimal control solution or `nothing`.

"""
state_name(sol::OptimalControlSolution)::String = sol.state_name

"""
$(TYPEDSIGNATURES)

Return the state (function of time) of the optimal control solution or `nothing`.

```@example
julia> t0 = time_grid(sol)[1]
julia> x  = state(sol)
julia> x0 = x(t0)
```
"""
state(sol::OptimalControlSolution)::Function = sol.state

"""
$(TYPEDSIGNATURES)

Return the state values at times `time_grid(sol)` of the optimal control solution or `nothing`.

```@example
julia> x  = state_discretized(sol)
julia> x0 = x[1] # state at initial time
```
"""
state_discretized(sol::OptimalControlSolution) = sol.state.(sol.time_grid)

"""
$(TYPEDSIGNATURES)

Return the dimension of the variable of the optimal control solution or `nothing`.

"""
variable_dimension(sol::OptimalControlSolution)::Dimension = sol.variable_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the variable of the optimal control solution or `nothing`.

"""
variable_components_names(sol::OptimalControlSolution) = sol.variable_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the variable of the optimal control solution or `nothing`.

"""
variable_name(sol::OptimalControlSolution)::String = sol.variable_name

"""
$(TYPEDSIGNATURES)

Return the variable of the optimal control solution or `nothing`.

```@example
julia> v  = variable(sol)
```
"""
variable(sol::OptimalControlSolution)::Variable = sol.variable

"""
$(TYPEDSIGNATURES)

Return the costate of the optimal control solution or `nothing`.

```@example
julia> t0 = time_grid(sol)[1]
julia> p  = costate(sol)
julia> p0 = p(t0)
```
"""
costate(sol::OptimalControlSolution)::Function = sol.costate

"""
$(TYPEDSIGNATURES)

Return the costate values at times `time_grid(sol)` of the optimal control solution or `nothing`.

```@example
julia> p  = costate_discretized(sol)
julia> p0 = p[1] # costate at initial time
```
"""
costate_discretized(sol::OptimalControlSolution) = sol.costate.(sol.time_grid)

"""
$(TYPEDSIGNATURES)

Return the objective value of the optimal control solution or `nothing`.

"""
objective(sol::OptimalControlSolution)::ctNumber = sol.objective

"""
$(TYPEDSIGNATURES)

Return the number of iterations (if solved by an iterative method) of the optimal control solution or `nothing`.

"""
iterations(sol::OptimalControlSolution)::Int = sol.iterations

"""
$(TYPEDSIGNATURES)

Return the stopping criterion (a Symbol) of the optimal control solution or `nothing`.

"""
stopping(sol::OptimalControlSolution)::Symbol = sol.stopping

"""
$(TYPEDSIGNATURES)

Return the message associated to the stopping criterion of the optimal control solution or `nothing`.

"""
message(sol::OptimalControlSolution)::String = sol.message

"""
$(TYPEDSIGNATURES)

Return the true if the solver has finished successfully of false if not, or `nothing`.

"""
success(sol::OptimalControlSolution)::Bool = sol.success

"""
$(TYPEDSIGNATURES)

Return a dictionary of additional infos depending on the solver or `nothing`.

"""
infos(sol::OptimalControlSolution)::Dict{Symbol, Any} = sol.infos

# constraints and multipliers

"""
$(TYPEDSIGNATURES)

Return the boundary constraints of the optimal control solution or `nothing`.

"""
boundary_constraints(sol::OptimalControlSolution)::ctVector = sol.boundary_constraints

"""
$(TYPEDSIGNATURES)

Return the multipliers to the boundary constraints of the optimal control solution or `nothing`.

"""
mult_boundary_constraints(sol::OptimalControlSolution)::ctVector = sol.mult_boundary_constraints

"""
$(TYPEDSIGNATURES)

Return the variable constraints of the optimal control solution or `nothing`.

"""
variable_constraints(sol::OptimalControlSolution)::ctVector = sol.variable_constraints

"""
$(TYPEDSIGNATURES)

Return the multipliers to the variable constraints of the optimal control solution or `nothing`.

"""
mult_variable_constraints(sol::OptimalControlSolution)::ctVector = sol.mult_variable_constraints

"""
$(TYPEDSIGNATURES)

Return the multipliers to the variable lower bounds of the optimal control solution or `nothing`.

"""
mult_variable_box_lower(sol::OptimalControlSolution)::ctVector = sol.mult_variable_box_lower

"""
$(TYPEDSIGNATURES)

Return the multipliers to the variable upper bounds of the optimal control solution or `nothing`.

"""
mult_variable_box_upper(sol::OptimalControlSolution)::ctVector = sol.mult_variable_box_upper

"""
$(TYPEDSIGNATURES)

Return the control constraints of the optimal control solution or `nothing`.

"""
control_constraints(sol::OptimalControlSolution)::Function = sol.control_constraints

"""
$(TYPEDSIGNATURES)

Return the multipliers to the control constraints of the optimal control solution or `nothing`.

"""
mult_control_constraints(sol::OptimalControlSolution)::Function = sol.mult_control_constraints

"""
$(TYPEDSIGNATURES)

Return the state constraints of the optimal control solution or `nothing`.

"""
state_constraints(sol::OptimalControlSolution)::Function = sol.state_constraints

"""
$(TYPEDSIGNATURES)

Return the multipliers to the state constraints of the optimal control solution or `nothing`.

"""
mult_state_constraints(sol::OptimalControlSolution)::Function = sol.mult_state_constraints

"""
$(TYPEDSIGNATURES)

Return the mixed state-control constraints of the optimal control solution or `nothing`.

"""
mixed_constraints(sol::OptimalControlSolution)::Function = sol.mixed_constraints

"""
$(TYPEDSIGNATURES)

Return the multipliers to the mixed state-control constraints of the optimal control solution or `nothing`.

"""
mult_mixed_constraints(sol::OptimalControlSolution)::Function = sol.mult_mixed_constraints

"""
$(TYPEDSIGNATURES)

Return the multipliers to the state lower bounds of the optimal control solution or `nothing`.

"""
mult_state_box_lower(sol::OptimalControlSolution)::Function = sol.mult_state_box_lower

"""
$(TYPEDSIGNATURES)

Return the multipliers to the state upper bounds of the optimal control solution or `nothing`.

"""
mult_state_box_upper(sol::OptimalControlSolution)::Function = sol.mult_state_box_upper

"""
$(TYPEDSIGNATURES)

Return the multipliers to the control lower bounds of the optimal control solution or `nothing`.

"""
mult_control_box_lower(sol::OptimalControlSolution)::Function = sol.mult_control_box_lower

"""
$(TYPEDSIGNATURES)

Return the multipliers to the control upper bounds of the optimal control solution or `nothing`.

"""
mult_control_box_upper(sol::OptimalControlSolution)::Function = sol.mult_control_box_upper
