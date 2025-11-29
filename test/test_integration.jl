struct DummyDocRefTag <: CTBase.AbstractDocumenterReferenceTag end

function test_integration()
    # Integration test: description workflow combining add, complete, remove, and exceptions
    @testset "Integration: description workflow" begin
        algorithms = ()
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :bisection))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :fixedstep))

        # Successful completion from partial descriptions
        @test CTBase.complete((:descent,); descriptions=algorithms) ==
            (:descent, :bfgs, :bisection)
        @test CTBase.complete((:gradient, :fixedstep); descriptions=algorithms) ==
            (:descent, :gradient, :fixedstep)

        # Removing known prefix from completed description
        full = CTBase.complete((:descent,); descriptions=algorithms)
        prefix = (:descent, :bfgs)
        diff = CTBase.remove(full, prefix)
        @test diff == (:bisection,)

        # Ambiguous / invalid descriptions should raise AmbiguousDescription
        @test_throws CTBase.AmbiguousDescription CTBase.complete((:unknown,); descriptions=algorithms)
        @test_throws CTBase.AmbiguousDescription CTBase.complete((:descent, :unknown); descriptions=algorithms)
    end

    # Integration test: formatting labels using utils (subscripts/superscripts) with descriptions
    @testset "Integration: label formatting with utils" begin
        base = :x

        # Single index / power labels
        label1 = string(base, CTBase.ctindice(1))      # x₁
        label2 = string(base, CTBase.ctupperscript(2)) # x²
        @test label1 == "x₁"
        @test label2 == "x²"

        # Multi-digit index and power combined
        label3 = string(base, CTBase.ctindices(10), CTBase.ctupperscripts(3))
        @test label3 == "x₁₀³"

        # Negative inputs should still throw via the public API
        @test_throws CTBase.IncorrectArgument CTBase.ctindices(-5)
        @test_throws CTBase.IncorrectArgument CTBase.ctupperscripts(-2)
    end

    # Integration test: descriptions and exceptions consistency
    @testset "Integration: descriptions and exceptions" begin
        descs = ()
        descs = CTBase.add(descs, (:a, :b))

        # Duplicate description via add should raise IncorrectArgument
        @test_throws CTBase.IncorrectArgument CTBase.add(descs, (:a, :b))

        # Build a small description set and complete from a prefix
        full = (:a, :b, :c)
        all_descs = ()
        all_descs = CTBase.add(all_descs, full)
        completed = CTBase.complete((:a,); descriptions=all_descs)
        @test completed == full

        # Removing a subset should leave the remaining tail
        tail = CTBase.remove(completed, (:a,))
        @test tail == (:b, :c)
    end

    # Integration test: automatic_reference_documentation fallback when extension is not used
    @testset "Integration: automatic_reference_documentation fallback" begin
        err = try
            CTBase.automatic_reference_documentation(DummyDocRefTag();)
            nothing
        catch e
            e
        end

        @test err isa CTBase.ExtensionError
        @test err.weakdeps == (:Documenter, :Markdown, :MarkdownAST)
    end

    return nothing
end
