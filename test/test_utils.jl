using Test

function test_utils()
    @testset "ctindice (single subscript char)" begin
        # Test exception thrown for out-of-range inputs
        @test_throws CTBase.IncorrectArgument CTBase.ctindice(-1)
        @test_throws CTBase.IncorrectArgument CTBase.ctindice(10)

        # Test all valid subscripts [0..9]
        @test CTBase.ctindice(0) == '₀'
        @test CTBase.ctindice(1) == '₁'
        @test CTBase.ctindice(2) == '₂'
        @test CTBase.ctindice(3) == '₃'
        @test CTBase.ctindice(4) == '₄'
        @test CTBase.ctindice(5) == '₅'
        @test CTBase.ctindice(6) == '₆'
        @test CTBase.ctindice(7) == '₇'
        @test CTBase.ctindice(8) == '₈'
        @test CTBase.ctindice(9) == '₉'
    end

    @testset "ctindices (multi-digit subscript string)" begin
        # Exception for negative input
        @test_throws CTBase.IncorrectArgument CTBase.ctindices(-1)

        # Test zero (single digit) and multiple digit inputs
        @test CTBase.ctindices(0) == "₀"
        @test CTBase.ctindices(19) == "₁₉"  # decimal 19, no leading zero to avoid confusion
        @test CTBase.ctindices(314) == "₃₁₄"
    end

    @testset "ctupperscript (single superscript char)" begin
        # Exception for out-of-range
        @test_throws CTBase.IncorrectArgument CTBase.ctupperscript(-1)
        @test_throws CTBase.IncorrectArgument CTBase.ctupperscript(10)

        # Test all valid superscripts [0..9]
        @test CTBase.ctupperscript(0) == '⁰'
        @test CTBase.ctupperscript(1) == '¹'
        @test CTBase.ctupperscript(2) == '²'
        @test CTBase.ctupperscript(3) == '³'
        @test CTBase.ctupperscript(4) == '⁴'
        @test CTBase.ctupperscript(5) == '⁵'
        @test CTBase.ctupperscript(6) == '⁶'
        @test CTBase.ctupperscript(7) == '⁷'
        @test CTBase.ctupperscript(8) == '⁸'
        @test CTBase.ctupperscript(9) == '⁹'
    end

    @testset "ctupperscripts (multi-digit superscript string)" begin
        # Exception for negative input
        @test_throws CTBase.IncorrectArgument CTBase.ctupperscripts(-1)

        # Test zero and multi-digit inputs
        @test CTBase.ctupperscripts(0) == "⁰"
        @test CTBase.ctupperscripts(19) == "¹⁹"  # no leading zero
        @test CTBase.ctupperscripts(109) == "¹⁰⁹"
    end

    @testset "ctindices / ctindice consistency" begin
        for d in 0:9
            @test CTBase.ctindices(d) == string(CTBase.ctindice(d))
        end
    end

    @testset "ctupperscripts / ctupperscript consistency" begin
        for d in 0:9
            @test CTBase.ctupperscripts(d) == string(CTBase.ctupperscript(d))
        end
    end

    return nothing
end
