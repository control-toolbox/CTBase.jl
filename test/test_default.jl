function test_default()

    @testset "Audo diff" begin
        CTBase.set_AD_backend(AutoForwardDiff())
        @test CTBase.__get_AD_backend() == AutoForwardDiff()
    end

    @testset "Default value of the stockage of elements in a matrix" begin
        @test CTBase.__matrix_dimension_stock() == 1
    end

    @testset "Default value of the display during resolution" begin
        @test CTBase.__display() isa Bool
    end

    @testset "Default value of the interpolation function for initialisation" begin
        @test CTBase.__init_interpolation() isa Function
    end

end
