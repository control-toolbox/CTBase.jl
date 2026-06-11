module TestDocumenterReference

import Test
import CTBase
import CTBase.Extensions: Extensions
import Documenter

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

# Test module for integration tests
module DocumenterReferenceIntegrationTestMod
    """
    Docstring for the main test module used to validate module-level documentation
    in the generated API pages.
    """
    myfun(x) = x
end
using .DocumenterReferenceIntegrationTestMod

function test_documenter_reference()
    # Keep only integration tests - pipeline integration with Documenter
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "APIBuilder runner integration" begin
        DR.reset_config!()

        pages = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="api_integration",
                    primary_modules=[DocumenterReferenceIntegrationTestMod],
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

    return nothing
end

end # module TestDocumenterReference

# CRITICAL: redefine in outer scope so the test runner can call it
test_documenter_reference() = TestDocumenterReference.test_documenter_reference()
