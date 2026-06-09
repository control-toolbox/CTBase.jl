module TestDocumenterReferenceTypes

import Test
import CTBase
import Documenter

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_documenter_reference_types()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "DocType enum" begin
        # Test that all enum values are valid
        for dt in instances(DR.DocType)
            Test.@test dt isa DR.DocType
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "DOCTYPE_NAMES" begin
        Test.@test haskey(DR.DOCTYPE_NAMES, DR.DOCTYPE_MACRO)
        Test.@test haskey(DR.DOCTYPE_NAMES, DR.DOCTYPE_MODULE)
        Test.@test haskey(DR.DOCTYPE_NAMES, DR.DOCTYPE_ABSTRACT_TYPE)
        Test.@test haskey(DR.DOCTYPE_NAMES, DR.DOCTYPE_STRUCT)
        Test.@test haskey(DR.DOCTYPE_NAMES, DR.DOCTYPE_FUNCTION)
        Test.@test haskey(DR.DOCTYPE_NAMES, DR.DOCTYPE_CONSTANT)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "DOCTYPE_ORDER" begin
        Test.@test DR.DOCTYPE_ORDER isa Dict{DR.DocType, Int}
        Test.@test length(DR.DOCTYPE_ORDER) > 0
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_Config struct" begin
        config = DR._Config(
            Main,
            "api",
            Dict(Main => Any[]),
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
        Test.@test config.current_module === Main
        Test.@test config.subdirectory == "api"
        Test.@test config.public == true
        Test.@test config.private == true
    end

    return nothing
end

end # module

test_documenter_reference_types() = TestDocumenterReferenceTypes.test_documenter_reference_types()
