module TestExtensionError

using Test: Test
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_extension_error()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ExtensionError Contract Implementation" begin
        # Test constructor throws if no dependencies provided
        Test.@test_throws Exceptions.PreconditionError Exceptions.ExtensionError()

        # Test enriched ExtensionError creation
        e = Exceptions.ExtensionError(
            :Documenter,
            :Markdown;
            message="to generate documentation",
            feature="automatic documentation",
            context="reference generation",
        )

        Test.@test e isa Exceptions.ExtensionError
        Test.@test e.weakdeps == (:Documenter, :Markdown)
        Test.@test e.msg == "missing dependencies to generate documentation"
        Test.@test e.feature == "automatic documentation"
        Test.@test e.context == "reference generation"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ExtensionError Constructor Validation" begin
        Test.@testset "No dependencies provided" begin
            Test.@test_throws Exceptions.PreconditionError Exceptions.ExtensionError()

            try
                Exceptions.ExtensionError()
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.PreconditionError
                Test.@test occursin("weak dependence", e.msg)
                Test.@test occursin("ExtensionError called without dependencies", e.reason)
            end
        end

        Test.@testset "Single dependency" begin
            e = Exceptions.ExtensionError(:MyExt)
            Test.@test e isa Exceptions.ExtensionError
            Test.@test e.weakdeps == (:MyExt,)
            Test.@test e.msg == "missing dependencies"
        end

        Test.@testset "Multiple dependencies with message" begin
            e = Exceptions.ExtensionError(:Ext1, :Ext2; message="to enable feature X")
            Test.@test e isa Exceptions.ExtensionError
            Test.@test e.weakdeps == (:Ext1, :Ext2)
            Test.@test e.msg == "missing dependencies to enable feature X"
        end
    end

    return nothing
end

end # module

test_extension_error() = TestExtensionError.test_extension_error()
