function test_utils()

    v = [1.0; 2.0; 3.0; 4.0; 5.0; 6.0]
    n = 2
    u = vec2vec(v, n)
    w = vec2vec(u)
    @test v == w


    A = [ 0 1
          2 3 ]

    V = CTBase.matrix2vec(A)
    @test V[1] == [0, 1]
    @test V[2] == [2, 3]

    W = CTBase.matrix2vec(A, 2)
    @test W[1] == [0, 2]
    @test W[2] == [1, 3]

    @test_throws IncorrectArgument CTBase.ctindice(-1)
    @test_throws IncorrectArgument CTBase.ctindice(10)

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

    @test_throws IncorrectArgument CTBase.ctindices(-1)
    @test CTBase.ctindices(019) == "₁₉"
    @test CTBase.ctindices(314) == "₃₁₄"

    @test_throws IncorrectArgument CTBase.ctupperscript(-1)
    @test_throws IncorrectArgument CTBase.ctupperscript(10)
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

    @test_throws IncorrectArgument CTBase.ctupperscripts(-1)
    @test CTBase.ctupperscripts(019) == "¹⁹"
    @test CTBase.ctupperscripts(109) == "¹⁰⁹"

end
