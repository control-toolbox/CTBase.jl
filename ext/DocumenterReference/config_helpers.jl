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
    _normalize_paths(paths) -> Vector{String}

Normalize a collection of paths to absolute paths.
"""
function _normalize_paths(paths)
    return isempty(paths) ? String[] : [abspath(p) for p in paths]
end

"""
    _register_config(current_module, subdirectory, modules, sort_by, exclude, public, private, 
                     title, title_in_menu, source_files, filename, include_without_source, 
                     external_modules_to_document, public_title, private_title, 
                     public_description, private_description)

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
Returns empty string for single pages to use configured title.
"""
function _default_title(public::Bool, private::Bool)
    public && private && return "API Reference"  # Combined page
    return ""  # Single page - use configured title
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
