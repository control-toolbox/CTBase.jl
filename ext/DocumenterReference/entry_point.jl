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
        public_title::String = "",
        private_title::String = "",
        public_description::String = "",
        private_description::String = "",
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
 * `public_title`: custom title for public API page. Empty string uses default ("Public API" or "Public").
 * `private_title`: custom title for private API page. Empty string uses default ("Private API" or "Private").
 * `public_description`: custom description text for public API page. Empty string uses default.
 * `private_description`: custom description text for private API page. Empty string uses default.

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
    public_title::String="",
    private_title::String="",
    public_description::String="",
    private_description::String="",
)
    # Validate arguments
    if !public && !private
        throw(
            CTBase.Exceptions.IncorrectArgument(
                "both `public` and `private` cannot be false";
                context="automatic_reference_documentation",
            ),
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
            public_title,
            private_title,
            public_description,
            private_description,
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
                public_title,
                private_title,
                public_description,
                private_description,
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
            public_title,
            private_title,
            public_description,
            private_description,
        )

        pages = _build_page_return_structure(
            default_title, module_subdir, module_filename, public, private
        )
        push!(list_of_pages, string(mod) => last(pages))
    end
    return effective_title_in_menu => list_of_pages
end
