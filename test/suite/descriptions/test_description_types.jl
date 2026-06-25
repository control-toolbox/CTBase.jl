module TestDescriptionTypes

using Test: Test
import CTBase.Descriptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_description_types()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Description Types" begin

        # ====================================================================
        # UNIT TESTS - Type Definitions
        # ====================================================================

        Test.@testset "DescVarArg type alias" begin
            # Verify type equality
            Test.@test Descriptions.DescVarArg == Vararg{Symbol}
            Test.@test Descriptions.DescVarArg === Vararg{Symbol}

            # Verify it's a type alias, not a new type
            Test.@test typeof(Descriptions.DescVarArg) == typeof(Vararg{Symbol})

            # Test that it can be used in function signatures
            test_func(args::Descriptions.DescVarArg) = length(args)
            Test.@test test_func(:a, :b, :c) == 3
            Test.@test test_func(:x) == 1
        end

        Test.@testset "Description type alias" begin
            # Verify type equality
            Test.@test Descriptions.Description == Tuple{Vararg{Symbol}}
            Test.@test Descriptions.Description === Tuple{Vararg{Symbol}}

            # Verify it's a type alias, not a new type
            Test.@test typeof(Descriptions.Description) == typeof(Tuple{Vararg{Symbol}})

            # Test concrete instances
            Test.@test (:a, :b) isa Descriptions.Description
            Test.@test (:x,) isa Descriptions.Description
            Test.@test (:a, :b, :c, :d) isa Descriptions.Description
            Test.@test () isa Descriptions.Description  # Empty tuple is valid
        end

        Test.@testset "Type properties" begin
            # Verify Description is a type (DataType or UnionAll depending on Julia version)
            Test.@test Descriptions.Description isa Type
            Test.@test Descriptions.Description == Tuple{Vararg{Symbol}}

            # Verify concrete tuple instances are of Description type
            Test.@test (:a, :b) isa Descriptions.Description
            Test.@test (:x,) isa Descriptions.Description
            Test.@test () isa Descriptions.Description

            # Verify concrete tuple types are subtypes
            Test.@test Tuple{Symbol,Symbol} <: Tuple{Vararg{Symbol}}
            Test.@test Tuple{Symbol} <: Tuple{Vararg{Symbol}}
            Test.@test Tuple{} <: Tuple{Vararg{Symbol}}

            # Verify non-Symbol tuples are not of Description type
            Test.@test !((1, 2) isa Descriptions.Description)
            Test.@test !("hello" isa Descriptions.Description)
            Test.@test !([1, 2, 3] isa Descriptions.Description)
        end

        Test.@testset "Type parameter behavior" begin
            # Test that Description accepts any number of Symbols
            desc1::Descriptions.Description = (:a,)
            desc2::Descriptions.Description = (:a, :b)
            desc3::Descriptions.Description = (:a, :b, :c)
            desc4::Descriptions.Description = ()

            Test.@test desc1 isa Descriptions.Description
            Test.@test desc2 isa Descriptions.Description
            Test.@test desc3 isa Descriptions.Description
            Test.@test desc4 isa Descriptions.Description

            # Verify length variability
            Test.@test length(desc1) == 1
            Test.@test length(desc2) == 2
            Test.@test length(desc3) == 3
            Test.@test length(desc4) == 0
        end

        Test.@testset "Type usage in collections" begin
            # Verify Description can be used in tuples of descriptions
            catalog::Tuple{Vararg{Descriptions.Description}} = ((:a, :b), (:c, :d))
            Test.@test length(catalog) == 2
            Test.@test catalog[1] isa Descriptions.Description
            Test.@test catalog[2] isa Descriptions.Description

            # Verify in vectors
            vec_catalog::Vector{Descriptions.Description} = [(:a, :b), (:c, :d)]
            Test.@test length(vec_catalog) == 2
            Test.@test vec_catalog[1] isa Descriptions.Description
        end

        Test.@testset "Type inference with aliases" begin
            # Verify type inference works correctly
            function create_description(syms::Symbol...)::Descriptions.Description
                return syms
            end

            result = create_description(:a, :b, :c)
            Test.@test result isa Descriptions.Description
            Test.@test result == (:a, :b, :c)

            # Test with Test.@inferred
            Test.@test (Test.@inferred create_description(:x, :y)) isa
                Descriptions.Description
        end
    end
end

end # module

test_description_types() = TestDescriptionTypes.test_description_types()
