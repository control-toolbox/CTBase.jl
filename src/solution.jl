# ------------------------------------------------------------------------------------
# Abstract solution
#
abstract type AbstractOptimalControlSolution end

#= # getters
message_aocs = "method not implemented for solutions of type "
error_aocs(sol::AbstractOptimalControlSolution) = error(message_aocs*String(typeof(sol)))
#
state_dimension(sol::AbstractOptimalControlSolution) = error_aocs(sol)
control_dimension(sol::AbstractOptimalControlSolution) = error_aocs(sol)
time_steps(sol::AbstractOptimalControlSolution) = error_aocs(sol)
time_steps_length(sol::AbstractOptimalControlSolution) = error_aocs(sol)
state(sol::AbstractOptimalControlSolution) = error_aocs(sol)
state_labels(sol::AbstractOptimalControlSolution) = error_aocs(sol)
control(sol::AbstractOptimalControlSolution) = error_aocs(sol)
adjoint(sol::AbstractOptimalControlSolution) = error_aocs(sol)
objective(sol::AbstractOptimalControlSolution) = error_aocs(sol)
iterations(sol::AbstractOptimalControlSolution) = error_aocs(sol)
success(sol::AbstractOptimalControlSolution) = error_aocs(sol)
message(sol::AbstractOptimalControlSolution) = error_aocs(sol)
stopping(sol::AbstractOptimalControlSolution) = error_aocs(sol)
constraints_violation(sol::AbstractOptimalControlSolution) = error_aocs(sol) =#

@with_kw mutable struct OptimalControlSolution <: AbstractOptimalControlSolution 
    state_dimension::Union{Nothing, Dimension}=nothing
    control_dimension::Union{Nothing, Dimension}=nothing
    times::Union{Nothing, TimesDisc}=nothing
    time_label::String=""
    state::Union{Nothing, Function}=nothing
    state_labels::Vector{String}=Vector{String}()
    adjoint::Union{Nothing, Function}=nothing
    control::Union{Nothing, Function}=nothing
    control_labels::Vector{String}=Vector{String}()
    objective::Union{Nothing, MyNumber}=nothing
    iterations::Union{Nothing, Integer}=nothing
    stopping::Union{Nothing, Symbol}=nothing # the stopping criterion
    message::Union{Nothing, String}=nothing # the message corresponding to the stopping criterion
    success::Union{Nothing, Bool}=nothing # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}()
end

#= # getters
state_dimension(sol::OptimalControlSolution) = sol.state_dimension
control_dimension(sol::OptimalControlSolution) = sol.control_dimension
time_steps(sol::OptimalControlSolution) = sol.times
time_steps_length(sol::OptimalControlSolution) = length(time(sol))
state(sol::OptimalControlSolution) = sol.state
state_labels(sol::OptimalControlSolution) = sol.state_labels
control(sol::OptimalControlSolution) = sol.control
control_labels(sol::OptimalControlSolution) = sol.control_labels
adjoint(sol::OptimalControlSolution) = sol.adjoint
objective(sol::OptimalControlSolution) = sol.objective
iterations(sol::OptimalControlSolution) = sol.iterations   
success(sol::OptimalControlSolution) = sol.success
message(sol::OptimalControlSolution) = sol.message
stopping(sol::OptimalControlSolution) = sol.stopping =#

# we get an error when a solution is printed so I add this function
# which has to be put in the package CTBase and has to be completed
function Base.show(io::IO, ::MIME"text/plain", sol::OptimalControlSolution)
    nothing
end