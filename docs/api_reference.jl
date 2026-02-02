
"""
    generate_api_reference(src_dir::String)

Generate the API reference documentation for CTBase.
Returns the list of pages.
"""
function generate_api_reference(src_dir::String)
    # Helper to build absolute paths
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    ext_dir = abspath(joinpath(src_dir, "..", "ext"))
    ext(files...) = [abspath(joinpath(ext_dir, f)) for f in files]

    # Symbols to exclude (must match make.jl if shared, or be defined here)
    EXCLUDE_SYMBOLS = Symbol[:include, :eval]

    pages = [
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[CTBase.Core => src(joinpath("Core", "Core.jl"))],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Core",
            title_in_menu="Core",
            filename="api_core",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[
                CTBase.Descriptions => src(joinpath("Descriptions", "Descriptions.jl"))
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Descriptions",
            title_in_menu="Descriptions",
            filename="api_descriptions",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[
                CTBase.Exceptions => src(
                    joinpath("Exceptions", "Exceptions.jl"),
                    joinpath("Exceptions", "types.jl"),
                    joinpath("Exceptions", "config.jl"),
                    joinpath("Exceptions", "display.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Exceptions",
            title_in_menu="Exceptions",
            filename="api_exceptions",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[CTBase.Unicode => src(joinpath("Unicode", "Unicode.jl"))],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Unicode",
            title_in_menu="Unicode",
            filename="api_unicode",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[
                CTBase.Extensions => src(joinpath("Extensions", "Extensions.jl"))
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Extensions",
            title_in_menu="Extensions",
            filename="api_extensions",
        ),
    ]

    DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
    if !isnothing(DocumenterReference)
        EXCLUDE_DOCREF = vcat(
            EXCLUDE_SYMBOLS,
            Symbol[
                :DOCTYPE_ABSTRACT_TYPE,
                :DOCTYPE_CONSTANT,
                :DOCTYPE_FUNCTION,
                :DOCTYPE_MACRO,
                :DOCTYPE_MODULE,
                :DOCTYPE_STRUCT,
            ],
        )
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                primary_modules=[DocumenterReference => ext("DocumenterReference.jl")],
                external_modules_to_document=[CTBase],
                exclude=EXCLUDE_DOCREF,
                public=true,
                private=true,
                title="DocumenterReference",
                title_in_menu="DocumenterReference",
                filename="documenter_reference",
            ),
        )
    end

    CoveragePostprocessing = Base.get_extension(CTBase, :CoveragePostprocessing)
    if !isnothing(CoveragePostprocessing)
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                primary_modules=[
                    CoveragePostprocessing => ext("CoveragePostprocessing.jl")
                ],
                external_modules_to_document=[CTBase],
                exclude=EXCLUDE_SYMBOLS,
                public=true,
                private=true,
                title="CoveragePostprocessing",
                title_in_menu="CoveragePostprocessing",
                filename="coverage_postprocessing",
            ),
        )
    end

    TestRunner = Base.get_extension(CTBase, :TestRunner)
    if !isnothing(TestRunner)
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                primary_modules=[TestRunner => ext("TestRunner.jl")],
                external_modules_to_document=[CTBase],
                exclude=EXCLUDE_SYMBOLS,
                public=true,
                private=true,
                title="TestRunner",
                title_in_menu="TestRunner",
                filename="test_runner",
            ),
        )
    end
    return pages
end

"""
    with_api_reference(f::Function, src_dir::String)

Generates the API reference, executes `f(pages)`, and cleans up generated files.
"""
function with_api_reference(f::Function, src_dir::String)
    pages = generate_api_reference(src_dir)
    try
        f(pages)
    finally
        # Clean up generated files
        # The pages are Pairs: "Title" => "filename.md" (relative to build? no, relative to src)
        # automatic_reference_documentation returns "filename" which is relative to docs/src if subdirectory="."

        # We need to reconstruct the full path to delete them.
        # Assuming they are in docs/src (which is where makedocs runs from?)
        # Wait, makedocs options say subdirectory=".". 
        # Typically automatic_reference_documentation writes to joinpath(@__DIR__, "src", subdirectory, filename.md) ??
        # I need to check where automatic_reference_documentation writes.
        # Assuming we are running from docs/ (where make.jl is).

        # Let's assume the files are in `docs/src`.
        docs_src = abspath(joinpath(@__DIR__, "src"))

        function cleanup_pages(pages)
            for p in pages
                content = last(p)
                if content isa AbstractString
                    # file path
                    filename = content
                    fname = endswith(filename, ".md") ? filename : filename * ".md"
                    full_path = joinpath(docs_src, fname)
                    if isfile(full_path)
                        rm(full_path)
                        println("Removed temporary API doc: $full_path")
                    end
                elseif content isa Vector
                    # nested pages
                    cleanup_pages(content)
                end
            end
        end

        cleanup_pages(pages)
    end
end
