module TestUnicodeUtils

import Test
import CTBase.Exceptions: Exceptions
import CTBase.Unicode: Unicode

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_unicode_utils()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctindice (single subscript char)" begin
        # Test exception thrown for out-of-range inputs
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctindice(-1)
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctindice(10)

        # Test all valid subscripts [0..9]
        Test.@test Unicode.ctindice(0) == '₀'
        Test.@test Unicode.ctindice(1) == '₁'
        Test.@test Unicode.ctindice(2) == '₂'
        Test.@test Unicode.ctindice(3) == '₃'
        Test.@test Unicode.ctindice(4) == '₄'
        Test.@test Unicode.ctindice(5) == '₅'
        Test.@test Unicode.ctindice(6) == '₆'
        Test.@test Unicode.ctindice(7) == '₇'
        Test.@test Unicode.ctindice(8) == '₈'
        Test.@test Unicode.ctindice(9) == '₉'
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctindices (multi-digit subscript string)" begin
        # Exception for negative input
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctindices(-1)

        # Test zero (single digit) and multiple digit inputs
        Test.@test Unicode.ctindices(0) == "₀"
        Test.@test Unicode.ctindices(19) == "₁₉"  # decimal 19, no leading zero to avoid confusion
        Test.@test Unicode.ctindices(314) == "₃₁₄"
    end

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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctindices / ctindice consistency" begin
        for d in 0:9
            Test.@test Unicode.ctindices(d) == string(Unicode.ctindice(d))
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctupperscripts / ctupperscript consistency" begin
        for d in 0:9
            Test.@test Unicode.ctupperscripts(d) == string(Unicode.ctupperscript(d))
        end
    end

    return nothing
end

end # module TestUnicodeUtils

# CRITICAL: redefine in outer scope so the test runner can call it
test_unicode_utils() = TestUnicodeUtils.test_unicode_utils()
