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
            ("All API" => ["Public" => "ref/public.md", "Private" => "ref/private.md"])

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
        @test Documenter.Selectors.order(DR.APIBuilder) == 0.0
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
        overview_priv, docs_priv = DR._build_private_page_content(
            modules_str, module_contents_private
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
        overview_pub, docs_pub = DR._build_public_page_content(
            modules_str, module_contents_public
        )
        @test occursin("Public API", overview_pub)
        @test occursin("ModA, ModB", overview_pub)
        @test !isempty(docs_pub)
        @test any(occursin("pub_a", s) for s in docs_pub)
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
        @test any(endswith(k, "private.md") for k in keys(doc.blueprint.pages))
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
end
