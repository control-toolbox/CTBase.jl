function check_time_dependence(time_dependence::Symbol)
    if time_dependence ∉ [:t_indep, :t_dep]
        throw(IncorrectArgument("time_dependence must be either :t_indep or :t_dep"))
    end
    return true
end

function check_variable_dependence(variable_dependence::Symbol)
    if variable_dependence ∉ [:v_indep, :v_dep]
        throw(IncorrectArgument("variable_dependence must be either :v_indep or :v_dep"))
    end
    return true
end

macro check(s::Symbol)
    s == :time_dependence && return esc(quote check_time_dependence($s) end)
    s == :variable_dependence && return esc(quote check_variable_dependence($s) end)
end