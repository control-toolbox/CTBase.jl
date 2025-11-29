function test_description()
    # Test adding and indexing descriptions
    @testset "Add and Index Descriptions" begin
        descriptions = ()
        descriptions = CTBase.add(descriptions, (:a,))
        @test descriptions[1] == (:a,)  # Intermediate test after first add
        descriptions = CTBase.add(descriptions, (:b,))
        @test descriptions[1] == (:a,)
        @test descriptions[2] == (:b,)
    end

    # Test building algorithm descriptions and completing partial descriptions
    @testset "Complete Descriptions with Algorithms" begin
        algorithms = ()
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :bisection))
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :backtracking))
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :fixedstep))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :bisection))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :backtracking))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :fixedstep))

        @test CTBase.complete((:descent,); descriptions=algorithms) ==
            (:descent, :bfgs, :bisection)
        @test CTBase.complete((:bfgs,); descriptions=algorithms) ==
            (:descent, :bfgs, :bisection)
        @test CTBase.complete((:bisection,); descriptions=algorithms) ==
            (:descent, :bfgs, :bisection)
        @test CTBase.complete((:backtracking,); descriptions=algorithms) ==
            (:descent, :bfgs, :backtracking)
        @test CTBase.complete((:fixedstep,); descriptions=algorithms) ==
            (:descent, :bfgs, :fixedstep)
        @test CTBase.complete((:fixedstep, :gradient); descriptions=algorithms) ==
            (:descent, :gradient, :fixedstep)
    end

    # Test ambiguous or invalid description completions throw errors
    @testset "Ambiguous and Incorrect Description Errors" begin
        algorithms = ()
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :bisection))
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :backtracking))
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :fixedstep))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :bisection))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :backtracking))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :fixedstep))

        @test_throws CTBase.AmbiguousDescription CTBase.complete(
            (:ttt,); descriptions=algorithms
        )
        @test_throws CTBase.AmbiguousDescription CTBase.complete(
            (:descent, :ttt); descriptions=algorithms
        )
    end

    # Test removing elements from descriptions and check type
    @testset "Remove Elements and Type Checking" begin
        x = (:a, :b, :c)
        y = (:b,)
        @test CTBase.remove(x, y) == (:a, :c)
        @test typeof(CTBase.remove(x, y)) <: CTBase.Description
    end

    # Type stability test for remove function using the is_inferred macro
    @testset "Remove Elements Type Stability" begin
        # example input
        x = (:a, :b, :c)
        y = (:b,)
        result = CTBase.remove(x, y)

        # instead of @inferred, check if the type is a subtype of Tuple{Vararg{Symbol}}
        @test typeof(result) <: Tuple{Vararg{Symbol}}
    end

    # Test completion with descriptions of different sizes and inclusion priority
    @testset "Completion with Variable Sized Descriptions" begin
        algorithms = ()
        algorithms = CTBase.add(algorithms, (:a, :b, :c))
        algorithms = CTBase.add(algorithms, (:a, :b, :c, :d))
        @test CTBase.complete((:a, :b); descriptions=algorithms) == (:a, :b, :c)
        @test CTBase.complete((:a, :b, :c, :d); descriptions=algorithms) == (:a, :b, :c, :d)
    end

    # Test priority when ordering of descriptions switched
    @testset "Priority in Completion with Different Ordering" begin
        algorithms = ()
        algorithms = CTBase.add(algorithms, (:a, :b, :c, :d))
        algorithms = CTBase.add(algorithms, (:a, :b, :c))
        @test CTBase.complete((:a, :b); descriptions=algorithms) == (:a, :b, :c, :d)
        @test CTBase.complete((:a, :b, :c, :d); descriptions=algorithms) == (:a, :b, :c, :d)
    end

    # Test error when adding a duplicate description
    @testset "Duplicate Description Addition" begin
        algorithms = ()
        algorithms = CTBase.add(algorithms, (:a, :b, :c))
        @test_throws CTBase.IncorrectArgument CTBase.add(algorithms, (:a, :b, :c))
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

    @testset "Base.show Edge Cases" begin
        io = IOBuffer()
        descriptions = ()
        show(io, MIME"text/plain"(), descriptions)
        output = String(take!(io))
        @test output == ""

        io = IOBuffer()
        descriptions = ((:a, :b),)
        show(io, MIME"text/plain"(), descriptions)
        output = String(take!(io))
        @test output == "(:a, :b)"
    end

    @testset "Complete with Empty Descriptions" begin
        algorithms = ()
        @test_throws CTBase.AmbiguousDescription CTBase.complete(:a; descriptions=algorithms)
    end

    return nothing
end
