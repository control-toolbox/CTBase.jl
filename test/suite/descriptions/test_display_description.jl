module TestDisplayDescription

using Test
using CTBase
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_display_description()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Description Display" begin
        io = IOBuffer()
        descriptions = ((:a, :b), (:b, :c))
        show(io, MIME"text/plain"(), descriptions)
        output = String(take!(io))
        expected = "(:a, :b)\n(:b, :c)"
        @test output == expected
        
        # Edge cases
        io = IOBuffer()
        show(io, MIME"text/plain"(), ())
        @test String(take!(io)) == ""
        
        io = IOBuffer()
        show(io, MIME"text/plain"(), ((:a, :b),))
        @test String(take!(io)) == "(:a, :b)"
    end
end

end # module

test_display_description() = TestDisplayDescription.test_display_description()
