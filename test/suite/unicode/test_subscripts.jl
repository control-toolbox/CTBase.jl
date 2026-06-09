module TestSubscripts

import Test
import CTBase.Exceptions: Exceptions
import CTBase.Unicode: Unicode

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_subscripts()
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctindice enriched errors" begin
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctindices enriched errors" begin
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ctindices / ctindice consistency" begin
        for d in 0:9
            Test.@test Unicode.ctindices(d) == string(Unicode.ctindice(d))
        end
    end

    return nothing
end

end # module

test_subscripts() = TestSubscripts.test_subscripts()
