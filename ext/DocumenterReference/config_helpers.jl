"""
    $(TYPEDSIGNATURES)

Parse the `primary_modules` argument into a dictionary mapping modules to their source files.
Handles both plain modules and `Module => files` pairs.

# Arguments
- `primary_modules::Vector`: vector of modules or `Module => files` pairs.

# Returns
- `Dict{Module, Vector{String}}`: dictionary mapping each module to its source file paths.

# Throws
- `CTBase.Exceptions.IncorrectArgument`: if an element is neither a `Module` nor a `Pair`.
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
            throw(
                CTBase.Exceptions.IncorrectArgument(
                    "Invalid element in primary_modules: expected Module or Module => files pair";
                    got=string(typeof(m)),
                    context="_parse_primary_modules",
                ),
            )
        end
    end
    return result
end

"""
    $(TYPEDSIGNATURES)

Normalize a collection of paths to absolute paths.

# Arguments
- `paths`: collection of file paths to normalize.

# Returns
- `Vector{String}`: vector of absolute paths, or empty vector if input is empty.
"""
function _normalize_paths(paths)
    return isempty(paths) ? String[] : [abspath(p) for p in paths]
end

"""
    $(TYPEDSIGNATURES)

Create and register a `_Config` in the global `CONFIG` vector.

# Arguments
- `current_module::Module`: the module being documented.
- `subdirectory::String`: output subdirectory for generated documentation.
- `modules::Dict{Module,Vector{String}}`: mapping of modules to their source files.
- `sort_by::Function`: sorting function for symbols.
- `exclude::Set{Symbol}`: symbols to exclude from documentation.
- `public::Bool`: whether to document public API.
- `private::Bool`: whether to document private API.
- `title::String`: page title.
- `title_in_menu::String`: title displayed in navigation menu.
- `source_files::Vector{String}`: global source files for filtering.
- `filename::String`: base filename for generated markdown.
- `include_without_source::Bool`: whether to include symbols without source location.
- `external_modules_to_document::Vector{Module}`: external modules to document.
- `public_title::String`: title for public API section.
- `private_title::String`: title for private API section.
- `public_description::String`: description for public API section.
- `private_description::String`: description for private API section.

# Returns
- `Nothing`.
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
    public_title::String,
    private_title::String,
    public_description::String,
    private_description::String,
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
            public_title,
            private_title,
            public_description,
            private_description,
        ),
    )
    return nothing
end

"""
    $(TYPEDSIGNATURES)

Compute the default base filename for the generated markdown file.

# Arguments
- `filename::String`: user-provided filename (empty to use default).
- `public::Bool`: whether documenting public API.
- `private::Bool`: whether documenting private API.

# Returns
- `String`: base filename for the generated markdown file.

"""
function _default_basename(filename::String, public::Bool, private::Bool)
    !isempty(filename) && return filename
    public && private && return "api"
    public && return "public"
    return "private"
end

"""
    $(TYPEDSIGNATURES)

Compute the default title based on public/private flags.
Returns empty string for single pages to use configured title.

# Arguments
- `public::Bool`: whether documenting public API.
- `private::Bool`: whether documenting private API.

# Returns
- `String`: default title, or empty string to use configured title.

"""
function _default_title(public::Bool, private::Bool)
    public && private && return "API Reference"  # Combined page
    return ""  # Single page - use configured title
end

"""
    $(TYPEDSIGNATURES)

Build the page path by joining subdirectory and filename.
Handles special cases where `subdirectory` is `"."` or empty.

# Arguments
- `subdirectory::String`: output subdirectory ("." or empty for current directory).
- `filename::String`: markdown filename.

# Returns
- `String`: complete page path.

"""
function _build_page_path(subdirectory::String, filename::String)
    (subdirectory == "." || isempty(subdirectory)) && return filename
    return "$subdirectory/$filename"
end

"""
    $(TYPEDSIGNATURES)

Build the return structure for `automatic_reference_documentation`.

# Arguments
- `title_in_menu::String`: title displayed in navigation menu.
- `subdirectory::String`: output subdirectory.
- `filename::String`: base filename for generated markdown.
- `public::Bool`: whether documenting public API.
- `private::Bool`: whether documenting private API.

# Returns
- `Pair`: structure suitable for `automatic_reference_documentation`, either a single page or nested public/private pages.

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
    $(TYPEDSIGNATURES)

Determine the effective source files for filtering symbols.
Priority: module-specific files > global source_files > empty (no filtering).

# Arguments
- `config::_Config`: configuration object.

# Returns
- `Vector{String}`: effective source files for the current module.

"""
function _get_effective_source_files(config::_Config)
    module_files = get(config.modules, config.current_module, String[])
    !isempty(module_files) && return module_files
    !isempty(config.source_files) && return config.source_files
    return String[]
end
