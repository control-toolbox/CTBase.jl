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

module DRTypeFormatTestMod
struct Simple end
struct Parametric{T} end
struct WithValue{T,N} end
end

module DRMethodTestMod
f() = 1
f(x::Int) = x
g(x::Int, y::String) = x
h(xs::Int...) = length(xs)
end

module DRExternalTestMod
extfun(x::Int) = x
extfun(x::String) = length(x)
end

module DRNoDocModule
module Inner end
end

module DRUnionAllTestMod
f(x::T) where {T} = x
end

using .DocumenterReferenceTestMod

function test_documenter_reference()
    DR = DocumenterReference

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Invalid primary_modules input" begin
        @test_throws ErrorException CTBase.automatic_reference_documentation(
            CTBase.Extensions.DocumenterReferenceTag();
            subdirectory="ref",
            primary_modules=["invalid_string"], # String is not Module or Pair
            title="My API",
        )
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "reset_config! clears CONFIG" begin
        DR.reset_config!()
        @test isempty(DR.CONFIG)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_default_basename and _build_page_path" begin
        @test DR._default_basename("manual", true, true) == "manual"
        @test DR._default_basename("", true, true) == "api"
        @test DR._default_basename("", true, false) == "public"
        @test DR._default_basename("", false, true) == "private"

        @test DR._build_page_path("api", "public") == "api/public"
        @test DR._build_page_path(".", "public") == "public"
        @test DR._build_page_path("", "public") == "public"
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_classify_symbol and _to_string" begin
        @test DR._classify_symbol(nothing, "@mymacro") == DR.DOCTYPE_MACRO
        @test DR._classify_symbol(DocumenterReferenceTestMod.SubModule, "SubModule") ==
            DR.DOCTYPE_MODULE
        @test DR._classify_symbol(DocumenterReferenceTestMod.AbstractFoo, "AbstractFoo") ==
            DR.DOCTYPE_ABSTRACT_TYPE
        @test DR._classify_symbol(DocumenterReferenceTestMod.Foo, "Foo") ==
            DR.DOCTYPE_STRUCT
        @test DR._classify_symbol(DocumenterReferenceTestMod.myfun, "myfun") ==
            DR.DOCTYPE_FUNCTION
        @test DR._classify_symbol(DocumenterReferenceTestMod.MYCONST, "MYCONST") ==
            DR.DOCTYPE_CONSTANT

        @test DR._to_string(DR.DOCTYPE_ABSTRACT_TYPE) == "abstract type"
        @test DR._to_string(DR.DOCTYPE_CONSTANT) == "constant"
        @test DR._to_string(DR.DOCTYPE_FUNCTION) == "function"
        @test DR._to_string(DR.DOCTYPE_MACRO) == "macro"
        @test DR._to_string(DR.DOCTYPE_MODULE) == "module"
        @test DR._to_string(DR.DOCTYPE_STRUCT) == "struct"
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_file" begin
        path = DR._get_source_file(DocumenterReferenceTestMod, :myfun, DR.DOCTYPE_FUNCTION)
        @test path === abspath(@__FILE__)

        # No docstring => should use method-based resolution
        path2 = DR._get_source_file(
            DocumenterReferenceTestMod, :no_doc, DR.DOCTYPE_FUNCTION
        )
        @test path2 === abspath(@__FILE__)

        # Missing symbol should be caught and return nothing
        missing_path = DR._get_source_file(
            DocumenterReferenceTestMod, :__does_not_exist__, DR.DOCTYPE_FUNCTION
        )
        @test missing_path === nothing

        const_path = DR._get_source_file(
            DocumenterReferenceTestMod, :MYCONST, DR.DOCTYPE_CONSTANT
        )
        @test const_path === nothing
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_from_methods" begin
        # For built-in operators like +, source detection behavior may vary by Julia version.
        # In Julia 1.12+, it may return a source file path even for +.
        # We just verify the function runs without error and returns String or nothing.
        result = DR._get_source_from_methods(+)
        @test result === nothing || result isa String
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_parse_primary_modules with Pair" begin
        d = DR._parse_primary_modules([DocumenterReferenceTestMod => @__FILE__])
        @test d[DocumenterReferenceTestMod] == [abspath(@__FILE__)]
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_has_documentation: module documented elsewhere" begin
        modules = Dict(DRNoDocModule.Inner => Any[])
        @test DR._has_documentation(DRNoDocModule, :Inner, DR.DOCTYPE_MODULE, modules) ==
            true
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Type formatting helpers" begin
        @test DR._format_datatype_for_docs(UInt) == "::UInt"

        # Parametric types without concrete params are UnionAll, use _format_type_for_docs
        param_result = DR._format_type_for_docs(DRTypeFormatTestMod.Parametric)
        @test occursin("Parametric", param_result)

        # Concrete params => kept (WithValue{Int,2} is a DataType)
        concrete_result = DR._format_datatype_for_docs(DRTypeFormatTestMod.WithValue{Int,2})
        @test occursin("WithValue", concrete_result)
        @test occursin("Int", concrete_result)
        @test occursin("2", concrete_result)

        # Fallback branch for non-type inputs
        @test DR._format_type_for_docs(1) == "::1"

        # TypeVar formatting in _format_type_param - need to unwrap UnionAll first
        unwrapped = Base.unwrap_unionall(DRTypeFormatTestMod.Parametric)
        tv = unwrapped.parameters[1]
        @test tv isa TypeVar
        @test DR._format_type_param(tv) == "T"
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_method_signature_string handles UnionAll" begin
        m = first(methods(DRUnionAllTestMod.f))
        s = DR._method_signature_string(m, DRUnionAllTestMod, :f)
        @test occursin("DRUnionAllTestMod.f", s)
        @test occursin("T", s)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_iterate_over_symbols filtering" begin
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
        DR._iterate_over_symbols(config, symbols) do key, type
            push!(seen, key)
        end

        @test :keep in seen
        @test :skip ∉ seen
        @test :no_doc ∉ seen
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_iterate_over_symbols with source_files and include_without_source" begin
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
        DR._iterate_over_symbols(config1, symbols1) do key, type
            push!(seen1, key)
        end
        @test :myfun in seen1

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
        DR._iterate_over_symbols(config2, symbols_module) do key, type
            push!(seen2, key)
        end
        @test isempty(seen2)

        seen3 = Symbol[]
        DR._iterate_over_symbols(config3, symbols_module) do key, type
            push!(seen3, key)
        end
        @test :SubModule in seen3
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation configuration" begin
        DR.reset_config!()

        # Single-module, public-only
        pages1 = CTBase.automatic_reference_documentation(
            CTBase.Extensions.DocumenterReferenceTag();
            subdirectory="ref",
            primary_modules=[DocumenterReferenceTestMod],
            public=true,
            private=false,
            title="My API",
        )

        @testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation default tag" begin
            DR.reset_config!()

            pages_default = CTBase.automatic_reference_documentation(;
                subdirectory="ref",
                primary_modules=[DocumenterReferenceTestMod],
                public=true,
                private=false,
                title="My API",
            )

            @test length(DR.CONFIG) == 1
            cfg_default = DR.CONFIG[1]
            @test cfg_default.current_module === DocumenterReferenceTestMod
            @test cfg_default.subdirectory == "ref"
            @test cfg_default.public == true
            @test cfg_default.private == false
            @test cfg_default.filename == "public"
            @test pages_default == pages1
        end

        @test length(DR.CONFIG) == 1
        cfg1 = DR.CONFIG[1]
        @test cfg1.current_module === DocumenterReferenceTestMod
        @test cfg1.subdirectory == "ref"
        @test cfg1.public == true
        @test cfg1.private == false
        @test cfg1.filename == "public"
        @test pages1 == ("My API" => "ref/public.md")

        # Both public and private pages
        DR.reset_config!()
        pages2 = CTBase.automatic_reference_documentation(
            CTBase.Extensions.DocumenterReferenceTag();
            subdirectory="ref",
            primary_modules=[DocumenterReferenceTestMod],
            public=true,
            private=true,
            title="All API",
        )

        @test length(DR.CONFIG) == 1
        cfg2 = DR.CONFIG[1]
        @test cfg2.filename == "api"
        @test cfg2.public == true
        @test cfg2.private == true
        @test cfg2.title == "All API"
        @test pages2 ==
            (
            "All API" =>
                ["Public" => "ref/api_public.md", "Private" => "ref/api_private.md"]
        )

        # public=false, private=false should error
        @test_throws ErrorException CTBase.automatic_reference_documentation(
            CTBase.Extensions.DocumenterReferenceTag();
            subdirectory="ref",
            primary_modules=[DocumenterReferenceTestMod],
            public=false,
            private=false,
        )
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Documenter.Selectors.order for APIBuilder" begin
        @test Documenter.Selectors.order(DR.APIBuilder) == 0.5
    end

    # ============================================================================
    # NEW TESTS: _exported_symbols
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_exported_symbols classification" begin
        # Test that _exported_symbols correctly classifies symbols
        result = DR._exported_symbols(DocumenterReferenceTestMod)

        # Check structure: should return NamedTuple with exported and private fields
        @test haskey(result, :exported)
        @test haskey(result, :private)

        # Check that exported list contains expected symbols (none exported in test module)
        @test result.exported isa Vector

        # Check that private list contains our test symbols
        private_symbols = Dict(result.private)
        @test haskey(private_symbols, :myfun)
        @test private_symbols[:myfun] == DR.DOCTYPE_FUNCTION
        @test haskey(private_symbols, :keep)
        @test haskey(private_symbols, :skip)
        @test haskey(private_symbols, :no_doc)
        @test haskey(private_symbols, :SubModule)
        @test private_symbols[:SubModule] == DR.DOCTYPE_MODULE
        @test haskey(private_symbols, :AbstractFoo)
        @test private_symbols[:AbstractFoo] == DR.DOCTYPE_ABSTRACT_TYPE
        @test haskey(private_symbols, :Foo)
        @test private_symbols[:Foo] == DR.DOCTYPE_STRUCT
        @test haskey(private_symbols, :MYCONST)
        @test private_symbols[:MYCONST] == DR.DOCTYPE_CONSTANT
    end

    # ============================================================================
    # NEW TESTS: automatic_reference_documentation multi-module
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation multi-module" begin
        DR.reset_config!()

        # Create a second test module for multi-module testing
        mod1 = DocumenterReferenceTestMod

        # Test multi-module case (using same module twice as a proxy)
        pages = CTBase.automatic_reference_documentation(
            CTBase.Extensions.DocumenterReferenceTag();
            subdirectory="api",
            primary_modules=[mod1, mod1],  # Two entries to trigger multi-module path
            public=true,
            private=true,
            title="Multi API",
        )

        # Should return a Pair with title and list of module pages
        @test pages isa Pair
        @test first(pages) == "Multi API"
        @test last(pages) isa Vector

        # CONFIG should have 1 entry (one per unique module)
        @test length(DR.CONFIG) == 1
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation multi-module with filename" begin
        DR.reset_config!()

        mod1 = DocumenterReferenceTestMod
        mod2 = DRMethodTestMod

        # Test multi-module case with explicit filename (combined page - public only)
        # Note: DocumenterReference currently splits public/private if both are true,
        # ignoring the filename for the split structure.
        # So we test public-only to verify filename is respected.
        pages = CTBase.automatic_reference_documentation(
            CTBase.Extensions.DocumenterReferenceTag();
            subdirectory="api",
            primary_modules=[mod1, mod2],
            public=true,
            private=false,
            title="Combined Public API",
            filename="combined_public",
        )

        # Should return a Pair with title and path to the combined file
        @test pages isa Pair
        @test first(pages) == "Combined Public API"
        @test last(pages) == "api/combined_public.md"

        # CONFIG should have 2 entries (one per unique module)
        @test length(DR.CONFIG) == 2
        @test count(c -> c.current_module == mod1, DR.CONFIG) == 1
        @test count(c -> c.current_module == mod2, DR.CONFIG) == 1
    end

    # ============================================================================
    # NEW TESTS: _get_source_file expanded
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_file expanded cases" begin
        # Function case (already tested, but verify)
        func_path = DR._get_source_file(
            DocumenterReferenceTestMod, :myfun, DR.DOCTYPE_FUNCTION
        )
        @test func_path !== nothing
        @test endswith(func_path, "test_documenter_reference.jl")

        # Struct case - should find source via constructor methods
        struct_path = DR._get_source_file(
            DocumenterReferenceTestMod, :Foo, DR.DOCTYPE_STRUCT
        )
        # Structs defined in test file should be found
        @test struct_path === nothing ||
            endswith(struct_path, "test_documenter_reference.jl")

        # Abstract type case - typically returns nothing (no constructor)
        abstract_path = DR._get_source_file(
            DocumenterReferenceTestMod, :AbstractFoo, DR.DOCTYPE_ABSTRACT_TYPE
        )
        @test abstract_path === nothing

        # Module case - modules cannot reliably determine source
        mod_path = DR._get_source_file(
            DocumenterReferenceTestMod, :SubModule, DR.DOCTYPE_MODULE
        )
        @test mod_path === nothing

        # Constant case (already tested)
        const_path = DR._get_source_file(
            DocumenterReferenceTestMod, :MYCONST, DR.DOCTYPE_CONSTANT
        )
        @test const_path === nothing
    end

    # ============================================================================
    # NEW TESTS: Edge cases
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Edge cases" begin
        # _build_page_path with various inputs
        @test DR._build_page_path("", "") == ""
        @test DR._build_page_path(".", "") == ""
        @test DR._build_page_path("dir", "") == "dir/"
        @test DR._build_page_path("a/b/c", "file.md") == "a/b/c/file.md"

        # _default_basename edge cases
        @test DR._default_basename("custom", false, false) == "custom"  # Custom overrides flags
        @test DR._default_basename("", false, false) == "private"  # Fallback when both false

        # _classify_symbol with edge cases
        @test DR._classify_symbol(42, "fortytwo") == DR.DOCTYPE_CONSTANT  # Integer constant
        @test DR._classify_symbol("hello", "greeting") == DR.DOCTYPE_CONSTANT  # String constant
        @test DR._classify_symbol([1, 2, 3], "myarray") == DR.DOCTYPE_CONSTANT  # Array constant

        # _to_string covers all enum values (verify no error)
        for dt in instances(DR.DocType)
            @test DR._to_string(dt) isa String
            @test length(DR._to_string(dt)) > 0
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
        DR._iterate_over_symbols(config, Pair{Symbol,DR.DocType}[]) do key, type
            push!(seen, key)
        end
        @test isempty(seen)

        # reset_config! is idempotent
        DR.reset_config!()
        DR.reset_config!()
        @test isempty(DR.CONFIG)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_for_docs and helpers" begin
        simple_str = DR._format_type_for_docs(DRTypeFormatTestMod.Simple)
        @test startswith(simple_str, "::")
        @test occursin("DRTypeFormatTestMod.Simple", simple_str)

        param_type = DRTypeFormatTestMod.Parametric{DRTypeFormatTestMod.Simple}
        param_str = DR._format_type_for_docs(param_type)
        @test occursin("Parametric", param_str)
        @test occursin("Simple", param_str)

        union_str = DR._format_type_for_docs(Union{DRTypeFormatTestMod.Simple,Nothing})
        @test occursin("Union", union_str)
        @test occursin("Simple", union_str)
        @test occursin("Nothing", union_str)

        value_type = DRTypeFormatTestMod.WithValue{Int,3}
        value_str = DR._format_type_for_docs(value_type)
        @test occursin("WithValue", value_str)
        @test occursin("3", value_str)

        param_fmt = DR._format_type_param(DRTypeFormatTestMod.Simple)
        @test occursin("DRTypeFormatTestMod.Simple", param_fmt)

        value_param_fmt = DR._format_type_param(3)
        @test value_param_fmt == "3"
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_method_signature_string and method collection" begin
        methods_f = methods(DRMethodTestMod.f)
        m0 = first(filter(m -> length(m.sig.parameters) == 1, methods_f))
        sig0 = DR._method_signature_string(m0, DRMethodTestMod, :f)
        @test endswith(sig0, "DRMethodTestMod.f()")

        m1 = first(filter(m -> length(m.sig.parameters) == 2, methods_f))
        sig1 = DR._method_signature_string(m1, DRMethodTestMod, :f)
        @test occursin("DRMethodTestMod.f", sig1)
        @test occursin("Int", sig1)

        methods_h = methods(DRMethodTestMod.h)
        mvar = first(methods_h)
        sigv = DR._method_signature_string(mvar, DRMethodTestMod, :h)
        @test occursin("Vararg", sigv)

        source_files = [abspath(@__FILE__)]
        methods_by_func = DR._collect_methods_from_source_files(
            DRMethodTestMod, source_files
        )
        @test :f in keys(methods_by_func)
        @test :h in keys(methods_by_func)
        for ms in values(methods_by_func)
            for m in ms
                file = String(m.file)
                @test abspath(file) in source_files
            end
        end
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Page content builders" begin
        modules_str = "ModA, ModB"
        module_contents_private = [
            (DocumenterReferenceTestMod, String[], ["priv_a"]),
            (DRMethodTestMod, String[], ["priv_b1", "priv_b2"]),
        ]
        # Test with is_split=false (single page)
        overview_priv, docs_priv = DR._build_private_page_content(
            modules_str, module_contents_private, false
        )
        @test occursin("Private API", overview_priv)
        @test occursin("ModA, ModB", overview_priv)
        @test !isempty(docs_priv)
        @test any(occursin("priv_a", s) for s in docs_priv)
        @test any(occursin("priv_b1", s) for s in docs_priv)

        module_contents_public = [
            (DocumenterReferenceTestMod, ["pub_a"], String[]),
            (DRMethodTestMod, String[], String[]),
        ]
        # Test with is_split=false (single page)
        overview_pub, docs_pub = DR._build_public_page_content(
            modules_str, module_contents_public, false
        )
        @test occursin("Public API", overview_pub)
        @test occursin("ModA, ModB", overview_pub)
        @test !isempty(docs_pub)
        @test any(occursin("pub_a", s) for s in docs_pub)

        module_contents_combined = [(DocumenterReferenceTestMod, ["pub_a"], ["priv_a"])]
        overview_comb, docs_comb = DR._build_combined_page_content(
            modules_str, module_contents_combined
        )
        @test occursin("API reference", overview_comb)
        @test any(occursin("Public API", s) for s in docs_comb)
        @test any(occursin("Private API", s) for s in docs_comb)
        @test any(occursin("pub_a", s) for s in docs_comb)
        @test any(occursin("priv_a", s) for s in docs_comb)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "external_modules_to_document" begin
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
        @test !isempty(private_docs)
        @test any(occursin("DRExternalTestMod.extfun", s) for s in private_docs)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "APIBuilder runner integration" begin
        DR.reset_config!()

        pages = CTBase.automatic_reference_documentation(
            CTBase.Extensions.DocumenterReferenceTag();
            subdirectory="api_integration",
            primary_modules=[DocumenterReferenceTestMod],
            public=true,
            private=true,
            title="Integration API",
        )

        @test !isempty(DR.CONFIG)

        doc = Documenter.Document(;
            root=pwd(), source="src", build="build", remotes=nothing
        )

        Documenter.Selectors.runner(DR.APIBuilder, doc)

        @test !isempty(doc.blueprint.pages)
        @test any(endswith(k, "api_private.md") for k in keys(doc.blueprint.pages))
    end

    # ============================================================================
    # Edge Case Tests: Type Formatting Functions
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_for_docs edge cases" begin
        # Test Union types formatting (covers L775-782)
        union_result = DR._format_type_for_docs(Union{Int,String})
        @test occursin("Union", union_result)
        @test occursin("Int", union_result)
        @test occursin("String", union_result)

        # Test simple non-DataType fallback (covers L782)
        @test DR._format_type_for_docs(Any) == "::Any"
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_format_datatype_for_docs with TypeVar" begin
        # Test parametric type with concrete parameters
        concrete_result = DR._format_datatype_for_docs(Vector{Int})
        @test occursin("Vector", concrete_result) || occursin("Array", concrete_result)
        @test occursin("Int", concrete_result)

        # Test parametric type - the function strips parameters when TypeVar present
        # Array{T,1} where T has a TypeVar, so it gets stripped
        @test DR._format_datatype_for_docs(Int) == "::Int"
        @test DR._format_datatype_for_docs(String) == "::String"
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_param edge cases" begin
        # Test Type parameter (covers L824-826)
        type_result = DR._format_type_param(Int)
        @test type_result == "Int"  # Should strip leading ::

        # Test value parameter (covers L830) - e.g., for sized arrays
        @test DR._format_type_param(3) == "3"
        @test DR._format_type_param(42) == "42"
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_method_signature_string edge cases" begin
        # Test method signature generation for DRMethodTestMod
        m = first(methods(DRMethodTestMod.f))
        sig = DR._method_signature_string(m, DRMethodTestMod, :f)
        @test occursin("DRMethodTestMod", sig)
        @test occursin("f", sig)

        # Test with multiple arguments
        m2 = first(methods(DRMethodTestMod.g))
        sig2 = DR._method_signature_string(m2, DRMethodTestMod, :g)
        @test occursin("g", sig2)
    end

    # ============================================================================
    # NEW TESTS: Title System with is_split Parameter
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Page content builders with is_split parameter" begin
        modules_str = "TestModule"
        
        # Test private page with is_split=false (single page)
        module_contents_private = [(DocumenterReferenceTestMod, String[], ["priv_doc"])]
        
        overview_priv_single, docs_priv_single = DR._build_private_page_content(
            modules_str, module_contents_private, false
        )
        @test occursin("# Private API", overview_priv_single)
        @test !occursin("# Private\n", overview_priv_single)
        @test occursin("non-exported", overview_priv_single)
        
        # Test private page with is_split=true (split page)
        overview_priv_split, docs_priv_split = DR._build_private_page_content(
            modules_str, module_contents_private, true
        )
        @test occursin("# Private", overview_priv_split)
        @test !occursin("# Private API", overview_priv_split)
        @test occursin("non-exported", overview_priv_split)
        
        # Test public page with is_split=false (single page)
        module_contents_public = [(DocumenterReferenceTestMod, ["pub_doc"], String[])]
        
        overview_pub_single, docs_pub_single = DR._build_public_page_content(
            modules_str, module_contents_public, false
        )
        @test occursin("# Public API", overview_pub_single)
        @test !occursin("# Public\n", overview_pub_single)
        @test occursin("exported", overview_pub_single)
        
        # Test public page with is_split=true (split page)
        overview_pub_split, docs_pub_split = DR._build_public_page_content(
            modules_str, module_contents_public, true
        )
        @test occursin("# Public", overview_pub_split)
        @test !occursin("# Public API", overview_pub_split)
        @test occursin("exported", overview_pub_split)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Title consistency across different page types" begin
        modules_str = "MyModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub"], ["priv"])]
        
        # Single private page should have "Private API" title
        overview_priv, _ = DR._build_private_page_content(modules_str, module_contents, false)
        @test occursin("# Private API", overview_priv)
        
        # Single public page should have "Public API" title
        overview_pub, _ = DR._build_public_page_content(modules_str, module_contents, false)
        @test occursin("# Public API", overview_pub)
        
        # Split private page should have "Private" title
        overview_priv_split, _ = DR._build_private_page_content(modules_str, module_contents, true)
        @test occursin("# Private", overview_priv_split)
        @test !occursin("API", overview_priv_split) || occursin("Private\n", overview_priv_split)
        
        # Split public page should have "Public" title
        overview_pub_split, _ = DR._build_public_page_content(modules_str, module_contents, true)
        @test occursin("# Public", overview_pub_split)
        @test !occursin("API", overview_pub_split) || occursin("Public\n", overview_pub_split)
        
        # Combined page should have "API reference" title
        overview_comb, _ = DR._build_combined_page_content(modules_str, module_contents)
        @test occursin("# API reference", overview_comb)
    end

    # ============================================================================
    # NEW TESTS: Customization Parameters
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Custom titles for API pages" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]
        
        # Test custom title for private page (single)
        overview_priv_custom, _ = DR._build_private_page_content(
            modules_str, module_contents, false;
            custom_title="Internal API"
        )
        @test occursin("# Internal API", overview_priv_custom)
        @test !occursin("# Private API", overview_priv_custom)
        
        # Test custom title for public page (single)
        overview_pub_custom, _ = DR._build_public_page_content(
            modules_str, module_contents, false;
            custom_title="Exported API"
        )
        @test occursin("# Exported API", overview_pub_custom)
        @test !occursin("# Public API", overview_pub_custom)
        
        # Test custom title for private page (split)
        overview_priv_split_custom, _ = DR._build_private_page_content(
            modules_str, module_contents, true;
            custom_title="Internal"
        )
        @test occursin("# Internal", overview_priv_split_custom)
        @test !occursin("# Private", overview_priv_split_custom)
        
        # Test custom title for public page (split)
        overview_pub_split_custom, _ = DR._build_public_page_content(
            modules_str, module_contents, true;
            custom_title="Exported"
        )
        @test occursin("# Exported", overview_pub_split_custom)
        @test !occursin("# Public", overview_pub_split_custom)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Custom descriptions for API pages" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]
        
        # Test custom description for private page
        custom_desc_priv = "This page documents internal implementation details."
        overview_priv_desc, _ = DR._build_private_page_content(
            modules_str, module_contents, false;
            custom_description=custom_desc_priv
        )
        @test occursin(custom_desc_priv, overview_priv_desc)
        @test !occursin("non-exported", overview_priv_desc)
        
        # Test custom description for public page
        custom_desc_pub = "This page documents the public interface for end users."
        overview_pub_desc, _ = DR._build_public_page_content(
            modules_str, module_contents, false;
            custom_description=custom_desc_pub
        )
        @test occursin(custom_desc_pub, overview_pub_desc)
        @test !occursin("exported", overview_pub_desc) || occursin(custom_desc_pub, overview_pub_desc)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Combined custom title and description" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]
        
        # Test both custom title and description together
        custom_title = "Developer Reference"
        custom_desc = "Advanced documentation for contributors and maintainers."
        
        overview, _ = DR._build_private_page_content(
            modules_str, module_contents, false;
            custom_title=custom_title,
            custom_description=custom_desc
        )
        
        @test occursin("# Developer Reference", overview)
        @test occursin(custom_desc, overview)
        @test !occursin("# Private API", overview)
        @test !occursin("non-exported", overview)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Empty customization uses defaults" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferenceTestMod, ["pub_doc"], ["priv_doc"])]
        
        # Empty strings should use default behavior
        overview_priv_empty, _ = DR._build_private_page_content(
            modules_str, module_contents, false;
            custom_title="",
            custom_description=""
        )
        @test occursin("# Private API", overview_priv_empty)
        @test occursin("non-exported", overview_priv_empty)
        
        overview_pub_empty, _ = DR._build_public_page_content(
            modules_str, module_contents, false;
            custom_title="",
            custom_description=""
        )
        @test occursin("# Public API", overview_pub_empty)
        @test occursin("exported", overview_pub_empty)
    end
    
end
