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

module DocumenterReference

using CTBase: CTBase
using Documenter: Documenter
using Markdown: Markdown
using MarkdownAST: MarkdownAST

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
    _Config

Internal configuration for API reference generation.

# Fields

- `current_module::Module`: The module being documented.
- `subdirectory::String`: Output directory for generated API pages.
- `modules::Dict{Module,<:Vector}`: Mapping of modules to extras (reserved for future use).
- `sort_by::Function`: Custom sort function for symbols.
- `exclude::Set{Symbol}`: Symbol names to exclude from documentation.
- `public::Bool`: Flag to generate public API page.
- `private::Bool`: Flag to generate private API page.
- `title::String`: Title displayed at the top of the generated page.
- `title_in_menu::String`: Title displayed in the navigation menu.
- `source_files::Vector{String}`: Absolute source file paths used to filter documented symbols (empty means no filtering).
- `filename::String`: Base filename (without extension) for the markdown file.
- `include_without_source::Bool`: If `true`, include symbols whose source file cannot be determined.
- `doc_modules::Vector{Module}`: Additional modules to search for docstrings (e.g., `Base`).
"""
struct _Config
    current_module::Module
    subdirectory::String
    modules::Dict{Module,<:Vector}
    sort_by::Function
    exclude::Set{Symbol}
    public::Bool
    private::Bool
    title::String
    title_in_menu::String
    source_files::Vector{String}
    filename::String
    include_without_source::Bool  # Include symbols whose source file cannot be determined
    doc_modules::Vector{Module}   # Additional modules to search for docstrings (e.g., Base)
end

"""
    CONFIG::Vector{_Config}

Global configuration storage for API reference generation.

Each call to [`automatic_reference_documentation`](@ref) appends a new `_Config`
entry to this vector. Use [`reset_config!`](@ref) to clear it between builds.
"""
const CONFIG = _Config[]

"""
    reset_config!()

Clear the global `CONFIG` vector. Useful between documentation builds or for testing.
"""
function reset_config!()
    empty!(CONFIG)
    return nothing
end

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

# Returns

- `Float64`: Always `0.0`, placing this stage early in the Documenter pipeline.
"""
Documenter.Selectors.order(::Type{APIBuilder}) = 0.0

"""
    _default_basename(filename::String, public::Bool, private::Bool) -> String

Compute the default base filename for the generated markdown file.

# Logic
- If `filename` is non-empty, use it.
- If only `public` is true, use `"public"`.
- If only `private` is true, use `"private"`.
- If both are true, use `"api"`.

# Arguments
- `filename::String`: User-provided filename (may be empty)
- `public::Bool`: Whether public API is requested
- `private::Bool`: Whether private API is requested

# Returns
- `String`: The base filename to use (without extension)
"""
function _default_basename(filename::String, public::Bool, private::Bool)
    if filename != ""
        return filename
    elseif public && private
        return "api"
    elseif public
        return "public"
    else
        return "private"
    end
end

"""
    _build_page_path(subdirectory::String, filename::String) -> String

Build the page path by joining subdirectory and filename.

Handles special cases where `subdirectory` is `"."` or empty, returning just
the filename in those cases.

# Arguments

- `subdirectory::String`: Directory path (may be `"."` or empty).
- `filename::String`: The filename to append.

# Returns

- `String`: The combined path, or just `filename` if subdirectory is `"."` or empty.
"""
function _build_page_path(subdirectory::String, filename::String)
    if subdirectory == "." || subdirectory == ""
        return filename
    else
        return "$subdirectory/$filename"
    end
end

"""
    automatic_reference_documentation(;
        subdirectory::String,
        modules,
        sort_by::Function = identity,
        exclude::Vector{Symbol} = Symbol[],
        public::Bool = true,
        private::Bool = true,
        title::String = "API Reference",
        filename::String = "",
        source_files::Vector{String} = String[],
        include_without_source::Bool = false,
        doc_modules::Vector{Module} = Module[],
    )

Automatically creates the API reference documentation for one or more modules and
returns a `Vector` which can be used in the `pages` argument of
`Documenter.makedocs`.

## Arguments

 * `subdirectory`: the directory relative to the documentation root in which to
   write the API files.
 * `modules`: a vector of modules or `module => extras` pairs. Extras are
   currently unused but reserved for future extensions.
 * `sort_by`: a custom sort function applied to symbol lists.
 * `exclude`: vector of symbol names to skip from the generated API (applied to
   both public and private symbols).
 * `public`: flag to generate public API page (default: `true`).
 * `private`: flag to generate private API page (default: `true`).
 * `title`: title displayed at the top of the generated page (default: "API Reference").
 * `title_in_menu`: title displayed in the navigation menu (default: same as `title`).
 * `filename`: base filename (without extension) used for the underlying markdown
   file. Defaults: `"public"` if only public, `"private"` if only private,
   `"api"` if both.
 * `source_files`: source file paths to filter documented symbols. Only symbols
   defined in these files will be included. Paths are normalized to absolute.
 * `include_without_source`: if `true`, include symbols whose source file cannot
   be determined (e.g., abstract types, some constants). Default: `false`.
 * `doc_modules`: additional modules to search for docstrings (e.g., `[Base]` to
   include `Base.showerror` documentation). Default: empty.

## Multiple instances

Each time you call this function, a new object is added to the global variable
`DocumenterReference.CONFIG`. Use `reset_config!()` to clear it between builds.
"""
function CTBase.automatic_reference_documentation(
    ::CTBase.DocumenterReferenceTag;
    subdirectory::String,
    modules::Vector,
    sort_by::Function=identity,
    exclude::Vector{Symbol}=Symbol[],
    public::Bool=true,
    private::Bool=true,
    title::String="API Reference",
    title_in_menu::String="",
    filename::String="",
    source_files::Vector{String}=String[],
    include_without_source::Bool=false,
    doc_modules::Vector{Module}=Module[],
)
    _to_extras(m::Module) = m => Any[]
    _to_extras(m::Pair) = m
    _modules = Dict(_to_extras(m) for m in modules)
    exclude_set = Set(exclude)
    normalized_source_files =
        isempty(source_files) ? String[] : [abspath(path) for path in source_files]

    if !public && !private
        error(
            "automatic_reference_documentation: both `public` and `private` cannot be false.",
        )
    end

    # Effective title_in_menu defaults to title if not provided
    effective_title_in_menu = title_in_menu == "" ? title : title_in_menu

    # For single-module case, return structure directly based on public/private flags
    if length(modules) == 1
        current_module = first(_to_extras(modules[1]))
        # Compute effective filename using defaults
        effective_filename = _default_basename(filename, public, private)
        push!(
            CONFIG,
            _Config(
                current_module,
                subdirectory,
                _modules,
                sort_by,
                exclude_set,
                public,
                private,
                title,
                effective_title_in_menu,
                normalized_source_files,
                effective_filename,
                include_without_source,
                doc_modules,
            ),
        )
        if public && private
            # Both pages: use subdirectory with public.md and private.md
            return effective_title_in_menu => [
                "Public" => _build_page_path(subdirectory, "public.md"),
                "Private" => _build_page_path(subdirectory, "private.md"),
            ]
        elseif public
            return effective_title_in_menu =>
                _build_page_path(subdirectory, "$effective_filename.md")
        else
            return effective_title_in_menu =>
                _build_page_path(subdirectory, "$effective_filename.md")
        end
    end

    # For multi-module case, create a per-module subdirectory
    list_of_pages = Any[]
    for m in modules
        current_module = first(_to_extras(m))
        module_subdir = joinpath(subdirectory, string(current_module))
        pages = _automatic_reference_documentation(
            current_module;
            subdirectory=module_subdir,
            modules=_modules,
            sort_by,
            exclude=exclude_set,
            public,
            private,
            source_files=normalized_source_files,
            include_without_source,
            doc_modules,
        )
        push!(list_of_pages, "$current_module" => pages)
    end
    return effective_title_in_menu => list_of_pages
end

"""
    _automatic_reference_documentation(current_module; subdirectory, modules, sort_by, exclude)

Internal helper for single-module API reference generation.

Registers the module configuration and returns the output path for the generated documentation.

# Arguments
- `current_module::Module`: Module to document
- `subdirectory::String`: Output directory for API pages
- `modules::Dict{Module,<:Vector}`: Module mapping
- `sort_by::Function`: Custom sort function
- `exclude::Set{Symbol}`: Symbols to exclude
- `public::Bool`: Flag to generate public API page
- `private::Bool`: Flag to generate private API page
- `source_files::Vector{String}`: Absolute source file paths used to filter documented symbols (empty means no filtering)

# Returns
- `String`: Path to the generated API documentation file
"""
function _automatic_reference_documentation(
    current_module::Module;
    subdirectory::String,
    modules::Dict{Module,<:Vector},
    sort_by::Function,
    exclude::Set{Symbol},
    public::Bool,
    private::Bool,
    source_files::Vector{String},
    include_without_source::Bool=false,
    doc_modules::Vector{Module}=Module[],
)
    effective_filename = _default_basename("", public, private)
    # For multi-module case, use default titles
    default_title = if public && !private
        "Public API"
    else
        (!public && private ? "Private API" : "API Reference")
    end
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
            default_title,
            default_title,
            source_files,
            effective_filename,
            include_without_source,
            doc_modules,
        ),
    )
    if public && private
        return [
            "Public" => _build_page_path(subdirectory, "public.md"),
            "Private" => _build_page_path(subdirectory, "private.md"),
        ]
    elseif public
        return _build_page_path(subdirectory, "$effective_filename.md")
    else
        return _build_page_path(subdirectory, "$effective_filename.md")
    end
end

"""
    _classify_symbol(obj, name_str::String) -> DocType

Classify a symbol by its type (function, macro, struct, constant, module, abstract type).

# Arguments
- `obj`: The object bound to the symbol
- `name_str::String`: String representation of the symbol name

# Returns
- `DocType`: The classification of the symbol
"""
function _classify_symbol(obj, name_str::String)
    # Check for macro (name starts with @)
    if startswith(name_str, "@")
        return DOCTYPE_MACRO
    end
    # Check for module
    if obj isa Module
        return DOCTYPE_MODULE
    end
    # Check for abstract type
    if obj isa Type && isabstracttype(obj)
        return DOCTYPE_ABSTRACT_TYPE
    end
    # Check for concrete type / struct
    if obj isa Type
        return DOCTYPE_STRUCT
    end
    # Check for function
    if obj isa Function
        return DOCTYPE_FUNCTION
    end
    # Everything else is a constant
    return DOCTYPE_CONSTANT
end

"""
    _get_source_file(mod::Module, key::Symbol, type::DocType) -> Union{String, Nothing}

Determine the source file path where a symbol is defined.

Supports functions, types (via constructors), macros, and constants.
Returns `nothing` if the source file cannot be determined.

# Arguments
- `mod::Module`: The module containing the symbol
- `key::Symbol`: The symbol name
- `type::DocType`: The type classification of the symbol

# Returns
- `Union{String, Nothing}`: Absolute path to the source file, or `nothing`
"""
function _get_source_file(mod::Module, key::Symbol, type::DocType)
    try
        # Strategy 1 (most reliable): Try docstring metadata
        # This works for all documented symbols (constants, types, functions, etc.)
        binding = Base.Docs.Binding(mod, key)
        meta = Base.Docs.meta(mod)
        if haskey(meta, binding)
            docs = meta[binding]
            if isa(docs, Base.Docs.MultiDoc) && !isempty(docs.docs)
                for (sig, docstr) in docs.docs
                    if isa(docstr, Base.Docs.DocStr) && haskey(docstr.data, :path)
                        path = docstr.data[:path]
                        if path !== nothing && path != ""
                            return abspath(String(path))
                        end
                    end
                end
            end
        end

        obj = getfield(mod, key)

        # Strategy 2: For functions and macros, use methods()
        if obj isa Function
            m_list = methods(obj)
            for m in m_list
                file = String(m.file)
                if file != "<built-in>" && file != "none" && !startswith(file, ".")
                    return abspath(file)
                end
            end
        end

        # Strategy 3: For concrete types, try constructor methods
        if obj isa Type && !isabstracttype(obj)
            m_list = methods(obj)
            for m in m_list
                file = String(m.file)
                if file != "<built-in>" && file != "none" && !startswith(file, ".")
                    return abspath(file)
                end
            end
        end

        # Strategy 4: For modules
        if obj isa Module
            # Modules are tricky - we cannot reliably determine their source file
            return nothing
        end

        return nothing
    catch e
        @debug "Could not determine source file for $key in $mod: $e"
        return nothing
    end
end

"""
    _exported_symbols(mod)

Classify all symbols in a module into exported and private categories.

Inspects the module's public API and internal symbols, filtering out compiler-generated
names and imported symbols. Classifies each symbol by type (function, struct, macro, etc.).

# Arguments
- `mod::Module`: Module to analyze

# Returns
- `NamedTuple`: With fields `exported` and `private`, each containing sorted lists of `(Symbol, DocType)` pairs
"""
function _exported_symbols(mod)
    exported = Pair{Symbol,DocType}[]
    private = Pair{Symbol,DocType}[]
    exported_names = Set(names(mod; all=false))  # Only exported symbols

    # Use all=true, imported=false to include non-exported (private) symbols
    # defined in this module, but skip names imported from other modules.
    for n in names(mod; all=true, imported=false)
        name_str = String(n)
        # Skip internal compiler-generated symbols like #save_json##... which
        # do not have meaningful bindings for documentation.
        if startswith(name_str, "#")
            continue
        end
        # Skip the module itself
        if n == nameof(mod)
            continue
        end

        local f
        try
            f = getfield(mod, n)
        catch
            continue
        end

        doc_type = _classify_symbol(f, name_str)

        # Separate exported from private
        if n in exported_names
            push!(exported, n => doc_type)
        else
            push!(private, n => doc_type)
        end
    end

    order = Dict(
        DOCTYPE_MODULE => 0,
        DOCTYPE_MACRO => 1,
        DOCTYPE_FUNCTION => 2,
        DOCTYPE_ABSTRACT_TYPE => 3,
        DOCTYPE_STRUCT => 4,
        DOCTYPE_CONSTANT => 5,
    )
    sort_fn = x -> (order[x[2]], "$(x[1])")
    return (exported=sort(exported; by=sort_fn), private=sort(private; by=sort_fn))
end

"""
    _iterate_over_symbols(f, config, symbol_list)

Iterate over symbols, applying a function to each documented symbol.

Filters symbols based on:
1. Exclusion list (`config.exclude`)
2. Presence of documentation (warns and skips undocumented symbols)
3. Source file filtering (`config.source_files`)

# Arguments

- `f::Function`: Callback function `f(key::Symbol, type::DocType)` applied to each valid symbol.
- `config::_Config`: Configuration containing exclusion rules, module info, and source file filters.
- `symbol_list::Vector{Pair{Symbol,DocType}}`: List of symbol-type pairs to process.

# Returns

- `nothing`
"""
function _iterate_over_symbols(f, config, symbol_list)
    current_module = config.current_module
    for (key, type) in sort!(symbol_list; by=config.sort_by)
        if key isa Symbol
            if key in config.exclude
                continue
            end
            binding = Base.Docs.Binding(current_module, key)
            missing_doc = false
            if isdefined(Base.Docs, :hasdoc)
                missing_doc = !Base.Docs.hasdoc(binding)
            else
                doc = Base.Docs.doc(binding)
                missing_doc =
                    doc === nothing || occursin("No documentation found.", string(doc))
            end
            if missing_doc
                if type == DOCTYPE_MODULE
                    mod = getfield(current_module, key)
                    if mod == current_module || !haskey(config.modules, mod)
                        @warn "No documentation found for module $key in $(current_module). Skipping from API reference."
                        continue
                    end
                else
                    @warn "No documentation found for $key in $(current_module). Skipping from API reference."
                    continue
                end
            end
            if !isempty(config.source_files)
                source_path = _get_source_file(current_module, key, type)
                if source_path === nothing
                    # If we can't determine source, include only if include_without_source is true
                    if !config.include_without_source
                        @debug "Cannot determine source file for $key ($(type)), skipping."
                        continue
                    end
                else
                    # Check if source_path matches any allowed file
                    keep = any(allowed -> source_path == allowed, config.source_files)
                    if !keep
                        continue
                    end
                end
            end
        end
        f(key, type)
    end
    return nothing
end

"""
    _to_string(x::DocType)

Convert a DocType enumeration value to its string representation.

# Arguments
- `x::DocType`: Documentation type to convert

# Returns
- `String`: Human-readable name (e.g., "function", "struct", "macro")
"""
function _to_string(x::DocType)
    if x == DOCTYPE_ABSTRACT_TYPE
        return "abstract type"
    elseif x == DOCTYPE_CONSTANT
        return "constant"
    elseif x == DOCTYPE_FUNCTION
        return "function"
    elseif x == DOCTYPE_MACRO
        return "macro"
    elseif x == DOCTYPE_MODULE
        return "module"
    elseif x == DOCTYPE_STRUCT
        return "struct"
    end
end

"""
    _build_api_page(document::Documenter.Document, config::_Config)

Generate public and/or private API reference pages for a module.

Creates markdown pages listing symbols with their docstrings. When both
`config.public` and `config.private` are `true`, two separate pages are
generated (`public.md` and `private.md`). Otherwise, a single page is created
using `config.filename`.

# Arguments

- `document::Documenter.Document`: The Documenter document object to add pages to.
- `config::_Config`: Configuration specifying the module, output paths, and filtering options.

# Returns

- `nothing`
"""
function _build_api_page(document::Documenter.Document, config::_Config)
    subdir = config.subdirectory
    current_module = config.current_module
    symbols = _exported_symbols(current_module)

    # Determine the page title: use config.title for single-page cases,
    # otherwise use default "Public API" / "Private API" for dual-page cases.
    page_title = config.title

    # Build Public API page
    public_title = config.public && config.private ? "Public API" : page_title
    public_overview = """
    # $(public_title)

    This page lists **exported** symbols of `$(current_module)`.

    Load all public symbols into the current scope with:
    ```julia
    using $(current_module)
    ```
    Alternatively, load only the module with:
    ```julia
    import $(current_module)
    ```
    and then prefix all calls with `$(current_module).` to create
    `$(current_module).<NAME>`.
    """
    if config.public
        # Choose output filename: when both public & private are requested we
        # keep `public.md`; otherwise, use the configured `filename` (already
        # computed with defaults in automatic_reference_documentation).
        public_basename = config.public && config.private ? "public" : config.filename
        public_docstrings = String[]
        _iterate_over_symbols(config, symbols.exported) do key, type
            if type == DOCTYPE_MODULE
                return nothing
            end
            push!(
                public_docstrings, "## `$key`\n\n```@docs\n$(current_module).$key\n```\n\n"
            )
            return nothing
        end
        public_md = Markdown.parse(public_overview * join(public_docstrings, "\n"))
        public_filename = _build_page_path(subdir, "$public_basename.md")
        document.blueprint.pages[public_filename] = Documenter.Page(
            joinpath(document.user.source, public_filename),
            joinpath(document.user.build, public_filename),
            document.user.build,
            public_md.content,
            Documenter.Globals(),
            convert(MarkdownAST.Node, public_md),
        )
    end

    # Build Private API page
    private_title = config.public && config.private ? "Private API" : page_title
    private_overview = """
    ```@meta
    EditURL = nothing
    ```

    # $(private_title)

    This page lists **non-exported** (internal) symbols of `$(current_module)`.

    Access these symbols with:
    ```julia
    import $(current_module)
    $(current_module).<NAME>
    ```
    """
    if config.private
        # Choose output filename: when both public & private are requested we
        # keep `private.md`; otherwise, use the configured `filename` (already
        # computed with defaults in automatic_reference_documentation).
        private_basename = config.public && config.private ? "private" : config.filename
        private_docstrings = String[]
        _iterate_over_symbols(config, symbols.private) do key, type
            if type == DOCTYPE_MODULE
                return nothing
            end
            push!(
                private_docstrings, "## `$key`\n\n```@docs\n$(current_module).$key\n```\n\n"
            )
            return nothing
        end
        # Add docstrings from additional modules (e.g., Base.showerror)
        # For each extra module, find functions that have methods defined in source_files
        for extra_mod in config.doc_modules
            found_symbols = Set{Symbol}()
            for key in names(extra_mod; all=true)
                key in found_symbols && continue
                try
                    obj = getfield(extra_mod, key)
                    if obj isa Function
                        # Check if any method of this function is defined in source_files
                        for m in methods(obj)
                            file = String(m.file)
                            if file != "<built-in>" && file != "none"
                                abs_file = abspath(file)
                                if abs_file in config.source_files
                                    push!(found_symbols, key)
                                    push!(
                                        private_docstrings,
                                        "## `$(extra_mod).$key`\n\n```@docs\n$(extra_mod).$key\n```\n\n",
                                    )
                                    break
                                end
                            end
                        end
                    end
                catch
                    continue
                end
            end
        end
        private_md = Markdown.parse(private_overview * join(private_docstrings, "\n"))
        private_filename = _build_page_path(subdir, "$private_basename.md")
        document.blueprint.pages[private_filename] = Documenter.Page(
            joinpath(document.user.source, private_filename),
            joinpath(document.user.build, private_filename),
            document.user.build,
            private_md.content,
            Documenter.Globals(),
            convert(MarkdownAST.Node, private_md),
        )
    end

    return nothing
end

"""
    Documenter.Selectors.runner(::Type{APIBuilder}, document)

Documenter pipeline runner for API reference generation.

Processes all registered module configurations and generates their API reference pages.
This function is called automatically by Documenter during the documentation build.

# Arguments
- `document::Documenter.Document`: Documenter document object
"""
function Documenter.Selectors.runner(::Type{APIBuilder}, document::Documenter.Document)
    @info "APIBuilder: creating API reference"
    for config in CONFIG
        _build_api_page(document, config)
    end
    return nothing
end

end  # module
