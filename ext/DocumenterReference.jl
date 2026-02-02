#  Copyright 2023, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
#  Modified November 2025 for CTBenchmarks.jl:
#  - Separated public and private API documentation into distinct pages
#  - Added robust handling for missing docstrings (warnings instead of errors)
#  - Included non-exported symbols in API reference
#  - Filtered internal compiler-generated symbols (starting with '#')
#
#  Refactored December 2025:
#  - Extracted helper functions to reduce code duplication
#  - Improved documentation and code organization
#  - Added Dict-based DocType to string conversion

module DocumenterReference

using CTBase: CTBase
using Documenter: Documenter
using Markdown: Markdown
using MarkdownAST: MarkdownAST

# ═══════════════════════════════════════════════════════════════════════════════
# Types and Constants
# ═══════════════════════════════════════════════════════════════════════════════

"""
    DocType

Enumeration of documentation element types recognized by the API reference generator.

# Values

- `DOCTYPE_ABSTRACT_TYPE`: An abstract type declaration
- `DOCTYPE_CONSTANT`: A constant binding (including non-function, non-type values)
- `DOCTYPE_FUNCTION`: A function or callable
- `DOCTYPE_MACRO`: A macro (name starts with `@`)
- `DOCTYPE_MODULE`: A submodule
- `DOCTYPE_STRUCT`: A concrete struct type
"""
@enum(
    DocType,
    DOCTYPE_ABSTRACT_TYPE,
    DOCTYPE_CONSTANT,
    DOCTYPE_FUNCTION,
    DOCTYPE_MACRO,
    DOCTYPE_MODULE,
    DOCTYPE_STRUCT,
)

"""
    DOCTYPE_NAMES::Dict{DocType, String}

Mapping from DocType enum values to their human-readable string representations.
"""
const DOCTYPE_NAMES = Dict{DocType,String}(
    DOCTYPE_ABSTRACT_TYPE => "abstract type",
    DOCTYPE_CONSTANT => "constant",
    DOCTYPE_FUNCTION => "function",
    DOCTYPE_MACRO => "macro",
    DOCTYPE_MODULE => "module",
    DOCTYPE_STRUCT => "struct",
)

"""
    DOCTYPE_ORDER::Dict{DocType, Int}

Ordering for DocType values used when sorting symbols for display.
Lower values appear first.
"""
const DOCTYPE_ORDER = Dict{DocType,Int}(
    DOCTYPE_MODULE => 0,
    DOCTYPE_MACRO => 1,
    DOCTYPE_FUNCTION => 2,
    DOCTYPE_ABSTRACT_TYPE => 3,
    DOCTYPE_STRUCT => 4,
    DOCTYPE_CONSTANT => 5,
)

"""
    _Config

Internal configuration for API reference generation.

# Fields

- `current_module::Module`: The module being documented.
- `subdirectory::String`: Output directory for generated API pages.
- `modules::Dict{Module,Vector{String}}`: Mapping of modules to their source files.
  When a module is specified as `Module => files`, the files are stored here.
- `sort_by::Function`: Custom sort function for symbols.
- `exclude::Set{Symbol}`: Symbol names to exclude from documentation.
- `public::Bool`: Flag to generate public API page.
- `private::Bool`: Flag to generate private API page.
- `title::String`: Title displayed at the top of the generated page.
- `title_in_menu::String`: Title displayed in the navigation menu.
- `source_files::Vector{String}`: Global source file paths (fallback if no module-specific files).
- `filename::String`: Base filename (without extension) for the markdown file.
- `include_without_source::Bool`: If `true`, include symbols whose source file cannot be determined.
- `external_modules_to_document::Vector{Module}`: Additional modules to search for docstrings.
"""
struct _Config
    current_module::Module
    subdirectory::String
    modules::Dict{Module,Vector{String}}
    sort_by::Function
    exclude::Set{Symbol}
    public::Bool
    private::Bool
    title::String
    title_in_menu::String
    source_files::Vector{String}
    filename::String
    include_without_source::Bool
    external_modules_to_document::Vector{Module}
end

"""
    CONFIG::Vector{_Config}

Global configuration storage for API reference generation.

Each call to `CTBase.automatic_reference_documentation` appends a new `_Config`
entry to this vector. Use [`reset_config!`](@ref) to clear it between builds.
"""
const CONFIG = _Config[]

"""
    PAGE_CONTENT_ACCUMULATOR::Dict{String, Vector{Tuple{Module, Vector{String}, Vector{String}}}}

Global accumulator for multi-module combined pages.
Maps output filename to a list of (module, public_docstrings, private_docstrings) tuples.
"""
const PAGE_CONTENT_ACCUMULATOR = Dict{
    String,Vector{Tuple{Module,Vector{String},Vector{String}}}
}()

# ═══════════════════════════════════════════════════════════════════════════════
# Public API
# ═══════════════════════════════════════════════════════════════════════════════

"""
    reset_config!()

Clear the global `CONFIG` vector and `PAGE_CONTENT_ACCUMULATOR`.
Useful between documentation builds or for testing.
"""
function reset_config!()
    empty!(CONFIG)
    empty!(PAGE_CONTENT_ACCUMULATOR)
    return nothing
end

"""
    automatic_reference_documentation(;
        subdirectory::String,
        primary_modules,
        sort_by::Function = identity,
        exclude::Vector{Symbol} = Symbol[],
        public::Bool = true,
        private::Bool = true,
        title::String = "API Reference",
        title_in_menu::String = "",
        filename::String = "",
        source_files::Vector{String} = String[],
        include_without_source::Bool = false,
        external_modules_to_document::Vector{Module} = Module[],
    )

Automatically creates the API reference documentation for one or more modules and
returns a structure which can be used in the `pages` argument of `Documenter.makedocs`.

## Arguments

 * `subdirectory`: the directory relative to the documentation root in which to
   write the API files.
 * `primary_modules`: a vector of modules or `Module => source_files` pairs to document.
   When source files are provided, only symbols defined in those files are documented.
 * `sort_by`: a custom sort function applied to symbol lists.
 * `exclude`: vector of symbol names to skip from the generated API.
 * `public`: flag to generate public API page (default: `true`).
 * `private`: flag to generate private API page (default: `true`).
 * `title`: title displayed at the top of the generated page.
 * `title_in_menu`: title displayed in the navigation menu (default: same as `title`).
 * `filename`: base filename (without extension) for the markdown file.
 * `source_files`: global source file paths (fallback if no module-specific files).
   **Deprecated**: prefer using `primary_modules=[Module => files]` instead.
 * `include_without_source`: if `true`, include symbols whose source file cannot
   be determined. Default: `false`.
 * `external_modules_to_document`: additional modules to search for docstrings
   (e.g., `[Plots]` to include `Plots.plot` methods defined in your source files).

## Multiple instances

Each time you call this function, a new object is added to the global variable
`DocumenterReference.CONFIG`. Use `reset_config!()` to clear it between builds.
"""
function CTBase.automatic_reference_documentation(
    ::CTBase.Extensions.DocumenterReferenceTag;
    subdirectory::String,
    primary_modules::Vector,
    sort_by::Function=identity,
    exclude::Vector{Symbol}=Symbol[],
    public::Bool=true,
    private::Bool=true,
    title::String="API Reference",
    title_in_menu::String="",
    filename::String="",
    source_files::Vector{String}=String[],
    include_without_source::Bool=false,
    external_modules_to_document::Vector{Module}=Module[],
)
    # Validate arguments
    if !public && !private
        error(
            "automatic_reference_documentation: both `public` and `private` cannot be false.",
        )
    end

    # Parse primary_modules into a Dict{Module, Vector{String}}
    modules_dict = _parse_primary_modules(primary_modules)
    exclude_set = Set(exclude)
    normalized_source_files = _normalize_paths(source_files)
    effective_title_in_menu = isempty(title_in_menu) ? title : title_in_menu
    effective_filename = _default_basename(filename, public, private)

    # Single-module case
    if length(primary_modules) == 1
        current_module = first(keys(modules_dict))
        _register_config(
            current_module,
            subdirectory,
            modules_dict,
            sort_by,
            exclude_set,
            public,
            private,
            title,
            effective_title_in_menu,
            normalized_source_files,
            effective_filename,
            include_without_source,
            external_modules_to_document,
        )
        return _build_page_return_structure(
            effective_title_in_menu, subdirectory, effective_filename, public, private
        )
    end

    # Multi-module case with combined page (filename provided)
    if !isempty(filename)
        for mod in keys(modules_dict)
            _register_config(
                mod,
                subdirectory,
                modules_dict,
                sort_by,
                exclude_set,
                public,
                private,
                title,
                effective_title_in_menu,
                normalized_source_files,
                effective_filename,
                include_without_source,
                external_modules_to_document,
            )
        end
        return _build_page_return_structure(
            effective_title_in_menu, subdirectory, effective_filename, public, private
        )
    end

    # Multi-module case with per-module subdirectories
    list_of_pages = Any[]
    for mod in keys(modules_dict)
        module_subdir = joinpath(subdirectory, string(mod))
        module_filename = _default_basename("", public, private)
        default_title = _default_title(public, private)

        _register_config(
            mod,
            module_subdir,
            modules_dict,
            sort_by,
            exclude_set,
            public,
            private,
            default_title,
            default_title,
            normalized_source_files,
            module_filename,
            include_without_source,
            external_modules_to_document,
        )

        pages = _build_page_return_structure(
            default_title, module_subdir, module_filename, public, private
        )
        push!(list_of_pages, string(mod) => last(pages))
    end
    return effective_title_in_menu => list_of_pages
end

# ═══════════════════════════════════════════════════════════════════════════════
# Documenter Pipeline Integration
# ═══════════════════════════════════════════════════════════════════════════════

"""
    APIBuilder <: Documenter.Builder.DocumentPipeline

Custom Documenter pipeline stage for automatic API reference generation.

This builder is inserted into the Documenter pipeline at order `0.0` (before
most other stages) to generate API reference pages from the configurations
stored in [`CONFIG`](@ref).
"""
abstract type APIBuilder <: Documenter.Builder.DocumentPipeline end

"""
    Documenter.Selectors.order(::Type{APIBuilder}) -> Float64

Return the pipeline order for [`APIBuilder`](@ref).
# Run before SetupBuildDirectory (1.0) so that generated files exist when Documenter checks pages.
"""
Documenter.Selectors.order(::Type{APIBuilder}) = 0.5

function Documenter.Selectors.runner(::Type{APIBuilder}, document::Documenter.Document)
    @info "APIBuilder: creating API reference"
    for config in CONFIG
        _build_api_page(document, config)
    end
    _finalize_api_pages(document)
    return nothing
end

# ═══════════════════════════════════════════════════════════════════════════════
# Helper Functions: Configuration
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _parse_primary_modules(primary_modules::Vector) -> Dict{Module, Vector{String}}

Parse the `primary_modules` argument into a dictionary mapping modules to their source files.
Handles both plain modules and `Module => files` pairs.
"""
function _parse_primary_modules(primary_modules::Vector)
    result = Dict{Module,Vector{String}}()
    for m in primary_modules
        if m isa Module
            result[m] = String[]
        elseif m isa Pair
            mod = first(m)
            files = last(m)
            result[mod] = _normalize_paths(files isa Vector ? files : [files])
        else
            error(
                "Invalid element in primary_modules: expected Module or Module => files pair",
            )
        end
    end
    return result
end

"""
    _normalize_paths(paths) -> Vector{String}

Normalize a collection of paths to absolute paths.
"""
function _normalize_paths(paths)
    isempty(paths) ? String[] : [abspath(p) for p in paths]
end

"""
    _register_config(current_module, subdirectory, modules, sort_by, exclude, public, private, 
                     title, title_in_menu, source_files, filename, include_without_source, 
                     external_modules_to_document)

Create and register a `_Config` in the global `CONFIG` vector.
"""
function _register_config(
    current_module::Module,
    subdirectory::String,
    modules::Dict{Module,Vector{String}},
    sort_by::Function,
    exclude::Set{Symbol},
    public::Bool,
    private::Bool,
    title::String,
    title_in_menu::String,
    source_files::Vector{String},
    filename::String,
    include_without_source::Bool,
    external_modules_to_document::Vector{Module},
)
    push!(
        CONFIG,
        _Config(
            current_module,
            subdirectory,
            modules,
            sort_by,
            exclude,
            public,
            private,
            title,
            title_in_menu,
            source_files,
            filename,
            include_without_source,
            external_modules_to_document,
        ),
    )
    return nothing
end

"""
    _default_basename(filename::String, public::Bool, private::Bool) -> String

Compute the default base filename for the generated markdown file.
"""
function _default_basename(filename::String, public::Bool, private::Bool)
    !isempty(filename) && return filename
    public && private && return "api"
    public && return "public"
    return "private"
end

"""
    _default_title(public::Bool, private::Bool) -> String

Compute the default title based on public/private flags.
"""
function _default_title(public::Bool, private::Bool)
    public && !private && return "Public API"
    !public && private && return "Private API"
    return "API Reference"
end

"""
    _build_page_path(subdirectory::String, filename::String) -> String

Build the page path by joining subdirectory and filename.
Handles special cases where `subdirectory` is `"."` or empty.
"""
function _build_page_path(subdirectory::String, filename::String)
    (subdirectory == "." || isempty(subdirectory)) && return filename
    return "$subdirectory/$filename"
end

"""
    _build_page_return_structure(title_in_menu, subdirectory, filename, public, private) -> Pair

Build the return structure for `automatic_reference_documentation`.
"""
function _build_page_return_structure(
    title_in_menu::String,
    subdirectory::String,
    filename::String,
    public::Bool,
    private::Bool,
)
    if public && private
        pub = !isempty(filename) ? "$(filename)_public.md" : "public.md"
        priv = !isempty(filename) ? "$(filename)_private.md" : "private.md"
        return title_in_menu => [
            "Public" => _build_page_path(subdirectory, pub),
            "Private" => _build_page_path(subdirectory, priv),
        ]
    else
        return title_in_menu => _build_page_path(subdirectory, "$filename.md")
    end
end

"""
    _get_effective_source_files(config::_Config) -> Vector{String}

Determine the effective source files for filtering symbols.
Priority: module-specific files > global source_files > empty (no filtering).
"""
function _get_effective_source_files(config::_Config)
    module_files = get(config.modules, config.current_module, String[])
    !isempty(module_files) && return module_files
    !isempty(config.source_files) && return config.source_files
    return String[]
end

# ═══════════════════════════════════════════════════════════════════════════════
# Helper Functions: Symbol Classification
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _to_string(x::DocType) -> String

Convert a DocType enumeration value to its string representation.
"""
_to_string(x::DocType) = DOCTYPE_NAMES[x]

"""
    _classify_symbol(obj, name_str::String) -> DocType

Classify a symbol by its type (function, macro, struct, constant, module, abstract type).
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
    _exported_symbols(mod::Module) -> NamedTuple

Classify all symbols in a module into exported and private categories.
Returns a NamedTuple with `exported` and `private` fields, each containing
sorted lists of `(Symbol, DocType)` pairs.
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

# ═══════════════════════════════════════════════════════════════════════════════
# Helper Functions: Source File Detection
# ═══════════════════════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════════════════════
# Helper Functions: Symbol Iteration
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _iterate_over_symbols(f, config, symbol_list)

Iterate over symbols, applying a function to each documented symbol.
Filters symbols based on exclusion list, documentation presence, and source files.
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
    _has_documentation(mod::Module, key::Symbol, type::DocType, modules::Dict) -> Bool

Check if a symbol has documentation. Logs a warning if not.
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
    _passes_source_filter(mod, key, type, source_files, include_without_source) -> Bool

Check if a symbol passes the source file filter.
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

# ═══════════════════════════════════════════════════════════════════════════════
# Helper Functions: Type Formatting for @docs Blocks
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _method_signature_string(m::Method, mod::Module, key::Symbol) -> String

Generate a Documenter-compatible signature string for a method.
Returns a string like `Module.func(::Type1, ::Type2)` for use in `@docs` blocks.
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
    _format_type_for_docs(T) -> String

Format a type for use in Documenter's `@docs` block.
Always fully qualifies types to avoid UndefVarError when Documenter evaluates in Main.
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
    _format_datatype_for_docs(T::DataType) -> String

Format a DataType for use in @docs blocks.
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
    _format_type_param(p) -> String

Format a type parameter (can be a type or a value like an integer).
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

# ═══════════════════════════════════════════════════════════════════════════════
# Page Building Functions
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _build_api_page(document::Documenter.Document, config::_Config)

Generate public and/or private API reference pages for a module.
Accumulates content in `PAGE_CONTENT_ACCUMULATOR` for later finalization.
"""
function _build_api_page(document::Documenter.Document, config::_Config)
    current_module = config.current_module
    symbols = _exported_symbols(current_module)

    # Determine output filenames
    public_basename = if config.public && config.private
        (!isempty(config.filename) ? "$(config.filename)_public" : "public")
    else
        config.filename
    end
    private_basename = if config.public && config.private
        (!isempty(config.filename) ? "$(config.filename)_private" : "private")
    else
        config.filename
    end

    # Collect docstrings
    public_docstrings =
        config.public ? _collect_module_docstrings(config, symbols.exported) : String[]
    private_docstrings =
        config.private ? _collect_private_docstrings(config, symbols.private) : String[]

    # Accumulate content
    if config.public && config.private
        # Split mode: use two separate keys
        pub_filename = _build_page_path(config.subdirectory, "$(public_basename).md")
        priv_filename = _build_page_path(config.subdirectory, "$(private_basename).md")

        for (fname, docs) in
            [(pub_filename, public_docstrings), (priv_filename, private_docstrings)]
            if !haskey(PAGE_CONTENT_ACCUMULATOR, fname)
                PAGE_CONTENT_ACCUMULATOR[fname] = Tuple{
                    Module,Vector{String},Vector{String}
                }[]
            end
            # In split mode, the other docstrings list is intentionally empty for that file
            if fname == pub_filename
                push!(PAGE_CONTENT_ACCUMULATOR[fname], (current_module, docs, String[]))
            else
                push!(PAGE_CONTENT_ACCUMULATOR[fname], (current_module, String[], docs))
            end
        end
    else
        # Combined mode: use one key (either public or private)
        filename = _build_page_path(config.subdirectory, "$(config.filename).md")
        if !haskey(PAGE_CONTENT_ACCUMULATOR, filename)
            PAGE_CONTENT_ACCUMULATOR[filename] = Tuple{
                Module,Vector{String},Vector{String}
            }[]
        end
        push!(
            PAGE_CONTENT_ACCUMULATOR[filename],
            (current_module, public_docstrings, private_docstrings),
        )
    end

    return nothing
end

"""
    _collect_module_docstrings(config::_Config, symbol_list) -> Vector{String}

Collect docstring blocks for symbols from the current module.
"""
function _collect_module_docstrings(config::_Config, symbol_list)
    docstrings = String[]
    current_module = config.current_module

    _iterate_over_symbols(config, symbol_list) do key, type
        type == DOCTYPE_MODULE && return nothing
        push!(docstrings, "## `$key`\n\n```@docs\n$(current_module).$key\n```\n\n")
        return nothing
    end

    return docstrings
end

"""
    _collect_private_docstrings(config::_Config, symbol_list) -> Vector{String}

Collect docstring blocks for private symbols, including external module methods.
"""
function _collect_private_docstrings(config::_Config, symbol_list)
    docstrings = _collect_module_docstrings(config, symbol_list)

    # Add docstrings from external modules
    if !isempty(config.external_modules_to_document)
        external_docs = _collect_external_module_docstrings(config)
        append!(docstrings, external_docs)
    end

    return docstrings
end

"""
    _collect_external_module_docstrings(config::_Config) -> Vector{String}

Collect docstrings for methods from external modules defined in source files.
"""
function _collect_external_module_docstrings(config::_Config)
    docstrings = String[]
    added_signatures = Set{String}()
    filtered_source_files = _get_effective_source_files(config)

    for extra_mod in config.external_modules_to_document
        methods_by_func = _collect_methods_from_source_files(
            extra_mod, filtered_source_files
        )

        for (key, method_list) in sort(collect(methods_by_func); by=first)
            for m in method_list
                sig_str = _method_signature_string(m, extra_mod, key)
                sig_str in added_signatures && continue

                push!(added_signatures, sig_str)
                push!(docstrings, "## `$(extra_mod).$key`\n\n```@docs\n$(sig_str)\n```\n\n")
            end
        end
    end

    return docstrings
end

"""
    _collect_methods_from_source_files(mod::Module, source_files::Vector{String}) -> Dict{Symbol, Vector{Method}}

Collect all methods from a module that are defined in the given source files.
"""
function _collect_methods_from_source_files(mod::Module, source_files::Vector{String})
    methods_by_func = Dict{Symbol,Vector{Method}}()

    for key in names(mod; all=true)
        obj = try
            getfield(mod, key)
        catch
            continue
        end

        obj isa Function || continue

        for m in methods(obj)
            file = String(m.file)
            (file == "<built-in>" || file == "none") && continue

            abs_file = abspath(file)
            should_include = isempty(source_files) || (abs_file in source_files)

            if should_include
                if !haskey(methods_by_func, key)
                    methods_by_func[key] = Method[]
                end
                push!(methods_by_func[key], m)
            end
        end
    end

    return methods_by_func
end

"""
    _finalize_api_pages(document::Documenter.Document)

Finalize all accumulated API pages by combining content from multiple modules.
"""
function _finalize_api_pages(document::Documenter.Document)
    for (filename, module_contents) in PAGE_CONTENT_ACCUMULATOR
        is_private_split = occursin("private", filename)
        is_public_split = occursin("public", filename)

        all_modules = [mc[1] for mc in module_contents]
        modules_str = join([string(m) for m in all_modules], "`, `")

        overview, all_docstrings = if is_public_split
            # Case 1: Pure Public Split Page
            _build_public_page_content(modules_str, module_contents)
        elseif is_private_split
            # Case 2: Pure Private Split Page
            _build_private_page_content(modules_str, module_contents)
        else
            # Case 3: Combined Page (Public then Private)
            _build_combined_page_content(modules_str, module_contents)
        end

        combined_md = Markdown.parse(overview * join(all_docstrings, "\n"))

        # Write to source directory so SetupBuildDirectory can find and copy it
        source_path = joinpath(document.user.source, filename)
        mkpath(dirname(source_path))
        open(source_path, "w") do io
            write(io, overview)
            write(io, join(all_docstrings, "\n"))
        end

        document.blueprint.pages[filename] = Documenter.Page(
            source_path,
            joinpath(document.user.build, filename),
            document.user.build,
            combined_md.content,
            Documenter.Globals(),
            convert(MarkdownAST.Node, combined_md),
        )
    end

    empty!(PAGE_CONTENT_ACCUMULATOR)
    return nothing
end

"""
    _build_combined_page_content(modules_str, module_contents) -> Tuple{String, Vector{String}}

Build the overview and docstrings for a combined (Public + Private) API page.
"""
function _build_combined_page_content(modules_str::String, module_contents)
    overview = """
    # API reference

    This page lists documented symbols of `$(modules_str)`.

    """

    all_docstrings = String[]
    for (mod, public_docs, private_docs) in module_contents
        if !isempty(public_docs) || !isempty(private_docs)
            push!(all_docstrings, "\n---\n\n## From `$(mod)`\n\n")
            if !isempty(public_docs)
                push!(all_docstrings, "### Public API\n\n")
                append!(all_docstrings, public_docs)
            end
            if !isempty(private_docs)
                push!(all_docstrings, "\n### Private API\n\n")
                append!(all_docstrings, private_docs)
            end
        end
    end

    return overview, all_docstrings
end

"""
    _build_private_page_content(modules_str, module_contents) -> Tuple{String, Vector{String}}

Build the overview and docstrings for a private API page.
"""
function _build_private_page_content(modules_str::String, module_contents)
    overview = """
    ```@meta
    EditURL = nothing
    ```

    # Private API

    This page lists **non-exported** (internal) symbols of `$(modules_str)`.

    """

    all_docstrings = String[]
    for (mod, _, private_docs) in module_contents
        if !isempty(private_docs)
            push!(all_docstrings, "\n---\n\n### From `$(mod)`\n\n")
            append!(all_docstrings, private_docs)
        end
    end

    return overview, all_docstrings
end

"""
    _build_public_page_content(modules_str, module_contents) -> Tuple{String, Vector{String}}

Build the overview and docstrings for a public API page.
"""
function _build_public_page_content(modules_str::String, module_contents)
    overview = """
    # Public API

    This page lists **exported** symbols of `$(modules_str)`.

    """

    all_docstrings = String[]
    for (mod, public_docs, _) in module_contents
        if !isempty(public_docs)
            push!(all_docstrings, "\n---\n\n### From `$(mod)`\n\n")
            append!(all_docstrings, public_docs)
        end
    end

    return overview, all_docstrings
end

end  # module
