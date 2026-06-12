module TestDocumenterReferenceSymbolHelpers

using Test: Test
using CTBase: CTBase
using Documenter: Documenter

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Test module for symbol helpers
module DocumenterReferenceSymbolTestMod
    """
    Simple documented function.
    """
    myfun(x) = x

    """
    Function to keep.
    """
    keep(x) = x

    """
    Function to skip.
    """
    skip(x) = x

    # No docstring
    no_doc(x) = x

    """
    Test submodule.
    """
    module SubModule end

    abstract type AbstractFoo end

    struct Foo <: AbstractFoo
        x::Int
    end

    const MYCONST = 42
end
using .DocumenterReferenceSymbolTestMod

module DRNoDocModule
    module Inner end
end

function test_documenter_reference_symbol_helpers()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_classify_symbol" begin
        Test.@test DR._classify_symbol(nothing, "@mymacro") == DR.DOCTYPE_MACRO
        Test.@test DR._classify_symbol(
            DocumenterReferenceSymbolTestMod.SubModule, "SubModule"
        ) == DR.DOCTYPE_MODULE
        Test.@test DR._classify_symbol(
            DocumenterReferenceSymbolTestMod.AbstractFoo, "AbstractFoo"
        ) == DR.DOCTYPE_ABSTRACT_TYPE
        Test.@test DR._classify_symbol(DocumenterReferenceSymbolTestMod.Foo, "Foo") ==
            DR.DOCTYPE_STRUCT
        Test.@test DR._classify_symbol(DocumenterReferenceSymbolTestMod.myfun, "myfun") ==
            DR.DOCTYPE_FUNCTION
        Test.@test DR._classify_symbol(
            DocumenterReferenceSymbolTestMod.MYCONST, "MYCONST"
        ) == DR.DOCTYPE_CONSTANT
        Test.@test DR._classify_symbol(42, "fortytwo") == DR.DOCTYPE_CONSTANT
        Test.@test DR._classify_symbol("hello", "greeting") == DR.DOCTYPE_CONSTANT
        Test.@test DR._classify_symbol([1, 2, 3], "myarray") == DR.DOCTYPE_CONSTANT
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_to_string" begin
        Test.@test DR._to_string(DR.DOCTYPE_ABSTRACT_TYPE) == "abstract type"
        Test.@test DR._to_string(DR.DOCTYPE_CONSTANT) == "constant"
        Test.@test DR._to_string(DR.DOCTYPE_FUNCTION) == "function"
        Test.@test DR._to_string(DR.DOCTYPE_MACRO) == "macro"
        Test.@test DR._to_string(DR.DOCTYPE_MODULE) == "module"
        Test.@test DR._to_string(DR.DOCTYPE_STRUCT) == "struct"

        # Verify all enum values have string representations
        for dt in instances(DR.DocType)
            Test.@test DR._to_string(dt) isa String
            Test.@test length(DR._to_string(dt)) > 0
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_file" begin
        path = DR._get_source_file(
            DocumenterReferenceSymbolTestMod, :myfun, DR.DOCTYPE_FUNCTION
        )
        Test.@test path === abspath(@__FILE__)

        # No docstring => should use method-based resolution
        path2 = DR._get_source_file(
            DocumenterReferenceSymbolTestMod, :no_doc, DR.DOCTYPE_FUNCTION
        )
        Test.@test path2 === abspath(@__FILE__)

        # Missing symbol should be caught and return nothing
        missing_path = DR._get_source_file(
            DocumenterReferenceSymbolTestMod, :__does_not_exist__, DR.DOCTYPE_FUNCTION
        )
        Test.@test missing_path === nothing

        const_path = DR._get_source_file(
            DocumenterReferenceSymbolTestMod, :MYCONST, DR.DOCTYPE_CONSTANT
        )
        Test.@test const_path === nothing

        # Struct case - should find source via constructor methods
        struct_path = DR._get_source_file(
            DocumenterReferenceSymbolTestMod, :Foo, DR.DOCTYPE_STRUCT
        )
        Test.@test struct_path === nothing ||
            endswith(struct_path, "test_documenter_reference_symbol_helpers.jl")

        # Abstract type case - typically returns nothing
        abstract_path = DR._get_source_file(
            DocumenterReferenceSymbolTestMod, :AbstractFoo, DR.DOCTYPE_ABSTRACT_TYPE
        )
        Test.@test abstract_path === nothing

        # Module case - modules cannot reliably determine source
        mod_path = DR._get_source_file(
            DocumenterReferenceSymbolTestMod, :SubModule, DR.DOCTYPE_MODULE
        )
        Test.@test mod_path === nothing
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_get_source_from_methods" begin
        # For built-in operators like +, source detection behavior may vary by Julia version.
        # We just verify the function runs without error and returns String or nothing.
        result = DR._get_source_from_methods(+)
        Test.@test result === nothing || result isa String
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_has_documentation" begin
        modules = Dict(DRNoDocModule.Inner => Any[])
        Test.@test DR._has_documentation(
            DRNoDocModule, :Inner, DR.DOCTYPE_MODULE, modules
        ) == true
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_iterate_over_symbols filtering" begin
        current_module = DocumenterReferenceSymbolTestMod
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_iterate_over_symbols with empty list" begin
        config = DR._Config(
            DocumenterReferenceSymbolTestMod,
            "api",
            Dict(DocumenterReferenceSymbolTestMod => Any[]),
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
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_exported_symbols classification" begin
        result = DR._exported_symbols(DocumenterReferenceSymbolTestMod)

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

    return nothing
end

end # module

function test_documenter_reference_symbol_helpers()
    return TestDocumenterReferenceSymbolHelpers.test_documenter_reference_symbol_helpers()
end
