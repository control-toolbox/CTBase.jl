module TestCatalog

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_catalog()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Catalog Operations" begin
        
        # ====================================================================
        # UNIT TESTS - Catalog Add Function
        # ====================================================================
        
        @testset "Add to empty catalog" begin
            # Initialize empty catalog
            descriptions = ()
            @test isempty(descriptions)
            
            # Add first description
            descriptions = CTBase.add(descriptions, (:a,))
            @test length(descriptions) == 1
            @test descriptions[1] == (:a,)
            @test typeof(descriptions) <: Tuple{Vararg{CTBase.Description}}
            
            # Add single-element description
            descriptions2 = ()
            descriptions2 = CTBase.add(descriptions2, (:x,))
            @test descriptions2[1] == (:x,)
            
            # Add multi-element description
            descriptions3 = ()
            descriptions3 = CTBase.add(descriptions3, (:a, :b, :c))
            @test descriptions3[1] == (:a, :b, :c)
        end
        
        @testset "Add to non-empty catalog" begin
            # Sequential additions
            descriptions = ()
            descriptions = CTBase.add(descriptions, (:a,))
            @test descriptions[1] == (:a,)
            
            descriptions = CTBase.add(descriptions, (:b,))
            @test descriptions[1] == (:a,)
            @test descriptions[2] == (:b,)
            @test length(descriptions) == 2
            
            # Add third description
            descriptions = CTBase.add(descriptions, (:c,))
            @test length(descriptions) == 3
            @test descriptions[3] == (:c,)
            
            # Verify order is preserved
            @test descriptions == ((:a,), (:b,), (:c,))
        end
        
        @testset "Add multiple descriptions in sequence" begin
            descriptions = ()
            descriptions = CTBase.add(descriptions, (:a, :b))
            descriptions = CTBase.add(descriptions, (:c, :d))
            descriptions = CTBase.add(descriptions, (:e, :f))
            descriptions = CTBase.add(descriptions, (:g, :h))
            
            @test length(descriptions) == 4
            @test descriptions[1] == (:a, :b)
            @test descriptions[2] == (:c, :d)
            @test descriptions[3] == (:e, :f)
            @test descriptions[4] == (:g, :h)
        end
        
        @testset "Add descriptions of varying sizes" begin
            descriptions = ()
            descriptions = CTBase.add(descriptions, (:a,))  # Size 1
            descriptions = CTBase.add(descriptions, (:b, :c))  # Size 2
            descriptions = CTBase.add(descriptions, (:d, :e, :f))  # Size 3
            descriptions = CTBase.add(descriptions, (:g, :h, :i, :j))  # Size 4
            
            @test length(descriptions) == 4
            @test length(descriptions[1]) == 1
            @test length(descriptions[2]) == 2
            @test length(descriptions[3]) == 3
            @test length(descriptions[4]) == 4
        end
        
        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================
        
        @testset "Type stability - add function" begin
            # Add to empty catalog
            @test (@inferred CTBase.add((), (:a,))) isa Tuple{Vararg{CTBase.Description}}
            @test (@inferred CTBase.add((), (:a, :b))) isa Tuple{Vararg{CTBase.Description}}
            
            # Add to non-empty catalog
            descriptions = ((:a,),)
            @test (@inferred CTBase.add(descriptions, (:b,))) isa Tuple{Vararg{CTBase.Description}}
            
            # Verify return type consistency
            result = CTBase.add((), (:x, :y))
            @test result isa Tuple{Vararg{Tuple{Vararg{Symbol}}}}
        end
        
        # ====================================================================
        # ERROR TESTS - Exception Quality
        # ====================================================================
        
        @testset "Duplicate description error" begin
            algorithms = ()
            algorithms = CTBase.add(algorithms, (:a, :b, :c))

            # Basic error check
            @test_throws CTBase.IncorrectArgument CTBase.add(algorithms, (:a, :b, :c))

            # Enriched error check - verify all exception fields
            try
                CTBase.add(algorithms, (:a, :b, :c))
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test occursin("already in", e.msg)
                @test e.got == "(:a, :b, :c)"
                @test occursin("unique description", e.expected)
                @test occursin("Check existing descriptions", e.suggestion)
                @test e.context == "description catalog management"
            end
        end
        
        @testset "Duplicate detection at different positions" begin
            descriptions = ((:a,), (:b,), (:c,))
            
            # Try to add duplicate of first
            @test_throws CTBase.IncorrectArgument CTBase.add(descriptions, (:a,))
            
            # Try to add duplicate of middle
            @test_throws CTBase.IncorrectArgument CTBase.add(descriptions, (:b,))
            
            # Try to add duplicate of last
            @test_throws CTBase.IncorrectArgument CTBase.add(descriptions, (:c,))
        end
        
        @testset "Return type consistency" begin
            # Verify add always returns correct type
            descriptions = ()
            result1 = CTBase.add(descriptions, (:a,))
            @test typeof(result1) <: Tuple{Vararg{CTBase.Description}}
            
            result2 = CTBase.add(result1, (:b,))
            @test typeof(result2) <: Tuple{Vararg{CTBase.Description}}
            # Both are tuples of descriptions (same supertype)
            @test typeof(result1) <: Tuple{Vararg{CTBase.Description}}
            @test typeof(result2) <: Tuple{Vararg{CTBase.Description}}
        end
    end
end

end # module

test_catalog() = TestCatalog.test_catalog()
