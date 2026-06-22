# Unified option definition and schema

"""
$(TYPEDEF)

Unified option definition for both option extraction and strategy contracts.

This type provides a comprehensive option definition that can be used for:
- Option extraction in the Options module
- Strategy contract definition in the Strategies module
- Action schema definition

# Fields
- `name::Symbol`: Primary name of the option
- `type::Type`: Expected Julia type for the option value
- `default::T`: Default value when the option is not provided (type parameter `T`)
- `description::String`: Human-readable description of the option's purpose
- `aliases::Tuple{Vararg{Symbol}}`: Alternative names for this option (default: empty tuple)
- `validator::Union{Function, Nothing}`: Optional validation function (default: `nothing`)
- `computed::Bool`: Whether the default value is computed from parameters (default: `false`)

# Type Parameter `T`

The type parameter `T` represents the type of the default value:
- `T = Any` when `default = nothing` (explicit nothing default)
- `T = NotProvidedType` when `default = NotProvided` (no default value)
- `T = typeof(default)` for concrete default values

# Validator Contract

Validators must follow this pattern:
```julia
x -> condition || throw(ArgumentError("error message"))
```

The validator should:
- Return `true` (or any truthy value) if the value is valid
- Throw an exception (preferably `ArgumentError`) if the value is invalid
- Be a pure function without side effects

# Constructor Validation

The constructor performs the following validations:
1. Checks that `default` matches the specified `type` (unless `default` is `nothing` or `NotProvided`)
2. Runs the `validator` on the `default` value (if both are provided and `default` is not `NotProvided`)

# Example
```julia
def = OptionDefinition(
    name = :max_iter,
    type = Int,
    default = 100,
    description = "Maximum number of iterations",
    aliases = (:max, :maxiter),
    validator = x -> x > 0 || throw(ArgumentError("\$x must be positive"))
)

def.name      # :max_iter
def.aliases   # (:max, :maxiter)
all_names(def) # (:max_iter, :max, :maxiter)
```

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the default value does not match the declared type
- `Exception`: If the validator function fails when applied to the default value

See also: `all_names`, `extract_option`, `extract_options`, `NotProvided`
"""
struct OptionDefinition{T}
    name::Symbol
    type::Type  # Not parameterized to allow NotProvided with any declared type
    default::T
    description::String
    aliases::Tuple{Vararg{Symbol}}
    validator::Union{Function,Nothing}
    computed::Bool

    function OptionDefinition{T}(;
        name::Symbol,
        type::Type,
        default::T,
        description::String,
        aliases::Tuple{Vararg{Symbol}}=(),
        validator::Union{Function,Nothing}=nothing,
        computed::Bool=false,
    ) where {T}
        # Validate with custom validator if provided (skip for NotProvided)
        if validator !== nothing && !(default isa NotProvidedType)
            try
                validator(default)
            catch e
                @error "Validation failed for option $name with default value $default" exception=(
                    e, catch_backtrace()
                )
                rethrow()
            end
        end

        new{T}(name, type, default, description, aliases, validator, computed)
    end
end

"""
$(TYPEDSIGNATURES)

Convenience constructor that infers the type parameter `T` from the default value.

This constructor automatically determines the appropriate type parameter and
delegates to specialized methods based on the type of `default`:
- `nothing` → creates `OptionDefinition{Any}` with `type = Any`
- `NotProvided` → creates `OptionDefinition{NotProvidedType}` with preserved `type`
- concrete values → creates `OptionDefinition{T}` where `T = typeof(default)`

# Arguments
- `name::Symbol`: Primary name of the option
- `type::Type`: Expected Julia type for the option value
- `default`: Default value (type parameter `T` is inferred automatically)
- `description::String`: Human-readable description of the option's purpose
- `aliases::Tuple{Vararg{Symbol}}`: Alternative names (default: empty tuple)
- `validator::Union{Function, Nothing}`: Optional validation function (default: `nothing`)
- `computed::Bool`: Whether the default is computed from parameters (default: `false`)

# Returns
- `OptionDefinition{T}`: Option definition with inferred type parameter

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If concrete `default` is not compatible with `type`

# Example
```julia-repl
julia> using CTBase.Options

julia> # Concrete default - infers Int
julia> def1 = OptionDefinition(
           name = :max_iter,
           type = Int,
           default = 100,
           description = "Maximum iterations"
       )
OptionDefinition{Int}(...)

julia> # Nothing default - creates Any
julia> def2 = OptionDefinition(
           name = :backend,
           type = Union{Nothing, String},
           default = nothing,
           description = "Execution backend"
       )
OptionDefinition{Any}(...)

julia> # No default - creates NotProvidedType
julia> def3 = OptionDefinition(
           name = :input_file,
           type = String,
           default = NotProvided,
           description = "Input file path"
       )
OptionDefinition{NotProvidedType}(...)
```

# Notes
- For `nothing` defaults, the `type` parameter is ignored and set to `Any`
- For `NotProvided` defaults, the declared `type` is preserved for validation
- For concrete defaults, type compatibility between `default` and `type` is enforced
- The validator function is applied to the default value (except for `NotProvided`)

See also: `OptionDefinition{T}`, `_construct_option_definition`, `NotProvided`
"""
function OptionDefinition(;
    name::Symbol,
    type::Type,
    default,
    description::String,
    aliases::Tuple{Vararg{Symbol}}=(),
    validator::Union{Function,Nothing}=nothing,
    computed::Bool=false,
)
    return _construct_option_definition(
        name, type, default, description, aliases, validator, computed
    )
end

# Dispatch methods for different default types

"""
$(TYPEDSIGNATURES)

Construct an `OptionDefinition` with a `nothing` default value.

This method handles the special case where `default = nothing`, creating an
`OptionDefinition{Any}` with `type = Any` since `nothing` can represent any type.

# Arguments
- `name::Symbol`: Primary name of the option
- `type::Type`: Expected Julia type (ignored for `nothing` defaults)
- `default::Nothing`: Must be `nothing`
- `description::String`: Human-readable description
- `aliases::Tuple{Vararg{Symbol}}`: Alternative names (default: empty tuple)
- `validator::Union{Function, Nothing}`: Optional validation function (default: `nothing`)
- `computed::Bool`: Whether the default is computed from parameters (default: `false`)

# Returns
- `OptionDefinition{Any}`: Option definition with `nothing` default

# Example
```julia-repl
julia> using CTBase.Options

julia> def = _construct_option_definition(
           :backend,
           Union{Nothing, String},
           nothing,
           "Execution backend",
           (:be,)
       )
OptionDefinition{Any}(...)

julia> default(def)
nothing
```

See also: `OptionDefinition`, `NotProvided`
"""
function _construct_option_definition(
    name::Symbol,
    type::Type,
    default::Nothing,
    description::String,
    aliases::Tuple{Vararg{Symbol}},
    validator::Union{Function,Nothing},
    computed::Bool,
)
    return OptionDefinition{Any}(;
        name=name,
        type=Any,
        default=nothing,
        description=description,
        aliases=aliases,
        validator=validator,
        computed=computed,
    )
end

"""
$(TYPEDSIGNATURES)

Construct an `OptionDefinition` with a `NotProvided` default value.

This method handles the special case where `default = NotProvided`, creating an
`OptionDefinition{NotProvidedType}`. The declared `type` is preserved since
`NotProvided` indicates the absence of a default value while maintaining type
information for validation.

# Arguments
- `name::Symbol`: Primary name of the option
- `type::Type`: Expected Julia type for user-provided values
- `default::NotProvidedType`: Must be `NotProvided`
- `description::String`: Human-readable description
- `aliases::Tuple{Vararg{Symbol}}`: Alternative names (default: empty tuple)
- `validator::Union{Function, Nothing}`: Optional validation function (default: `nothing`)
- `computed::Bool`: Whether the default is computed from parameters (default: `false`)

# Returns
- `OptionDefinition{NotProvidedType}`: Option definition with no default value

# Example
```julia-repl
julia> using CTBase.Options

julia> def = _construct_option_definition(
           :input_file,
           String,
           NotProvided,
           "Input file path",
           (:input,)
       )
OptionDefinition{NotProvidedType}(...)

julia> is_required(def)
true
```

See also: `OptionDefinition`, `NotProvided`, `is_required`
"""
function _construct_option_definition(
    name::Symbol,
    type::Type,
    default::NotProvidedType,
    description::String,
    aliases::Tuple{Vararg{Symbol}},
    validator::Union{Function,Nothing},
    computed::Bool,
)
    return OptionDefinition{NotProvidedType}(;
        name=name,
        type=type,
        default=default,
        description=description,
        aliases=aliases,
        validator=validator,
        computed=computed,
    )
end

"""
$(TYPEDSIGNATURES)

Construct an `OptionDefinition` with a concrete default value.

This method handles the general case where `default` is a concrete value.
It infers the type parameter `T` from the default value and validates that
the default value is compatible with the declared `type`.

# Arguments
- `name::Symbol`: Primary name of the option
- `type::Type`: Expected Julia type for the option value
- `default::T`: Default value (type `T` is inferred)
- `description::String`: Human-readable description
- `aliases::Tuple{Vararg{Symbol}}`: Alternative names (default: empty tuple)
- `validator::Union{Function, Nothing}`: Optional validation function (default: `nothing`)
- `computed::Bool`: Whether the default is computed from parameters (default: `false`)

# Returns
- `OptionDefinition{T}`: Option definition with concrete default value

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If `default` is not compatible with `type`

# Example
```julia-repl
julia> using CTBase.Options

julia> def = _construct_option_definition(
           :max_iter,
           Int,
           100,
           "Maximum number of iterations",
           (:max,)
       )
OptionDefinition{Int}(...)

julia> default(def)
100
```

See also: `OptionDefinition`, `Exceptions.IncorrectArgument`
"""
function _construct_option_definition(
    name::Symbol,
    type::Type,
    default::T,
    description::String,
    aliases::Tuple{Vararg{Symbol}},
    validator::Union{Function,Nothing},
    computed::Bool,
) where {T}
    # Check type compatibility
    if !isa(default, type)
        throw(
            Exceptions.IncorrectArgument(
                "Type mismatch in option definition";
                got="default value $default of type $T",
                expected="value of type $type",
                suggestion="Ensure the default value matches the declared type, or adjust the type parameter",
                context="OptionDefinition constructor - validating type compatibility",
            ),
        )
    end

    # Create with inferred type
    return OptionDefinition{T}(;
        name=name,
        type=type,
        default=default,
        description=description,
        aliases=aliases,
        validator=validator,
        computed=computed,
    )
end

# OptionDefinition getters and introspection

"""
$(TYPEDSIGNATURES)

Get the primary name of this option definition.

# Returns
- `Symbol`: The option name

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations")
OptionDefinition{Int}(...)

julia> name(def)
:max_iter
```

See also: `type`, `default`, `aliases`
"""
name(def::OptionDefinition) = def.name

"""
$(TYPEDSIGNATURES)

Get the expected type for this option definition.

# Returns
- `Type`: The expected type

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations")
OptionDefinition{Int}(...)

julia> type(def)
Int
```

See also: `name`, `default`
"""
type(def::OptionDefinition) = def.type

"""
$(TYPEDSIGNATURES)

Get the default value for this option definition.

# Returns
- The default value

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations")
OptionDefinition{Int}(...)

julia> default(def)
100
```

See also: `name`, `type`, `is_required`
"""
default(def::OptionDefinition) = def.default

"""
$(TYPEDSIGNATURES)

Get the description for this option definition.

# Returns
- `String`: The option description

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations")
OptionDefinition{Int}(...)

julia> description(def)
"Maximum iterations"
```

See also: `name`, `type`
"""
description(def::OptionDefinition) = def.description

"""
$(TYPEDSIGNATURES)

Get the validator function for this option definition.

# Returns
- `Union{Function, Nothing}`: The validator function or `nothing`

# Example
```julia-repl
julia> using CTBase.Options

julia> validator_fn = x -> x > 0

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations",
                          validator=validator_fn)
OptionDefinition{Int}(...)

julia> validator(def) === validator_fn
true
```

See also: `has_validator`, `name`
"""
validator(def::OptionDefinition) = def.validator

"""
$(TYPEDSIGNATURES)

Get the aliases for this option definition.

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of alias names

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations",
                          aliases=(:max, :maxiter))
OptionDefinition{Int}(...)

julia> aliases(def)
(:max, :maxiter)
```

See also: `all_names`, `name`
"""
aliases(def::OptionDefinition) = def.aliases

"""
$(TYPEDSIGNATURES)

Check if this option is required (has no default value).

Returns `true` when the default value is `NotProvided`.

# Returns
- `Bool`: `true` if the option is required

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:input, type=String, default=NotProvided,
                          description="Input file")
OptionDefinition{NotProvidedType}(...)

julia> is_required(def)
true
```

See also: `has_default`, `default`
"""
is_required(def::OptionDefinition) = def.default isa NotProvidedType

"""
$(TYPEDSIGNATURES)

Check if this option definition has a default value.

Returns `false` when the default value is `NotProvided`.

# Returns
- `Bool`: `true` if a default value is defined

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations")
OptionDefinition{Int}(...)

julia> has_default(def)
true
```

See also: `is_required`, `default`
"""
has_default(def::OptionDefinition) = !(def.default isa NotProvidedType)

"""
$(TYPEDSIGNATURES)

Check if this option definition has a validator function.

# Returns
- `Bool`: `true` if a validator is defined

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations",
                          validator=x -> x > 0)
OptionDefinition{Int}(...)

julia> has_validator(def)
true
```

See also: `validator`, `name`
"""
has_validator(def::OptionDefinition) = def.validator !== nothing

"""
$(TYPEDSIGNATURES)

Check if this option definition has a computed default value.

Returns `true` when the default value is computed from strategy parameters
(e.g., `backend` in `Exa{GPU}` which depends on the `GPU` parameter).

# Returns
- `Bool`: `true` if the default is computed from parameters

# Example
```julia-repl
julia> using CTBase.Options

julia> # Static default
julia> def1 = OptionDefinition(name=:max_iter, type=Int, default=100,
                          description="Maximum iterations")
OptionDefinition{Int}(...)

julia> is_computed(def1)
false

julia> # Computed default
julia> def2 = OptionDefinition(name=:backend, type=Any, default=compute_backend(),
                          description="Backend", computed=true)
OptionDefinition{...}(...)

julia> is_computed(def2)
true
```

See also: `has_default`, `is_required`, `OptionDefinition`
"""
is_computed(def::OptionDefinition) = def.computed

# Get all names (primary + aliases) for extraction
"""
$(TYPEDSIGNATURES)

Return all valid names for an option definition (primary name plus aliases).

This function is used by the extraction system to search for an option in kwargs
using all possible names (primary name and all aliases).

# Arguments
- `def::OptionDefinition`: The option definition

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing the primary name followed by all aliases

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(
           name = :grid_size,
           type = Int,
           default = 100,
           description = "Grid size",
           aliases = (:n, :size)
       )
OptionDefinition{Int}(...)

julia> all_names(def)
(:grid_size, :n, :size)
```

See also: `OptionDefinition`, `extract_option`
"""
all_names(def::OptionDefinition) = (def.name, def.aliases...)

# Display
"""
$(TYPEDSIGNATURES)

Display an OptionDefinition in a readable format.

Shows the option name, type, default value, and description. If aliases are present,
they are shown in parentheses after the primary name.

# Arguments
- `io::IO`: Output stream
- `def::OptionDefinition`: The option definition to display

# Example
```julia-repl
julia> using CTBase.Options

julia> def = OptionDefinition(
           name = :max_iter,
           type = Int,
           default = 100,
           description = "Maximum iterations",
           aliases = (:max, :maxiter)
       )
OptionDefinition{Int}(...)

julia> println(def)
max_iter (max, maxiter) :: Int64
  default: 100
  Maximum iterations
```

See also: `OptionDefinition`
"""
function Base.show(io::IO, def::OptionDefinition)
    fmt = Core.get_format_codes(io)

    # Show primary name with aliases if present
    if isempty(def.aliases)
        print(io, fmt.name, def.name, fmt.reset, "::", fmt.type, def.type, fmt.reset)
    else
        print(
            io,
            fmt.name,
            def.name,
            fmt.reset,
            " (",
            fmt.keyword,
            join(def.aliases, ", "),
            fmt.reset,
            ")::",
            fmt.type,
            def.type,
            fmt.reset,
        )
    end

    # Show default with source indicator
    if def.computed
        print(
            io,
            " (",
            fmt.value,
            "default: ",
            def.default,
            fmt.reset,
            " [",
            fmt.keyword,
            "computed",
            fmt.reset,
            "])",
        )
    else
        print(io, " (", fmt.value, "default: ", def.default, fmt.reset, ")")
    end
end
