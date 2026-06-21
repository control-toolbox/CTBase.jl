module TestExtensionStubs

using Test: Test
import CTBase.DevTools
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Fake tag types for extension stub testing (testing-creation.md §6).
# These subtype the abstract tags but are unknown to any extension,
# so the stubs always throw ExtensionError regardless of which extensions are loaded.
struct FakeDocumenterReferenceTag <: DevTools.AbstractDocumenterReferenceTag end
struct FakeCoveragePostprocessingTag <: DevTools.AbstractCoveragePostprocessingTag end
struct FakeTestRunnerTag <: DevTools.AbstractTestRunnerTag end

function test_extension_stubs()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Extension Function Error Handling" begin
        # Test automatic_reference_documentation error
        Test.@testset "automatic_reference_documentation" begin
            Test.@test_throws Exceptions.ExtensionError DevTools.automatic_reference_documentation(
                FakeDocumenterReferenceTag()
            )
        end

        # Test postprocess_coverage error
        Test.@testset "postprocess_coverage" begin
            Test.@test_throws Exceptions.ExtensionError DevTools.postprocess_coverage(
                FakeCoveragePostprocessingTag()
            )
        end

        # Test run_tests error
        Test.@testset "run_tests" begin
            Test.@test_throws Exceptions.ExtensionError DevTools.run_tests(
                FakeTestRunnerTag()
            )
        end
    end

    return nothing
end

end # module

# Export to outer scope for TestRunner
test_extension_stubs() = TestExtensionStubs.test_extension_stubs()
