# Option value representation with provenance

"""
$(TYPEDEF)

Represents an option value with its source provenance.

# Fields
- `value::T`: The actual option value.
- `source::Symbol`: Where the value came from (`:default`, `:user`, `:computed`).

# Constructor Validation

The constructor validates the source symbol using Val dispatch for compile-time
type safety and performance optimization. Invalid sources throw `Exceptions.IncorrectArgument`.

# Notes
The `source` field tracks the provenance of the option value:
- `:default`: Value comes from the tool's default configuration
- `:user`: Value was explicitly provided by the user
- `:computed`: Value was computed/derived from other options

# Example
```julia-repl
julia> using CTBase.Options

julia> opt = OptionValue(100, :user)
OptionValue{Int64}(100, :user)

julia> opt.value
100

julia> opt.source
:user
```

# Throws
- `Exceptions.IncorrectArgument`: If source is not one of `:default`, `:user`, or `:computed`

See also: `value`, `source`, `is_user`
"""
struct OptionValue{T}
    value::T
    source::Symbol

    function OptionValue(value::T, source::Symbol) where {T}
        _construct_option_value(value, Val(source))
    end

    # Internal constructor dispatch functions
    function _construct_option_value(value::T, ::Val{:default}) where {T}
        return new{T}(value, :default)
    end

    function _construct_option_value(value::T, ::Val{:user}) where {T}
        return new{T}(value, :user)
    end

    function _construct_option_value(value::T, ::Val{:computed}) where {T}
        return new{T}(value, :computed)
    end

    function _construct_option_value(value, source::Val)
        throw(
            Exceptions.IncorrectArgument(
                "Invalid option source";
                got="source=$(typeof(source).parameters[1])",
                expected=":default, :user, or :computed",
                suggestion="Use one of the valid source symbols: :default (tool default), :user (user-provided), or :computed (derived)",
                context="OptionValue constructor - validating source provenance",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Create an `OptionValue` defaulting to `:user` source.

# Arguments
- `value`: The option value.

# Returns
- `OptionValue{T}`: Option value with `:user` source.

# Example
```julia
OptionValue(42)  # Equivalent to OptionValue(42, :user)
```
"""
OptionValue(value) = OptionValue(value, :user)

# OptionValue getters and introspection

"""
$(TYPEDSIGNATURES)

Get the value from this option value wrapper.

# Returns
- The stored option value

# Example
```julia
opt = OptionValue(100, :user)
value(opt)  # 100
```

See also: `source`, `is_user`
"""
value(opt::OptionValue) = opt.value

"""
$(TYPEDSIGNATURES)

Get the source provenance of this option value.

# Returns
- `Symbol`: `:default`, `:user`, or `:computed`

# Example
```julia
opt = OptionValue(100, :user)
source(opt)  # :user
```

See also: `value`, `is_user`
"""
source(opt::OptionValue) = opt.source

"""
$(TYPEDSIGNATURES)

Check if this option value was explicitly provided by the user.

# Returns
- `Bool`: `true` if the source is `:user`

# Example
```julia
opt = OptionValue(100, :user)
is_user(opt)  # true
```

See also: `is_default`, `is_computed`, `source`
"""
is_user(opt::OptionValue) = opt.source === :user

"""
$(TYPEDSIGNATURES)

Check if this option value is using its default.

# Returns
- `Bool`: `true` if the source is `:default`

# Example
```julia
opt = OptionValue(100, :default)
is_default(opt)  # true
```

See also: `is_user`, `is_computed`, `source`
"""
is_default(opt::OptionValue) = opt.source === :default

"""
$(TYPEDSIGNATURES)

Check if this option value was computed from other options.

# Returns
- `Bool`: `true` if the source is `:computed`

# Example
```julia
opt = OptionValue(100, :computed)
is_computed(opt)  # true
```

See also: `is_user`, `is_default`, `source`
"""
is_computed(opt::OptionValue) = opt.source === :computed

"""
$(TYPEDSIGNATURES)

Display the option value in the format "value (source)".

# Example
```julia
println(OptionValue(3.14, :default))  # "3.14 (default)"
```
"""
Base.show(io::IO, opt::OptionValue) = print(io, "$(opt.value) ($(opt.source))")
