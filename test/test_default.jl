function test_default()

    @testset "Default value of the display during resolution" begin
        @test CTBase.__display()
    end

end
