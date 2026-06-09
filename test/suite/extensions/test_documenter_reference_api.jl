module TestDocumenterReferenceAPI

import Test
import CTBase
import CTBase.Exceptions: Exceptions
import CTBase.Extensions: Extensions
import Documenter

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Test module for API tests
module DocumenterReferenceAPITestMod
    myfun(x) = x
end
using .DocumenterReferenceAPITestMod

function test_documenter_reference_api()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "reset_config!" begin
        DR.reset_config!()
        Test.@test isempty(DR.CONFIG)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Invalid primary_modules input" begin
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Test.@test_throws Extensions.IncorrectArgument Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=["invalid_string"], # String is not Module or Pair
                    title="My API",
                )
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation configuration" begin
        DR.reset_config!()

        # Single-module, public-only
        pages1 = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=[DocumenterReferenceAPITestMod],
                    public=true,
                    private=false,
                    title="My API",
                )
            end
        end

        Test.@test length(DR.CONFIG) == 1
        cfg1 = DR.CONFIG[1]
        Test.@test cfg1.current_module === DocumenterReferenceAPITestMod
        Test.@test cfg1.subdirectory == "ref"
        Test.@test cfg1.public == true
        Test.@test cfg1.private == false
        Test.@test cfg1.filename == "public"
        Test.@test pages1 == ("My API" => "ref/public.md")

        # Both public and private pages
        DR.reset_config!()
        pages2 = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=[DocumenterReferenceAPITestMod],
                    public=true,
                    private=true,
                    title="All API",
                )
            end
        end

        Test.@test length(DR.CONFIG) == 1
        cfg2 = DR.CONFIG[1]
        Test.@test cfg2.filename == "api"
        Test.@test cfg2.public == true
        Test.@test cfg2.private == true
        Test.@test cfg2.title == "All API"
        Test.@test pages2 == (
            "All API" =>
                ["Public" => "ref/api_public.md", "Private" => "ref/api_private.md"]
        )

        # public=false, private=false should error
        redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Test.@test_throws Extensions.IncorrectArgument Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="ref",
                    primary_modules=[DocumenterReferenceAPITestMod],
                    public=false,
                    private=false,
                )
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation multi-module" begin
        DR.reset_config!()

        # Test multi-module case (using same module twice as a proxy)
        pages = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="api",
                    primary_modules=[DocumenterReferenceAPITestMod, DocumenterReferenceAPITestMod],
                    public=true,
                    private=true,
                    title="Multi API",
                )
            end
        end

        # Should return a Pair with title and list of module pages
        Test.@test pages isa Pair
        Test.@test first(pages) == "Multi API"
        Test.@test last(pages) isa Vector

        # CONFIG should have 1 entry (one per unique module)
        Test.@test length(DR.CONFIG) == 1
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "automatic_reference_documentation multi-module with filename" begin
        DR.reset_config!()

        # Test multi-module case with explicit filename (combined page - public only)
        pages = redirect_stdout(devnull) do
            redirect_stderr(devnull) do
                Extensions.automatic_reference_documentation(
                    Extensions.DocumenterReferenceTag();
                    subdirectory="api",
                    primary_modules=[DocumenterReferenceAPITestMod, DocumenterReferenceAPITestMod],
                    public=true,
                    private=false,
                    title="Combined Public API",
                    filename="combined_public",
                )
            end
        end

        # Should return a Pair with title and path to the combined file
        Test.@test pages isa Pair
        Test.@test first(pages) == "Combined Public API"
        Test.@test last(pages) == "api/combined_public.md"

        # CONFIG should have 1 entry (one per unique module)
        Test.@test length(DR.CONFIG) == 1
    end

    return nothing
end

end # module

test_documenter_reference_api() = TestDocumenterReferenceAPI.test_documenter_reference_api()
