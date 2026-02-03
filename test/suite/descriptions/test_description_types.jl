module TestDescriptionTypes

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_description_types()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Description Types" begin
        
        # ====================================================================
        # UNIT TESTS - Type Definitions
        # ====================================================================
        
        @testset "DescVarArg type alias" begin
            # Verify type equality
            @test CTBase.DescVarArg == Vararg{Symbol}
            @test CTBase.DescVarArg === Vararg{Symbol}
            
            # Verify it's a type alias, not a new type
            @test typeof(CTBase.DescVarArg) == typeof(Vararg{Symbol})
            
            # Test that it can be used in function signatures
            test_func(args::CTBase.DescVarArg) = length(args)
            @test test_func(:a, :b, :c) == 3
            @test test_func(:x) == 1
        end
        
        @testset "Description type alias" begin
            # Verify type equality
            @test CTBase.Description == Tuple{Vararg{Symbol}}
            @test CTBase.Description === Tuple{Vararg{Symbol}}
            
            # Verify it's a type alias, not a new type
            @test typeof(CTBase.Description) == typeof(Tuple{Vararg{Symbol}})
            
            # Test concrete instances
            @test (:a, :b) isa CTBase.Description
            @test (:x,) isa CTBase.Description
            @test (:a, :b, :c, :d) isa CTBase.Description
            @test () isa CTBase.Description  # Empty tuple is valid
        end
        
        @testset "Type properties" begin
            # Verify Description is a type (DataType or UnionAll depending on Julia version)
            @test CTBase.Description isa Type
            @test CTBase.Description == Tuple{Vararg{Symbol}}
            
            # Verify concrete tuple instances are of Description type
            @test (:a, :b) isa CTBase.Description
            @test (:x,) isa CTBase.Description
            @test () isa CTBase.Description
            
            # Verify concrete tuple types are subtypes
            @test Tuple{Symbol, Symbol} <: Tuple{Vararg{Symbol}}
            @test Tuple{Symbol} <: Tuple{Vararg{Symbol}}
            @test Tuple{} <: Tuple{Vararg{Symbol}}
            
            # Verify non-Symbol tuples are not of Description type
            @test !((1, 2) isa CTBase.Description)
            @test !("hello" isa CTBase.Description)
            @test !([1, 2, 3] isa CTBase.Description)
        end
        
        @testset "Type parameter behavior" begin
            # Test that Description accepts any number of Symbols
            desc1::CTBase.Description = (:a,)
            desc2::CTBase.Description = (:a, :b)
            desc3::CTBase.Description = (:a, :b, :c)
            desc4::CTBase.Description = ()
            
            @test desc1 isa CTBase.Description
            @test desc2 isa CTBase.Description
            @test desc3 isa CTBase.Description
            @test desc4 isa CTBase.Description
            
            # Verify length variability
            @test length(desc1) == 1
            @test length(desc2) == 2
            @test length(desc3) == 3
            @test length(desc4) == 0
        end
        
        @testset "Type usage in collections" begin
            # Verify Description can be used in tuples of descriptions
            catalog::Tuple{Vararg{CTBase.Description}} = ((:a, :b), (:c, :d))
            @test length(catalog) == 2
            @test catalog[1] isa CTBase.Description
            @test catalog[2] isa CTBase.Description
            
            # Verify in vectors
            vec_catalog::Vector{CTBase.Description} = [(:a, :b), (:c, :d)]
            @test length(vec_catalog) == 2
            @test vec_catalog[1] isa CTBase.Description
        end
        
        @testset "Type inference with aliases" begin
            # Verify type inference works correctly
            function create_description(syms::Symbol...)::CTBase.Description
                return syms
            end
            
            result = create_description(:a, :b, :c)
            @test result isa CTBase.Description
            @test result == (:a, :b, :c)
            
            # Test with @inferred
            @test (@inferred create_description(:x, :y)) isa CTBase.Description
        end
    end
end

end # module

test_description_types() = TestDescriptionTypes.test_description_types()
