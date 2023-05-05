function check_time_dependence(time_dependence::Symbol)
    time_dependence ∉ [:t_indep, :t_dep] && throw(IncorrectArgument("time_dependence must be either :t_indep or :t_dep"))
end

function check_variable_dependence(variable_dependence::Symbol)
    variable_dependence ∉ [:v_indep, :v_dep] && throw(IncorrectArgument("variable_dependence must be either :v_indep or :v_dep"))
end

function check_criterion(criterion::Symbol)
    criterion ∉ [:min, :max] && throw(IncorrectArgument("criterion must be either :min or :max"))
end

macro check(s::Symbol)
    s ∉ [:time_dependence, :variable_dependence, :criterion] && 
        throw(IncorrectArgument("s must belongs to [:time_dependence, :variable_dependence, criterion]"))
    s == :time_dependence && return esc(quote check_time_dependence($s) end)
    s == :variable_dependence && return esc(quote check_variable_dependence($s) end)
    s == :criterion && return esc(quote check_criterion($s) end)
end

# --------------------------------------------------------------------
function check_state_set(ocp::OptimalControlModel)
    state_not_set(ocp) && throw(UnauthorizedCall("the state dimension has to be set before. Use state!."))
end

function check_control_set(ocp::OptimalControlModel)
    control_not_set(ocp) && throw(UnauthorizedCall("the control dimension has to be set before. Use control!."))
end

function check_time_set(ocp::OptimalControlModel)
    time_not_set(ocp) && throw(UnauthorizedCall("the time dimension has to be set before. Use time!."))
end

function check_variable_set(ocp::OptimalControlModel)
    variable_not_set(ocp) && throw(UnauthorizedCall("the variable dimension has to be set before. Use variable!."))
end

macro check(o::Symbol, s::Symbol)
    s ∉ [:state, :control, :time, :variable, :set] && throw(IncorrectArgument("s must be either :state, :control, :time or :variable"))
    s == :state && return esc(quote check_state_set($o) end)
    s == :control && return esc(quote check_control_set($o) end)
    s == :time && return esc(quote check_time_set($o) end)
    s == :variable && return esc(quote check_variable_set($o) end) 
    s == :set && return esc(quote begin
        check_state_set($o)
        check_control_set($o)
        check_time_set($o)
        check_variable_set($o)
    end end)
end