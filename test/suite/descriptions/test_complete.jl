module TestComplete

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_complete()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Complete Descriptions" begin
        algorithms = ()
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :bisection))
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :backtracking))
        algorithms = CTBase.add(algorithms, (:descent, :bfgs, :fixedstep))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :bisection))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :backtracking))
        algorithms = CTBase.add(algorithms, (:descent, :gradient, :fixedstep))

        @testset "Successful completions" begin
            @test CTBase.complete((:descent,); descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
            @test CTBase.complete((:bfgs,); descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
            # Tuple overload check
            @test CTBase.complete(:descent; descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
        end

        @testset "Completion with Variable Sized Descriptions" begin
            algorithms = ()
            algorithms = CTBase.add(algorithms, (:a, :b, :c))
            algorithms = CTBase.add(algorithms, (:a, :b, :c, :d))
            @test CTBase.complete((:a, :b); descriptions=algorithms) == (:a, :b, :c)
            @test CTBase.complete((:a, :b, :c, :d); descriptions=algorithms) ==
                (:a, :b, :c, :d)
        end

        @testset "Priority handling" begin
            # Test priority when ordering of descriptions switched
            algos_swapped = ()
            algos_swapped = CTBase.add(algos_swapped, (:a, :b, :c, :d))
            algos_swapped = CTBase.add(algos_swapped, (:a, :b, :c))
            @test CTBase.complete((:a, :b); descriptions=algos_swapped) == (:a, :b, :c, :d)

            algos_ordered = ()
            algos_ordered = CTBase.add(algos_ordered, (:a, :b, :c))
            algos_ordered = CTBase.add(algos_ordered, (:a, :b, :c, :d))
            @test CTBase.complete((:a, :b); descriptions=algos_ordered) == (:a, :b, :c)
        end

        @testset "Successful completion with exact and partial matches" begin
            descriptions = ((:a, :b), (:a, :b, :c), (:b, :c))
            
            # Test exact match
            result = CTBase.complete(:a, :b; descriptions=descriptions)
            @test result == (:a, :b)
            
            # Test partial match
            result2 = CTBase.complete(:a; descriptions=descriptions)
            @test result2 in [(:a, :b), (:a, :b, :c)]
        end

        @testset "Ambiguous/Invalid completions" begin
            # Basic error check
            @test_throws CTBase.AmbiguousDescription CTBase.complete(
                (:ttt,); descriptions=algorithms
            )

            # Empty catalog
            @test_throws CTBase.AmbiguousDescription CTBase.complete(:a; descriptions=())

            # Enriched error checks - rigorous

            # 1. Empty descriptions check
            try
                CTBase.complete(:a; descriptions=())
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test isempty(e.candidates)
                @test occursin("No descriptions available", e.suggestion)
                @test e.context == "description completion"
            end

            # 2. Description not found with suggestions (subset of existing)
            descriptions = ((:a, :b), (:c, :d), (:e, :f))
            try
                CTBase.complete(:x; descriptions=descriptions)
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test e.description == (:x,)
                @test !isempty(e.candidates)
                @test length(e.candidates) == 3
                @test "(:a, :b)" in e.candidates
                @test occursin(
                    "Choose from the available descriptions listed above", e.suggestion
                )
            end

            # 3. Description not found with similar suggestions
            descriptions_sim = ((:a, :b, :c), (:a, :d, :e), (:x, :y, :z))
            try
                CTBase.complete(:b, :f; descriptions=descriptions_sim)
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test !isempty(e.candidates)
                @test occursin("closest matches", e.suggestion)
                # Should suggest descriptions containing :b (which is (:a, :b, :c))
                @test any(occursin("(:a,", candidate) for candidate in e.candidates)
            end
        end
    end
end

end # module

test_complete() = TestComplete.test_complete()
