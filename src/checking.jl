function __check_time_dependence(time_dependence::DataType)
    time_dependence ∉ [Autonomous, NonAutonomous] && throw(IncorrectArgument("time_dependence must be either Autonomous or NonAutonomous"))
end

function __check_variable_dependence(variable_dependence::DataType)
    variable_dependence ∉ [Fixed, NonFixed] && throw(IncorrectArgument("variable_dependence must be either Fixed or NonFixed"))
end

function __check_dependences(dependences::Tuple{Vararg{DataType}})
    size(filter(p->p<:VariableDependence,dependences),1) > 1 && throw(IncorrectArgument("the number of arguments about variable dependence must be equal at most to 1"))
    size(filter(p->p<:TimeDependence,dependences),1) > 1 && throw(IncorrectArgument("the number of arguments about time dependence must be equal at most to 1"))
    size(dependences,1) > 2 && throw(IncorrectArgument("the number of arguments about dependences must be equal at most to 2"))
    size(filter(p->!(p<:Union{TimeDependence,VariableDependence}),dependences),1) > 0 && throw(IncorrectArgument("the wrong of arguments, possible arguments are : NonAutonomous, Autonomous, Fixed, NonFixed"))
end

function __check_criterion(criterion::Symbol)
    criterion ∉ [:min, :max] && throw(IncorrectArgument("criterion must be either :min or :max"))
end

function __check_state_set(ocp::OptimalControlModel)
    __is_state_not_set(ocp) && throw(UnauthorizedCall("the state dimension has to be set before. Use state!."))
end

function __check_control_set(ocp::OptimalControlModel)
    __is_control_not_set(ocp) && throw(UnauthorizedCall("the control dimension has to be set before. Use control!."))
end

function __check_is_time_set(ocp::OptimalControlModel)
    __is_time_not_set(ocp) && throw(UnauthorizedCall("the time dimension has to be set before. Use time!."))
end

function __check_variable_set(ocp::OptimalControlModel{<:TimeDependence, NonFixed})
    __is_variable_not_set(ocp) && throw(UnauthorizedCall("the variable dimension has to be set before. Use variable!."))
end

function __check_variable_set(ocp::OptimalControlModel{<:TimeDependence, Fixed})
    nothing
end

function __check_all_set(ocp::OptimalControlModel)
    __check_state_set(ocp)
    __check_control_set(ocp)
    __check_is_time_set(ocp)
    __check_variable_set(ocp)
end

## macro __check(s::Symbol)
##     s == :dependences && return esc(quote __check_dependences($s) end)
##     s == :time_dependence && return esc(quote __check_time_dependence($s) end)
##     s == :variable_dependence && return esc(quote __check_variable_dependence($s) end)
##     s == :criterion && return esc(quote __check_criterion($s) end)
##     s == :ocp && return esc(quote __check_all_set($s) end)
##     error("s must be either :time_dependence, :variable_dependence or :criterion")
## end

macro __check(s)
    esc( @match s begin
        :dependences         => :( __check_dependences($s)         )
        :time_dependence     => :( __check_time_dependence($s)     )
        :variable_dependence => :( __check_variable_dependence($s) )
        :criterion           => :( __check_criterion($s)           )
        :ocp                 => :( __check_all_set($s)             )
        _                    => :( error("unknown check")          )
    end )
end
