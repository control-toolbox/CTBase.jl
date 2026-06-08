module TestDocumenterReference

import Test
import CTBase
import CTBase.Exceptions: Exceptions
import CTBase.Extensions: Extensions
import Documenter

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

# ------------------------------------------------------------------------------------------ #
"""
Docstring for the main test module used to validate module-level documentation
in the generated API pages.
"""
module DocumenterReferenceTestMod

"""
Simple documented function used to test source file detection and inclusion.
"""
myfun(x) = x

"""
Function that should be kept by _iterate_over_symbols.
"""
keep(x) = x

"""
Function that will be excluded via the `exclude` configuration.
"""
skip(x) = x

# No docstring: this function should be skipped by _iterate_over_symbols.
no_doc(x) = x

"""
Test submodule with a docstring but no associated source file information.
Used to exercise include_without_source behaviour for modules.
"""
module SubModule end

abstract type AbstractFoo end

struct Foo <: AbstractFoo
    x::Int
end

const MYCONST = 42

end
using .DocumenterReferenceTestMod
# ------------------------------------------------------------------------------------------ #

# ------------------------------------------------------------------------------------------ #
module DRTypeFormatTestMod
struct Simple end
struct Parametric{T} end
struct WithValue{T,N} end
end
# ------------------------------------------------------------------------------------------ #

# ------------------------------------------------------------------------------------------ #
module DRMethodTestMod
f() = 1
f(x::Int) = x
g(x::Int, y::String) = x
h(xs::Int...) = length(xs)
end
# ------------------------------------------------------------------------------------------ #

# ------------------------------------------------------------------------------------------ #
module DRExternalTestMod
extfun(x::Int) = x
extfun(x::String) = length(x)
end
# ------------------------------------------------------------------------------------------ #

# ------------------------------------------------------------------------------------------ #
module DRNoDocModule
module Inner end
end
# ------------------------------------------------------------------------------------------ #

# ------------------------------------------------------------------------------------------ #
module DRUnionAllTestMod
f(x::T) where {T} = x
end
# ------------------------------------------------------------------------------------------ #

function test_documenter_reference()

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Invalid primary_modules input" begin
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Test.@test_throws Extensions.IncorrectArgument Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=["invalid_string"], # String is not Module or Pair
                    title="My API",
                )
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "reset_config! clears CONFIG" begin
        DR.reset_config!()
        Test.@test isempty(DR.CONFIG)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_default_basename and _build_page_path" begin
        Test.@test DR._default_basename("manual", true, true) == "manual"
        Test.@test DR._default_basename("", true, true) == "api"
        Test.@test DR._default_basename("", true, false) == "public"
        Test.@test DR._default_basename("", false, true) == "private"

        Test.@test DR._build_page_path("api", "public") == "api/public"
        Test.@test DR._build_page_path(".", "public") == "public"
        Test.@test DR._build_page_path("", "public") == "public"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_classify_symbol and _to_string" begin
        Test.@test DR._classify_symbol(nothing, "@mymacro") == DR.DOCTYPE_MACRO
        Test.@test DR._classify_symbol(DocumenterReferenceTestMod.SubModule, "SubModule") ==
            DR.DOCTYPE_MODULE
        Test.@test DR._classify_symbol(DocumenterReferenceTestMod.AbstractFoo, "AbstractFoo") ==
            DR.DOCTYPE_ABSTRACT_TYPE
        Test.@test DR._classify_symbol(DocumenterReferenceTestMod.Foo, "Foo") ==
            DR.DOCTYPE_STRUCT
        Test.@test DR._classify_symbol(DocumenterReferenceTestMod.myfun, "myfun") ==
            DR.DOCTYPE_FUNCTION
        Test.@test DR._classify_symbol(DocumenterReferenceTestMod.MYCONST, "MYCONST") ==
            DR.DOCTYPE_CONSTANT

        Test.@test DR._to_string(DR.DOCTYPE_ABSTRACT_TYPE) == "abstract type"
        Test.@test DR._to_string(DR.DOCTYPE_CONSTANT) == "constant"
        Test.@test DR._to_string(DR.DOCTYPE_FUNCTION) == "function"
        Test.@test DR._to_string(DR.DOCTYPE_MACRO) == "macro"
        Test.@test DR._to_string(DR.DOCTYPE_MODULE) == "module"
        Test.@test DR._to_string(DR.DOCTYPE_STRUCT) == "struct"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_file" begin
        path = DR._get_source_file(DocumenterReferenceTestMod, :myfun, DR.DOCTYPE_FUNCTION)
        Test.@test path === abspath(@__FILE__)

        # No docstring => should use method-based resolution
        path2 = DR._get_source_file(
            DocumenterReferenceTestMod, :no_doc, DR.DOCTYPE_FUNCTION
        )
        Test.@test path2 === abspath(@__FILE__)

        # Missing symbol should be caught and return nothing
        missing_path = DR._get_source_file(
            DocumenterReferenceTestMod, :__does_not_exist__, DR.DOCTYPE_FUNCTION
        )
        Test.@test missing_path === nothing

        const_path = DR._get_source_file(
            DocumenterReferenceTestMod, :MYCONST, DR.DOCTYPE_CONSTANT
        )
        Test.@test const_path === nothing
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_from_methods" begin
        # For built-in operators like +, source detection behavior may vary by Julia version.
        # In Julia 1.12+, it may return a source file path even for +.
        # We just verify the function runs without error and returns String or nothing.
        result = DR._get_source_from_methods(+)
        Test.@test result === nothing || result isa String
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_parse_primary_modules with Pair" begin
        d = DR._parse_primary_modules([DocumenterReferenceTestMod => @__FILE__])
        Test.@test d[DocumenterReferenceTestMod] == [abspath(@__FILE__)]
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_has_documentation: module documented elsewhere" begin
        modules = Dict(DRNoDocModule.Inner => Any[])
        Test.@test DR._has_documentation(DRNoDocModule, :Inner, DR.DOCTYPE_MODULE, modules) ==
            true
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Type formatting helpers" begin
        Test.@test DR._format_datatype_for_docs(UInt) == "::UInt"

        # Parametric types without concrete params are UnionAll, use _format_type_for_docs
        param_result = DR._format_type_for_docs(DRTypeFormatTestMod.Parametric)
        Test.@test occursin("Parametric", param_result)

        # Concrete params => kept (WithValue{Int,2} is a DataType)
        concrete_result = DR._format_datatype_for_docs(DRTypeFormatTestMod.WithValue{Int,2})
        Test.@test occursin("WithValue", concrete_result)
        Test.@test occursin("Int", concrete_result)
        Test.@test occursin("2", concrete_result)

        # Fallback branch for non-type inputs
        Test.@test DR._format_type_for_docs(1) == "::1"

        # TypeVar formatting in _format_type_param - need to unwrap UnionAll first
        unwrapped = Base.unwrap_unionall(DRTypeFormatTestMod.Parametric)
        tv = unwrapped.parameters[1]
        Test.@test tv isa TypeVar
        Test.@test DR._format_type_param(tv) == "T"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_method_signature_string handles UnionAll" begin
        m = first(methods(DRUnionAllTestMod.f))
        s = DR._method_signature_string(m, DRUnionAllTestMod, :f)
        Test.@test occursin("DRUnionAllTestMod.f", s)
        Test.@test occursin("T", s)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_iterate_over_symbols filtering" begin
        current_module = DocumenterReferenceTestMod
        modules = Dict(current_module => Any[])
        exclude = Set{Symbol}([:skip])
        sort_by(x) = x
        source_files = String[]

        config = DR._Config(
            current_module,
            "api",
            modules,
            sort_by,
            exclude,
            true,
            true,
            "API Reference",
            "API Reference",
            source_files,
            "api",
            false,
            Module[],
            "",
            "",
            "",
            "",
        )

        symbols = [
            :keep => DR.DOCTYPE_FUNCTION,
            :skip => DR.DOCTYPE_FUNCTION,
            :no_doc => DR.DOCTYPE_FUNCTION,
        ]

        seen = Symbol[]
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                DR._iterate_over_symbols(config, symbols) do key, type
                    return push!(seen, key)
                end
            end
        end

        Test.@test :keep in seen
        Test.@test :skip ∉ seen
        Test.@test :no_doc ∉ seen
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_iterate_over_symbols with source_files and include_without_source" begin
        current_module = DocumenterReferenceTestMod
        modules = Dict(current_module => Any[])
        sort_by(x) = x
        allowed = [abspath(@__FILE__)]

        # Case 1: Only symbols whose source is in `allowed` are kept
        config1 = DR._Config(
            current_module,
            "api",
            modules,
            sort_by,
            Set{Symbol}(),
            true,
            true,
            "API Reference",
            "API Reference",
            allowed,
            "api",
            false,
            Module[],
            "",
            "",
            "",
            "",
        )

        symbols1 = [:myfun => DR.DOCTYPE_FUNCTION]

        seen1 = Symbol[]
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                DR._iterate_over_symbols(config1, symbols1) do key, type
                    return push!(seen1, key)
                end
            end
        end
        Test.@test :myfun in seen1

        # Case 2: Module symbols without source are kept only when include_without_source=true
        config2 = DR._Config(
            current_module,
            "api",
            modules,
            sort_by,
            Set{Symbol}(),
            true,
            true,
            "API Reference",
            "API Reference",
            allowed,
            "api",
            false,
            Module[],
            "",
            "",
            "",
            "",
        )

        config3 = DR._Config(
            current_module,
            "api",
            modules,
            sort_by,
            Set{Symbol}(),
            true,
            true,
            "API Reference",
            "API Reference",
            allowed,
            "api",
            true,
            Module[],
            "",
            "",
            "",
            "",
        )

        symbols_module = [:SubModule => DR.DOCTYPE_MODULE]

        seen2 = Symbol[]
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                DR._iterate_over_symbols(config2, symbols_module) do key, type
                    return push!(seen2, key)
                end
            end
        end
        Test.@test isempty(seen2)

        seen3 = Symbol[]
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                DR._iterate_over_symbols(config3, symbols_module) do key, type
                    return push!(seen3, key)
                end
            end
        end
        Test.@test :SubModule in seen3
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation configuration" begin
        DR.reset_config!()

        # Single-module, public-only
        pages1 = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=[DocumenterReferenceTestMod],
                    public=true,
                    private=false,
                    title="My API",
                )
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation default tag" begin
            DR.reset_config!()

            pages_default = redirect_stdout(devnull) do
                redirect_stderr(devnull) do
                    Extensions.automatic_reference_documentation(;
                        subdirectory="ref",
                        primary_modules=[DocumenterReferenceTestMod],
                        public=true,
                        private=false,
                        title="My API",
                    )
                end
            end

            Test.@test length(DR.CONFIG) == 1
            cfg_default = DR.CONFIG[1]
            Test.@test cfg_default.current_module === DocumenterReferenceTestMod
            Test.@test cfg_default.subdirectory == "ref"
            Test.@test cfg_default.public == true
            Test.@test cfg_default.private == false
            Test.@test cfg_default.filename == "public"
            Test.@test pages_default == pages1
        end

        Test.@test length(DR.CONFIG) == 1
        cfg1 = DR.CONFIG[1]
        Test.@test cfg1.current_module === DocumenterReferenceTestMod
        Test.@test cfg1.subdirectory == "ref"
        Test.@test cfg1.public == true
        Test.@test cfg1.private == false
        Test.@test cfg1.filename == "public"
        Test.@test pages1 == ("My API" => "ref/public.md")

        # Both public and private pages
        DR.reset_config!()
        pages2 = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=[DocumenterReferenceTestMod],
                    public=true,
                    private=true,
                    title="All API",
                )
            end
        end

        Test.@test length(DR.CONFIG) == 1
        cfg2 = DR.CONFIG[1]
        Test.@test cfg2.filename == "api"
        Test.@test cfg2.public == true
        Test.@test cfg2.private == true
        Test.@test cfg2.title == "All API"
        Test.@test pages2 == (
            "All API" =>
                ["Public" => "ref/api_public.md", "Private" => "ref/api_private.md"]
        )

        # public=false, private=false should error
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Test.@test_throws Extensions.IncorrectArgument Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=[DocumenterReferenceTestMod],
                    public=false,
                    private=false,
                )
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Documenter.Selectors.order for APIBuilder" begin
        Test.@test Documenter.Selectors.order(DR.APIBuilder) == 0.5
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_collect_module_docstrings includes module docstring" begin
        DR.reset_config!()

        config = DR._Config(
            DocumenterReferenceTestMod,
            "api",
            Dict(DocumenterReferenceTestMod => Any[]),
            identity,
            Set{Symbol}(),
            true,
            true,
            "API",
            "API",
            String[],
            "api",
            false,
            Module[],
            "",
            "",
            "",
            "",
        )

        symbols = DR._exported_symbols(DocumenterReferenceTestMod).exported
        docs = DR._collect_module_docstrings(config, symbols)

        Test.@test any(
            doc -> occursin("```@docs\n$(DocumenterReferenceTestMod)\n```", doc), docs
        )
    end

    # ============================================================================
    # NEW TESTS: _exported_symbols
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_exported_symbols classification" begin
        # Test that _exported_symbols correctly classifies symbols
        result = DR._exported_symbols(DocumenterReferenceTestMod)

        # Check structure: should return NamedTuple with exported and private fields
        Test.@test haskey(result, :exported)
        Test.@test haskey(result, :private)

        # Check that exported list contains expected symbols (none exported in test module)
        Test.@test result.exported isa Vector

        # Check that private list contains our test symbols
        private_symbols = Dict(result.private)
        Test.@test haskey(private_symbols, :myfun)
        Test.@test private_symbols[:myfun] == DR.DOCTYPE_FUNCTION
        Test.@test haskey(private_symbols, :keep)
        Test.@test haskey(private_symbols, :skip)
        Test.@test haskey(private_symbols, :no_doc)
        Test.@test haskey(private_symbols, :SubModule)
        Test.@test private_symbols[:SubModule] == DR.DOCTYPE_MODULE
        Test.@test haskey(private_symbols, :AbstractFoo)
        Test.@test private_symbols[:AbstractFoo] == DR.DOCTYPE_ABSTRACT_TYPE
        Test.@test haskey(private_symbols, :Foo)
        Test.@test private_symbols[:Foo] == DR.DOCTYPE_STRUCT
        Test.@test haskey(private_symbols, :MYCONST)
        Test.@test private_symbols[:MYCONST] == DR.DOCTYPE_CONSTANT
    end

    # ============================================================================
    # NEW TESTS: automatic_reference_documentation multi-module
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation multi-module" begin
        DR.reset_config!()

        # Create a second test module for multi-module testing
        mod1 = DocumenterReferenceTestMod

        # Test multi-module case (using same module twice as a proxy)
        pages = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="api",
                    primary_modules=[mod1, mod1],  # Two entries to trigger multi-module path
                    public=true,
                    private=true,
                    title="Multi API",
                )
            end
        end

        # Should return a Pair with title and list of module pages
        Test.@test pages isa Pair
        Test.@test first(pages) == "Multi API"
        Test.@test last(pages) isa Vector

        # CONFIG should have 1 entry (one per unique module)
        Test.@test length(DR.CONFIG) == 1
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation multi-module with filename" begin
        DR.reset_config!()

        mod1 = DocumenterReferenceTestMod
        mod2 = DRMethodTestMod

        # Test multi-module case with explicit filename (combined page - public only)
        # Note: DocumenterReference currently splits public/private if both are true,
        # ignoring the filename for the split structure.
        # So we test public-only to verify filename is respected.
        pages = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="api",
                    primary_modules=[mod1, mod2],
                    public=true,
                    private=false,
                    title="Combined Public API",
                    filename="combined_public",
                )
            end
        end

        # Should return a Pair with title and path to the combined file
        Test.@test pages isa Pair
        Test.@test first(pages) == "Combined Public API"
        Test.@test last(pages) == "api/combined_public.md"

        # CONFIG should have 2 entries (one per unique module)
        Test.@test length(DR.CONFIG) == 2
        Test.@test count(c -> c.current_module == mod1, DR.CONFIG) == 1
        Test.@test count(c -> c.current_module == mod2, DR.CONFIG) == 1
    end

    # ============================================================================
    # NEW TESTS: _get_source_file expanded
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_file expanded cases" begin
        # Function case (already tested, but verify)
        func_path = DR._get_source_file(
            DocumenterReferenceTestMod, :myfun, DR.DOCTYPE_FUNCTION
        )
        Test.@test func_path !== nothing
        Test.@test endswith(func_path, "test_documenter_reference.jl")

        # Struct case - should find source via constructor methods
        struct_path = DR._get_source_file(
            DocumenterReferenceTestMod, :Foo, DR.DOCTYPE_STRUCT
        )
        # Structs defined in test file should be found
        Test.@test struct_path === nothing ||
            endswith(struct_path, "test_documenter_reference.jl")

        # Abstract type case - typically returns nothing (no constructor)
        abstract_path = DR._get_source_file(
            DocumenterReferenceTestMod, :AbstractFoo, DR.DOCTYPE_ABSTRACT_TYPE
        )
        Test.@test abstract_path === nothing

        # Module case - modules cannot reliably determine source
        mod_path = DR._get_source_file(
            DocumenterReferenceTestMod, :SubModule, DR.DOCTYPE_MODULE
        )
        Test.@test mod_path === nothing

        # Constant case (already tested)
        const_path = DR._get_source_file(
            DocumenterReferenceTestMod, :MYCONST, DR.DOCTYPE_CONSTANT
        )
        Test.@test const_path === nothing
    end

    # ============================================================================
    # NEW TESTS: Edge cases
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Edge cases" begin
        # _build_page_path with various inputs
        Test.@test DR._build_page_path("", "") == ""
        Test.@test DR._build_page_path(".", "") == ""
        Test.@test DR._build_page_path("dir", "") == "dir/"
        Test.@test DR._build_page_path("a/b/c", "file.md") == "a/b/c/file.md"

        # _default_basename edge cases
        Test.@test DR._default_basename("custom", false, false) == "custom"  # Custom overrides flags
        Test.@test DR._default_basename("", false, false) == "private"  # Fallback when both false

        # _classify_symbol with edge cases
        Test.@test DR._classify_symbol(42, "fortytwo") == DR.DOCTYPE_CONSTANT  # Integer constant
        Test.@test DR._classify_symbol("hello", "greeting") == DR.DOCTYPE_CONSTANT  # String constant
        Test.@test DR._classify_symbol([1, 2, 3], "myarray") == DR.DOCTYPE_CONSTANT  # Array constant

        # _to_string covers all enum values (verify no error)
        for dt in instances(DR.DocType)
            Test.@test DR._to_string(dt) isa String
            Test.@test length(DR._to_string(dt)) > 0
        end

        # _iterate_over_symbols with empty list
        config = DR._Config(
            DocumenterReferenceTestMod,
            "api",
            Dict(DocumenterReferenceTestMod => Any[]),
            identity,
            Set{Symbol}(),
            true,
            true,
            "API",
            "API",
            String[],
            "api",
            false,
            Module[],
            "",
            "",
            "",
            "",
        )
        seen = Symbol[]
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                DR._iterate_over_symbols(config, Pair{Symbol,DR.DocType}[]) do key, type
                    return push!(seen, key)
                end
            end
        end
        Test.@test isempty(seen)

        # reset_config! is idempotent
        DR.reset_config!()
        DR.reset_config!()
        Test.@test isempty(DR.CONFIG)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_for_docs and helpers" begin
        simple_str = DR._format_type_for_docs(DRTypeFormatTestMod.Simple)
        Test.@test startswith(simple_str, "::")
        Test.@test occursin("DRTypeFormatTestMod.Simple", simple_str)

        param_type = DRTypeFormatTestMod.Parametric{DRTypeFormatTestMod.Simple}
        param_str = DR._format_type_for_docs(param_type)
        Test.@test occursin("Parametric", param_str)
        Test.@test occursin("Simple", param_str)

        union_str = DR._format_type_for_docs(Union{DRTypeFormatTestMod.Simple,Nothing})
        Test.@test occursin("Union", union_str)
        Test.@test occursin("Simple", union_str)
        Test.@test occursin("Nothing", union_str)

        value_type = DRTypeFormatTestMod.WithValue{Int,3}
        value_str = DR._format_type_for_docs(value_type)
        Test.@test occursin("WithValue", value_str)
        Test.@test occursin("3", value_str)

        param_fmt = DR._format_type_param(DRTypeFormatTestMod.Simple)
        Test.@test occursin("DRTypeFormatTestMod.Simple", param_fmt)

        value_param_fmt = DR._format_type_param(3)
        Test.@test value_param_fmt == "3"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_method_signature_string and method collection" begin
        methods_f = methods(DRMethodTestMod.f)
        m0 = first(filter(m -> length(m.sig.parameters) == 1, methods_f))
        sig0 = DR._method_signature_string(m0, DRMethodTestMod, :f)
        Test.@test endswith(sig0, "DRMethodTestMod.f()")

        m1 = first(filter(m -> length(m.sig.parameters) == 2, methods_f))
        sig1 = DR._method_signature_string(m1, DRMethodTestMod, :f)
        Test.@test occursin("DRMethodTestMod.f", sig1)
        Test.@test occursin("Int", sig1)

        methods_h = methods(DRMethodTestMod.h)
        mvar = first(methods_h)
        sigv = DR._method_signature_string(mvar, DRMethodTestMod, :h)
        Test.@test occursin("Vararg", sigv)

        source_files = [abspath(@__FILE__)]
        methods_by_func = DR._collect_methods_from_source_files(
            DRMethodTestMod, source_files
        )
        Test.@test :f in keys(methods_by_func)
        Test.@test :h in keys(methods_by_func)
        for ms in values(methods_by_func)
            for m in ms
                file = String(m.file)
                Test.@test abspath(file) in source_files
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Page content builders" begin
        modules_str = "ModA, ModB"
        module_contents_private = [
            (DocumenterReferenceTestMod, String[], ["priv_a"]),
            (DRMethodTestMod, String[], ["priv_b1", "priv_b2"]),
        ]
        # Test with is_split=false (single page)
        overview_priv, docs_priv = DR._build_private_page_content(
            modules_str, module_contents_private, false
        )
        Test.@test occursin("Private API", overview_priv)
        Test.@test occursin("ModA, ModB", overview_priv)
        Test.@test !isempty(docs_priv)
        Test.@test any(occursin("priv_a", s) for s in docs_priv)
        Test.@test any(occursin("priv_b1", s) for s in docs_priv)

        module_contents_public = [
            (DocumenterReferenceTestMod, ["pub_a"], String[]),
            (DRMethodTestMod, String[], String[]),
        ]
        # Test with is_split=false (single page)
        overview_pub, docs_pub = DR._build_public_page_content(
            modules_str, module_contents_public, false
        )
        Test.@test occursin("Public API", overview_pub)
        Test.@test occursin("ModA, ModB", overview_pub)
        Test.@test !isempty(docs_pub)
        Test.@test any(occursin("pub_a", s) for s in docs_pub)

        module_contents_combined = [(DocumenterReferenceTestMod, ["pub_a"], ["priv_a"])]
        overview_comb, docs_comb = DR._build_combined_page_content(
            modules_str, module_contents_combined
        )
        Test.@test occursin("API reference", overview_comb)
        Test.@test any(occursin("Public API", s) for s in docs_comb)
        Test.@test any(occursin("Private API", s) for s in docs_comb)
        Test.@test any(occursin("pub_a", s) for s in docs_comb)
        Test.@test any(occursin("priv_a", s) for s in docs_comb)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "external_modules_to_document" begin
        current_module = DocumenterReferenceTestMod
        modules = Dict(current_module => String[])
        sort_by(x) = x
        source_files = [abspath(@__FILE__)]

        config = DR._Config(
            current_module,
            "api_ext",
            modules,
            sort_by,
            Set{Symbol}(),
            true,
            true,
            "Ext API",
            "Ext API",
            source_files,
            "api_ext",
            false,
            [DRExternalTestMod],
            "",
            "",
            "",
            "",
        )

        private_docs = DR._collect_private_docstrings(config, Pair{Symbol,DR.DocType}[])
        Test.@test !isempty(private_docs)
        Test.@test any(occursin("DRExternalTestMod.extfun", s) for s in private_docs)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "APIBuilder runner integration" begin
        DR.reset_config!()

        pages = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="api_integration",
                    primary_modules=[DocumenterReferenceTestMod],
                    public=true,
                    private=true,
                    title="Integration API",
                )
            end
        end

        Test.@test !isempty(DR.CONFIG)

        doc = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Documenter.Document(;
                    root=pwd(), source="_test_docs_src", build="_test_docs_build", remotes=nothing
                )
            end
        end

        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Documenter.Selectors.runner(DR.APIBuilder, doc)
            end
        end

        Test.@test !isempty(doc.blueprint.pages)
        Test.@test any(endswith(k, "api_private.md") for k in keys(doc.blueprint.pages))
    end

    # ============================================================================
    # Edge Case Tests: Type Formatting Functions
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_for_docs edge cases" begin
        # Test Union types formatting (covers L775-782)
        union_result = DR._format_type_for_docs(Union{Int,String})
        Test.@test occursin("Union", union_result)
        Test.@test occursin("Int", union_result)
        Test.@test occursin("String", union_result)

        # Test simple non-DataType fallback (covers L782)
        Test.@test DR._format_type_for_docs(Any) == "::Any"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_datatype_for_docs with TypeVar" begin
        # Test parametric type with concrete parameters
        concrete_result = DR._format_datatype_for_docs(Vector{Int})
        Test.@test occursin("Vector", concrete_result) || occursin("Array", concrete_result)
        Test.@test occursin("Int", concrete_result)

        # Test parametric type - the function strips parameters when TypeVar present
        # Array{T,1} where T has a TypeVar, so it gets stripped
        Test.@test DR._format_datatype_for_docs(Int) == "::Int"
        Test.@test DR._format_datatype_for_docs(String) == "::String"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_param edge cases" begin
        # Test Type parameter (covers L824-826)
        type_result = DR._format_type_param(Int)
        Test.@test type_result == "Int"  # Should strip leading ::

        # Test value parameter (covers L830) - e.g., for sized arrays
        Test.@test DR._format_type_param(3) == "3"
        Test.@test DR._format_type_param(42) == "42"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_method_signature_string edge cases" begin
        # Test method signature generation for DRMethodTestMod
        m = first(methods(DRMethodTestMod.f))
        sig = DR._method_signature_string(m, DRMethodTestMod, :f)
        Test.@test occursin("DRMethodTestMod", sig)
        Test.@test occursin("f", sig)

        # Test with multiple arguments
        m2 = first(methods(DRMethodTestMod.g))
        sig2 = DR._method_signature_string(m2, DRMethodTestMod, :g)
        Test.@test occursin("g", sig2)
    end

    # ============================================================================
    # NEW TESTS: Title System with is_split Parameter
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Page content builders with is_split parameter" begin
        modules_str = "TestModule"

        # Test private page with is_split=false (single page)
        module_contents_private = [(DocumenterReferenceTestMod, String[], ["priv_doc"])]

        overview_priv_single, docs_priv_single = DR._build_private_page_content(
            modules_str, module_contents_private, false
        )
        Test.@test occursin("# Private API", overview_priv_single)
        Test.@test !occursin("# Private\n", overview_priv_single)
        Test.@test occursin("non-exported", overview_priv_single)

        # Test private page with is_split=true (split page)
        overview_priv_split, docs_priv_split = DR._build_private_page_content(
            modules_str, module_contents_private, true
        )
        Test.@test occursin("# Private API", overview_priv_split)
        Test.@test occursin("non-exported", overview_priv_split)

        # Test public page with is_split=false (single page)
        module_contents_public = [(DocumenterReferenceTestMod, ["pub_doc"], String[])]

        overview_pub_single, docs_pub_single = DR._build_public_page_content(
            modules_str, module_contents_public, false
        )
        Test.@test occursin("# Public API", overview_pub_single)
        Test.@test occursin("exported", overview_pub_single)

        # Test public page with is_split=true (split page)
        overview_pub_split, docs_pub_split = DR._build_public_page_content(
            modules_str, module_contents_public, true
        )
        Test.@test occursin("# Public API", overview_pub_split)
        Test.@test occursin("exported", overview_pub_split)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Title consistency across different page types" begin
        modules_str = "MyModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub"], ["priv"])]

        # Single private page should have "Private API" title
        overview_priv, _ = DR._build_private_page_content(
            modules_str, module_contents, false
        )
        Test.@test occursin("# Private API", overview_priv)

        # Single public page should have "Public API" title
        overview_pub, _ = DR._build_public_page_content(modules_str, module_contents, false)
        Test.@test occursin("# Public API", overview_pub)

        # Split private page should have "Private API" title
        overview_priv_split, _ = DR._build_private_page_content(
            modules_str, module_contents, true
        )
        Test.@test occursin("# Private API", overview_priv_split)

        # Split public page should have "Public API" title
        overview_pub_split, _ = DR._build_public_page_content(
            modules_str, module_contents, true
        )
        Test.@test occursin("# Public API", overview_pub_split)

        # Combined page should have "API reference" title
        overview_comb, _ = DR._build_combined_page_content(modules_str, module_contents)
        Test.@test occursin("# API reference", overview_comb)
    end

    # ============================================================================
    # NEW TESTS: Customization Parameters
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Custom titles for API pages" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]

        # Test custom title for private page (single)
        overview_priv_custom, _ = DR._build_private_page_content(
            modules_str, module_contents, false; custom_title="Internal API"
        )
        Test.@test occursin("# Internal API", overview_priv_custom)
        Test.@test !occursin("# Private API", overview_priv_custom)

        # Test custom title for public page (single)
        overview_pub_custom, _ = DR._build_public_page_content(
            modules_str, module_contents, false; custom_title="Exported API"
        )
        Test.@test occursin("# Exported API", overview_pub_custom)
        Test.@test !occursin("# Public API", overview_pub_custom)

        # Test custom title for private page (split)
        overview_priv_split_custom, _ = DR._build_private_page_content(
            modules_str, module_contents, true; custom_title="Internal"
        )
        Test.@test occursin("# Internal", overview_priv_split_custom)
        Test.@test !occursin("# Private API", overview_priv_split_custom)

        # Test custom title for public page (split)
        overview_pub_split_custom, _ = DR._build_public_page_content(
            modules_str, module_contents, true; custom_title="Exported"
        )
        Test.@test occursin("# Exported", overview_pub_split_custom)
        Test.@test !occursin("# Public API", overview_pub_split_custom)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Custom descriptions for API pages" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]

        # Test custom description for private page
        custom_desc_priv = "This page documents internal implementation details."
        overview_priv_desc, _ = DR._build_private_page_content(
            modules_str, module_contents, false; custom_description=custom_desc_priv
        )
        Test.@test occursin(custom_desc_priv, overview_priv_desc)
        Test.@test !occursin("non-exported", overview_priv_desc)

        # Test custom description for public page
        custom_desc_pub = "This page documents the public interface for end users."
        overview_pub_desc, _ = DR._build_public_page_content(
            modules_str, module_contents, false; custom_description=custom_desc_pub
        )
        Test.@test occursin(custom_desc_pub, overview_pub_desc)
        Test.@test !occursin("exported", overview_pub_desc) ||
            occursin(custom_desc_pub, overview_pub_desc)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Combined custom title and description" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]

        # Test both custom title and description together
        custom_title = "Developer Reference"
        custom_desc = "Advanced documentation for contributors and maintainers."

        overview, _ = DR._build_private_page_content(
            modules_str,
            module_contents,
            false;
            custom_title=custom_title,
            custom_description=custom_desc,
        )

        Test.@test occursin("# Developer Reference", overview)
        Test.@test occursin(custom_desc, overview)
        Test.@test !occursin("# Private API", overview)
        Test.@test !occursin("non-exported", overview)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Empty customization uses defaults" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]

        # Empty strings should use default behavior
        overview_priv_empty, _ = DR._build_private_page_content(
            modules_str, module_contents, false; custom_title="", custom_description=""
        )
        Test.@test occursin("# Private API", overview_priv_empty)
        Test.@test occursin("non-exported", overview_priv_empty)

        overview_pub_empty, _ = DR._build_public_page_content(
            modules_str, module_contents, false; custom_title="", custom_description=""
        )
        Test.@test occursin("# Public API", overview_pub_empty)
        Test.@test occursin("exported", overview_pub_empty)
    end
end

end # module TestDocumenterReference

# CRITICAL: redefine in outer scope so the test runner can call it
test_documenter_reference() = TestDocumenterReference.test_documenter_reference()
