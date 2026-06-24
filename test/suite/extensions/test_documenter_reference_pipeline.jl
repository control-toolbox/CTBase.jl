module TestDocumenterReferencePipeline

using Test: Test
using CTBase: CTBase
import CTBase.DevTools: DevTools
using Documenter: Documenter

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Test module for pipeline tests
module DocumenterReferencePipelineTestMod
    myfun(x) = x
end
using .DocumenterReferencePipelineTestMod

function test_documenter_reference_pipeline()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Documenter.Selectors.order for APIBuilder" begin
        Test.@test Documenter.Selectors.order(DR.APIBuilder) == 0.5
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "APIBuilder runner integration" begin
        DR.reset_config!()

        pages = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                return DevTools.automatic_reference_documentation(
                    DevTools.DocumenterReferenceTag();
                    subdirectory="api_integration",
                    primary_modules=[DocumenterReferencePipelineTestMod],
                    public=true,
                    private=true,
                    title="Integration API",
                )
            end
        end

        Test.@test !isempty(DR.CONFIG)

        doc = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                return Documenter.Document(;
                    root=pwd(),
                    source="_test_docs_src",
                    build="_test_docs_build",
                    remotes=nothing,
                )
            end
        end

        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                return Documenter.Selectors.runner(DR.APIBuilder, doc)
            end
        end

        Test.@test !isempty(doc.blueprint.pages)
        Test.@test any(endswith(k, "api_private.md") for k in keys(doc.blueprint.pages))
    end

    return nothing
end

end # module

function test_documenter_reference_pipeline()
    return TestDocumenterReferencePipeline.test_documenter_reference_pipeline()
end
