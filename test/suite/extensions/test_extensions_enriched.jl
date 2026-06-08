module TestExtensionsEnriched

import Test
import CTBase.Extensions
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Fake tag types for extension stub testing (testing-creation.md §6).
# These subtype the abstract tags but are unknown to any extension,
# so the stubs always throw ExtensionError regardless of which extensions are loaded.
struct FakeDocumenterReferenceTag <: Extensions.AbstractDocumenterReferenceTag end
struct FakeCoveragePostprocessingTag <: Extensions.AbstractCoveragePostprocessingTag end
struct FakeTestRunnerTag <: Extensions.AbstractTestRunnerTag end

function test_extensions_enriched()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Enriched Extension Errors" begin

        # ====================================================================
        # UNIT TESTS - Extension Error Contract
        # ====================================================================

        Test.@testset "ExtensionError Contract Implementation" begin
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

        # ====================================================================
        # INTEGRATION TESTS - Extension Functions
        # ====================================================================

        Test.@testset "Extension Function Error Handling" begin
            # Test automatic_reference_documentation error
            Test.@testset "automatic_reference_documentation" begin
                Test.@test_throws Exceptions.ExtensionError Extensions.automatic_reference_documentation(
                    FakeDocumenterReferenceTag()
                )
            end

            # Test postprocess_coverage error
            Test.@testset "postprocess_coverage" begin
                Test.@test_throws Exceptions.ExtensionError Extensions.postprocess_coverage(
                    FakeCoveragePostprocessingTag()
                )
            end

            # Test run_tests error
            Test.@testset "run_tests" begin
                Test.@test_throws Exceptions.ExtensionError Extensions.run_tests(FakeTestRunnerTag())
            end
        end

        # ====================================================================
        # ERROR TESTS - Exception Quality
        # ====================================================================

        Test.@testset "ExtensionError Constructor Validation" begin
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
    end

    return nothing
end

end # module

# Export to outer scope for TestRunner
test_extensions_enriched() = TestExtensionsEnriched.test_extensions_enriched()
