"""
    @ensure condition exception

Throws the provided `exception` if `condition` is false.

# Usage
```julia-repl
julia> @ensure true Exceptions.IncorrectArgument("This won't throw")
julia> @ensure false Exceptions.IncorrectArgument("This will throw")
ERROR: IncorrectArgument("This will throw")
```

# Arguments
- `condition`: A Boolean expression to test.
- `exception`: An instance of an exception to throw if `condition` is false.

# Throws
- The provided `exception` if the condition is not satisfied.
"""
macro ensure(cond, exc)
    return esc(:(
        if !($cond)
            throw($exc)
        end
    ))
end
