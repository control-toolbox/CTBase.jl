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

    @test CTBase.complete((:descent,);              descriptions=algorithmes) == (:descent, :bfgs, :bissection)
    @test CTBase.complete((:bfgs,);                 descriptions=algorithmes) == (:descent, :bfgs, :bissection)
    @test CTBase.complete((:bissection,);           descriptions=algorithmes) == (:descent, :bfgs, :bissection)
    @test CTBase.complete((:backtracking,);         descriptions=algorithmes) == (:descent, :bfgs, :backtracking)
    @test CTBase.complete((:fixedstep,);            descriptions=algorithmes) == (:descent, :bfgs, :fixedstep)
    @test CTBase.complete((:fixedstep, :gradient);  descriptions=algorithmes) == (:descent, :gradient, :fixedstep)

    # incorrect description
    @test_throws CTBase.AmbiguousDescription CTBase.complete((:ttt,);           descriptions=algorithmes)
    @test_throws CTBase.AmbiguousDescription CTBase.complete((:descent, :ttt);  descriptions=algorithmes)

    # diff
    x = (:a, :b, :c)
    y = (:b,)
    @test CTBase.remove(x, y) == (:a, :c)
    @test typeof(CTBase.remove(x, y)) <: CTBase.Description

    # inclusion and different sizes
    algorithmes = ()
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c, :d))
    @test CTBase.complete((:a, :b);         descriptions=algorithmes) == (:a, :b, :c)
    @test CTBase.complete((:a, :b, :c, :d); descriptions=algorithmes) == (:a, :b, :c, :d)

    # inclusion and different sizes - switch ordering 
    # priority to the first with max shared elements
    algorithmes = ()
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c, :d))
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
    @test CTBase.complete((:a, :b);         descriptions=algorithmes) == (:a, :b, :c, :d)
    @test CTBase.complete((:a, :b, :c, :d); descriptions=algorithmes) == (:a, :b, :c, :d)

    # CTBase.add a description already in the list
    algorithmes = ()
    algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
    @test_throws CTBase.IncorrectArgument CTBase.add(algorithmes, (:a, :b, :c))
end
