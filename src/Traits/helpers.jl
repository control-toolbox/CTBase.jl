"""
    _caller_function_name() -> Symbol

Return the name of the calling function by inspecting the stacktrace.

This is used to provide better error messages in trait check functions
without requiring an explicit `source_method` argument.

# Returns
- `Symbol`: The name of the calling function, or `:unknown` if it cannot be determined.
"""
function _caller_function_name()
    stack = stacktrace()
    for frame in stack
        func_name = frame.func
        func_str = string(func_name)
        if func_str != "_caller_function_name" &&
            !startswith(func_str, "#") &&
            func_str != "has_time_dependence_trait" &&
            func_str != "has_variable_dependence_trait" &&
            func_str != "has_mutability_trait"
            return func_name
        end
    end
    return :unknown
end
