
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
            subdirectory="api",
            primary_modules=[CTBase.Core => src(joinpath("Core", "Core.jl"))],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Core",
            title_in_menu="Core",
            filename="core",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTBase.Descriptions => src(
                    joinpath("Descriptions", "Descriptions.jl"),
                    joinpath("Descriptions", "types.jl"),
                    joinpath("Descriptions", "similarity.jl"),
                    joinpath("Descriptions", "display.jl"),
                    joinpath("Descriptions", "catalog.jl"),
                    joinpath("Descriptions", "complete.jl"),
                    joinpath("Descriptions", "remove.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Descriptions",
            title_in_menu="Descriptions",
            filename="descriptions",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTBase.Exceptions => src(
                    joinpath("Exceptions", "Exceptions.jl"),
                    joinpath("Exceptions", "types.jl"),
                    joinpath("Exceptions", "display.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Exceptions",
            title_in_menu="Exceptions",
            filename="exceptions",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[CTBase.Unicode => src(joinpath("Unicode", "Unicode.jl"))],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=false, # there is no private API
            title="Unicode",
            title_in_menu="Unicode",
            filename="unicode",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTBase.Extensions => src(joinpath("Extensions", "Extensions.jl"))
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Extensions",
            title_in_menu="Extensions",
            filename="extensions",
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
                subdirectory="api",
                primary_modules=[DocumenterReference => ext("DocumenterReference.jl")],
                external_modules_to_document=[CTBase],
                exclude=EXCLUDE_DOCREF,
                public=false, # there is no public API
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
                subdirectory="api",
                primary_modules=[
                    CoveragePostprocessing => ext("CoveragePostprocessing.jl")
                ],
                external_modules_to_document=[CTBase],
                exclude=EXCLUDE_SYMBOLS,
                public=false, # there is no public API
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
                subdirectory="api",
                primary_modules=[TestRunner => ext("TestRunner.jl")],
                external_modules_to_document=[CTBase],
                exclude=EXCLUDE_SYMBOLS,
                public=false, # there is no public API
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
        docs_src = abspath(joinpath(@__DIR__, "src"))
        _cleanup_pages(docs_src, pages)
    end
end

function _cleanup_pages(docs_src::String, pages)
    for p in pages
        val = last(p)
        if val isa AbstractString
            fname = endswith(val, ".md") ? val : val * ".md"
            full_path = joinpath(docs_src, fname)
            if isfile(full_path)
                rm(full_path)
                println("Removed temporary API doc: $full_path")
            end
        elseif val isa AbstractVector
            _cleanup_pages(docs_src, val)
        end
    end
end
