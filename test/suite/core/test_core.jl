module TestCore

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_core()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Core" begin
        @testset "Default value of the display during resolution" begin
            @test CTBase.Core.__display()
        end

        @testset "Type aliases" begin
            @test CTBase.ctNumber === Real
            @test CTBase.ctNumber === Real
        end
    end
end

end # module

test_core() = TestCore.test_core()
