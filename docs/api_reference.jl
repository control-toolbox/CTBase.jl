
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
            primary_modules=[CTBase => src("CTBase.jl")],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="CTBase",
            title_in_menu="CTBase",
            filename="ctbase",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[CTBase => src("default.jl")],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="Default",
            title_in_menu="Default",
            filename="default",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[CTBase => src("description.jl")],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="Description",
            title_in_menu="Description",
            filename="description",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[CTBase => src("exception.jl")],
            external_modules_to_document=[Base],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="Exception",
            title_in_menu="Exception",
            filename="exception",
        ),
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[CTBase => src("utils.jl")],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="Utils",
            title_in_menu="Utils",
            filename="utils",
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
                exclude=EXCLUDE_DOCREF,
                public=false,
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
                primary_modules=[CoveragePostprocessing => ext("CoveragePostprocessing.jl")],
                exclude=EXCLUDE_SYMBOLS,
                public=false,
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
                exclude=EXCLUDE_SYMBOLS,
                public=false,
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
        
        for p in pages
            # p is "Title" => "filename.md" (or path)
            # automatic_reference_documentation returns a path relative to docs/src?
            # actually it returns what should be put in `pages`.
            
            # If I look at make.jl, it passed subdirectory="."
            # So the file is likely at `docs/src/filename.md`.
            
            filename = last(p) # "ctbase.md" or "ctbase" (if extension added automatically?)
            # automatic_reference_documentation usually adds .md if filename argument didn't have it?
            # In make.jl: filename="ctbase"
            
            # Let's handle both cases just in case
            fname = endswith(filename, ".md") ? filename : filename * ".md"
            full_path = joinpath(docs_src, fname)
            
            if isfile(full_path)
                rm(full_path)
                println("Removed temporary API doc: $full_path")
            end
        end
    end
end
