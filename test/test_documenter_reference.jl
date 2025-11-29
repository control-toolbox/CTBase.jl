using Test
using CTBase
using Documenter

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
    module SubModule
    end

    abstract type AbstractFoo end

    struct Foo <: AbstractFoo
        x::Int
    end

    const MYCONST = 42

end

function test_documenter_reference()
    DR = DocumenterReference

    @testset "reset_config! clears CONFIG" begin
        DR.reset_config!()
        @test isempty(DR.CONFIG)
    end

    @testset "_default_basename and _build_page_path" begin
        @test DR._default_basename("manual", true, true) == "manual"
        @test DR._default_basename("", true, true) == "api"
        @test DR._default_basename("", true, false) == "public"
        @test DR._default_basename("", false, true) == "private"

        @test DR._build_page_path("api", "public") == "api/public"
        @test DR._build_page_path(".", "public") == "public"
        @test DR._build_page_path("", "public") == "public"
    end

    @testset "_classify_symbol and _to_string" begin
        using .DocumenterReferenceTestMod

        @test DR._classify_symbol(nothing, "@mymacro") == DR.DOCTYPE_MACRO
        @test DR._classify_symbol(DocumenterReferenceTestMod.SubModule, "SubModule") == DR.DOCTYPE_MODULE
        @test DR._classify_symbol(DocumenterReferenceTestMod.AbstractFoo, "AbstractFoo") == DR.DOCTYPE_ABSTRACT_TYPE
        @test DR._classify_symbol(DocumenterReferenceTestMod.Foo, "Foo") == DR.DOCTYPE_STRUCT
        @test DR._classify_symbol(DocumenterReferenceTestMod.myfun, "myfun") == DR.DOCTYPE_FUNCTION
        @test DR._classify_symbol(DocumenterReferenceTestMod.MYCONST, "MYCONST") == DR.DOCTYPE_CONSTANT

        @test DR._to_string(DR.DOCTYPE_ABSTRACT_TYPE) == "abstract type"
        @test DR._to_string(DR.DOCTYPE_CONSTANT) == "constant"
        @test DR._to_string(DR.DOCTYPE_FUNCTION) == "function"
        @test DR._to_string(DR.DOCTYPE_MACRO) == "macro"
        @test DR._to_string(DR.DOCTYPE_MODULE) == "module"
        @test DR._to_string(DR.DOCTYPE_STRUCT) == "struct"
    end

    @testset "_get_source_file" begin
        using .DocumenterReferenceTestMod

        path = DR._get_source_file(DocumenterReferenceTestMod, :myfun, DR.DOCTYPE_FUNCTION)
        @test path === abspath(@__FILE__)

        const_path = DR._get_source_file(DocumenterReferenceTestMod, :MYCONST, DR.DOCTYPE_CONSTANT)
        @test const_path === nothing
    end

    @testset "_iterate_over_symbols filtering" begin
        using .DocumenterReferenceTestMod

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

    @testset "_iterate_over_symbols with source_files and include_without_source" begin
        using .DocumenterReferenceTestMod

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

        symbols1 = [
            :myfun => DR.DOCTYPE_FUNCTION,
        ]

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

        symbols_module = [
            :SubModule => DR.DOCTYPE_MODULE,
        ]

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

    @testset "automatic_reference_documentation configuration" begin
        DR.reset_config!()
        using .DocumenterReferenceTestMod

        # Single-module, public-only
        pages1 = CTBase.automatic_reference_documentation(
            CTBase.DocumenterReferenceTag();
            subdirectory="ref",
            modules=[DocumenterReferenceTestMod],
            public=true,
            private=false,
            title="My API",
        )

        @test length(DR.CONFIG) == 1
        cfg1 = DR.CONFIG[1]
        @test cfg1.current_module === DocumenterReferenceTestMod
        @test cfg1.subdirectory == "ref"
        @test cfg1.public == true
        @test cfg1.private == false
        @test cfg1.filename == "public"
        @test pages1 == "My API" => "ref/public.md"

        # Both public and private pages
        DR.reset_config!()
        pages2 = CTBase.automatic_reference_documentation(
            CTBase.DocumenterReferenceTag();
            subdirectory="ref",
            modules=[DocumenterReferenceTestMod],
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
        @test first(pages2) == "All API" => [
            "Public" => "ref/public.md",
            "Private" => "ref/private.md",
        ]

        # public=false, private=false should error
        @test_throws ErrorException CTBase.automatic_reference_documentation(
            CTBase.DocumenterReferenceTag();
            subdirectory="ref",
            modules=[DocumenterReferenceTestMod],
            public=false,
            private=false,
        )
    end

    @testset "Documenter.Selectors.order for APIBuilder" begin
        @test Documenter.Selectors.order(DR.APIBuilder) == 0.0
    end
end