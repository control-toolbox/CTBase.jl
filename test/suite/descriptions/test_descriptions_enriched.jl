module TestDescriptionsEnriched

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_descriptions_enriched()

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Descriptions Helper Functions" begin
        
        # ====================================================================
        # UNIT TESTS - Helper Functions Contract
        # ====================================================================
        
        @testset "compute_similarity" begin
            # Test identical descriptions
            desc1 = (:a, :b)
            desc2 = (:a, :b)
            @test CTBase.compute_similarity(desc1, desc2) == 1.0
            
            # Test partial similarity
            desc3 = (:a, :c)
            desc4 = (:a, :b, :c)
            @test CTBase.compute_similarity(desc3, desc4) == 2/3
            
            # Test no similarity
            desc5 = (:x, :y)
            desc6 = (:a, :b)
            @test CTBase.compute_similarity(desc5, desc6) == 0.0
            
            # Test edge cases
            @test CTBase.compute_similarity((), ()) == 0.0
            @test CTBase.compute_similarity((), (:a,)) == 0.0
        end

        @testset "find_similar_descriptions" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y))
            target = (:a,)
            
            # Test finding similar descriptions
            similar = CTBase.find_similar_descriptions(target, descriptions)
            @test length(similar) == 2  # Should find descriptions containing :a
            @test "(:a, :b)" in similar
            @test "(:a, :c)" in similar
            @test !("(:x, :y)" in similar)
            
            # Test no similar descriptions
            target2 = (:z,)
            similar2 = CTBase.find_similar_descriptions(target2, descriptions)
            @test isempty(similar2)
            
            # Test empty descriptions
            similar3 = CTBase.find_similar_descriptions(target, ())
            @test isempty(similar3)
        end

        @testset "format_description_candidates" begin
            descriptions = ((:a, :b), (:a, :c), (:x, :y), (:p, :q), (:r, :s), (:t, :u))
            
            # Test default max_show=5
            formatted = CTBase.format_description_candidates(descriptions)
            @test length(formatted) == 5
            @test formatted[1] == "(:a, :b)"
            @test formatted[5] == "(:r, :s)"
            
            # Test custom max_show
            formatted2 = CTBase.format_description_candidates(descriptions; max_show=3)
            @test length(formatted2) == 3
            @test formatted2[1] == "(:a, :b)"
            @test formatted2[3] == "(:x, :y)"
            
            # Test empty descriptions
            formatted3 = CTBase.format_description_candidates(())
            @test isempty(formatted3)
        end
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Enriched complete() Errors" begin
        
        # ====================================================================
        # INTEGRATION TESTS - Complete Function
        # ====================================================================
        
        @testset "Empty descriptions" begin
            @test_throws CTBase.AmbiguousDescription CTBase.complete(:a; descriptions=())
            
            try
                CTBase.complete(:a; descriptions=())
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test isempty(e.candidates)
                @test occursin("No descriptions available", e.suggestion)
                @test e.context == "description completion"
            end
        end

        @testset "Description not found with suggestions" begin
            descriptions = ((:a, :b), (:c, :d), (:e, :f))
            
            @test_throws CTBase.AmbiguousDescription CTBase.complete(:x; descriptions=descriptions)
            
            try
                CTBase.complete(:x; descriptions=descriptions)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test e.description == (:x,)
                @test !isempty(e.candidates)
                @test length(e.candidates) == 3  # All descriptions should be candidates
                @test "(:a, :b)" in e.candidates
                @test "(:c, :d)" in e.candidates
                @test "(:e, :f)" in e.candidates
                @test occursin("Available descriptions", e.suggestion)
                @test e.context == "description completion"
            end
        end

        @testset "Description not found with similar suggestions" begin
            descriptions = ((:a, :b, :c), (:a, :d, :e), (:x, :y, :z))
            
            try
                CTBase.complete(:a, :b; descriptions=descriptions)
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.AmbiguousDescription
                @test e.description == (:a, :b)
                @test !isempty(e.candidates)
                @test occursin("similar descriptions", e.suggestion)
                # Should suggest descriptions containing :a
                @test any(occursin("(:a,", candidate) for candidate in e.candidates)
            end
        end

        @testset "Successful completion" begin
            descriptions = ((:a, :b), (:a, :b, :c), (:b, :c))
            
            # Test exact match
            result = CTBase.complete(:a, :b; descriptions=descriptions)
            @test result == (:a, :b)
            
            # Test partial match
            result2 = CTBase.complete(:a; descriptions=descriptions)
            @test result2 in [(:a, :b), (:a, :b, :c)]
        end
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Enriched add() Errors" begin
        
        # ====================================================================
        # ERROR TESTS - Add Function Exception Quality
        # ====================================================================
        
        @testset "Duplicate description" begin
            existing = ((:a, :b), (:c, :d))
            
            @test_throws CTBase.IncorrectArgument CTBase.add(existing, (:a, :b))
            
            try
                CTBase.add(existing, (:a, :b))
                @test false  # Should not reach here
            catch e
                @test e isa CTBase.IncorrectArgument
                @test occursin("already in", e.msg)
                @test e.got == "(:a, :b)"
                @test occursin("unique description", e.expected)
                @test occursin("Check existing descriptions", e.suggestion)
                @test e.context == "description catalog management"
            end
        end

        @testset "Successful addition" begin
            existing = ((:a, :b),)
            new_desc = (:c, :d)
            
            result = CTBase.add(existing, new_desc)
            @test result == ((:a, :b), (:c, :d))
        end
    end

    return nothing
end

end # module

# Export to outer scope for TestRunner
test_descriptions_enriched() = TestDescriptionsEnriched.test_descriptions_enriched()
