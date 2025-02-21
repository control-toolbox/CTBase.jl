function test_description()

    #
    descriptions = ()
    descriptions = CTBase.CTBase.add(descriptions, (:a,))
    descriptions = CTBase.CTBase.add(descriptions, (:b,))
    @test descriptions[1] == (:a,)
    @test descriptions[2] == (:b,)

    # get the complete description of the chosen method
    algorithmes = ()
    algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :bissection))
    algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :backtracking))
    algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :fixedstep))
    algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :bissection))
    algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :backtracking))
    algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :fixedstep))

    @test CTBase.getFullDescription((:descent,), algorithmes) == (:descent, :bfgs, :bissection)
    @test CTBase.getFullDescription((:bfgs,), algorithmes) == (:descent, :bfgs, :bissection)
    @test CTBase.getFullDescription((:bissection,), algorithmes) == (:descent, :bfgs, :bissection)
    @test CTBase.getFullDescription((:backtracking,), algorithmes) == (:descent, :bfgs, :backtracking)
    @test CTBase.getFullDescription((:fixedstep,), algorithmes) == (:descent, :bfgs, :fixedstep)
    @test CTBase.getFullDescription((:fixedstep, :gradient), algorithmes) == (:descent, :gradient, :fixedstep)

    # incorrect description
    @test_throws CTBase.AmbiguousDescription CTBase.getFullDescription((:ttt,), algorithmes)
    @test_throws CTBase.AmbiguousDescription CTBase.getFullDescription((:descent, :ttt), algorithmes)

    # diff
    x = (:a, :b, :c)
    y = (:b,)
    @test CTBase.remove(x, y) == (:a, :c)
    @test typeof(CTBase.remove(x, y)) <: CTBase.Description

    # inclusion and different sizes
    algorithmes = ()
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c, :d))
    @test CTBase.getFullDescription((:a, :b), algorithmes) == (:a, :b, :c)
    @test CTBase.getFullDescription((:a, :b, :c, :d), algorithmes) == (:a, :b, :c, :d)

    # inclusion and different sizes - switch ordering 
    # priority to the first with max shared elements
    algorithmes = ()
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c, :d))
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
    @test CTBase.getFullDescription((:a, :b), algorithmes) == (:a, :b, :c, :d)
    @test CTBase.getFullDescription((:a, :b, :c, :d), algorithmes) == (:a, :b, :c, :d)

    # CTBase.add a description already in the list
    algorithmes = ()
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
    @test_throws CTBase.IncorrectArgument CTBase.add(algorithmes, (:a, :b, :c))
end
