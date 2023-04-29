using Test
using CTBase
include("../src/differential_geometry.jl")

# ---------------------------------------------------------------------------
function test_differential_geometry()

    @testset "Lie derivative" begin
    
        # autonomous
        X = VectorField(x -> [x[2], -x[1]])
        f = x -> x[1]^2 + x[2]^2
        Test.@test Lie(X, f)([1, 2]) == 0
        Test.@test (X⋅f)([1, 2]) == Lie(X, f)([1, 2])
    
        # nonautonomous
        X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
        f = (t, x) -> t + x[1]^2 + x[2]^2
        Test.@test Lie(X, f)(1, [1, 2]) == 2
        Test.@test (X⋅f)(1, [1, 2]) == Lie(X, f)(1, [1, 2])
    
    end

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

    @testset "Lie bracket - minimal order" begin
        
        @testset "autonomous case" begin
            X = VectorField(x -> [x[2], -x[1]])
            Y = VectorField(x -> [x[2], -x[1]])
            Test.@test Lie(X, Y)([1, 2]) == [0, 0]
            Test.@test (X⋅Y)([1, 2]) == Lie(X, Y)([1, 2])
        end

        @testset "nonautonomous case" begin
            X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
            Y = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
            Test.@test Lie(X, Y)(1, [1, 2]) == [0, 0]
            Test.@test (X⋅Y)(1, [1, 2]) == Lie(X, Y)(1, [1, 2])
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

        @testset "exceptions" begin
            X = VectorField(x -> [x[2], -x[1]])
            Y = VectorField(x -> [x[2], -x[1]])
            Test.@test_throws TypeError Lie(X, Y, order=0)
            Test.@test_throws TypeError Lie(X, Y, order=1.5)
            Test.@test_throws TypeError Lie(X, Y, order=(1, 1.5))
            Test.@test_throws IncorrectArgument Lie(X, order=(1, 1))
            Test.@test_throws IncorrectArgument Lie(X, Y, order=(1,))
            Test.@test_throws IncorrectArgument Lie(X, Y, order=(1, 0))
            Test.@test_throws IncorrectArgument Lie(X, Y, order=(1, 2, 3))            
        end

    end # tests for Lie bracket - order 1

    @testset "multiple Lie brackets of any order" begin

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
        F01 = Lie(F0, F1, order=(1,2))
        F02 = Lie(F0, F2, order=(1,2))
        F12 = Lie(F1, F2, order=(1,2))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        
        # length 3
        F120_ = Lie(F12, F0, order=(1,2))
        F121_ = Lie(F12, F1, order=(1,2))
        F122_ = Lie(F12, F2, order=(1,2))
        F011_ = Lie(F01, F1, order=(1,2))
        F012_ = Lie(F01, F2, order=(1,2))
        F022_ = Lie(F02, F2, order=(1,2))
        F010_ = Lie(F01, F0, order=(1,2))
        F020_ = Lie(F02, F0, order=(1,2))

        F120 = Lie(F0, F1, F2, order=(2,3,1))
        F121 = Lie(F1, F2, order=(1,2,1))
        F122 = Lie(F1, F2, order=(1,2,2))
        F011 = Lie(F0, F1, order=(1,2,2))
        F012 = Lie(F0, F1, F2, order=(1,2,3))
        F022 = Lie(F0, F2, order=(1,2,2))
        F010 = Lie(F0, F1, order=(1,2,1))
        F020 = Lie(F0, F2, order=(1,2,1))

        Test.@test F120(x) ≈ F120_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6
        Test.@test F011(x) ≈ F011_(x) atol=1e-6
        Test.@test F012(x) ≈ F012_(x) atol=1e-6
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

        # length 3 with cdot
        F120 = ((F1 ⋅ F2) ⋅ F0)
        Test.@test F120(x) ≈ F120_(x) atol=1e-6

        # length 3 with cdot and no parenthesis
        F120 = F1 ⋅ F2 ⋅ F0
        Test.@test F120(x) ≈ F120_(x) atol=1e-6

        # multiple Lie brackets of any length
        F01, F02, F12 = Lie(F0, F1, F2, orders=((1,2), (1, 3), (2, 3)))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6

        F12, F121, F122 = Lie(F1, F2, orders=((1,2), (1,2,1), (1, 2, 2)))
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6

    end

    @testset "multiple Lie brackets of any order - with labels" begin
        
        x = [1, 2, 3]
        Γ = 2
        γ = 1
        δ = γ-Γ
        F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])], label=:F0)
        F1 = VectorField(x -> [0, -x[3], x[2]], label=:F1)
        F2 = VectorField(x -> [x[3], 0, -x[1]], label=:F2)

        # length 2
        F01_ = Lie(F0, F1)
        F02_ = Lie(F0, F2)
        F12_ = Lie(F1, F2)
        F01 = Lie(F0, F1, order=(:F0, :F1))
        F02 = Lie(F0, F2, order=(:F0, :F2))
        F12 = Lie(F1, F2, order=(:F1, :F2))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        Test.@test F01.label == :F0F1

        # length 3
        F120_ = Lie(F12, F0, order=(1,2))
        F121_ = Lie(F12, F1, order=(1,2))
        F122_ = Lie(F12, F2, order=(1,2))
        F120 = Lie(F0, F1, F2, order=(:F1, :F2, :F0))
        F121 = Lie(F1, F2, order=(:F1, :F2, :F1))
        F122 = Lie(F1, F2, order=(:F1, :F2, :F2))
        Test.@test F120(x) ≈ F120_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6
        Test.@test F120.label == :F1F2F0

        # multiple Lie brackets of any length
        F01, F02, F12 = Lie(F0, F1, F2, orders=((:F0, :F1), (:F0, :F2), (:F1, :F2)))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6

        F12, F121, F122 = Lie(F1, F2, orders=((:F1, :F2), (:F1, :F2, :F1), (:F1, :F2, :F2)))
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6

        # exceptions
        @test_throws IncorrectArgument Lie(F0, F1, order=(:F0, :F1, :F2))
        @test_throws IncorrectArgument Lie(F0, order=(:F0,))
        @test_throws IncorrectArgument Lie(F0, F1, order=(:F0,))
        @test_throws IncorrectArgument Lie(F1, F1, order=(:F0, :F1))

    end

end # test_differential_geometry

@testset "differential geometry" begin
    test_differential_geometry()
end
