"""
$(TYPEDEF)

Singleton type marking the absence of a provided value.

Ecosystem-wide sentinel for "no default / argument not given". The canonical
value is `CTBase.Core.NotProvided`.

See also: `CTBase.Core.NotProvided`.
"""
struct NotProvidedType end

"""
    NotProvided

Singleton instance of `CTBase.Core.NotProvidedType`.

The canonical "not provided" sentinel used across the control-toolbox ecosystem
(option defaults, optional variable parameters, optional AD backends, …).

# Example
```julia-repl
julia> using CTBase.Core

julia> x = NotProvided
NotProvided

julia> x isa NotProvidedType
true

julia> x === NotProvided
true
```

See also: `CTBase.Core.NotProvidedType`.
"""
const NotProvided = NotProvidedType()

Base.show(io::IO, ::NotProvidedType) = print(io, "NotProvided")
