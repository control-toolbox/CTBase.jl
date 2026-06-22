"""
    $(TYPEDSIGNATURES)

Convert a DocType enumeration value to its string representation.

# Arguments
- `x::DocType`: the DocType value to convert.

# Returns
- `String`: human-readable string representation.

"""
_to_string(x::DocType) = DOCTYPE_NAMES[x]

"""
    $(TYPEDSIGNATURES)

Classify a symbol by its type (function, macro, struct, constant, module, abstract type).

# Arguments
- `obj`: the symbol object to classify.
- `name_str::String`: the name of the symbol as a string.

# Returns
- `DocType`: the classification of the symbol.

"""
function _classify_symbol(obj, name_str::String)
    startswith(name_str, "@") && return DOCTYPE_MACRO
    obj isa Module && return DOCTYPE_MODULE
    obj isa Type && isabstracttype(obj) && return DOCTYPE_ABSTRACT_TYPE
    obj isa Type && return DOCTYPE_STRUCT
    obj isa Function && return DOCTYPE_FUNCTION
    return DOCTYPE_CONSTANT
end

"""
    $(TYPEDSIGNATURES)

Classify all symbols in a module into exported and private categories.
Returns a NamedTuple with `exported` and `private` fields, each containing
sorted lists of `(Symbol, DocType)` pairs.

# Arguments
- `mod::Module`: the module to analyze.

# Returns
- `NamedTuple`: with `exported` and `private` fields, each containing sorted lists of `(Symbol, DocType)` pairs.

"""
function _exported_symbols(mod::Module)
    exported = Pair{Symbol,DocType}[]
    private = Pair{Symbol,DocType}[]
    exported_names = Set(names(mod; all=false))

    for n in names(mod; all=true, imported=false)
        name_str = String(n)
        # Skip compiler-generated symbols and the module itself
        startswith(name_str, "#") && continue
        n == nameof(mod) && continue

        obj = try
            getfield(mod, n)
        catch
            continue
        end

        doc_type = _classify_symbol(obj, name_str)
        target = n in exported_names ? exported : private
        push!(target, n => doc_type)
    end

    sort_fn = x -> (DOCTYPE_ORDER[x[2]], string(x[1]))
    return (exported=sort(exported; by=sort_fn), private=sort(private; by=sort_fn))
end
