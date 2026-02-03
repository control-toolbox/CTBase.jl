module TestRemove

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_remove()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Remove Symbols" begin
        x = (:a, :b, :c)
        y = (:b,)
        @test CTBase.remove(x, y) == (:a, :c)
        @test typeof(CTBase.remove(x, y)) <: CTBase.Description
        
        # Type stability check
        result = CTBase.remove(x, y)
        @test typeof(result) <: Tuple{Vararg{Symbol}}
    end
end

end # module

test_remove() = TestRemove.test_remove()
