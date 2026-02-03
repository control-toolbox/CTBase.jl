function test_default()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Default value of the display during resolution" begin
        @test CTBase.__display()
    end
end
