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

            # autonomous nonfixed case
            X = VectorField((x, v) -> 2x, NonFixed)
            H = Lift(X)
            Test.@test H(1, 1, 1) == 2
            Test.@test H([1, 2], [3, 4], 1) == 22
            Test.@test_throws MethodError H([1, 2], 1)
            Test.@test_throws MethodError H(1, [1, 2])
    
            # multiple VectorFields
            X1 = VectorField((x, v) -> 2x, NonFixed)
            X2 = VectorField((x, v) -> 3x, NonFixed)
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1([1, 2], [3, 4], 1) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2([1, 2], [3, 4], 1) == 33
    
            # nonautonomous nonfixed case
            X = VectorField((t, x, v) -> 2x, NonAutonomous, NonFixed)
            H = Lift(X)
            Test.@test H(1, 1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4], 1) == 22
    
            # multiple VectorFields
            X1 = VectorField((t, x, v) -> 2x, NonAutonomous, NonFixed)
            X2 = VectorField((t, x, v) -> 3x, NonAutonomous, NonFixed)
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4], 1) == 22
            Test.@test H2(1, 1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4], 1) == 33
    
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

            # autonomous nonfixed case
            Xv::Function = (x, v) -> 2x
            H = Lift(Xv, variable=true)
            Test.@test H(1, 1, 1) == 2
            Test.@test H([1, 2], [3, 4], 1) == 22
    
            # multiple VectorFields
            X1v::Function = (x, v) -> 2x
            X2v::Function = (x, v) -> 3x
            H1, H2 = Lift(X1v, X2v, variable=true)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1([1, 2], [3, 4], 1) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2([1, 2], [3, 4], 1) == 33
    
            # nonautonomous nonfixed case
            Xtv::Function = (t, x, v) -> 2x
            H = Lift(Xtv, autonomous=false, variable=true)
            Test.@test H(1, 1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4], 1) == 22
    
            # multiple VectorFields
            X1tv::Function = (t, x, v) -> 2x
            X2tv::Function = (t, x, v) -> 3x
            H1, H2 = Lift(X1tv, X2tv, autonomous=false, variable=true)
            Test.@test H1(1, 1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4], 1) == 22
            Test.@test H2(1, 1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4], 1) == 33

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

        # autonomous, nonfixed, dim 2
        X = VectorField((x, v) -> [x[2] + v[1], -x[1] + v[2]], NonFixed)
        f = (x, v) -> x[1]^2 + x[2]^2
        Test.@test Der(X, f)([1, 2], [2, 1]) == 8
        Test.@test (X⋅f)([1, 2], [2, 1]) == Der(X, f)([1, 2], [2, 1])

        # autonomous, nonfixed, dim 1
        X = VectorField((x, v) -> 2x + v, NonFixed)
        f = (x, v) -> x^2
        Test.@test Der(X, f)(1, 1) == 6
        Test.@test (X⋅f)(1, 1) == Der(X, f)(1, 1)
    
        # nonautonomous, nonfixed, dim 2
        X = VectorField((t, x, v) -> [t + x[2], -x[1]], NonAutonomous, NonFixed)
        f = (t, x, v) -> t + x[1]^2 + x[2]^2
        Test.@test Der(X, f)(1, [1, 2], 1) == 2
        Test.@test (X⋅f)(1, [1, 2], 1) == Der(X, f)(1, [1, 2], 1)

        # nonautonomous, nonfixed, dim 1
        X = VectorField((v, t, x) -> 2x+t+v, NonAutonomous, NonFixed)
        f = (t, x, v) -> t + x^2
        Test.@test Der(X, f)(1, 1, 1) == 8
        Test.@test (X⋅f)(1, 1, 1) == Der(X, f)(1, 1, 1)
    
    end

    @testset "Directional derivative of a vector field" begin
        
        # autonomous, dim 2
        X = VectorField(x -> [x[2], -x[1]])
        Y = VectorField(x -> [x[1], x[2]])
        Test.@test ⅋(X, Y)([1, 2]) == [2, -1]

        # autonomous, dim 1
        X = VectorField(x -> 2x)
        Y = VectorField(x -> 3x)
        Test.@test ⅋(X, Y)(1) == 6

        # nonautonomous, dim 2
        X = VectorField((t, x) -> [t + x[2], -x[1]], NonAutonomous)
        Y = VectorField((t, x) -> [t + x[1], x[2]], NonAutonomous)
        Test.@test ⅋(X, Y)(1, [1, 2]) == [4, -1]

        # nonautonomous, dim 1
        X = VectorField((t, x) -> 2x+t, NonAutonomous)
        Y = VectorField((t, x) -> 3x+t, NonAutonomous)
        Test.@test ⅋(X, Y)(1, 1) == 10

        # autonomous, nonfixed, dim 1
        X = VectorField((x, v) -> 2x+v, NonFixed)
        Y = VectorField((x, v) -> 3x+v, NonFixed)
        Test.@test ⅋(X, Y)(1, 1) == 9

        # nonautonomous, nonfixed, dim 1
        X = VectorField((t, x, v) -> t+2x+v, NonAutonomous, NonFixed)
        Y = VectorField((t, x, v) -> t+3x+v, NonAutonomous, NonFixed)
        Test.@test ⅋(X, Y)(1, 1, 1) == 13
        
        # autonomous, nonfixed, dim 2
        X = VectorField((x, v) -> [v[1] + v[2] + x[2], -x[1]], NonFixed)
        Y = VectorField((x, v) ->  [v[1] + v[2] + x[1], x[2]], NonFixed)
        Test.@test ⅋(X, Y)([1, 2], [2, 3]) == [7, -1]

        # nonautonomous, nonfixed, dim 2
        X = VectorField((t, x, v) -> [t + v[1] + v[2] + x[2], -x[1]], NonFixed, NonAutonomous)
        Y = VectorField((t, x, v) ->  [v[1] + v[2] + x[1], x[2]], NonFixed, NonAutonomous)
        Test.@test ⅋(X, Y)(1, [1, 2], [2, 3]) == [8, -1]

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

        @testset "autonomous nonfixed case" begin
            f = (x, v) -> [x[2] + v, 2x[1]]
            g = (x, v) -> [3x[2], v - x[1]]
            X = VectorField(f, NonFixed)
            Y = VectorField(g, variable=true)
            Test.@test Lie(X, Y)([1, 2], 1) == [6, -15]
            Test.@test Lie(X, Y)([1, 2], 1) == ad(X, Y)([1, 2], 1)
            Test.@test Lie(X, Y)([1, 2], 1) == Lie(f, g, NonFixed)([1, 2], 1)
            Test.@test Lie(X, Y)([1, 2], 1) == ad(f, g, variable=true)([1, 2], 1)
        end

        @testset "nonautonomous nonfixed case" begin
            f = (t, x, v) -> [t + x[2] + v, -2x[1] - v]
            g = (t, x, v) -> [t + 3x[2] + v, -x[1] - v]
            X = VectorField(f, NonAutonomous, NonFixed)
            Y = VectorField(g, NonAutonomous, NonFixed)
            Test.@test Lie(X, Y)(1, [1, 2], 1) == [-7,12]
            Test.@test Lie(X, Y)(1, [1, 2], 1) == ad(X, Y)(1, [1, 2], 1)
            Test.@test Lie(X, Y)(1, [1, 2], 1) == Lie(f, g, autonomous=false, variable=true)(1, [1, 2], 1)
            Test.@test Lie(X, Y)(1, [1, 2], 1) == ad(f, g, autonomous=false, variable=true)(1, [1, 2], 1)
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

    @testset "Poisson bracket" begin
        @testset "autonomous case" begin
            f = (x, p) -> x[2]^2 + 2x[1]^2 + p[1]^2
            g = (x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1]
            h = (x, p) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2
            f₊g = (x, p) -> f(x, p) + g(x, p)
            fg = (x, p) -> f(x, p)*g(x, p)
            F = Hamiltonian(f)
            G = Hamiltonian(g)
            H = Hamiltonian(h) 
            F₊G = Hamiltonian(f₊g)
            FG = Hamiltonian(fg)
            Test.@test Poisson(F, Hamiltonian((x,p) -> 42))([1, 2], [2, 1]) == 0
            Test.@test Poisson(F, G)([1, 2], [2, 1]) == 20
            Test.@test Poisson(F, G)([1, 2], [2, 1]) == - Poisson(G, F)([1, 2], [2, 1]) # anticommutativity
            Test.@test Poisson(F₊G, H)([1, 2], [2, 1]) == Poisson(F, H)([1, 2], [2, 1]) + Poisson(G, H)([1, 2], [2, 1]) # bilinearity 1
            Test.@test Poisson(H, F₊G)([1, 2], [2, 1]) == Poisson(H, F)([1, 2], [2, 1]) + Poisson(H, G)([1, 2], [2, 1]) # bilinearity 2
            Test.@test Poisson(FG, H)([1, 2], [2, 1]) == Poisson(F, H)([1, 2], [2, 1])*G([1, 2], [2, 1]) + F([1, 2], [2, 1])*Poisson(G, H)([1, 2], [2, 1]) # Liebniz's rule
            Test.@test Poisson(F, Poisson(G,H))([1, 2], [2, 1]) + Poisson(G, Poisson(H,F))([1, 2], [2, 1]) + Poisson(H, Poisson(F,G))([1, 2], [2, 1]) == 0 # Jacobi identity
        end

        @testset "nonautonomous case" begin
            f = (t, x, p) -> t*x[2]^2 + 2x[1]^2 + p[1]^2 + t
            g = (t, x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] - t
            h = (t, x, p) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2 + t
            f₊g = (t, x, p) -> f(t, x, p) + g(t, x, p)
            fg = (t, x, p) -> f(t, x, p)*g(t, x, p)
            F = Hamiltonian(f, autonomous=false)
            G = Hamiltonian(g, autonomous=false)
            H = Hamiltonian(h, autonomous=false) 
            F₊G = Hamiltonian(f₊g, autonomous=false)
            FG = Hamiltonian(fg, autonomous=false)
            Test.@test Poisson(F, Hamiltonian((t, x, p) -> 42, autonomous=false))(2, [1, 2], [2, 1]) == 0
            Test.@test Poisson(F, G)(2, [1, 2], [2, 1]) == 28
            Test.@test Poisson(F, G)(2, [1, 2], [2, 1]) == - Poisson(G, F)(2, [1, 2], [2, 1]) # anticommutativity
            Test.@test Poisson(F₊G, H)(2, [1, 2], [2, 1]) == Poisson(F, H)(2, [1, 2], [2, 1]) + Poisson(G, H)(2, [1, 2], [2, 1]) # bilinearity 1
            Test.@test Poisson(H, F₊G)(2, [1, 2], [2, 1]) == Poisson(H, F)(2, [1, 2], [2, 1]) + Poisson(H, G)(2, [1, 2], [2, 1]) # bilinearity 2
            Test.@test Poisson(FG, H)(2, [1, 2], [2, 1]) == Poisson(F, H)(2, [1, 2], [2, 1])*G(2, [1, 2], [2, 1]) + F(2, [1, 2], [2, 1])*Poisson(G, H)(2, [1, 2], [2, 1]) # Liebniz's rule
            Test.@test Poisson(F, Poisson(G,H))(2, [1, 2], [2, 1]) + Poisson(G, Poisson(H,F))(2, [1, 2], [2, 1]) + Poisson(H, Poisson(F,G))(2, [1, 2], [2, 1]) == 0 # Jacobi identity
        end

        @testset "autonomous nonfixed case" begin
            f = (x, p, v) -> v[1]*x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
            g = (x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] - v[2]
            h = (x, p, v) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2 + v[2]
            f₊g = (x, p, v) -> f(x, p, v) + g(x, p, v)
            fg = (x, p, v)-> f(x, p, v)*g(x, p, v)
            F = Hamiltonian(f, variable=true)
            G = Hamiltonian(g, variable=true)
            H = Hamiltonian(h, variable=true) 
            F₊G = Hamiltonian(f₊g, variable=true)
            FG = Hamiltonian(fg, variable=true)
            Test.@test Poisson(F, Hamiltonian((x, p, v) -> 42, variable=true))([1, 2], [2, 1], [4, 4]) == 0
            Test.@test Poisson(F, G)([1, 2], [2, 1], [4, 4]) == 44
            Test.@test Poisson(F, G)([1, 2], [2, 1], [4, 4]) == - Poisson(G, F)([1, 2], [2, 1], [4, 4]) # anticommutativity
            Test.@test Poisson(F₊G, H)([1, 2], [2, 1], [4, 4]) == Poisson(F, H)([1, 2], [2, 1], [4, 4]) + Poisson(G, H)([1, 2], [2, 1], [4, 4]) # bilinearity 1
            Test.@test Poisson(H, F₊G)([1, 2], [2, 1], [4, 4]) == Poisson(H, F)([1, 2], [2, 1], [4, 4]) + Poisson(H, G)([1, 2], [2, 1], [4, 4]) # bilinearity 2
            Test.@test Poisson(FG, H)([1, 2], [2, 1], [4, 4]) == Poisson(F, H)([1, 2], [2, 1], [4, 4])*G([1, 2], [2, 1], [4, 4]) + F([1, 2], [2, 1], [4, 4])*Poisson(G, H)([1, 2], [2, 1], [4, 4]) # Liebniz's rule
            Test.@test Poisson(F, Poisson(G,H))([1, 2], [2, 1], [4, 4]) + Poisson(G, Poisson(H,F))([1, 2], [2, 1], [4, 4]) + Poisson(H, Poisson(F,G))([1, 2], [2, 1], [4, 4]) == 0 # Jacobi identity
        end

        @testset "nonautonomous nonfixed case" begin
            @testset "autonomous nonfixed case" begin
                f = (t, x, p, v) -> t*v[1]*x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
                g = (t, x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] + t - v[2]
                h = (t, x, p, v) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2 + t + v[2]
                f₊g = (t, x, p, v) -> f(t, x, p, v) + g(t, x, p, v)
                fg = (t, x, p, v)-> f(t, x, p, v)*g(t, x, p, v)
                F = Hamiltonian(f, autonomous=false, variable=true)
                G = Hamiltonian(g, autonomous=false, variable=true)
                H = Hamiltonian(h, autonomous=false, variable=true) 
                F₊G = Hamiltonian(f₊g, autonomous=false, variable=true)
                FG = Hamiltonian(fg, autonomous=false, variable=true)
                Test.@test Poisson(F, Hamiltonian((t, x, p, v) -> 42, autonomous=false, variable=true))(2, [1, 2], [2, 1], [4, 4]) == 0
                Test.@test Poisson(F, G)(2, [1, 2], [2, 1], [4, 4]) == 76
                Test.@test Poisson(F, G)(2, [1, 2], [2, 1], [4, 4]) == - Poisson(G, F)(2, [1, 2], [2, 1], [4, 4]) # anticommutativity
                Test.@test Poisson(F₊G, H)(2, [1, 2], [2, 1], [4, 4]) == Poisson(F, H)(2, [1, 2], [2, 1], [4, 4]) + Poisson(G, H)(2, [1, 2], [2, 1], [4, 4]) # bilinearity 1
                Test.@test Poisson(H, F₊G)(2, [1, 2], [2, 1], [4, 4]) == Poisson(H, F)(2, [1, 2], [2, 1], [4, 4]) + Poisson(H, G)(2, [1, 2], [2, 1], [4, 4]) # bilinearity 2
                Test.@test Poisson(FG, H)(2, [1, 2], [2, 1], [4, 4]) == Poisson(F, H)(2, [1, 2], [2, 1], [4, 4])*G(2, [1, 2], [2, 1], [4, 4]) + F(2, [1, 2], [2, 1], [4, 4])*Poisson(G, H)(2, [1, 2], [2, 1], [4, 4]) # Liebniz's rule
                Test.@test Poisson(F, Poisson(G,H))(2, [1, 2], [2, 1], [4, 4]) + Poisson(G, Poisson(H,F))(2, [1, 2], [2, 1], [4, 4]) + Poisson(H, Poisson(F,G))(2, [1, 2], [2, 1], [4, 4]) == 0 # Jacobi identity
            end
        end
    end

    # macros

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

        # autonomous nonfixed
        F0 = VectorField((x,v) -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])], NonFixed)
        F1 = VectorField((x,v) -> [0, -x[3], x[2]], NonFixed)
        F2 = VectorField((x,v) -> [x[3], 0, -x[1]], NonFixed)
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__= @Lie [F0, F1]
        F011__= @Lie [[F0, F1], F1]
       
        Test.@test F01_(x, v) ≈ F01__(x, v) atol=1e-6
        Test.@test F011_(x, v) ≈ F011__(x, v) atol=1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(x, v) ≈ F011___(x, v) atol=1e-6

        # nonautonomous nonfixed
        F0 = VectorField((t, x, v) -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])], NonAutonomous, NonFixed)
        F1 = VectorField((t, x, v) -> [0, -x[3], x[2]], NonAutonomous, NonFixed)
        F2 = VectorField((t, x, v) -> [x[3], 0, -x[1]], NonAutonomous, NonFixed)
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__= @Lie [F0, F1]
        F011__= @Lie [[F0, F1], F1]
       
        Test.@test F01_(t, x, v) ≈ F01__(t, x, v) atol=1e-6
        Test.@test F011_(t, x, v) ≈ F011__(t, x, v) atol=1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(t, x, v) ≈ F011___(t, x, v) atol=1e-6

    end

    @testset "Poisson macro" begin
        # parameters
        t = 1
        x = [1, 2, 3]
        p = [1,0,7]
        Γ = 2
        γ = 1
        δ = γ-Γ
        v = 2

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

        # autonomous nonfixed
        H0 = Hamiltonian((x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[1]^2+v), variable=true)
        H1 = Hamiltonian((x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[2]^2+v), variable=true)
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_= @Poisson {H0, H1}
        P011_= @Poisson {{H0, H1}, H1}
        Test.@test P01(x, p, v) ≈ P01_(x, p, v) atol=1e-6
        Test.@test P011(x, p, v) ≈ P011_(x, p, v) atol=1e-6
        get_H0 = () -> H0
        P011__ = @Poisson {{get_H0(), H1}, H1}
        Test.@test P011_(x, p, v) ≈ P011__(x, p, v) atol=1e-6

        # nonautonomous nonfixed
        H0 = Hamiltonian((t, x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[1]^2+v), autonomous=false, variable=true)
        H1 = Hamiltonian((t, x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[2]^2+v), NonAutonomous, NonFixed)
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_= @Poisson {H0, H1}
        P011_= @Poisson {{H0, H1}, H1}
        Test.@test P01(t, x, p, v) ≈ P01_(t, x, p,v ) atol=1e-6
        Test.@test P011(t, x, p, v) ≈ P011_(t, x, p, v) atol=1e-6
        get_H0 = () -> H0
        P011__ = @Poisson {{get_H0(), H1}, H1}
        Test.@test P011_(t, x, p, v) ≈ P011__(t, x, p, v) atol=1e-6
    end

end # test_differential_geometry

@testset "differential geometry" begin
    test_differential_geometry()
end
