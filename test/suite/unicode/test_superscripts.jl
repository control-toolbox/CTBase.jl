module TestSuperscripts

using Test: Test
import CTBase.Exceptions: Exceptions
import CTBase.Unicode: Unicode

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_superscripts()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctupperscript (single superscript char)" begin
        # Exception for out-of-range
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscript(-1)
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscript(10)

        # Test all valid superscripts [0..9]
        Test.@test Unicode.ctupperscript(0) == '⁰'
        Test.@test Unicode.ctupperscript(1) == '¹'
        Test.@test Unicode.ctupperscript(2) == '²'
        Test.@test Unicode.ctupperscript(3) == '³'
        Test.@test Unicode.ctupperscript(4) == '⁴'
        Test.@test Unicode.ctupperscript(5) == '⁵'
        Test.@test Unicode.ctupperscript(6) == '⁶'
        Test.@test Unicode.ctupperscript(7) == '⁷'
        Test.@test Unicode.ctupperscript(8) == '⁸'
        Test.@test Unicode.ctupperscript(9) == '⁹'
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctupperscripts (multi-digit superscript string)" begin
        # Exception for negative input
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscripts(-1)

        # Test zero and multi-digit inputs
        Test.@test Unicode.ctupperscripts(0) == "⁰"
        Test.@test Unicode.ctupperscripts(19) == "¹⁹"  # no leading zero
        Test.@test Unicode.ctupperscripts(109) == "¹⁰⁹"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctupperscript enriched errors" begin
        # Test negative value
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscript(-1)

        try
            Unicode.ctupperscript(-1)
            Test.@test false  # Should not reach here
        catch e
            Test.@test e isa Exceptions.IncorrectArgument
            Test.@test e.got == "-1"
            Test.@test e.expected == "≥ 0"
            Test.@test occursin("superscript must be positive", e.msg)
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
            Test.@test occursin("superscript must be a single digit", e.msg)
            Test.@test occursin("ctupperscripts()", e.suggestion)
            Test.@test e.context == "Unicode superscript generation"
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctupperscripts enriched errors" begin
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctupperscripts / ctupperscript consistency" begin
        for d in 0:9
            Test.@test Unicode.ctupperscripts(d) == string(Unicode.ctupperscript(d))
        end
    end

    return nothing
end

end # module

test_superscripts() = TestSuperscripts.test_superscripts()
