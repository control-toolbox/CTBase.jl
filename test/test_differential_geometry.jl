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
            X = VectorField((t, x) -> 2x, NonAutonomous)
            H = Lift(X)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22
    
            # multiple VectorFields
            X1 = VectorField((t, x) -> 2x, NonAutonomous)
            X2 = VectorField((t, x) -> 3x, NonAutonomous)
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4]) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4]) == 33
    
        end
        
        @testset "from Function" begin
    
            # autonomous case
            X::Function = x -> 2x
            H = Lift(X)
            Test.@test H(1, 1) == 2
            Test.@test H([1, 2], [3, 4]) == 22
    
            # multiple Functions
            X1::Function = x -> 2x
            X2::Function = x -> 3x
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1) == 2
            Test.@test H1([1, 2], [3, 4]) == 22
            Test.@test H2(1, 1) == 3
            Test.@test H2([1, 2], [3, 4]) == 33
    
            # nonautonomous case
            Xt::Function = (t, x) -> 2x
            H = Lift(Xt, autonomous=false)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22
    
            # multiple Functions
            X1t::Function = (t, x) -> 2x
            X2t::Function = (t, x) -> 3x
            H1, H2 = Lift(X1t, X2t, autonomous=false)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4]) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4]) == 33

            # exceptions
            Test.@test_throws IncorrectArgument Lift(X1, Int64)
            Test.@test_throws IncorrectArgument Lift(X1, X2, Int64)
    
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
        X = VectorField((t, x) -> [t + x[2], -x[1]], NonAutonomous)
        f = (t, x) -> t + x[1]^2 + x[2]^2
        Test.@test Der(X, f)(1, [1, 2]) == 2
        Test.@test (X⋅f)(1, [1, 2]) == Der(X, f)(1, [1, 2])

        # nonautonomous, dim 1
        X = VectorField((t, x) -> 2x+t, NonAutonomous)
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
        X = VectorField(x -> 2x)
        Y = VectorField(x -> 3x)
        Test.@test ⅋(X, Y)(1) == 6

        # autonomous, dim 1
        X = VectorField(x -> 2x)
        Y = VectorField(x -> 3x)
        Test.@test ⅋(X, Y)(1) == 6

        # nonautonomous, dim 2
        X = VectorField((t, x) -> [t + x[2], -x[1]], NonAutonomous)
        Y = VectorField((t, x) -> [t + x[1], x[2]], NonAutonomous)
        Test.@test ⅋(X, Y)(1, [1, 2]) == [3, -1]

        # nonautonomous, dim 1, with state_dimension
        X = VectorField((t, x) -> 2x+t, NonAutonomous)
        Y = VectorField((t, x) -> 3x+t, NonAutonomous)
        Test.@test ⅋(X, Y)(1, 1) == 9

        # nonautonomous, dim 1
        X = VectorField((t, x) -> 2x+t, NonAutonomous)
        Y = VectorField((t, x) -> 3x+t, NonAutonomous)
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
            X = VectorField(f, NonAutonomous)
            Y = VectorField(g, NonAutonomous)
            Test.@test Lie(X, Y)(1, [1, 2]) == [-5,11]
            Test.@test Lie(X, Y)(1, [1, 2]) == ad(X, Y)(1, [1, 2])
            Test.@test Lie(X, Y)(1, [1, 2]) == Lie(f, g, autonomous=false)(1, [1, 2])
            Test.@test Lie(X, Y)(1, [1, 2]) == ad(f, g, autonomous=false)(1, [1, 2])
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
    end

    @testset "lie macro" begin

        # parameters
        t = 1
        x = [1, 2, 3]
        Γ = 2
        γ = 1
        δ = γ-Γ
        v = 1

        # autonomous
        F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])])
        F1 = VectorField(x -> [0, -x[3], x[2]])
        F2 = VectorField(x -> [x[3], 0, -x[1]])
        F01_  = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__= @Lie [F0, F1]
        F011__= @Lie [[F0, F1], F1]
        
        Test.@test F01_(x) ≈ F01__(x) atol=1e-6
        Test.@test F011_(x) ≈ F011__(x) atol=1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(x) ≈ F011___(x) atol=1e-6

        # nonautonomous
        F0 = VectorField((t,x) -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])], NonAutonomous)
        F1 = VectorField((t,x) -> [0, -x[3], x[2]], NonAutonomous)
        F2 = VectorField((t,x) -> [x[3], 0, -x[1]], NonAutonomous)
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__= @Lie [F0, F1]
        F011__= @Lie [[F0, F1], F1]
       
        Test.@test F01_(t,x) ≈ F01__(t,x) atol=1e-6
        Test.@test F011_(t,x) ≈ F011__(t,x) atol=1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(t, x) ≈ F011___(t, x) atol=1e-6

        # # nonfixed
        # F0 = VectorField((x,v) -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])], NonFixed)
        # F1 = VectorField((x,v) -> [0, -x[3], x[2]], NonFixed)
        # F2 = VectorField((x,v) -> [x[3], 0, -x[1]], NonFixed)
        # F01_ = Lie(F0, F1)
        # F011_ = Lie(F01_, F1)
        # F01__= @Lie [F0, F1]
        # F011__= @Lie [[F0, F1], F1]
       
        # Test.@test F01_(x,v) ≈ F01__(x,v) atol=1e-6
        # Test.@test F011_(x) ≈ F011__(x) atol=1e-6
        # #
        # get_F0 = () -> F0
        # F011___ = @Lie [[get_F0(), F1], F1]
        # Test.@test F011_(x) ≈ F011___(x) atol=1e-6

    end

    @testset "Poisson" begin

        #dimension 1
        g1(x,p) = 0.5*(x^2+p^2)
        g2(x,p) = 0.5*(x^2-p^2)
        g3(x,p) = 0.5*x^2
        g12(x,p) = g1(x,p)*g2(x,p) 
        g0(x,p) = 0.5

        H_1 = Hamiltonian(g1)
        H_2 = Hamiltonian(g2)
        H_3 = Hamiltonian(g3)
        H_12 = Hamiltonian(g12)

        P_1_2 = Poisson(H_1, H_2)
        P_2_1 = Poisson(H_2, H_1)
        P_1_1 = Poisson(H_1, H_1)

        a = 1
        b = 2

        Test.@test P_1_2(a,b) ≈ -P_2_1(a,b) atol=1e-6
        Test.@test Poisson(H_12,H_3)(a,b) ≈ (Poisson(H_1,H_3)(a,b)*H_2(a,b) + H_1(a,b)*Poisson(H_2,H_3)(a,b)) atol=1e-6
        Test.@test P_1_1(a,b) ≈ 0 atol=1e-6
        Test.@test Poisson(H_1,Hamiltonian(g0))(a,b) ≈ 0 atol=1e-6


        #dimension 2
        f1(x, p) = 0.5*(x[1]^2+x[2]^2+p[1]^2)
        f2(x, p) = 0.5*(x[1]^2+x[2]^2+p[2]^2)
        f3(x, p) = 0.5*(x[1]^2+x[2]^2)
        f12(x,p) = f1(x,p)*f2(x,p)
        f0(x,p) = 0.5

        H_1 = Hamiltonian(f1)
        H_2 = Hamiltonian(f2)
        H_3 = Hamiltonian(f3)
        H_12 = Hamiltonian(f12)

        P_1_2 = Poisson(H_1, H_2)
        P_2_1 = Poisson(H_2, H_1)
        P_1_1 = Poisson(H_1, H_1)

        a = [1, 2]
        b = [10, 0]

        Test.@test P_1_2(a,b) ≈ -P_2_1(a,b) atol=1e-6
        Test.@test Poisson(H_12,H_3)(a,b) ≈ (Poisson(H_1,H_3)(a,b)*H_2(a,b) + H_1(a,b)*Poisson(H_2,H_3)(a,b)) atol=1e-6
        Test.@test P_1_1(a,b) ≈ 0 atol=1e-6
        Test.@test Poisson(H_1,Hamiltonian(f0))(a,b) ≈ 0 atol=1e-6
    end

    @testset "Poisson macro" begin
        # parameters
        t = 1
        x = [1, 2, 3]
        p = [1,0,7]
        Γ = 2
        γ = 1
        δ = γ-Γ

        # autonomous
        H0 = Hamiltonian((x, p) -> 0.5*(x[1]^2+x[2]^2+p[1]^2))
        H1 = Hamiltonian((x, p) -> 0.5*(x[1]^2+x[2]^2+p[2]^2))
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_= @Poisson {H0, H1}
        P011_= @Poisson {{H0, H1}, H1}
        
        Test.@test P01(x, p) ≈ P01_(x, p) atol=1e-6
        Test.@test P011(x, p) ≈ P011_(x, p) atol=1e-6
        
        get_H0 = () -> H0
        P011__ = @Poisson {{get_H0(), H1}, H1}
        Test.@test P011_(x, p) ≈ P011__(x, p) atol=1e-6

        # nonautonomous
        H0 = Hamiltonian((t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[1]^2), autonomous=false)
        H1 = Hamiltonian((t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[2]^2), NonAutonomous)
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_= @Poisson {H0, H1}
        P011_= @Poisson {{H0, H1}, H1}
        Test.@test P01(t, x, p) ≈ P01_(t, x, p) atol=1e-6
        Test.@test P011(t, x, p) ≈ P011_(t, x, p) atol=1e-6
        
        get_H0 = () -> H0
        P011__ = @Poisson {{get_H0(), H1}, H1}
        Test.@test P011_(t, x, p) ≈ P011__(t, x, p) atol=1e-6
    end

end # test_differential_geometry

@testset "differential geometry" begin
    test_differential_geometry()
end
