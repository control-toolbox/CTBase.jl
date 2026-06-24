module TestDocumenterReferenceConfigHelpers

using Test: Test
using CTBase: CTBase
using Documenter: Documenter

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Test module for config helpers
module DocumenterReferenceConfigTestMod
    myfun(x) = x
end
using .DocumenterReferenceConfigTestMod

function test_documenter_reference_config_helpers()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_default_basename" begin
        Test.@test DR._default_basename("manual", true, true) == "manual"
        Test.@test DR._default_basename("", true, true) == "api"
        Test.@test DR._default_basename("", true, false) == "public"
        Test.@test DR._default_basename("", false, true) == "private"
        Test.@test DR._default_basename("custom", false, false) == "custom"
        Test.@test DR._default_basename("", false, false) == "private"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_build_page_path" begin
        Test.@test DR._build_page_path("api", "public") == "api/public"
        Test.@test DR._build_page_path(".", "public") == "public"
        Test.@test DR._build_page_path("", "public") == "public"
        Test.@test DR._build_page_path("", "") == ""
        Test.@test DR._build_page_path(".", "") == ""
        Test.@test DR._build_page_path("dir", "") == "dir/"
        Test.@test DR._build_page_path("a/b/c", "file.md") == "a/b/c/file.md"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_parse_primary_modules" begin
        d = DR._parse_primary_modules([DocumenterReferenceConfigTestMod => @__FILE__])
        Test.@test d[DocumenterReferenceConfigTestMod] == [abspath(@__FILE__)]
    end

    return nothing
end

end # module

function test_documenter_reference_config_helpers()
    return TestDocumenterReferenceConfigHelpers.test_documenter_reference_config_helpers()
end
