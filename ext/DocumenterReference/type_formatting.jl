"""
    $(TYPEDSIGNATURES)

Generate a Documenter-compatible signature string for a method.
Returns a string like `Module.func(::Type1, ::Type2)` for use in `@docs` blocks.

# Arguments
- `m::Method`: the method to format.
- `mod::Module`: the module containing the method.
- `key::Symbol`: the function name.

# Returns
- `String`: Documenter-compatible signature string.

"""
function _method_signature_string(m::Method, mod::Module, key::Symbol)
    sig = m.sig
    while sig isa UnionAll
        sig = sig.body
    end

    if !(sig <: Tuple)
        return "$(mod).$(key)"
    end

    params = sig.parameters
    arg_types = length(params) > 1 ? params[2:end] : Any[]

    if isempty(arg_types)
        return "$(mod).$(key)()"
    end

    type_strs = [_format_type_for_docs(T) for T in arg_types]
    return "$(mod).$(key)($(join(type_strs, ", ")))"
end

"""
    $(TYPEDSIGNATURES)

Format a type for use in Documenter's `@docs` block.
Always fully qualifies types to avoid UndefVarError when Documenter evaluates in Main.

# Arguments
- `T`: the type to format.

# Returns
- `String`: formatted type string with `::` prefix and full module qualification.

"""
function _format_type_for_docs(T)
    # Vararg
    if T isa Core.TypeofVararg
        inner = _format_type_for_docs(T.T)
        inner_clean = startswith(inner, "::") ? inner[3:end] : inner
        return "::Vararg{$(inner_clean)}"
    end

    # TypeVar
    T isa TypeVar && return "::$(T.name)"

    # UnionAll - unwrap and format
    T isa UnionAll && return _format_type_for_docs(Base.unwrap_unionall(T))

    # DataType
    if T isa DataType
        return _format_datatype_for_docs(T)
    end

    # Union
    if T isa Union
        union_types = Base.uniontypes(T)
        formatted = [_format_type_for_docs(ut) for ut in union_types]
        cleaned = [startswith(s, "::") ? s[3:end] : s for s in formatted]
        return "::Union{$(join(cleaned, ", "))}"
    end

    return "::$(T)"
end

"""
    $(TYPEDSIGNATURES)

Format a DataType for use in @docs blocks.

# Arguments
- `T::DataType`: the DataType to format.

# Returns
- `String`: formatted DataType string with full module qualification.

"""
function _format_datatype_for_docs(T::DataType)
    type_mod = parentmodule(T)
    type_name = T.name.name
    is_core_or_base = type_mod === Core || type_mod === Base

    if T === Int
        type_name = :Int
    elseif T === UInt
        type_name = :UInt
    end

    # Handle parametric types
    if !isempty(T.parameters)
        has_typevar_params = any(p -> p isa TypeVar, T.parameters)

        if has_typevar_params
            # Strip type parameters to avoid UndefVarError
            return is_core_or_base ? "::$(type_name)" : "::$(type_mod).$(type_name)"
        else
            # Keep concrete type parameters
            params = [_format_type_param(p) for p in T.parameters]
            params_str = join(params, ", ")
            return if is_core_or_base
                "::$(type_name){$(params_str)}"
            else
                "::$(type_mod).$(type_name){$(params_str)}"
            end
        end
    end

    # Simple type
    return is_core_or_base ? "::$(type_name)" : "::$(type_mod).$(type_name)"
end

"""
    $(TYPEDSIGNATURES)

Format a type parameter (can be a type or a value like an integer).

# Arguments
- `p`: the type parameter to format.

# Returns
- `String`: formatted type parameter string.

"""
function _format_type_param(p)
    if p isa Type
        s = _format_type_for_docs(p)
        return startswith(s, "::") ? s[3:end] : s
    elseif p isa TypeVar
        return string(p.name)
    else
        return string(p)
    end
end
