"""
$(TYPEDSIGNATURES)

Return the times (discretization time grid) of the optimal control solution or `nothing`.

"""
get_times(sol::OptimalControlSolution) = sol.times

"""
$(TYPEDSIGNATURES)

Return the name of the initial time of the optimal control solution or `nothing`.

"""
get_initial_time_name(sol::OptimalControlSolution) = sol.initial_time_name

"""
$(TYPEDSIGNATURES)

Return the name of final time of the optimal control solution or `nothing`.

"""
get_final_time_name(sol::OptimalControlSolution) = sol.final_time_name

"""
$(TYPEDSIGNATURES)

Return the name of the time component of the optimal control solution or `nothing`.

"""
get_time_name(sol::OptimalControlSolution) = sol.time_name

"""
$(TYPEDSIGNATURES)

Return the dimension of the control of the optimal control solution or `nothing`.

"""
get_control_dimension(sol::OptimalControlSolution) = sol.control_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the control of the optimal control solution or `nothing`.

"""
get_control_components_names(sol::OptimalControlSolution) = sol.control_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the control of the optimal control solution or `nothing`.

"""
get_control_name(sol::OptimalControlSolution) = sol.control_name

"""
$(TYPEDSIGNATURES)

Return the control (function of time) of the optimal control solution or `nothing`.

```@example
julia> t0 = times(sol)[1]
julia> u  = control(sol)
julia> u0 = u(t0)
```
"""
get_control(sol::OptimalControlSolution) = sol.control

"""
$(TYPEDSIGNATURES)

Return the dimension of the state of the optimal control solution or `nothing`.

"""
get_state_dimension(sol::OptimalControlSolution) = sol.state_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the state of the optimal control solution or `nothing`.

"""
get_state_components_names(sol::OptimalControlSolution) = sol.state_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the state of the optimal control solution or `nothing`.

"""
get_state_name(sol::OptimalControlSolution) = sol.state_name

"""
$(TYPEDSIGNATURES)

Return the state (function of time) of the optimal control solution or `nothing`.

```@example
julia> t0 = times(sol)[1]
julia> x  = state(sol)
julia> x0 = x(t0)
```
"""
get_state(sol::OptimalControlSolution) = sol.state

"""
$(TYPEDSIGNATURES)

Return the dimension of the variable of the optimal control solution or `nothing`.

"""
get_variable_dimension(sol::OptimalControlSolution) = sol.variable_dimension

"""
$(TYPEDSIGNATURES)

Return the names of the components of the variable of the optimal control solution or `nothing`.

"""
get_variable_components_names(sol::OptimalControlSolution) = sol.variable_components_names

"""
$(TYPEDSIGNATURES)

Return the name of the variable of the optimal control solution or `nothing`.

"""
get_variable_name(sol::OptimalControlSolution) = sol.variable_name

"""
$(TYPEDSIGNATURES)

Return the variable of the optimal control solution or `nothing`.

```@example
julia> v  = variable(sol)
```
"""
get_variable(sol::OptimalControlSolution) = sol.variable

"""
$(TYPEDSIGNATURES)

Return the costate of the optimal control solution or `nothing`.

```@example
julia> t0 = times(sol)[1]
julia> p  = costate(sol)
julia> p0 = p(t0)
```
"""
get_costate(sol::OptimalControlSolution) = sol.costate

"""
$(TYPEDSIGNATURES)

Return the objective value of the optimal control solution or `nothing`.

"""
get_objective(sol::OptimalControlSolution) = sol.objective

"""
$(TYPEDSIGNATURES)

Return the number of iterations (if solved by an iterative method) of the optimal control solution or `nothing`.

"""
get_iterations(sol::OptimalControlSolution) = sol.iterations

"""
$(TYPEDSIGNATURES)

Return the stopping criterion (a Symbol) of the optimal control solution or `nothing`.

"""
get_stopping(sol::OptimalControlSolution) = sol.stopping

"""
$(TYPEDSIGNATURES)

Return the message associated to the stopping criterion of the optimal control solution or `nothing`.

"""
get_message(sol::OptimalControlSolution) = sol.message

"""
$(TYPEDSIGNATURES)

Return the true if the solver has finished successfully of false if not, or `nothing`.

"""
get_success(sol::OptimalControlSolution) = sol.success

"""
$(TYPEDSIGNATURES)

Return a dictionary of additional infos depending on the solver or `nothing`.

"""
get_infos(sol::OptimalControlSolution) = sol.infos