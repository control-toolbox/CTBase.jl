module TestSimilarity

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_similarity()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Similarity Utilities" begin
        
        # ====================================================================
        # UNIT TESTS - Similarity Computation
        # ====================================================================
        
        @testset "compute_similarity - basic cases" begin
            # Identical descriptions
            @test CTBase.Descriptions.compute_similarity((:a, :b), (:a, :b)) == 1.0
            
            # Partial overlap
            @test CTBase.Descriptions.compute_similarity((:a, :b), (:a, :c)) == 1 / 3
            @test CTBase.Descriptions.compute_similarity((:a, :c), (:a, :b, :c)) == 2 / 3
            
            # No overlap
            @test CTBase.Descriptions.compute_similarity((:x, :y), (:a, :b)) == 0.0
        end
        
        @testset "compute_similarity - edge cases" begin
            # Empty tuples
            @test CTBase.Descriptions.compute_similarity((), ()) == 0.0
            @test CTBase.Descriptions.compute_similarity((), (:a,)) == 0.0
            @test CTBase.Descriptions.compute_similarity((:a,), ()) == 0.0
            
            # Single-element tuples
            @test CTBase.Descriptions.compute_similarity((:a,), (:a,)) == 1.0
            @test CTBase.Descriptions.compute_similarity((:a,), (:b,)) == 0.0
            @test CTBase.Descriptions.compute_similarity((:a,), (:a, :b)) == 0.5
            
            # Large descriptions
            desc1 = (:a, :b, :c, :d, :e)
            desc2 = (:a, :b, :c, :d, :e)
            @test CTBase.Descriptions.compute_similarity(desc1, desc2) == 1.0
            
            desc3 = (:a, :b, :c)
            desc4 = (:d, :e, :f)
            @test CTBase.Descriptions.compute_similarity(desc3, desc4) == 0.0
        end
        
        @testset "compute_similarity - mathematical properties" begin
            # Symmetry: sim(A, B) == sim(B, A)
            desc1 = (:a, :b, :c)
            desc2 = (:b, :c, :d)
            @test CTBase.Descriptions.compute_similarity(desc1, desc2) == 
                  CTBase.Descriptions.compute_similarity(desc2, desc1)
            
            # Reflexivity: sim(A, A) == 1.0
            @test CTBase.Descriptions.compute_similarity(desc1, desc1) == 1.0
            @test CTBase.Descriptions.compute_similarity(desc2, desc2) == 1.0
            
            # Range: 0.0 <= sim(A, B) <= 1.0
            desc3 = (:x, :y)
            desc4 = (:a, :b, :c, :d)
            sim = CTBase.Descriptions.compute_similarity(desc3, desc4)
            @test 0.0 <= sim <= 1.0
        end
        
        @testset "Type stability - compute_similarity" begin
            # Basic case
            @test (@inferred CTBase.Descriptions.compute_similarity((:a, :b), (:a, :c))) isa Float64
            
            # Edge cases
            @test (@inferred CTBase.Descriptions.compute_similarity((), ())) isa Float64
            @test (@inferred CTBase.Descriptions.compute_similarity((:a,), (:b,))) isa Float64
            
            # Verify always returns Float64
            result = CTBase.Descriptions.compute_similarity((:a, :b, :c), (:b, :c, :d))
            @test result isa Float64
        end
        
        # ====================================================================
        # UNIT TESTS - Similar Descriptions Finding
        # ====================================================================
        
        @testset "find_similar_descriptions - basic" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y))
            target = (:a,)
            similar = CTBase.Descriptions.find_similar_descriptions(target, descriptions)
            @test length(similar) == 2
            @test "(:a, :b)" in similar
            @test "(:a, :c)" in similar
            @test !("(:x, :y)" in similar)
            
            # No similar descriptions
            @test isempty(
                CTBase.Descriptions.find_similar_descriptions((:z,), descriptions)
            )
        end
        
        @testset "find_similar_descriptions - boundaries" begin
            # Test max_results boundary - exactly max_results
            descriptions = ((:a, :b), (:a, :c), (:a, :d), (:a, :e), (:a, :f))
            target = (:a,)
            similar = CTBase.Descriptions.find_similar_descriptions(target, descriptions; max_results=5)
            @test length(similar) == 5
            
            # More than max_results available
            descriptions2 = ((:a, :b), (:a, :c), (:a, :d), (:a, :e), (:a, :f), (:a, :g))
            similar2 = CTBase.Descriptions.find_similar_descriptions(target, descriptions2; max_results=3)
            @test length(similar2) == 3
            
            # Less than max_results available
            descriptions3 = ((:a, :b), (:a, :c))
            similar3 = CTBase.Descriptions.find_similar_descriptions(target, descriptions3; max_results=5)
            @test length(similar3) == 2
            
            # All zero similarity (should return empty)
            descriptions4 = ((:x, :y), (:z, :w))
            similar4 = CTBase.Descriptions.find_similar_descriptions((:a,), descriptions4)
            @test isempty(similar4)
        end
        
        @testset "find_similar_descriptions - edge cases" begin
            # Empty descriptions catalog
            @test isempty(
                CTBase.Descriptions.find_similar_descriptions((:a,), ())
            )
            
            # Empty target
            descriptions = ((:a, :b), (:c, :d))
            @test isempty(
                CTBase.Descriptions.find_similar_descriptions((), descriptions)
            )
            
            # Single description in catalog
            descriptions2 = ((:a, :b),)
            similar = CTBase.Descriptions.find_similar_descriptions((:a,), descriptions2)
            @test length(similar) == 1
            @test "(:a, :b)" in similar
        end
        
        @testset "Type stability - find_similar_descriptions" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y))
            target = (:a,)
            
            @test (@inferred CTBase.Descriptions.find_similar_descriptions(target, descriptions)) isa Vector{String}
            @test (@inferred CTBase.Descriptions.find_similar_descriptions(target, descriptions; max_results=3)) isa Vector{String}
            
            # Edge cases
            @test (@inferred CTBase.Descriptions.find_similar_descriptions((), ())) isa Vector{String}
        end
        
        # ====================================================================
        # UNIT TESTS - Candidate Formatting
        # ====================================================================
        
        @testset "format_description_candidates - basic" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y), (:p, :q), (:r, :s), (:t, :u))
            formatted = CTBase.Descriptions.format_description_candidates(descriptions)
            @test length(formatted) == 5 # default max_show=5
            @test formatted[1] == "(:a, :b)"
            @test formatted[5] == "(:r, :s)"
            
            # Custom max_show
            formatted3 = CTBase.Descriptions.format_description_candidates(
                descriptions; max_show=3
            )
            @test length(formatted3) == 3
            @test formatted3[1] == "(:a, :b)"
            @test formatted3[3] == "(:x, :y)"
        end
        
        @testset "format_description_candidates - boundaries" begin
            # Exactly max_show descriptions
            descriptions = ((:a, :b), (:c, :d), (:e, :f), (:g, :h), (:i, :j))
            formatted = CTBase.Descriptions.format_description_candidates(descriptions; max_show=5)
            @test length(formatted) == 5
            
            # Less than max_show
            descriptions2 = ((:a, :b), (:c, :d))
            formatted2 = CTBase.Descriptions.format_description_candidates(descriptions2; max_show=5)
            @test length(formatted2) == 2
            
            # More than max_show
            descriptions3 = ((:a, :b), (:c, :d), (:e, :f), (:g, :h), (:i, :j), (:k, :l))
            formatted3 = CTBase.Descriptions.format_description_candidates(descriptions3; max_show=3)
            @test length(formatted3) == 3
            
            # max_show=1
            formatted4 = CTBase.Descriptions.format_description_candidates(descriptions3; max_show=1)
            @test length(formatted4) == 1
            @test formatted4[1] == "(:a, :b)"
        end
        
        @testset "format_description_candidates - edge cases" begin
            # Empty descriptions
            @test isempty(
                CTBase.Descriptions.format_description_candidates(())
            )
            
            # Single description
            descriptions = ((:a, :b),)
            formatted = CTBase.Descriptions.format_description_candidates(descriptions)
            @test length(formatted) == 1
            @test formatted[1] == "(:a, :b)"
        end
        
        @testset "Type stability - format_description_candidates" begin
            descriptions = ((:a, :b), (:c, :d), (:e, :f))
            
            @test (@inferred CTBase.Descriptions.format_description_candidates(descriptions)) isa Vector{String}
            @test (@inferred CTBase.Descriptions.format_description_candidates(descriptions; max_show=2)) isa Vector{String}
            
            # Edge case
            @test (@inferred CTBase.Descriptions.format_description_candidates(())) isa Vector{String}
        end
    end
end

end # module

test_similarity() = TestSimilarity.test_similarity()
