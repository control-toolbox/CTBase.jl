module TestRemove

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_remove()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Remove Symbols" begin
        
        # ====================================================================
        # UNIT TESTS - Remove Function Core Logic
        # ====================================================================
        
        @testset "Basic removal" begin
            x = (:a, :b, :c)
            y = (:b,)
            @test CTBase.remove(x, y) == (:a, :c)
            @test typeof(CTBase.remove(x, y)) <: CTBase.Description
        end
        
        @testset "Multiple symbol removal" begin
            x = (:a, :b, :c, :d)
            y = (:b, :d)
            @test CTBase.remove(x, y) == (:a, :c)
            
            # Remove multiple consecutive symbols
            x2 = (:a, :b, :c, :d, :e)
            y2 = (:b, :c, :d)
            @test CTBase.remove(x2, y2) == (:a, :e)
        end
        
        @testset "Edge cases - empty inputs" begin
            # Remove from empty tuple
            @test CTBase.remove((), ()) == ()
            @test CTBase.remove((), (:a,)) == ()
            
            # Remove empty tuple from description
            x = (:a, :b, :c)
            @test CTBase.remove(x, ()) == (:a, :b, :c)
        end
        
        @testset "Edge cases - no overlap" begin
            # No common symbols
            x = (:a, :b, :c)
            y = (:x, :y, :z)
            @test CTBase.remove(x, y) == (:a, :b, :c)
            
            # Single symbol, no overlap
            x2 = (:a,)
            y2 = (:b,)
            @test CTBase.remove(x2, y2) == (:a,)
        end
        
        @testset "Edge cases - complete overlap" begin
            # Remove all symbols
            x = (:a, :b, :c)
            y = (:a, :b, :c)
            @test CTBase.remove(x, y) == ()
            
            # Single symbol removal
            x2 = (:a,)
            y2 = (:a,)
            @test CTBase.remove(x2, y2) == ()
        end
        
        @testset "Edge cases - partial overlap" begin
            # Remove first symbol
            x = (:a, :b, :c)
            y = (:a,)
            @test CTBase.remove(x, y) == (:b, :c)
            
            # Remove last symbol
            x2 = (:a, :b, :c)
            y2 = (:c,)
            @test CTBase.remove(x2, y2) == (:a, :b)
            
            # Remove middle symbol
            x3 = (:a, :b, :c)
            y3 = (:b,)
            @test CTBase.remove(x3, y3) == (:a, :c)
        end
        
        @testset "Order preservation" begin
            # Verify order is preserved after removal
            x = (:z, :y, :x, :w, :v)
            y = (:y, :w)
            result = CTBase.remove(x, y)
            @test result == (:z, :x, :v)
            @test result[1] == :z
            @test result[2] == :x
            @test result[3] == :v
        end
        
        @testset "Duplicate symbols handling" begin
            # Note: Descriptions are tuples, can have duplicates
            # setdiff removes duplicates, so test actual behavior
            x = (:a, :b, :a, :c)
            y = (:a,)
            result = CTBase.remove(x, y)
            # setdiff removes all :a occurrences
            @test :a ∉ result
            @test :b ∈ result
            @test :c ∈ result
        end
        
        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================
        
        @testset "Type stability" begin
            # Note: Julia's type inference returns concrete tuple types (e.g., Tuple{Symbol, Symbol})
            # rather than Tuple{Vararg{Symbol}} for fixed-size results.
            # This is expected and correct behavior.
            
            # Test that remove returns correct results
            @test CTBase.remove((:a, :b, :c), (:b,)) == (:a, :c)
            @test CTBase.remove((:a,), ()) == (:a,)
            @test CTBase.remove((:a, :b), (:a,)) == (:b,)
            @test CTBase.remove((), ()) == ()
            @test CTBase.remove((:a, :b), (:a, :b)) == ()
            
            # Verify return types are tuple types with Symbol elements
            result1 = CTBase.remove((:a, :b, :c), (:b,))
            @test typeof(result1) <: Tuple{Vararg{Symbol}}
            @test result1 isa Tuple
            @test all(x -> x isa Symbol, result1)
            
            # Verify type consistency
            result2 = CTBase.remove((:x, :y, :z), (:y,))
            @test typeof(result2) <: Tuple{Vararg{Symbol}}
            @test typeof(result1) == typeof(result2)  # Same structure
        end
    end
end

end # module

test_remove() = TestRemove.test_remove()
