function test_description()

    # Test adding and indexing descriptions
    @testset "Add and Index Descriptions" begin
        descriptions = ()
        descriptions = CTBase.CTBase.add(descriptions, (:a,))
        descriptions = CTBase.CTBase.add(descriptions, (:b,))
        @test descriptions[1] == (:a,)
        @test descriptions[2] == (:b,)
    end

    # Test building algorithms descriptions and completing partial descriptions
    @testset "Complete Descriptions with Algorithms" begin
        algorithmes = ()
        algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :bissection))
        algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :backtracking))
        algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :fixedstep))
        algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :bissection))
        algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :backtracking))
        algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :fixedstep))

        @test CTBase.complete((:descent,); descriptions=algorithmes) ==
            (:descent, :bfgs, :bissection)
        @test CTBase.complete((:bfgs,); descriptions=algorithmes) ==
            (:descent, :bfgs, :bissection)
        @test CTBase.complete((:bissection,); descriptions=algorithmes) ==
            (:descent, :bfgs, :bissection)
        @test CTBase.complete((:backtracking,); descriptions=algorithmes) ==
            (:descent, :bfgs, :backtracking)
        @test CTBase.complete((:fixedstep,); descriptions=algorithmes) ==
            (:descent, :bfgs, :fixedstep)
        @test CTBase.complete((:fixedstep, :gradient); descriptions=algorithmes) ==
            (:descent, :gradient, :fixedstep)
    end

    # Test ambiguous or invalid description completions throw errors
    @testset "Ambiguous and Incorrect Description Errors" begin
        algorithmes = ()
        algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :bissection))
        algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :backtracking))
        algorithmes = CTBase.add(algorithmes, (:descent, :bfgs, :fixedstep))
        algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :bissection))
        algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :backtracking))
        algorithmes = CTBase.add(algorithmes, (:descent, :gradient, :fixedstep))

        @test_throws CTBase.AmbiguousDescription CTBase.complete(
            (:ttt,); descriptions=algorithmes
        )
        @test_throws CTBase.AmbiguousDescription CTBase.complete(
            (:descent, :ttt); descriptions=algorithmes
        )
    end

    # Test removing elements from descriptions and check type
    @testset "Remove Elements and Type Checking" begin
        x = (:a, :b, :c)
        y = (:b,)
        @test CTBase.remove(x, y) == (:a, :c)
        @test typeof(CTBase.remove(x, y)) <: CTBase.Description
    end

    # Test completion with descriptions of different sizes and inclusion priority
    @testset "Completion with Variable Sized Descriptions" begin
        algorithmes = ()
        algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
        algorithmes = CTBase.add(algorithmes, (:a, :b, :c, :d))
        @test CTBase.complete((:a, :b); descriptions=algorithmes) == (:a, :b, :c)
        @test CTBase.complete((:a, :b, :c, :d); descriptions=algorithmes) ==
            (:a, :b, :c, :d)
    end

    # Test priority when ordering of descriptions switched
    @testset "Priority in Completion with Different Ordering" begin
        algorithmes = ()
        algorithmes = CTBase.add(algorithmes, (:a, :b, :c, :d))
        algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
        @test CTBase.complete((:a, :b); descriptions=algorithmes) == (:a, :b, :c, :d)
        @test CTBase.complete((:a, :b, :c, :d); descriptions=algorithmes) ==
            (:a, :b, :c, :d)
    end

    # Test error when adding a duplicate description
    @testset "Duplicate Description Addition" begin
        algorithmes = ()
        algorithmes = CTBase.add(algorithmes, (:a, :b, :c))
        @test_throws CTBase.IncorrectArgument CTBase.add(algorithmes, (:a, :b, :c))
    end

    # Test Base.show method for Description tuples outputs correctly
    @testset "Base.show Method Output" begin
        io = IOBuffer()
        descriptions = ((:a, :b), (:b, :c))
        show(io, MIME"text/plain"(), descriptions)
        output = String(take!(io))
        expected = "(:a, :b)\n(:b, :c)"
        @test output == expected
    end

    return nothing
end
