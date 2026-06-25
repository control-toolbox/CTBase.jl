module TestComplete

using Test: Test
import CTBase.Descriptions
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_complete()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Complete Descriptions" begin

        # ====================================================================
        # UNIT TESTS - Complete Function Core Logic
        # ====================================================================

        algorithms = ()
        algorithms = Descriptions.add(algorithms, (:descent, :bfgs, :bisection))
        algorithms = Descriptions.add(algorithms, (:descent, :bfgs, :backtracking))
        algorithms = Descriptions.add(algorithms, (:descent, :bfgs, :fixedstep))
        algorithms = Descriptions.add(algorithms, (:descent, :gradient, :bisection))
        algorithms = Descriptions.add(algorithms, (:descent, :gradient, :backtracking))
        algorithms = Descriptions.add(algorithms, (:descent, :gradient, :fixedstep))

        Test.@testset "Successful completions" begin
            Test.@test Descriptions.complete((:descent,); descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
            Test.@test Descriptions.complete((:bfgs,); descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
            # Tuple overload check
            Test.@test Descriptions.complete(:descent; descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
        end

        Test.@testset "Completion with Variable Sized Descriptions" begin
            algorithms = ()
            algorithms = Descriptions.add(algorithms, (:a, :b, :c))
            algorithms = Descriptions.add(algorithms, (:a, :b, :c, :d))
            Test.@test Descriptions.complete((:a, :b); descriptions=algorithms) ==
                (:a, :b, :c)
            Test.@test Descriptions.complete((:a, :b, :c, :d); descriptions=algorithms) ==
                (:a, :b, :c, :d)
        end

        Test.@testset "Priority handling" begin
            # Test priority when ordering of descriptions switched
            algos_swapped = ()
            algos_swapped = Descriptions.add(algos_swapped, (:a, :b, :c, :d))
            algos_swapped = Descriptions.add(algos_swapped, (:a, :b, :c))
            Test.@test Descriptions.complete((:a, :b); descriptions=algos_swapped) ==
                (:a, :b, :c, :d)

            algos_ordered = ()
            algos_ordered = Descriptions.add(algos_ordered, (:a, :b, :c))
            algos_ordered = Descriptions.add(algos_ordered, (:a, :b, :c, :d))
            Test.@test Descriptions.complete((:a, :b); descriptions=algos_ordered) ==
                (:a, :b, :c)
        end

        Test.@testset "Successful completion with exact and partial matches" begin
            descriptions = ((:a, :b), (:a, :b, :c), (:b, :c))

            # Test exact match
            result = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result == (:a, :b)

            # Test partial match
            result2 = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result2 in [(:a, :b), (:a, :b, :c)]
        end

        Test.@testset "Tie-breaking behavior" begin
            # When multiple descriptions have same intersection size, first wins
            descriptions = ((:a, :b, :c), (:a, :b, :d), (:a, :b, :e))
            result = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result == (:a, :b, :c)  # First one wins

            # Different order
            descriptions2 = ((:x, :y, :z), (:x, :y, :w), (:x, :y, :v))
            result2 = Descriptions.complete(:x, :y; descriptions=descriptions2)
            Test.@test result2 == (:x, :y, :z)  # First one wins

            # Single symbol query with equal matches
            descriptions3 = ((:a, :b), (:a, :c), (:a, :d))
            result3 = Descriptions.complete(:a; descriptions=descriptions3)
            Test.@test result3 == (:a, :b)  # First one wins
        end

        Test.@testset "Exact match with multiple candidates" begin
            # Exact match exists among multiple partial matches
            descriptions = ((:a, :b, :c), (:a, :b), (:a, :c))
            result = Descriptions.complete(:a, :b; descriptions=descriptions)
            # Should prefer exact match or first with max intersection
            Test.@test result in [(:a, :b, :c), (:a, :b)]

            # Multiple exact matches - first wins
            descriptions2 = ((:x, :y), (:x, :y), (:x, :y, :z))
            result2 = Descriptions.complete(:x, :y; descriptions=descriptions2)
            Test.@test result2 == (:x, :y)  # First exact match
        end

        Test.@testset "Single vs multi-symbol input" begin
            descriptions = ((:a, :b, :c), (:a, :d), (:b, :c))

            # Single symbol
            result1 = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result1 in [(:a, :b, :c), (:a, :d)]

            # Two symbols
            result2 = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result2 == (:a, :b, :c)

            # Three symbols
            result3 = Descriptions.complete(:a, :b, :c; descriptions=descriptions)
            Test.@test result3 == (:a, :b, :c)
        end

        Test.@testset "Tuple overload delegation" begin
            descriptions = ((:a, :b), (:c, :d))

            # Test that tuple overload works correctly
            result1 = Descriptions.complete((:a,); descriptions=descriptions)
            result2 = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result1 == result2

            # Multi-element tuple
            result3 = Descriptions.complete((:a, :b); descriptions=descriptions)
            result4 = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result3 == result4
        end

        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================

        Test.@testset "Type stability - complete function" begin
            descriptions = ((:a, :b), (:a, :c), (:b, :c))

            # Varargs overload
            Test.@test (Test.@inferred Descriptions.complete(
                :a; descriptions=descriptions
            )) isa Descriptions.Description
            Test.@test (Test.@inferred Descriptions.complete(
                :a, :b; descriptions=descriptions
            )) isa Descriptions.Description

            # Tuple overload
            Test.@test (Test.@inferred Descriptions.complete(
                (:a,); descriptions=descriptions
            )) isa Descriptions.Description
            Test.@test (Test.@inferred Descriptions.complete(
                (:a, :b); descriptions=descriptions
            )) isa Descriptions.Description

            # Verify return type consistency
            result = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result isa Tuple{Vararg{Symbol}}
        end

        # ====================================================================
        # ERROR TESTS - AmbiguousDescription Quality
        # ====================================================================

        Test.@testset "Ambiguous/Invalid completions" begin
            # Basic error check
            Test.@test_throws Exceptions.AmbiguousDescription Descriptions.complete(
                (:ttt,); descriptions=algorithms
            )

            # Empty catalog
            Test.@test_throws Exceptions.AmbiguousDescription Descriptions.complete(
                :a; descriptions=()
            )

            # Enriched error checks - rigorous

            # 1. Empty descriptions check
            try
                Descriptions.complete(:a; descriptions=())
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test isempty(e.candidates)
                Test.@test occursin("No descriptions available", e.suggestion)
                Test.@test e.context == "description completion"
            end

            # 2. Description not found with suggestions (subset of existing)
            descriptions = ((:a, :b), (:c, :d), (:e, :f))
            try
                Descriptions.complete(:x; descriptions=descriptions)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.description == (:x,)
                Test.@test !isempty(e.candidates)
                Test.@test length(e.candidates) == 3
                Test.@test "(:a, :b)" in e.candidates
                Test.@test occursin(
                    "Choose from the available descriptions listed above", e.suggestion
                )
            end

            # 3. Description not found with similar suggestions
            descriptions_sim = ((:a, :b, :c), (:a, :d, :e), (:x, :y, :z))
            try
                Descriptions.complete(:b, :f; descriptions=descriptions_sim)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test !isempty(e.candidates)
                Test.@test occursin("closest matches", e.suggestion)
                # Should suggest descriptions containing :b (which is (:a, :b, :c))
                Test.@test any(occursin("(:a,", candidate) for candidate in e.candidates)
            end
        end

        Test.@testset "Diagnostic field verification" begin
            # Empty catalog - should have diagnostic
            try
                Descriptions.complete(:a; descriptions=())
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.diagnostic == "empty catalog"
            end

            # Unknown symbols - should have diagnostic
            descriptions = ((:a, :b), (:c, :d))
            try
                Descriptions.complete(:x, :y; descriptions=descriptions)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.diagnostic in ["unknown symbols", "no complete match"]
            end

            # Partial match but not complete - should have diagnostic
            descriptions2 = ((:a, :b, :c), (:d, :e, :f))
            try
                Descriptions.complete(:a, :x; descriptions=descriptions2)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.diagnostic == "no complete match"
            end
        end
    end
end

end # module

test_complete() = TestComplete.test_complete()
