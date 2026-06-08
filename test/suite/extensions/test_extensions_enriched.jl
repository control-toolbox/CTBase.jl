module TestExtensionsEnriched

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

# Fake tag types for extension stub testing (testing-creation.md §6).
# These subtype the abstract tags but are unknown to any extension,
# so the stubs always throw ExtensionError regardless of which extensions are loaded.
struct FakeDocumenterReferenceTag <: CTBase.AbstractDocumenterReferenceTag end
struct FakeCoveragePostprocessingTag <: CTBase.AbstractCoveragePostprocessingTag end
struct FakeTestRunnerTag <: CTBase.AbstractTestRunnerTag end

function test_extensions_enriched()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Enriched Extension Errors" begin

        # ====================================================================
        # UNIT TESTS - Extension Error Contract
        # ====================================================================

        @testset "ExtensionError Contract Implementation" begin
            # Test constructor throws if no dependencies provided
            @test_throws CTBase.PreconditionError CTBase.ExtensionError()

            # Test enriched ExtensionError creation
            e = CTBase.ExtensionError(
                :Documenter,
                :Markdown;
                message="to generate documentation",
                feature="automatic documentation",
                context="reference generation",
            )

            @test e isa CTBase.ExtensionError
            @test e.weakdeps == (:Documenter, :Markdown)
            @test e.msg == "missing dependencies to generate documentation"
            @test e.feature == "automatic documentation"
            @test e.context == "reference generation"
        end

        # ====================================================================
        # INTEGRATION TESTS - Extension Functions
        # ====================================================================

        @testset "Extension Function Error Handling" begin
            # Test automatic_reference_documentation error
            @testset "automatic_reference_documentation" begin
                @test_throws CTBase.ExtensionError CTBase.automatic_reference_documentation(
                    FakeDocumenterReferenceTag()
                )
            end

            # Test postprocess_coverage error
            @testset "postprocess_coverage" begin
                @test_throws CTBase.ExtensionError CTBase.postprocess_coverage(
                    FakeCoveragePostprocessingTag()
                )
            end

            # Test run_tests error
            @testset "run_tests" begin
                @test_throws CTBase.ExtensionError CTBase.run_tests(FakeTestRunnerTag())
            end
        end

        # ====================================================================
        # ERROR TESTS - Exception Quality
        # ====================================================================

        @testset "ExtensionError Constructor Validation" begin
            @testset "No dependencies provided" begin
                @test_throws CTBase.PreconditionError CTBase.ExtensionError()

                try
                    CTBase.ExtensionError()
                    @test false  # Should not reach here
                catch e
                    @test e isa CTBase.PreconditionError
                    @test occursin("weak dependence", e.msg)
                    @test occursin("ExtensionError called without dependencies", e.reason)
                end
            end

            @testset "Single dependency" begin
                e = CTBase.ExtensionError(:MyExt)
                @test e isa CTBase.ExtensionError
                @test e.weakdeps == (:MyExt,)
                @test e.msg == "missing dependencies"
            end

            @testset "Multiple dependencies with message" begin
                e = CTBase.ExtensionError(:Ext1, :Ext2; message="to enable feature X")
                @test e isa CTBase.ExtensionError
                @test e.weakdeps == (:Ext1, :Ext2)
                @test e.msg == "missing dependencies to enable feature X"
            end
        end
    end

    return nothing
end

end # module

# Export to outer scope for TestRunner
test_extensions_enriched() = TestExtensionsEnriched.test_extensions_enriched()
