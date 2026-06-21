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
function _collect_module_docstrings(config::_Config, symbol_list; include_module::Bool=true)
    docstrings = String[]
    current_module = config.current_module
    effective_source_files = _get_effective_source_files(config)

    # Include the module docstring itself (if present and not filtered out)
    if include_module &&
        _has_documentation(
            current_module, nameof(current_module), DOCTYPE_MODULE, config.modules
        ) &&
        _passes_source_filter(
            current_module,
            nameof(current_module),
            DOCTYPE_MODULE,
            effective_source_files,
            config.include_without_source,
        )
        push!(docstrings, "### `$(current_module)`\n\n```@docs\n$(current_module)\n```\n\n")
    end

    _iterate_over_symbols(config, symbol_list) do key, type
        type == DOCTYPE_MODULE && return nothing
        push!(docstrings, "### `$key`\n\n```@docs\n$(current_module).$key\n```\n\n")
        return nothing
    end

    return docstrings
end

"""
    _collect_private_docstrings(config::_Config, symbol_list) -> Vector{String}

Collect docstring blocks for private symbols, including external module methods.
"""
function _collect_private_docstrings(config::_Config, symbol_list)
    docstrings = _collect_module_docstrings(config, symbol_list; include_module=false)

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
        is_private_split = occursin("_private", filename)
        is_public_split = occursin("_public", filename)

        # Detect if this is a split page by checking if both public and private files exist
        # Extract base filename by removing _public.md or _private.md suffixes
        base_filename = replace(replace(filename, "_public.md" => ""), "_private.md" => "")

        # Check if the counterpart file exists (if we have _public, check for _private and vice versa)
        is_split = if is_public_split
            haskey(PAGE_CONTENT_ACCUMULATOR, "$(base_filename)_private.md")
        elseif is_private_split
            haskey(PAGE_CONTENT_ACCUMULATOR, "$(base_filename)_public.md")
        else
            false  # Not a split page at all
        end

        all_modules = [mc[1] for mc in module_contents]
        modules_str = join([string(m) for m in all_modules], "`, `")

        # Get custom titles and descriptions from the first module's config
        # (assuming all modules in the same page share the same customization)
        first_module = first(all_modules)
        config = findfirst(c -> c.current_module === first_module, CONFIG)
        custom_public_title = config !== nothing ? CONFIG[config].public_title : ""
        custom_private_title = config !== nothing ? CONFIG[config].private_title : ""
        custom_public_desc = config !== nothing ? CONFIG[config].public_description : ""
        custom_private_desc = config !== nothing ? CONFIG[config].private_description : ""

        # Determine if this is a single-type page or truly combined
        has_public = any(mc -> !isempty(mc[2]), module_contents)  # mc[2] = public_docs
        has_private = any(mc -> !isempty(mc[3]), module_contents)  # mc[3] = private_docs

        overview, all_docstrings = if is_public_split
            # Case 1: Pure Public Split Page
            _build_public_page_content(
                modules_str,
                module_contents,
                is_split;
                custom_title=custom_public_title,
                custom_description=custom_public_desc,
            )
        elseif is_private_split
            # Case 2: Pure Private Split Page
            _build_private_page_content(
                modules_str,
                module_contents,
                is_split;
                custom_title=custom_private_title,
                custom_description=custom_private_desc,
            )
        elseif has_public && !has_private
            # Case 3: Single public-only page
            _build_public_page_content(
                modules_str,
                module_contents,
                false;
                custom_title=custom_public_title,
                custom_description=custom_public_desc,
            )
        elseif has_private && !has_public
            # Case 4: Single private-only page
            _build_private_page_content(
                modules_str,
                module_contents,
                false;
                custom_title=custom_private_title,
                custom_description=custom_private_desc,
            )
        else
            # Case 5: Combined Page (Public then Private)
            _build_combined_page_content(modules_str, module_contents)
        end

        combined_md = Markdown.parse(overview * join(all_docstrings, "\n"))

        # Write to source directory so SetupBuildDirectory can find and copy it
        source_path = joinpath(document.user.source, filename)
        mkpath(dirname(source_path))
        open(source_path, "w") do io
            write(io, overview)
            return write(io, join(all_docstrings, "\n"))
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
    _build_private_page_content(modules_str, module_contents, is_split; custom_title="", custom_description="") -> Tuple{String, Vector{String}}

Build the overview and docstrings for a private API page.

# Arguments
- `modules_str`: Comma-separated list of module names
- `module_contents`: Vector of (module, public_docs, private_docs) tuples
- `is_split`: Whether this is part of a split public/private documentation
- `custom_title`: Optional custom title (empty string uses default)
- `custom_description`: Optional custom description (empty string uses default)
"""
function _build_private_page_content(
    modules_str::String,
    module_contents,
    is_split::Bool;
    custom_title::String="",
    custom_description::String="",
)
    # Choose title based on context and customization
    title = if !isempty(custom_title)
        custom_title
    else
        "Private API"
    end

    # Choose description based on customization
    description = if !isempty(custom_description)
        custom_description
    else
        "This page lists **non-exported** (internal) symbols of `$(modules_str)`."
    end

    overview = """
    ```@meta
    EditURL = nothing
    ```

    # $(title)

    $(description)

    """

    all_docstrings = String[]
    for (mod, _, private_docs) in module_contents
        if !isempty(private_docs)
            push!(all_docstrings, "\n---\n\n## From `$(mod)`\n\n")
            append!(all_docstrings, private_docs)
        end
    end

    return overview, all_docstrings
end

"""
    _build_public_page_content(modules_str, module_contents, is_split; custom_title="", custom_description="") -> Tuple{String, Vector{String}}

Build the overview and docstrings for a public API page.

# Arguments
- `modules_str`: Comma-separated list of module names
- `module_contents`: Vector of (module, public_docs, private_docs) tuples
- `is_split`: Whether this is part of a split public/private documentation
- `custom_title`: Optional custom title (empty string uses default)
- `custom_description`: Optional custom description (empty string uses default)
"""
function _build_public_page_content(
    modules_str::String,
    module_contents,
    is_split::Bool;
    custom_title::String="",
    custom_description::String="",
)
    # Choose title based on context and customization
    title = if !isempty(custom_title)
        custom_title
    else
        "Public API"
    end

    # Choose description based on customization
    description = if !isempty(custom_description)
        custom_description
    else
        "This page lists **exported** symbols of `$(modules_str)`."
    end

    overview = """
    # $(title)

    $(description)

    """

    all_docstrings = String[]
    for (mod, public_docs, _) in module_contents
        if !isempty(public_docs)
            push!(all_docstrings, "\n---\n\n## From `$(mod)`\n\n")
            append!(all_docstrings, public_docs)
        end
    end

    return overview, all_docstrings
end
