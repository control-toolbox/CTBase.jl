module TestDocumenterReferencePageBuilding

using Test: Test
using CTBase: CTBase
using Documenter: Documenter

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Test module for page building
module DocumenterReferencePageTestMod
    """
    Docstring for the main test module.
    """
    myfun(x) = x
    keep(x) = x
    skip(x) = x
    no_doc(x) = x

    """
    Test submodule.
    """
    module SubModule end
end
using .DocumenterReferencePageTestMod

module DRExternalTestMod
    extfun(x::Int) = x
    extfun(x::String) = length(x)
end

function test_documenter_reference_page_building()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_collect_module_docstrings" begin
        DR.reset_config!()

        config = DR._Config(
            DocumenterReferencePageTestMod,
            "api",
            Dict(DocumenterReferencePageTestMod => Any[]),
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

        # Test with private symbols (which have docstrings)
        symbols = redirect_stderr(devnull) do
            return DR._exported_symbols(DocumenterReferencePageTestMod).private
        end
        docs = redirect_stderr(devnull) do
            return DR._collect_module_docstrings(config, symbols)
        end

        # Should collect docstrings for documented symbols
        Test.@test !isempty(docs)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Page content builders" begin
        modules_str = "ModA, ModB"
        module_contents_private = [
            (DocumenterReferencePageTestMod, String[], ["priv_a"]),
            (DocumenterReferencePageTestMod, String[], ["priv_b1", "priv_b2"]),
        ]
        # Test with is_split=false (single page)
        overview_priv, docs_priv = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str, module_contents_private, false
            )
        end
        Test.@test occursin("Private API", overview_priv)
        Test.@test occursin("ModA, ModB", overview_priv)
        Test.@test !isempty(docs_priv)
        Test.@test any(occursin("priv_a", s) for s in docs_priv)
        Test.@test any(occursin("priv_b1", s) for s in docs_priv)

        module_contents_public = [
            (DocumenterReferencePageTestMod, ["pub_a"], String[]),
            (DocumenterReferencePageTestMod, String[], String[]),
        ]
        # Test with is_split=false (single page)
        overview_pub, docs_pub = redirect_stderr(devnull) do
            return DR._build_public_page_content(modules_str, module_contents_public, false)
        end
        Test.@test occursin("Public API", overview_pub)
        Test.@test occursin("ModA, ModB", overview_pub)
        Test.@test !isempty(docs_pub)
        Test.@test any(occursin("pub_a", s) for s in docs_pub)

        module_contents_combined = [(DocumenterReferencePageTestMod, ["pub_a"], ["priv_a"])]
        overview_comb, docs_comb = redirect_stderr(devnull) do
            return DR._build_combined_page_content(modules_str, module_contents_combined)
        end
        Test.@test occursin("API reference", overview_comb)
        Test.@test any(occursin("Public API", s) for s in docs_comb)
        Test.@test any(occursin("Private API", s) for s in docs_comb)
        Test.@test any(occursin("pub_a", s) for s in docs_comb)
        Test.@test any(occursin("priv_a", s) for s in docs_comb)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Page content builders with is_split parameter" begin
        modules_str = "TestModule"

        # Test private page with is_split=false (single page)
        module_contents_private = [(DocumenterReferencePageTestMod, String[], ["priv_doc"])]

        overview_priv_single, docs_priv_single = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str, module_contents_private, false
            )
        end
        Test.@test occursin("# Private API", overview_priv_single)
        Test.@test !occursin("# Private\n", overview_priv_single)
        Test.@test occursin("non-exported", overview_priv_single)

        # Test private page with is_split=true (split page)
        overview_priv_split, docs_priv_split = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str, module_contents_private, true
            )
        end
        Test.@test occursin("# Private API", overview_priv_split)
        Test.@test occursin("non-exported", overview_priv_split)

        # Test public page with is_split=false (single page)
        module_contents_public = [(DocumenterReferencePageTestMod, ["pub_doc"], String[])]

        overview_pub_single, docs_pub_single = redirect_stderr(devnull) do
            return DR._build_public_page_content(modules_str, module_contents_public, false)
        end
        Test.@test occursin("# Public API", overview_pub_single)
        Test.@test occursin("exported", overview_pub_single)

        # Test public page with is_split=true (split page)
        overview_pub_split, docs_pub_split = redirect_stderr(devnull) do
            return DR._build_public_page_content(modules_str, module_contents_public, true)
        end
        Test.@test occursin("# Public API", overview_pub_split)
        Test.@test occursin("exported", overview_pub_split)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Title consistency across different page types" begin
        modules_str = "MyModule"
        module_contents = [(DocumenterReferencePageTestMod, ["pub"], ["priv"])]

        # Single private page should have "Private API" title
        overview_priv, _ = redirect_stderr(devnull) do
            return DR._build_private_page_content(modules_str, module_contents, false)
        end
        Test.@test occursin("# Private API", overview_priv)

        # Single public page should have "Public API" title
        overview_pub, _ = redirect_stderr(devnull) do
            return DR._build_public_page_content(modules_str, module_contents, false)
        end
        Test.@test occursin("# Public API", overview_pub)

        # Split private page should have "Private API" title
        overview_priv_split, _ = redirect_stderr(devnull) do
            return DR._build_private_page_content(modules_str, module_contents, true)
        end
        Test.@test occursin("# Private API", overview_priv_split)

        # Split public page should have "Public API" title
        overview_pub_split, _ = redirect_stderr(devnull) do
            return DR._build_public_page_content(modules_str, module_contents, true)
        end
        Test.@test occursin("# Public API", overview_pub_split)

        # Combined page should have "API reference" title
        overview_comb, _ = redirect_stderr(devnull) do
            return DR._build_combined_page_content(modules_str, module_contents)
        end
        Test.@test occursin("# API reference", overview_comb)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Custom titles for API pages" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferencePageTestMod, ["pub_doc"], ["priv_doc"])]

        # Test custom title for private page (single)
        overview_priv_custom, _ = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str, module_contents, false; custom_title="Internal API"
            )
        end
        Test.@test occursin("# Internal API", overview_priv_custom)
        Test.@test !occursin("# Private API", overview_priv_custom)

        # Test custom title for public page (single)
        overview_pub_custom, _ = redirect_stderr(devnull) do
            return DR._build_public_page_content(
                modules_str, module_contents, false; custom_title="Exported API"
            )
        end
        Test.@test occursin("# Exported API", overview_pub_custom)
        Test.@test !occursin("# Public API", overview_pub_custom)

        # Test custom title for private page (split)
        overview_priv_split_custom, _ = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str, module_contents, true; custom_title="Internal"
            )
        end
        Test.@test occursin("# Internal", overview_priv_split_custom)
        Test.@test !occursin("# Private API", overview_priv_split_custom)

        # Test custom title for public page (split)
        overview_pub_split_custom, _ = redirect_stderr(devnull) do
            return DR._build_public_page_content(
                modules_str, module_contents, true; custom_title="Exported"
            )
        end
        Test.@test occursin("# Exported", overview_pub_split_custom)
        Test.@test !occursin("# Public API", overview_pub_split_custom)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Custom descriptions for API pages" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferencePageTestMod, ["pub_doc"], ["priv_doc"])]

        # Test custom description for private page
        custom_desc_priv = "This page documents internal implementation details."
        overview_priv_desc, _ = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str, module_contents, false; custom_description=custom_desc_priv
            )
        end
        Test.@test occursin(custom_desc_priv, overview_priv_desc)
        Test.@test !occursin("non-exported", overview_priv_desc)

        # Test custom description for public page
        custom_desc_pub = "This page documents the public interface for end users."
        overview_pub_desc, _ = redirect_stderr(devnull) do
            return DR._build_public_page_content(
                modules_str, module_contents, false; custom_description=custom_desc_pub
            )
        end
        Test.@test occursin(custom_desc_pub, overview_pub_desc)
        Test.@test !occursin("exported", overview_pub_desc) ||
            occursin(custom_desc_pub, overview_pub_desc)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Combined custom title and description" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferencePageTestMod, ["pub_doc"], ["priv_doc"])]

        # Test both custom title and description together
        custom_title = "Developer Reference"
        custom_desc = "Advanced documentation for contributors and maintainers."

        overview, _ = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str,
                module_contents,
                false;
                custom_title=custom_title,
                custom_description=custom_desc,
            )
        end

        Test.@test occursin("# Developer Reference", overview)
        Test.@test occursin(custom_desc, overview)
        Test.@test !occursin("# Private API", overview)
        Test.@test !occursin("non-exported", overview)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Empty customization uses defaults" begin
        modules_str = "TestModule"
        module_contents = [(DocumenterReferencePageTestMod, ["pub_doc"], ["priv_doc"])]

        # Empty strings should use default behavior
        overview_priv_empty, _ = redirect_stderr(devnull) do
            return DR._build_private_page_content(
                modules_str, module_contents, false; custom_title="", custom_description=""
            )
        end
        Test.@test occursin("# Private API", overview_priv_empty)
        Test.@test occursin("non-exported", overview_priv_empty)

        overview_pub_empty, _ = redirect_stderr(devnull) do
            return DR._build_public_page_content(
                modules_str, module_contents, false; custom_title="", custom_description=""
            )
        end
        Test.@test occursin("# Public API", overview_pub_empty)
        Test.@test occursin("exported", overview_pub_empty)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "external_modules_to_document" begin
        current_module = DocumenterReferencePageTestMod
        modules = Dict(current_module => String[])
        sort_by(x) = x
        source_files = [abspath(@__FILE__)]

        config = DR._Config(
            current_module,
            "api_ext",
            modules,
            sort_by,
            Set{Symbol}(),
            true,
            true,
            "Ext API",
            "Ext API",
            source_files,
            "api_ext",
            false,
            [DRExternalTestMod],
            "",
            "",
            "",
            "",
        )

        private_docs = redirect_stderr(devnull) do
            return DR._collect_private_docstrings(config, Pair{Symbol,DR.DocType}[])
        end
        Test.@test !isempty(private_docs)
        Test.@test any(occursin("DRExternalTestMod.extfun", s) for s in private_docs)
    end

    return nothing
end

end # module

function test_documenter_reference_page_building()
    return TestDocumenterReferencePageBuilding.test_documenter_reference_page_building()
end
