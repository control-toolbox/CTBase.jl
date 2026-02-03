module TestCatalog

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_catalog()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Catalog Operations" begin
        @testset "Add descriptions" begin
            descriptions = ()
            descriptions = CTBase.add(descriptions, (:a,))
            @test descriptions[1] == (:a,)
            descriptions = CTBase.add(descriptions, (:b,))
            @test descriptions[1] == (:a,)
            @test descriptions[2] == (:b,)
        end

        @testset "Duplicate Description Addition" begin
            algorithms = ()
            algorithms = CTBase.add(algorithms, (:a, :b, :c))

            @test_throws CTBase.IncorrectArgument CTBase.add(algorithms, (:a, :b, :c))

            # Enriched error check - rigorous
            try
                CTBase.add(algorithms, (:a, :b, :c))
            catch e
                @test e isa CTBase.IncorrectArgument
                @test occursin("already in", e.msg)
                @test e.got == "(:a, :b, :c)"
                @test occursin("unique description", e.expected)
                @test occursin("Check existing descriptions", e.suggestion)
            end
        end
    end
end

end # module

test_catalog() = TestCatalog.test_catalog()
