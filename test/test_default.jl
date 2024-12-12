function test_default()
    @testset "Audo diff" begin
        set_AD_backend(AutoForwardDiff())
        @test CTBase.__get_AD_backend() == AutoForwardDiff()
    end

    @testset "Default value of the time dependence of the functions" begin
        @test CTBase.__fun_time_dependence() == Autonomous
    end

    @testset "Default value of the time dependence of the Optimal Control Problem" begin
        @test CTBase.__ocp_time_dependence() == Autonomous
    end

    @testset "Default value of the variable dependence of the functions" begin
        @test CTBase.__fun_variable_dependence() == Fixed
    end

    @testset "Default value of the variable dependence of the Optimal Control Problem" begin
        @test CTBase.__ocp_variable_dependence() == Fixed
    end

    @testset "Default value of the state names of the Optimal Control Problem" begin
        @test CTBase.__state_name() == "x"
        @test CTBase.__state_components_names(2, CTBase.__state_name()) == ["x₁", "x₂"]
    end

    @testset "Default value of the control names of the Optimal Control Problem" begin
        @test CTBase.__control_name() == "u"
        @test CTBase.__control_components_names(2, CTBase.__control_name()) == ["u₁", "u₂"]
    end

    @testset "Default value of the variable names of the Optimal Control Problem" begin
        @test CTBase.__variable_name() == "v"
        @test CTBase.__variable_components_names(2, CTBase.__variable_name()) ==
            ["v₁", "v₂"]
    end

    @testset "Default value of the time name of the Optimal Control Problem" begin
        @test CTBase.__time_name() == "t"
    end

    @testset "Default value of the criterion type of the Optimal Control Problem" begin
        @test CTBase.__criterion_type() == :min
    end

    @testset "Default value of the constraint label" begin
        @test CTBase.__constraint_label() isa Symbol
    end

    @testset "Default value of the stockage of elements in a matrix" begin
        @test CTBase.__matrix_dimension_stock() == 1
    end

    @testset "Default value of the display during resolution" begin
        @test CTBase.__display() isa Bool
    end

    @testset "Default value of the additional callback function" begin
        @test isempty(CTBase.__callbacks())
    end

    @testset "Default value of the interpolation function for initialisation" begin
        @test CTBase.__init_interpolation() isa Function
    end

    @testset "Default value of the initial guess" begin
        @test isnothing(CTBase.__ocp_init())
    end
end
