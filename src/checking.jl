function check_time_dependence(time_dependence::Symbol)
    if time_dependence ∉ [:autonomous, :nonautonomous]
        throw(IncorrectArgument("time_dependence must be either :autonomous or :nonautonomous"))
    end
    nothing
end