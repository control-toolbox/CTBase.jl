"""
    _get_source_file(mod::Module, key::Symbol, type::DocType) -> Union{String, Nothing}

Determine the source file path where a symbol is defined.
Returns `nothing` if the source file cannot be determined.
"""
function _get_source_file(mod::Module, key::Symbol, type::DocType)
    try
        # Strategy 1: Try docstring metadata
        path = _get_source_from_docstring(mod, key)
        path !== nothing && return path

        obj = getfield(mod, key)

        # Strategy 2: For functions/macros, use methods()
        if obj isa Function
            path = _get_source_from_methods(obj)
            path !== nothing && return path
        end

        # Strategy 3: For concrete types, try constructor methods
        if obj isa Type && !isabstracttype(obj)
            path = _get_source_from_methods(obj)
            path !== nothing && return path
        end

        return nothing
    catch e
        @debug "Could not determine source file for $key in $mod" exception=e
        return nothing
    end
end

"""
    _get_source_from_docstring(mod::Module, key::Symbol) -> Union{String, Nothing}

Try to get source file path from docstring metadata.
"""
function _get_source_from_docstring(mod::Module, key::Symbol)
    binding = Base.Docs.Binding(mod, key)
    meta = Base.Docs.meta(mod)
    haskey(meta, binding) || return nothing

    docs = meta[binding]
    if isa(docs, Base.Docs.MultiDoc) && !isempty(docs.docs)
        for (_, docstr) in docs.docs
            if isa(docstr, Base.Docs.DocStr) && haskey(docstr.data, :path)
                path = docstr.data[:path]
                if path !== nothing && !isempty(path)
                    return abspath(String(path))
                end
            end
        end
    end
    return nothing
end

"""
    _get_source_from_methods(obj) -> Union{String, Nothing}

Try to get source file path from method definitions.
"""
function _get_source_from_methods(obj)
    for m in methods(obj)
        file = String(m.file)
        if file != "<built-in>" && file != "none" && !startswith(file, ".")
            return abspath(file)
        end
    end
    return nothing
end
