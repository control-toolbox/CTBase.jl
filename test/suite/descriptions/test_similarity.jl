module TestSimilarity

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_similarity()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Similarity Utilities" begin
        @testset "compute_similarity" begin
            @test CTBase.Descriptions.compute_similarity((:a, :b), (:a, :b)) == 1.0
            @test CTBase.Descriptions.compute_similarity((:a, :b), (:a, :c)) == 1 / 3
            @test CTBase.Descriptions.compute_similarity((:a, :c), (:a, :b, :c)) == 2 / 3
            @test CTBase.Descriptions.compute_similarity((:x, :y), (:a, :b)) == 0.0
            @test CTBase.Descriptions.compute_similarity((), ()) == 0.0
            @test CTBase.Descriptions.compute_similarity((), (:a,)) == 0.0
        end

        @testset "find_similar_descriptions" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y))
            target = (:a,)
            similar = CTBase.Descriptions.find_similar_descriptions(target, descriptions)
            @test length(similar) == 2
            @test "(:a, :b)" in similar
            @test "(:a, :c)" in similar
            @test !("(:x, :y)" in similar)

            @test isempty(
                CTBase.Descriptions.find_similar_descriptions((:z,), descriptions)
            )
        end

        @testset "format_description_candidates" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y), (:p, :q), (:r, :s), (:t, :u))
            formatted = CTBase.Descriptions.format_description_candidates(descriptions)
            @test length(formatted) == 5 # default max check

            formatted3 = CTBase.Descriptions.format_description_candidates(
                descriptions; max_show=3
            )
            @test length(formatted3) == 3
        end
    end
end

end # module

test_similarity() = TestSimilarity.test_similarity()
