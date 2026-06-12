module TestSimilarity

using Test: Test
import CTBase.Descriptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_similarity()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Similarity Utilities" begin

        # ====================================================================
        # UNIT TESTS - Similarity Computation
        # ====================================================================

        Test.@testset "compute_similarity - basic cases" begin
            # Identical descriptions
            Test.@test Descriptions._compute_similarity((:a, :b), (:a, :b)) == 1.0

            # Partial overlap
            Test.@test Descriptions._compute_similarity((:a, :b), (:a, :c)) == 1 / 3
            Test.@test Descriptions._compute_similarity((:a, :c), (:a, :b, :c)) == 2 / 3

            # No overlap
            Test.@test Descriptions._compute_similarity((:x, :y), (:a, :b)) == 0.0
        end

        Test.@testset "compute_similarity - edge cases" begin
            # Empty tuples
            Test.@test Descriptions._compute_similarity((), ()) == 0.0
            Test.@test Descriptions._compute_similarity((), (:a,)) == 0.0
            Test.@test Descriptions._compute_similarity((:a,), ()) == 0.0

            # Single-element tuples
            Test.@test Descriptions._compute_similarity((:a,), (:a,)) == 1.0
            Test.@test Descriptions._compute_similarity((:a,), (:b,)) == 0.0
            Test.@test Descriptions._compute_similarity((:a,), (:a, :b)) == 0.5

            # Large descriptions
            desc1 = (:a, :b, :c, :d, :e)
            desc2 = (:a, :b, :c, :d, :e)
            Test.@test Descriptions._compute_similarity(desc1, desc2) == 1.0

            desc3 = (:a, :b, :c)
            desc4 = (:d, :e, :f)
            Test.@test Descriptions._compute_similarity(desc3, desc4) == 0.0
        end

        Test.@testset "compute_similarity - mathematical properties" begin
            # Symmetry: sim(A, B) == sim(B, A)
            desc1 = (:a, :b, :c)
            desc2 = (:b, :c, :d)
            Test.@test Descriptions._compute_similarity(desc1, desc2) ==
                Descriptions._compute_similarity(desc2, desc1)

            # Reflexivity: sim(A, A) == 1.0
            Test.@test Descriptions._compute_similarity(desc1, desc1) == 1.0
            Test.@test Descriptions._compute_similarity(desc2, desc2) == 1.0

            # Range: 0.0 <= sim(A, B) <= 1.0
            desc3 = (:x, :y)
            desc4 = (:a, :b, :c, :d)
            sim = Descriptions._compute_similarity(desc3, desc4)
            Test.@test 0.0 <= sim <= 1.0
        end

        Test.@testset "Type stability - compute_similarity" begin
            # Basic case
            Test.@test (Test.@inferred Descriptions._compute_similarity(
                (:a, :b), (:a, :c)
            )) isa Float64

            # Edge cases
            Test.@test (Test.@inferred Descriptions._compute_similarity((), ())) isa Float64
            Test.@test (Test.@inferred Descriptions._compute_similarity((:a,), (:b,))) isa
                Float64

            # Verify always returns Float64
            result = Descriptions._compute_similarity((:a, :b, :c), (:b, :c, :d))
            Test.@test result isa Float64
        end

        # ====================================================================
        # UNIT TESTS - Similar Descriptions Finding
        # ====================================================================

        Test.@testset "find_similar_descriptions - basic" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y))
            target = (:a,)
            similar = Descriptions._find_similar_descriptions(target, descriptions)
            Test.@test length(similar) == 2
            Test.@test "(:a, :b)" in similar
            Test.@test "(:a, :c)" in similar
            Test.@test !("(:x, :y)" in similar)

            # No similar descriptions
            Test.@test isempty(Descriptions._find_similar_descriptions((:z,), descriptions))
        end

        Test.@testset "find_similar_descriptions - boundaries" begin
            # Test max_results boundary - exactly max_results
            descriptions = ((:a, :b), (:a, :c), (:a, :d), (:a, :e), (:a, :f))
            target = (:a,)
            similar = Descriptions._find_similar_descriptions(
                target, descriptions; max_results=5
            )
            Test.@test length(similar) == 5

            # More than max_results available
            descriptions2 = ((:a, :b), (:a, :c), (:a, :d), (:a, :e), (:a, :f), (:a, :g))
            similar2 = Descriptions._find_similar_descriptions(
                target, descriptions2; max_results=3
            )
            Test.@test length(similar2) == 3

            # Less than max_results available
            descriptions3 = ((:a, :b), (:a, :c))
            similar3 = Descriptions._find_similar_descriptions(
                target, descriptions3; max_results=5
            )
            Test.@test length(similar3) == 2

            # All zero similarity (should return empty)
            descriptions4 = ((:x, :y), (:z, :w))
            similar4 = Descriptions._find_similar_descriptions((:a,), descriptions4)
            Test.@test isempty(similar4)
        end

        Test.@testset "find_similar_descriptions - edge cases" begin
            # Empty descriptions catalog
            Test.@test isempty(Descriptions._find_similar_descriptions((:a,), ()))

            # Empty target
            descriptions = ((:a, :b), (:c, :d))
            Test.@test isempty(Descriptions._find_similar_descriptions((), descriptions))

            # Single description in catalog
            descriptions2 = ((:a, :b),)
            similar = Descriptions._find_similar_descriptions((:a,), descriptions2)
            Test.@test length(similar) == 1
            Test.@test "(:a, :b)" in similar
        end

        Test.@testset "Type stability - find_similar_descriptions" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y))
            target = (:a,)

            Test.@test (Test.@inferred Descriptions._find_similar_descriptions(
                target, descriptions
            )) isa Vector{String}
            Test.@test (Test.@inferred Descriptions._find_similar_descriptions(
                target, descriptions; max_results=3
            )) isa Vector{String}

            # Edge cases
            Test.@test (Test.@inferred Descriptions._find_similar_descriptions((), ())) isa
                Vector{String}
        end

        # ====================================================================
        # UNIT TESTS - Candidate Formatting
        # ====================================================================

        Test.@testset "format_description_candidates - basic" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y), (:p, :q), (:r, :s), (:t, :u))
            formatted = Descriptions._format_description_candidates(descriptions)
            Test.@test length(formatted) == 5 # default max_show=5
            Test.@test formatted[1] == "(:a, :b)"
            Test.@test formatted[5] == "(:r, :s)"

            # Custom max_show
            formatted3 = Descriptions._format_description_candidates(
                descriptions; max_show=3
            )
            Test.@test length(formatted3) == 3
            Test.@test formatted3[1] == "(:a, :b)"
            Test.@test formatted3[3] == "(:x, :y)"
        end

        Test.@testset "format_description_candidates - boundaries" begin
            # Exactly max_show descriptions
            descriptions = ((:a, :b), (:c, :d), (:e, :f), (:g, :h), (:i, :j))
            formatted = Descriptions._format_description_candidates(
                descriptions; max_show=5
            )
            Test.@test length(formatted) == 5

            # Less than max_show
            descriptions2 = ((:a, :b), (:c, :d))
            formatted2 = Descriptions._format_description_candidates(
                descriptions2; max_show=5
            )
            Test.@test length(formatted2) == 2

            # More than max_show
            descriptions3 = ((:a, :b), (:c, :d), (:e, :f), (:g, :h), (:i, :j), (:k, :l))
            formatted3 = Descriptions._format_description_candidates(
                descriptions3; max_show=3
            )
            Test.@test length(formatted3) == 3

            # max_show=1
            formatted4 = Descriptions._format_description_candidates(
                descriptions3; max_show=1
            )
            Test.@test length(formatted4) == 1
            Test.@test formatted4[1] == "(:a, :b)"
        end

        Test.@testset "format_description_candidates - edge cases" begin
            # Empty descriptions
            Test.@test isempty(Descriptions._format_description_candidates(()))

            # Single description
            descriptions = ((:a, :b),)
            formatted = Descriptions._format_description_candidates(descriptions)
            Test.@test length(formatted) == 1
            Test.@test formatted[1] == "(:a, :b)"
        end

        Test.@testset "Type stability - format_description_candidates" begin
            descriptions = ((:a, :b), (:c, :d), (:e, :f))

            Test.@test (Test.@inferred Descriptions._format_description_candidates(
                descriptions
            )) isa Vector{String}
            Test.@test (Test.@inferred Descriptions._format_description_candidates(
                descriptions; max_show=2
            )) isa Vector{String}

            # Edge case
            Test.@test (Test.@inferred Descriptions._format_description_candidates(())) isa
                Vector{String}
        end
    end
end

end # module

test_similarity() = TestSimilarity.test_similarity()
