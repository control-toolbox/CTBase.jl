module TestRemove

import Test
import CTBase.Descriptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_remove()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Remove Symbols" begin

        # ====================================================================
        # UNIT TESTS - Remove Function Core Logic
        # ====================================================================

        Test.@testset "Basic removal" begin
            x = (:a, :b, :c)
            y = (:b,)
            Test.@test Descriptions.remove(x, y) == (:a, :c)
            Test.@test typeof(Descriptions.remove(x, y)) <: Descriptions.Description
        end

        Test.@testset "Multiple symbol removal" begin
            x = (:a, :b, :c, :d)
            y = (:b, :d)
            Test.@test Descriptions.remove(x, y) == (:a, :c)

            # Remove multiple consecutive symbols
            x2 = (:a, :b, :c, :d, :e)
            y2 = (:b, :c, :d)
            Test.@test Descriptions.remove(x2, y2) == (:a, :e)
        end

        Test.@testset "Edge cases - empty inputs" begin
            # Remove from empty tuple
            Test.@test Descriptions.remove((), ()) == ()
            Test.@test Descriptions.remove((), (:a,)) == ()

            # Remove empty tuple from description
            x = (:a, :b, :c)
            Test.@test Descriptions.remove(x, ()) == (:a, :b, :c)
        end

        Test.@testset "Edge cases - no overlap" begin
            # No common symbols
            x = (:a, :b, :c)
            y = (:x, :y, :z)
            Test.@test Descriptions.remove(x, y) == (:a, :b, :c)

            # Single symbol, no overlap
            x2 = (:a,)
            y2 = (:b,)
            Test.@test Descriptions.remove(x2, y2) == (:a,)
        end

        Test.@testset "Edge cases - complete overlap" begin
            # Remove all symbols
            x = (:a, :b, :c)
            y = (:a, :b, :c)
            Test.@test Descriptions.remove(x, y) == ()

            # Single symbol removal
            x2 = (:a,)
            y2 = (:a,)
            Test.@test Descriptions.remove(x2, y2) == ()
        end

        Test.@testset "Edge cases - partial overlap" begin
            # Remove first symbol
            x = (:a, :b, :c)
            y = (:a,)
            Test.@test Descriptions.remove(x, y) == (:b, :c)

            # Remove last symbol
            x2 = (:a, :b, :c)
            y2 = (:c,)
            Test.@test Descriptions.remove(x2, y2) == (:a, :b)

            # Remove middle symbol
            x3 = (:a, :b, :c)
            y3 = (:b,)
            Test.@test Descriptions.remove(x3, y3) == (:a, :c)
        end

        Test.@testset "Order preservation" begin
            # Verify order is preserved after removal
            x = (:z, :y, :x, :w, :v)
            y = (:y, :w)
            result = Descriptions.remove(x, y)
            Test.@test result == (:z, :x, :v)
            Test.@test result[1] == :z
            Test.@test result[2] == :x
            Test.@test result[3] == :v
        end

        Test.@testset "Duplicate symbols handling" begin
            # Note: Descriptions are tuples, can have duplicates
            # setdiff removes duplicates, so test actual behavior
            x = (:a, :b, :a, :c)
            y = (:a,)
            result = Descriptions.remove(x, y)
            # setdiff removes all :a occurrences
            Test.@test :a ∉ result
            Test.@test :b ∈ result
            Test.@test :c ∈ result
        end

        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================

        Test.@testset "Type stability" begin
            # Note: Julia's type inference returns concrete tuple types (e.g., Tuple{Symbol, Symbol})
            # rather than Tuple{Vararg{Symbol}} for fixed-size results.
            # This is expected and correct behavior.

            # Test that remove returns correct results
            Test.@test Descriptions.remove((:a, :b, :c), (:b,)) == (:a, :c)
            Test.@test Descriptions.remove((:a,), ()) == (:a,)
            Test.@test Descriptions.remove((:a, :b), (:a,)) == (:b,)
            Test.@test Descriptions.remove((), ()) == ()
            Test.@test Descriptions.remove((:a, :b), (:a, :b)) == ()

            # Verify return types are tuple types with Symbol elements
            result1 = Descriptions.remove((:a, :b, :c), (:b,))
            Test.@test typeof(result1) <: Tuple{Vararg{Symbol}}
            Test.@test result1 isa Tuple
            Test.@test all(x -> x isa Symbol, result1)

            # Verify type consistency
            result2 = Descriptions.remove((:x, :y, :z), (:y,))
            Test.@test typeof(result2) <: Tuple{Vararg{Symbol}}
            Test.@test typeof(result1) == typeof(result2)  # Same structure
        end
    end
end

end # module

test_remove() = TestRemove.test_remove()
