module TestComplete

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_complete()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Complete Descriptions" begin
        
        # ====================================================================
        # UNIT TESTS - Complete Function Core Logic
        # ====================================================================
        
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
        
        @testset "Tie-breaking behavior" begin
            # When multiple descriptions have same intersection size, first wins
            descriptions = ((:a, :b, :c), (:a, :b, :d), (:a, :b, :e))
            result = CTBase.complete(:a, :b; descriptions=descriptions)
            @test result == (:a, :b, :c)  # First one wins
            
            # Different order
            descriptions2 = ((:x, :y, :z), (:x, :y, :w), (:x, :y, :v))
            result2 = CTBase.complete(:x, :y; descriptions=descriptions2)
            @test result2 == (:x, :y, :z)  # First one wins
            
            # Single symbol query with equal matches
            descriptions3 = ((:a, :b), (:a, :c), (:a, :d))
            result3 = CTBase.complete(:a; descriptions=descriptions3)
            @test result3 == (:a, :b)  # First one wins
        end
        
        @testset "Exact match with multiple candidates" begin
            # Exact match exists among multiple partial matches
            descriptions = ((:a, :b, :c), (:a, :b), (:a, :c))
            result = CTBase.complete(:a, :b; descriptions=descriptions)
            # Should prefer exact match or first with max intersection
            @test result in [(:a, :b, :c), (:a, :b)]
            
            # Multiple exact matches - first wins
            descriptions2 = ((:x, :y), (:x, :y), (:x, :y, :z))
            result2 = CTBase.complete(:x, :y; descriptions=descriptions2)
            @test result2 == (:x, :y)  # First exact match
        end
        
        @testset "Single vs multi-symbol input" begin
            descriptions = ((:a, :b, :c), (:a, :d), (:b, :c))
            
            # Single symbol
            result1 = CTBase.complete(:a; descriptions=descriptions)
            @test result1 in [(:a, :b, :c), (:a, :d)]
            
            # Two symbols
            result2 = CTBase.complete(:a, :b; descriptions=descriptions)
            @test result2 == (:a, :b, :c)
            
            # Three symbols
            result3 = CTBase.complete(:a, :b, :c; descriptions=descriptions)
            @test result3 == (:a, :b, :c)
        end
        
        @testset "Tuple overload delegation" begin
            descriptions = ((:a, :b), (:c, :d))
            
            # Test that tuple overload works correctly
            result1 = CTBase.complete((:a,); descriptions=descriptions)
            result2 = CTBase.complete(:a; descriptions=descriptions)
            @test result1 == result2
            
            # Multi-element tuple
            result3 = CTBase.complete((:a, :b); descriptions=descriptions)
            result4 = CTBase.complete(:a, :b; descriptions=descriptions)
            @test result3 == result4
        end

        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================
        
        @testset "Type stability - complete function" begin
            descriptions = ((:a, :b), (:a, :c), (:b, :c))
            
            # Varargs overload
            @test (@inferred CTBase.complete(:a; descriptions=descriptions)) isa CTBase.Description
            @test (@inferred CTBase.complete(:a, :b; descriptions=descriptions)) isa CTBase.Description
            
            # Tuple overload
            @test (@inferred CTBase.complete((:a,); descriptions=descriptions)) isa CTBase.Description
            @test (@inferred CTBase.complete((:a, :b); descriptions=descriptions)) isa CTBase.Description
            
            # Verify return type consistency
            result = CTBase.complete(:a; descriptions=descriptions)
            @test result isa Tuple{Vararg{Symbol}}
        end
        
        # ====================================================================
        # ERROR TESTS - AmbiguousDescription Quality
        # ====================================================================
        
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
        
        @testset "Diagnostic field verification" begin
            # Empty catalog - should have diagnostic
            try
                CTBase.complete(:a; descriptions=())
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test e.diagnostic == "empty catalog"
            end
            
            # Unknown symbols - should have diagnostic
            descriptions = ((:a, :b), (:c, :d))
            try
                CTBase.complete(:x, :y; descriptions=descriptions)
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test e.diagnostic in ["unknown symbols", "no complete match"]
            end
            
            # Partial match but not complete - should have diagnostic
            descriptions2 = ((:a, :b, :c), (:d, :e, :f))
            try
                CTBase.complete(:a, :x; descriptions=descriptions2)
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test e.diagnostic == "no complete match"
            end
        end
    end
end

end # module

test_complete() = TestComplete.test_complete()
