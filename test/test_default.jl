function test_default()

    @testset "Default value of the time dependence of the functions" begin
        @test CTBase.__fun_time_dependence() == :autonomous
    end

    @testset "Default value of the dimension usage of the functions" begin
        @test CTBase.__fun_dimension_usage() == :scalar
    end

    @testset "Default value of the time dependence of the Optimal Control Problem" begin
        @test CTBase.__ocp_time_dependence() == :autonomous
    end

    @testset "Default value of the dimension usage of the Optimal Control Problem" begin
        @test CTBase.__ocp_dimension_usage() == :scalar
    end

    @testset "Default value of the state names of the Optimal Control Problem" begin
        @test CTBase.__state_names(1) == "x"
        @test CTBase.__state_names(2) == ["x₁", "x₂"]
    end

    @testset "Default value of the control names of the Optimal Control Problem" begin
        @test CTBase.__control_names(1) == "u"
        @test CTBase.__control_names(2) == ["u₁", "u₂"]
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

    @testset "Default value of the grid size for the direct shooting method" begin
        @test CTBase.__grid_size_direct_shooting() isa Integer
    end

    @testset "Default value of the penalty term for the direct shooting method" begin
        @test CTBase.__penalty_term_direct_shooting() isa Real
    end

    @testset "Default value of the maximum number of iterations for the direct shooting method" begin
        @test CTBase.__max_iter_direct_shooting() isa Integer
    end

    @testset "Default value of the absolute tolerance for the direct shooting method" begin
        @test CTBase.__abs_tol_direct_shooting() isa Real
    end

    @testset "Default value of the optimality tolerance for the direct shooting method" begin
        @test CTBase.__opt_tol_direct_shooting() isa Real
    end

    @testset "Default value of the stagnation tolerance for the direct shooting method" begin
        @test CTBase.__stagnation_tol_direct_shooting() isa Real
    end

    @testset "Default value of the grid size for the direct method" begin
        @test CTBase.__grid_size_direct() isa Integer
    end

    @testset "Default value of the print level of ipopt for the direct method" begin
        @test CTBase.__print_level_ipopt() isa Integer
        @test CTBase.__print_level_ipopt() ≤ 12
        @test CTBase.__print_level_ipopt() ≥ 0
    end

    @testset "Default value of the mu strategy of ipopt for the direct method" begin
        @test CTBase.__mu_strategy_ipopt() isa String
    end

end