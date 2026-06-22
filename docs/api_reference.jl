
"""
    generate_api_reference(src_dir::String)

Generate the API reference documentation for CTBase.
Returns the list of pages.
"""
function generate_api_reference(src_dir::String)
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    ext_dir = abspath(joinpath(src_dir, "..", "ext"))
    ext(files...) = [abspath(joinpath(ext_dir, f)) for f in files]

    EXCLUDE_SYMBOLS = Symbol[:include, :eval]
    EXCLUDE_INTERNALS = vcat(EXCLUDE_SYMBOLS, Symbol[
        :DOCTYPE_ABSTRACT_TYPE, :DOCTYPE_CONSTANT, :DOCTYPE_FUNCTION,
        :DOCTYPE_MACRO, :DOCTYPE_MODULE, :DOCTYPE_STRUCT,
    ])

    # ── Public API: one flat page per module ──────────────────────────────────
    modules_config = [
        (mod=CTBase.Core, title="Core", filename="core", files=src(
            joinpath("Core", "Core.jl"), joinpath("Core", "default.jl"),
            joinpath("Core", "types.jl"), joinpath("Core", "matrix_utils.jl"),
            joinpath("Core", "function_utils.jl"), joinpath("Core", "macros.jl"),
            joinpath("Core", "palette.jl"), joinpath("Core", "display.jl"),
        )),
        (mod=CTBase.Descriptions, title="Descriptions", filename="descriptions", files=src(
            joinpath("Descriptions", "Descriptions.jl"), joinpath("Descriptions", "types.jl"),
            joinpath("Descriptions", "similarity.jl"), joinpath("Descriptions", "display.jl"),
            joinpath("Descriptions", "catalog.jl"), joinpath("Descriptions", "complete.jl"),
            joinpath("Descriptions", "remove.jl"),
        )),
        (mod=CTBase.DevTools, title="DevTools", filename="devtools", files=src(
            joinpath("DevTools", "DevTools.jl"), joinpath("DevTools", "coverage_postprocessing.jl"),
            joinpath("DevTools", "documenter_reference.jl"), joinpath("DevTools", "test_runner.jl"),
        )),
        (mod=CTBase.Exceptions, title="Exceptions", filename="exceptions", files=src(
            joinpath("Exceptions", "Exceptions.jl"), joinpath("Exceptions", "types.jl"),
            joinpath("Exceptions", "display.jl"),
        )),
        (mod=CTBase.Interpolation, title="Interpolation", filename="interpolation", files=src(
            joinpath("Interpolation", "Interpolation.jl"), joinpath("Interpolation", "types.jl"),
            joinpath("Interpolation", "ctinterpolate.jl"), joinpath("Interpolation", "display.jl"),
        )),
        (mod=CTBase.Options, title="Options", filename="options", files=src(
            joinpath("Options", "Options.jl"), joinpath("Options", "not_provided.jl"),
            joinpath("Options", "option_value.jl"), joinpath("Options", "option_definition.jl"),
            joinpath("Options", "extraction.jl"),
        )),
        (mod=CTBase.Orchestration, title="Orchestration", filename="orchestration", files=src(
            joinpath("Orchestration", "Orchestration.jl"),
            joinpath("Orchestration", "disambiguation.jl"),
            joinpath("Orchestration", "builders.jl"),
            joinpath("Orchestration", "routing.jl"),
        )),
        (mod=CTBase.Strategies, title="Strategies", filename="strategies", files=src(
            joinpath("Strategies", "Strategies.jl"),
            joinpath("Strategies", "display_formatting.jl"),
            joinpath("Strategies", "contract", "abstract_strategy.jl"),
            joinpath("Strategies", "contract", "metadata.jl"),
            joinpath("Strategies", "contract", "strategy_options.jl"),
            joinpath("Strategies", "contract", "parameters.jl"),
            joinpath("Strategies", "api", "registry.jl"),
            joinpath("Strategies", "api", "describe_registry.jl"),
            joinpath("Strategies", "api", "introspection.jl"),
            joinpath("Strategies", "api", "bypass.jl"),
            joinpath("Strategies", "api", "builders.jl"),
            joinpath("Strategies", "api", "configuration.jl"),
            joinpath("Strategies", "api", "utilities.jl"),
            joinpath("Strategies", "api", "validation_helpers.jl"),
            joinpath("Strategies", "api", "disambiguation.jl"),
        )),
        (mod=CTBase.Unicode, title="Unicode", filename="unicode", files=src(
            joinpath("Unicode", "Unicode.jl"), joinpath("Unicode", "subscripts.jl"),
            joinpath("Unicode", "superscripts.jl"),
        )),
    ]

    pages = [
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[cfg.mod => cfg.files],
            exclude=EXCLUDE_SYMBOLS,
            public=true, private=false,
            title=cfg.title, title_in_menu=cfg.title, filename=cfg.filename,
        )
        for cfg in modules_config
    ]

    # ── Internals: all private symbols in one page, sections by module ────────
    internals_modules = Any[cfg.mod => cfg.files for cfg in modules_config]

    for (sym, files) in [
        (:DocumenterReference, ext(
            joinpath("DocumenterReference", "DocumenterReference.jl"),
            joinpath("DocumenterReference", "config_helpers.jl"),
            joinpath("DocumenterReference", "entry_point.jl"),
            joinpath("DocumenterReference", "page_building.jl"),
            joinpath("DocumenterReference", "source_file_detection.jl"),
            joinpath("DocumenterReference", "symbol_classification.jl"),
            joinpath("DocumenterReference", "symbol_iteration.jl"),
            joinpath("DocumenterReference", "type_formatting.jl"),
            joinpath("DocumenterReference", "types.jl"),
        )),
        (:CoveragePostprocessing, ext(
            joinpath("CoveragePostprocessing", "CoveragePostprocessing.jl"),
            joinpath("CoveragePostprocessing", "entry_point.jl"),
            joinpath("CoveragePostprocessing", "helpers.jl"),
        )),
        (:TestRunner, ext(
            joinpath("TestRunner", "TestRunner.jl"),
            joinpath("TestRunner", "arg_parsing.jl"),
            joinpath("TestRunner", "entry_point.jl"),
            joinpath("TestRunner", "progress.jl"),
            joinpath("TestRunner", "test_execution.jl"),
            joinpath("TestRunner", "test_selection.jl"),
            joinpath("TestRunner", "types.jl"),
        )),
    ]
        extmod = Base.get_extension(CTBase, sym)
        isnothing(extmod) || push!(internals_modules, extmod => files)
    end

    push!(pages, CTBase.automatic_reference_documentation(;
        subdirectory="api",
        primary_modules=internals_modules,
        external_modules_to_document=[CTBase],
        exclude=EXCLUDE_INTERNALS,
        public=false, private=true,
        title="Internals", title_in_menu="Internals", filename="internals",
    ))

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
