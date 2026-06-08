module TestCatalog

import Test
import CTBase.Descriptions
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_catalog()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Catalog Operations" begin

        # ====================================================================
        # UNIT TESTS - Catalog Add Function
        # ====================================================================

        Test.@testset "Add to empty catalog" begin
            # Initialize empty catalog
            descriptions = ()
            Test.@test isempty(descriptions)

            # Add first description
            descriptions = Descriptions.add(descriptions, (:a,))
            Test.@test length(descriptions) == 1
            Test.@test descriptions[1] == (:a,)
            Test.@test typeof(descriptions) <: Tuple{Vararg{Descriptions.Description}}

            # Add single-element description
            descriptions2 = ()
            descriptions2 = Descriptions.add(descriptions2, (:x,))
            Test.@test descriptions2[1] == (:x,)

            # Add multi-element description
            descriptions3 = ()
            descriptions3 = Descriptions.add(descriptions3, (:a, :b, :c))
            Test.@test descriptions3[1] == (:a, :b, :c)
        end

        Test.@testset "Add to non-empty catalog" begin
            # Sequential additions
            descriptions = ()
            descriptions = Descriptions.add(descriptions, (:a,))
            Test.@test descriptions[1] == (:a,)

            descriptions = Descriptions.add(descriptions, (:b,))
            Test.@test descriptions[1] == (:a,)
            Test.@test descriptions[2] == (:b,)
            Test.@test length(descriptions) == 2

            # Add third description
            descriptions = Descriptions.add(descriptions, (:c,))
            Test.@test length(descriptions) == 3
            Test.@test descriptions[3] == (:c,)

            # Verify order is preserved
            Test.@test descriptions == ((:a,), (:b,), (:c,))
        end

        Test.@testset "Add multiple descriptions in sequence" begin
            descriptions = ()
            descriptions = Descriptions.add(descriptions, (:a, :b))
            descriptions = Descriptions.add(descriptions, (:c, :d))
            descriptions = Descriptions.add(descriptions, (:e, :f))
            descriptions = Descriptions.add(descriptions, (:g, :h))

            Test.@test length(descriptions) == 4
            Test.@test descriptions[1] == (:a, :b)
            Test.@test descriptions[2] == (:c, :d)
            Test.@test descriptions[3] == (:e, :f)
            Test.@test descriptions[4] == (:g, :h)
        end

        Test.@testset "Add descriptions of varying sizes" begin
            descriptions = ()
            descriptions = Descriptions.add(descriptions, (:a,))  # Size 1
            descriptions = Descriptions.add(descriptions, (:b, :c))  # Size 2
            descriptions = Descriptions.add(descriptions, (:d, :e, :f))  # Size 3
            descriptions = Descriptions.add(descriptions, (:g, :h, :i, :j))  # Size 4

            Test.@test length(descriptions) == 4
            Test.@test length(descriptions[1]) == 1
            Test.@test length(descriptions[2]) == 2
            Test.@test length(descriptions[3]) == 3
            Test.@test length(descriptions[4]) == 4
        end

        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================

        Test.@testset "Type stability - add function" begin
            # Add to empty catalog
            Test.@test (Test.@inferred Descriptions.add((), (:a,))) isa Tuple{Vararg{Descriptions.Description}}
            Test.@test (Test.@inferred Descriptions.add((), (:a, :b))) isa Tuple{Vararg{Descriptions.Description}}

            # Add to non-empty catalog
            descriptions = ((:a,),)
            Test.@test (Test.@inferred Descriptions.add(descriptions, (:b,))) isa
                Tuple{Vararg{Descriptions.Description}}

            # Verify return type consistency
            result = Descriptions.add((), (:x, :y))
            Test.@test result isa Tuple{Vararg{Tuple{Vararg{Symbol}}}}
        end

        # ====================================================================
        # ERROR TESTS - Exception Quality
        # ====================================================================

        Test.@testset "Duplicate description error" begin
            algorithms = ()
            algorithms = Descriptions.add(algorithms, (:a, :b, :c))

            # Basic error check
            Test.@test_throws Exceptions.IncorrectArgument Descriptions.add(algorithms, (:a, :b, :c))

            # Enriched error check - verify all exception fields
            try
                Descriptions.add(algorithms, (:a, :b, :c))
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test occursin("already in", e.msg)
                Test.@test e.got == "(:a, :b, :c)"
                Test.@test occursin("unique description", e.expected)
                Test.@test occursin("Check existing descriptions", e.suggestion)
                Test.@test e.context == "description catalog management"
            end
        end

        Test.@testset "Duplicate detection at different positions" begin
            descriptions = ((:a,), (:b,), (:c,))

            # Try to add duplicate of first
            Test.@test_throws Exceptions.IncorrectArgument Descriptions.add(descriptions, (:a,))

            # Try to add duplicate of middle
            Test.@test_throws Exceptions.IncorrectArgument Descriptions.add(descriptions, (:b,))

            # Try to add duplicate of last
            Test.@test_throws Exceptions.IncorrectArgument Descriptions.add(descriptions, (:c,))
        end

        Test.@testset "Return type consistency" begin
            # Verify add always returns correct type
            descriptions = ()
            result1 = Descriptions.add(descriptions, (:a,))
            Test.@test typeof(result1) <: Tuple{Vararg{Descriptions.Description}}

            result2 = Descriptions.add(result1, (:b,))
            Test.@test typeof(result2) <: Tuple{Vararg{Descriptions.Description}}
            # Both are tuples of descriptions (same supertype)
            Test.@test typeof(result1) <: Tuple{Vararg{Descriptions.Description}}
            Test.@test typeof(result2) <: Tuple{Vararg{Descriptions.Description}}
        end
    end
end

end # module

test_catalog() = TestCatalog.test_catalog()
