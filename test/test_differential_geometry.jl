using Test
using CTBase
using MacroTools: @capture, postwalk
include("../src/differential_geometry.jl")

# ---------------------------------------------------------------------------
function test_differential_geometry()

    @testset "Lifts" begin
        
        @testset "from VectorFields" begin
    
            # autonomous case
            X = VectorField(x -> 2x)
            H = Lift(X)
            Test.@test H(1, 1) == 2
            Test.@test H([1, 2], [3, 4]) == 22
            Test.@test_throws MethodError H([1, 2], 1)
            Test.@test_throws MethodError H(1, [1, 2])
    
            # multiple VectorFields
            X1 = VectorField(x -> 2x)
            X2 = VectorField(x -> 3x)
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1) == 2
            Test.@test H1([1, 2], [3, 4]) == 22
            Test.@test H2(1, 1) == 3
            Test.@test H2([1, 2], [3, 4]) == 33
    
            # nonautonomous case
            X = VectorField((t, x) -> 2x, time_dependence=:nonautonomous)
            H = Lift(X)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22
    
            # multiple VectorFields
            X1 = VectorField((t, x) -> 2x, time_dependence=:nonautonomous)
            X2 = VectorField((t, x) -> 3x, time_dependence=:nonautonomous)
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4]) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4]) == 33
    
        end
        
        @testset "from Function" begin
    
            # autonomous case
            X = x -> 2x
            H = Lift(X)
            Test.@test H(1, 1) == 2
            Test.@test H([1, 2], [3, 4]) == 22
    
            # multiple Functions
            X1 = x -> 2x
            X2 = x -> 3x
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1) == 2
            Test.@test H1([1, 2], [3, 4]) == 22
            Test.@test H2(1, 1) == 3
            Test.@test H2([1, 2], [3, 4]) == 33
    
            # nonautonomous case
            X = (t, x) -> 2x
            H = Lift(X, time_dependence=:nonautonomous)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22
    
            # multiple Functions
            X1 = (t, x) -> 2x
            X2 = (t, x) -> 3x
            H1, H2 = Lift(X1, X2, time_dependence=:nonautonomous)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4]) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4]) == 33

            # exceptions
            Test.@test_throws IncorrectArgument Lift(X1, time_dependence=:dummy)
            Test.@test_throws IncorrectArgument Lift(X1, X2, time_dependence=:dummy)
    
        end
    
    end # tests for Lift

    @testset "Directional derivative of a scalar function" begin
    
        # autonomous, dim 2
        X = VectorField(x -> [x[2], -x[1]])
        f = x -> x[1]^2 + x[2]^2
        Test.@test Der(X, f)([1, 2]) == 0
        Test.@test (X⋅f)([1, 2]) == Der(X, f)([1, 2])

        # autonomous, dim 1
        X = VectorField(x -> 2x)
        f = x -> x^2
        Test.@test Der(X, f)(1) == 4
        Test.@test (X⋅f)(1) == Der(X, f)(1)
    
        # nonautonomous, dim 2
        X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
        f = (t, x) -> t + x[1]^2 + x[2]^2
        Test.@test Der(X, f)(1, [1, 2]) == 2
        Test.@test (X⋅f)(1, [1, 2]) == Der(X, f)(1, [1, 2])

        # nonautonomous, dim 1
        X = VectorField((t, x) -> 2x+t, time_dependence=:nonautonomous)
        f = (t, x) -> t + x^2
        Test.@test Der(X, f)(1, 1) == 6
        Test.@test (X⋅f)(1, 1) == Der(X, f)(1, 1)
    
    end

    @testset "Directional derivative of a vector field" begin
        
        # autonomous, dim 2
        X = VectorField(x -> [x[2], -x[1]])
        Y = VectorField(x -> [x[1], x[2]])
        Test.@test ⅋(X, Y)([1, 2]) == [2, -1]

        # autonomous, dim 1, with state_dimension
        X = VectorField(x -> 2x, state_dimension=1)
        Y = VectorField(x -> 3x, state_dimension=1)
        Test.@test ⅋(X, Y)(1) == 6

        # autonomous, dim 1
        X = VectorField(x -> 2x)
        Y = VectorField(x -> 3x)
        Test.@test ⅋(X, Y)(1) == 6

        # nonautonomous, dim 2
        X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
        Y = VectorField((t, x) -> [t + x[1], x[2]], time_dependence=:nonautonomous)
        Test.@test ⅋(X, Y)(1, [1, 2]) == [3, -1]

        # nonautonomous, dim 1, with state_dimension
        X = VectorField((t, x) -> 2x+t, time_dependence=:nonautonomous, state_dimension=1)
        Y = VectorField((t, x) -> 3x+t, time_dependence=:nonautonomous, state_dimension=1)
        Test.@test ⅋(X, Y)(1, 1) == 9

        # nonautonomous, dim 1
        X = VectorField((t, x) -> 2x+t, time_dependence=:nonautonomous)
        Y = VectorField((t, x) -> 3x+t, time_dependence=:nonautonomous)
        Test.@test ⅋(X, Y)(1, 1) == 9

    end

    @testset "Lie bracket - length 2" begin
        
        @testset "autonomous case" begin
            f = x -> [x[2], 2x[1]]
            g = x -> [3x[2], -x[1]]
            X = VectorField(f)
            Y = VectorField(g)
            Test.@test Lie(X, Y)([1, 2]) == [7, -14]
            Test.@test Lie(X, Y)([1, 2]) == ad(X, Y)([1, 2])
            Test.@test Lie(X, Y)([1, 2]) == Lie(f, g)([1, 2])
            Test.@test Lie(X, Y)([1, 2]) == ad(f, g)([1, 2])
        end

        @testset "nonautonomous case" begin
            f = (t, x) -> [t + x[2], -2x[1]]
            g = (t, x) -> [t + 3x[2], -x[1]]
            X = VectorField(f, time_dependence=:nonautonomous)
            Y = VectorField(g, time_dependence=:nonautonomous)
            Test.@test Lie(X, Y)(1, [1, 2]) == [-5,11]
            Test.@test Lie(X, Y)(1, [1, 2]) == ad(X, Y)(1, [1, 2])
            Test.@test Lie(X, Y)(1, [1, 2]) == Lie(f, g, time_dependence=:nonautonomous)(1, [1, 2])
            Test.@test Lie(X, Y)(1, [1, 2]) == ad(f, g, time_dependence=:nonautonomous)(1, [1, 2])
        end

        @testset "mri example" begin
            Γ = 2
            γ = 1
            δ = γ-Γ
            F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])])
            F1 = VectorField(x -> [0, -x[3], x[2]])
            F2 = VectorField(x -> [x[3], 0, -x[1]])
            F01 = Lie(F0, F1)
            F02 = Lie(F0, F2)
            F12 = Lie(F1, F2)
            x = [1, 2, 3]
            Test.@test F01(x) ≈ -[0, γ-δ*x[3], -δ*x[2]] atol=1e-6
            Test.@test F02(x) ≈ -[-γ+δ*x[3], 0, δ*x[1]] atol=1e-6
            Test.@test F12(x) ≈ -[-x[2], x[1], 0] atol=1e-6
        end

        @testset "intrinsic definition" begin

            X = VectorField(x -> [x[2]^2, -2x[1]*x[2]])
            Y = VectorField(x -> [x[1]*(1+x[2]), 3x[2]^3])
            f = x -> x[1]^4 + 2x[2]^3
            x = [1, 2]

            # check real intrinsic order 2 definition of Lie bracket
            Test.@test ((@Lie [ X, Y ])⋅f)(x) == ((X⋅(Y⋅f))(x) - (Y⋅(X⋅f))(x))

        end

        @testset "exceptions" begin
            X = VectorField(x -> [x[2], -x[1]])
            Y = VectorField(x -> [x[2], -x[1]])
            Test.@test_throws TypeError _Lie_sequence(X, Y, sequence=0)
            Test.@test_throws TypeError _Lie_sequence(X, Y, sequence=1.5)
            Test.@test_throws TypeError _Lie_sequence(X, Y, sequence=(1, 1.5))
            Test.@test_throws IncorrectArgument _Lie_sequence(X, sequence=(1, 1))
            Test.@test_throws IncorrectArgument _Lie_sequence(X, Y, sequence=(1,))
            Test.@test_throws IncorrectArgument _Lie_sequence(X, Y, sequence=(1, 0))
            Test.@test_throws IncorrectArgument _Lie_sequence(X, Y, sequence=(1, 2, 3))            
        end

    end # tests for Lie bracket - sequence 1

    @testset "multiple Lie brackets of any length" begin

        x = [1, 2, 3]
        Γ = 2
        γ = 1
        δ = γ-Γ
        F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])])
        F1 = VectorField(x -> [0, -x[3], x[2]])
        F2 = VectorField(x -> [x[3], 0, -x[1]])

        # length 2
        F01_ = Lie(F0, F1)
        F02_ = Lie(F0, F2)
        F12_ = Lie(F1, F2)

        #
        F01 = _Lie_sequence(F0, F1, sequence=(1,2))
        F02 = _Lie_sequence(F0, F2, sequence=(1,2))
        F12 = _Lie_sequence(F1, F2, sequence=(1,2))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6     
        
        # length 3
        F120_ = _Lie_sequence(F12, F0, sequence=(1,2))
        F121_ = _Lie_sequence(F12, F1, sequence=(1,2))
        F122_ = _Lie_sequence(F12, F2, sequence=(1,2))
        F011_ = _Lie_sequence(F01, F1, sequence=(1,2))
        F012_ = _Lie_sequence(F01, F2, sequence=(1,2))
        F022_ = _Lie_sequence(F02, F2, sequence=(1,2))
        F010_ = _Lie_sequence(F01, F0, sequence=(1,2))
        F020_ = _Lie_sequence(F02, F0, sequence=(1,2))

        F120 = _Lie_sequence(F0, F1, F2, sequence=(2,3,1))
        F121 = _Lie_sequence(F1, F2, sequence=(1,2,1))
        F122 = _Lie_sequence(F1, F2, sequence=(1,2,2))
        F011 = _Lie_sequence(F0, F1, sequence=(1,2,2))
        F012 = _Lie_sequence(F0, F1, F2, sequence=(1,2,3))
        F012_default = _Lie_sequence(F0, F1, F2)
        F022 = _Lie_sequence(F0, F2, sequence=(1,2,2))
        F010 = _Lie_sequence(F0, F1, sequence=(1,2,1))
        F020 = _Lie_sequence(F0, F2, sequence=(1,2,1))

        Test.@test F120(x) ≈ F120_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6
        Test.@test F011(x) ≈ F011_(x) atol=1e-6
        Test.@test F012(x) ≈ F012_(x) atol=1e-6
        Test.@test F012_default(x) ≈ F012_(x) atol=1e-6
        Test.@test F022(x) ≈ F022_(x) atol=1e-6
        Test.@test F010(x) ≈ F010_(x) atol=1e-6
        Test.@test F020(x) ≈ F020_(x) atol=1e-6

        Test.@test F120_(x) ≈ [0, 0, 0] atol=1e-6
        Test.@test F121_(x) ≈ F2(x) atol=1e-6
        Test.@test F122_(x) ≈ -F1(x) atol=1e-6
        Test.@test F011_(x) ≈ [0, -2*δ*x[2], -γ+2*δ*x[3]] atol=1e-6
        Test.@test F012_(x) ≈ [δ*x[2], δ*x[1], 0] atol=1e-6
        Test.@test F022_(x) ≈ [-2*δ*x[1], 0, 2*δ*x[3]-γ] atol=1e-6
        Test.@test F010_(x) ≈ [0, -γ*(γ-2*Γ)+δ^2*x[3], -δ^2*x[2]] atol=1e-6
        Test.@test F020_(x) ≈ [γ*(γ-2*Γ)-δ^2*x[3], 0, δ^2*x[1]] atol=1e-6

    end

    @testset "macro" begin

        # parameters
        t = 1
        x = [1, 2, 3]
        Γ = 2
        γ = 1
        δ = γ-Γ

        # autonomous
        F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])])
        F1 = VectorField(x -> [0, -x[3], x[2]])
        F2 = VectorField(x -> [x[3], 0, -x[1]])
        F01_  = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__= @Lie [F0, F1]
        F011__= @Lie [[F0, F1], F1]
        # @Lie F01
        # @Lie F011
        #Test.@test F01(x) ≈ F01_(x) atol=1e-6
        #Test.@test F011(x) ≈ F011_(x) atol=1e-6
        Test.@test F01_(x) ≈ F01__(x) atol=1e-6
        Test.@test F011_(x) ≈ F011__(x) atol=1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(x) ≈ F011___(x) atol=1e-6

        # nonautonomous
        F0 = VectorField((t,x) -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])], time_dependence=:nonautonomous)
        F1 = VectorField((t,x) -> [0, -x[3], x[2]], time_dependence=:nonautonomous)
        F2 = VectorField((t,x) -> [x[3], 0, -x[1]], time_dependence=:nonautonomous)
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__= @Lie [F0, F1]
        F011__= @Lie [[F0, F1], F1]
        # @Lie F01
        # @Lie F011
        # Test.@test F01(t,x) ≈ F01_(t,x) atol=1e-6
        # Test.@test F011(t,x) ≈ F011_(t,x) atol=1e-6
        Test.@test F01_(t,x) ≈ F01__(t,x) atol=1e-6
        Test.@test F011_(t,x) ≈ F011__(t,x) atol=1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(t, x) ≈ F011___(t, x) atol=1e-6

    end

    @testset "Poisson" begin

        

        # Define the Hamiltonian functions
        function f1(x, p)
            return(0.5*(x[1]^2+x[2]^2+p[1]^2))
        end

        function f2(x, p)
            return(0.5*(x[1]^2+x[2]^2+p[2]^2))
        end

        H_1 = Hamiltonian(f1)
        H_2 = Hamiltonian(f2)

        println(typeof(H_1) <: AbstractHamiltonian)

        # Test case 1
        H_1_2 = Poisson(H_1, H_2)

        # Test case 2
        H_2_1 = Poisson(H_2, H_1)

        # Test case 3
        H_1_1 = Poisson(H_1, H_1)

    end

end # test_differential_geometry

@testset "differential geometry" begin
    test_differential_geometry()
end
