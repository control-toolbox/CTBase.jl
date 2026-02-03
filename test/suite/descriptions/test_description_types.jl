module TestDescriptionTypes

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_description_types()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Description Types" begin
        @test CTBase.DescVarArg == Vararg{Symbol}
        @test CTBase.Description == Tuple{Vararg{Symbol}}
    end
end

end # module

test_description_types() = TestDescriptionTypes.test_description_types()
