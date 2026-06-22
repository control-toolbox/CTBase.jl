"""
    $(TYPEDSIGNATURES)

Iterate over symbols, applying a function to each documented symbol.
Filters symbols based on exclusion list, documentation presence, and source files.

# Arguments
- `f`: function to apply to each symbol, receives `(key::Symbol, type::DocType)`.
- `config::_Config`: configuration for documentation generation.
- `symbol_list`: list of symbols to iterate over.

# Returns
- `Nothing`.

"""
function _iterate_over_symbols(f, config::_Config, symbol_list)
    current_module = config.current_module
    effective_source_files = _get_effective_source_files(config)

    for (key, type) in sort!(copy(symbol_list); by=config.sort_by)
        key isa Symbol || continue

        # Check exclusion
        key in config.exclude && continue

        # Check documentation
        if !_has_documentation(current_module, key, type, config.modules)
            continue
        end

        # Check source file filtering
        if !_passes_source_filter(
            current_module, key, type, effective_source_files, config.include_without_source
        )
            continue
        end

        f(key, type)
    end
    return nothing
end

"""
    $(TYPEDSIGNATURES)

Check if a symbol has documentation. Logs a warning if not.

# Arguments
- `mod::Module`: the module containing the symbol.
- `key::Symbol`: the symbol name.
- `type::DocType`: the type of the symbol.
- `modules::Dict`: mapping of modules to their source files.

# Returns
- `Bool`: `true` if the symbol has documentation, `false` otherwise.

"""
function _has_documentation(mod::Module, key::Symbol, type::DocType, modules::Dict)
    binding = Base.Docs.Binding(mod, key)

    has_doc = if isdefined(Base.Docs, :hasdoc)
        Base.Docs.hasdoc(binding)
    else
        doc = Base.Docs.doc(binding)
        doc !== nothing && !occursin("No documentation found.", string(doc))
    end

    if !has_doc
        if type == DOCTYPE_MODULE
            submod = getfield(mod, key)
            if submod != mod && haskey(modules, submod)
                return true  # Module is documented elsewhere
            end
        end
        @warn "No documentation found for $key in $mod. Skipping from API reference."
        return false
    end
    return true
end

"""
    $(TYPEDSIGNATURES)

Check if a symbol passes the source file filter.

# Arguments
- `mod::Module`: the module containing the symbol.
- `key::Symbol`: the symbol name.
- `type::DocType`: the type of the symbol.
- `source_files::Vector{String}`: source file paths to filter by.
- `include_without_source::Bool`: whether to include symbols without source location.

# Returns
- `Bool`: `true` if the symbol passes the filter, `false` otherwise.

"""
function _passes_source_filter(
    mod::Module,
    key::Symbol,
    type::DocType,
    source_files::Vector{String},
    include_without_source::Bool,
)
    isempty(source_files) && return true

    source_path = _get_source_file(mod, key, type)
    if source_path === nothing
        if !include_without_source
            @debug "Cannot determine source file for $key ($type), skipping."
            return false
        end
        return true
    end

    return source_path in source_files
end
