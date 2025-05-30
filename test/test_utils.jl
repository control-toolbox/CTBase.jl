function test_utils()
    @test_throws CTBase.IncorrectArgument CTBase.ctindice(-1)
    @test_throws CTBase.IncorrectArgument CTBase.ctindice(10)

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

    @test_throws CTBase.IncorrectArgument CTBase.ctindices(-1)
    @test CTBase.ctindices(019) == "₁₉"
    @test CTBase.ctindices(314) == "₃₁₄"

    @test_throws CTBase.IncorrectArgument CTBase.ctupperscript(-1)
    @test_throws CTBase.IncorrectArgument CTBase.ctupperscript(10)
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

    @test_throws CTBase.IncorrectArgument CTBase.ctupperscripts(-1)
    @test CTBase.ctupperscripts(019) == "¹⁹"
    @test CTBase.ctupperscripts(109) == "¹⁰⁹"
end
