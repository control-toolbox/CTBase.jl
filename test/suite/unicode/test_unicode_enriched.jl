module TestUnicodeEnriched

import Test
import CTBase.Unicode
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_unicode_enriched()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Enriched Unicode Errors" begin

        # ====================================================================
        # ERROR TESTS - Unicode Functions Exception Quality
        # ====================================================================

        Test.@testset "ctindice enriched errors" begin
            # Test negative value
            Test.@test_throws Exceptions.IncorrectArgument Unicode.ctindice(-1)

            try
                Unicode.ctindice(-1)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test e.got == "-1"
                Test.@test e.expected == "0-9"
                Test.@test occursin("subscript must be between 0 and 9", e.msg)
                Test.@test occursin("ctindices()", e.suggestion)
                Test.@test e.context == "Unicode subscript generation"
            end

            # Test value too large
            Test.@test_throws Exceptions.IncorrectArgument Unicode.ctindice(15)

            try
                Unicode.ctindice(15)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test e.got == "15"
                Test.@test e.expected == "0-9"
                Test.@test occursin("ctindices()", e.suggestion)
                Test.@test e.context == "Unicode subscript generation"
            end
        end

        Test.@testset "ctindices enriched errors" begin
            # Test negative value
            Test.@test_throws Exceptions.IncorrectArgument Unicode.ctindices(-5)

            try
                Unicode.ctindices(-5)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test e.got == "-5"
                Test.@test e.expected == "≥ 0"
                Test.@test occursin("subscript must be positive", e.msg)
                Test.@test e.context == "Unicode subscript string generation"
            end
        end

        Test.@testset "ctupperscript enriched errors" begin
            # Test negative value
            Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscript(-1)

            try
                Unicode.ctupperscript(-1)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test e.got == "-1"
                Test.@test e.expected == "0-9"
                Test.@test occursin("superscript must be between 0 and 9", e.msg)
                Test.@test occursin("ctupperscripts()", e.suggestion)
                Test.@test e.context == "Unicode superscript generation"
            end

            # Test value too large
            Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscript(12)

            try
                Unicode.ctupperscript(12)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test e.got == "12"
                Test.@test e.expected == "0-9"
                Test.@test occursin("ctupperscripts()", e.suggestion)
                Test.@test e.context == "Unicode superscript generation"
            end
        end

        Test.@testset "ctupperscripts enriched errors" begin
            # Test negative value
            Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscripts(-3)

            try
                Unicode.ctupperscripts(-3)
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test e.got == "-3"
                Test.@test e.expected == "≥ 0"
                Test.@test occursin("superscript must be positive", e.msg)
                Test.@test e.context == "Unicode superscript string generation"
            end
        end

        # ====================================================================
        # UNIT TESTS - Successful Operations
        # ====================================================================

        Test.@testset "Successful Unicode operations" begin
            # Test ctindice
            Test.@test Unicode.ctindice(0) == '\u2080'
            Test.@test Unicode.ctindice(5) == '\u2085'
            Test.@test Unicode.ctindice(9) == '\u2089'

            # Test ctindices
            Test.@test Unicode.ctindices(0) == "\u2080"
            Test.@test Unicode.ctindices(123) == "\u2081\u2082\u2083"

            # Test ctupperscript
            Test.@test Unicode.ctupperscript(0) == '\u2070'
            Test.@test Unicode.ctupperscript(1) == '\u00B9'
            Test.@test Unicode.ctupperscript(2) == '\u00B2'
            Test.@test Unicode.ctupperscript(3) == '\u00B3'
            Test.@test Unicode.ctupperscript(5) == '\u2075'

            # Test ctupperscripts
            Test.@test Unicode.ctupperscripts(0) == "\u2070"
            Test.@test Unicode.ctupperscripts(123) == "\u00B9\u00B2\u00B3"
        end
    end

    return nothing
end

end # module

# Export to outer scope for TestRunner
test_unicode_enriched() = TestUnicodeEnriched.test_unicode_enriched()
