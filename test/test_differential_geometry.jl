function test_differential_geometry()
    ∅ = Vector{Real}()
    dummy_function() = nothing

    @testset "Lifts" begin
        @testset "HamiltonianLift from VectorField" begin
            HL = HamiltonianLift(
                VectorField(x -> [x[1]^2, x[2]^2], autonomous = true, variable = false),
            )
            @test HL([1, 0], [0, 1]) == 0
            @test HL(1, [1, 0], [0, 1], 1) == 0
            HL = HamiltonianLift(
                VectorField((x, v) -> [x[1]^2, x[2]^2 + v], autonomous = true, variable = true),
            )
            @test HL([1, 0], [0, 1], 1) == 1
            @test HL(1, [1, 0], [0, 1], 1) == 1
            HL = HamiltonianLift(
                VectorField((t, x) -> [t + x[1]^2, x[2]^2], autonomous = false, variable = false),
            )
            @test HL(1, [1, 0], [0, 1]) == 0
            @test HL(1, [1, 0], [0, 1], 1) == 0
            HL = HamiltonianLift(
                VectorField(
                    (t, x, v) -> [t + x[1]^2, x[2]^2 + v],
                    autonomous = false,
                    variable = true,
                ),
            )
            @test HL(1, [1, 0], [0, 1], 1) == 1
        end

        @testset "HamiltonianLift from Function" begin
            HL = HamiltonianLift(x -> [x[1]^2, x[2]^2], autonomous = true, variable = false)
            @test HL([1, 0], [0, 1]) == 0
            @test HL(1, [1, 0], [0, 1], 1) == 0
            HL = HamiltonianLift((x, v) -> [x[1]^2, x[2]^2 + v], autonomous = true, variable = true)
            @test HL([1, 0], [0, 1], 1) == 1
            @test HL(1, [1, 0], [0, 1], 1) == 1
            HL = HamiltonianLift(
                (t, x) -> [t + x[1]^2, x[2]^2],
                autonomous = false,
                variable = false,
            )
            @test HL(1, [1, 0], [0, 1]) == 0
            @test HL(1, [1, 0], [0, 1], 1) == 0
            HL = HamiltonianLift(
                (t, x, v) -> [t + x[1]^2, x[2]^2 + v],
                autonomous = false,
                variable = true,
            )
            @test HL(1, [1, 0], [0, 1], 1) == 1
            HL = HamiltonianLift(x -> [x[1]^2, x[2]^2], autonomous=true, variable=false)
            @test HL([1, 0], [0, 1]) == 0
            @test HL(1, [1, 0], [0, 1], 1) == 0
            HL = HamiltonianLift((x, v) -> [x[1]^2, x[2]^2 + v], autonomous=true, variable=true)
            @test HL([1, 0], [0, 1], 1) == 1
            @test HL(1, [1, 0], [0, 1], 1) == 1
            HL = HamiltonianLift((t, x) -> [t + x[1]^2, x[2]^2], autonomous=false, variable=false)
            @test HL(1, [1, 0], [0, 1]) == 0
            @test HL(1, [1, 0], [0, 1], 1) == 0
            HL = HamiltonianLift((t, x, v) -> [t + x[1]^2, x[2]^2 + v], autonomous=false, variable=true)
            @test HL(1, [1, 0], [0, 1], 1) == 1
        end

        @testset "from VectorFields" begin

            # autonomous case
            X = VectorField(x -> 2x)
            H = Lift(X)
            Test.@test H(1, 1) == 2
            Test.@test H([1, 2], [3, 4]) == 22
            Test.@test_throws MethodError H([1, 2], 1)
            Test.@test_throws MethodError H(1, [1, 2])

            # nonautonomous case
            X = VectorField((t, x) -> 2x, autonomous=false, variable=false)
            H = Lift(X)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22

            # autonomous nonfixed case
            X = VectorField((x, v) -> 2x, autonomous=true, variable=true)
            H = Lift(X)
            Test.@test H(1, 1, 1) == 2
            Test.@test H([1, 2], [3, 4], 1) == 22
            Test.@test_throws MethodError H([1, 2], 1)
            Test.@test_throws MethodError H(1, [1, 2])

            # nonautonomous nonfixed case
            X = VectorField((t, x, v) -> 2x, autonomous=false, variable=true)
            H = Lift(X)
            Test.@test H(1, 1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4], 1) == 22
        end

        @testset "from Function" begin

            # autonomous case
            X::Function = x -> 2x
            H = Lift(X)
            Test.@test H(1, 1) == 2
            Test.@test H([1, 2], [3, 4]) == 22

            # nonautonomous case
            Xt::Function = (t, x) -> 2x
            H = Lift(Xt, autonomous = false)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22

            # autonomous nonfixed case
            Xv::Function = (x, v) -> 2x
            H = Lift(Xv, variable = true)
            Test.@test H(1, 1, 1) == 2
            Test.@test H([1, 2], [3, 4], 1) == 22

            # nonautonomous nonfixed case
            Xtv::Function = (t, x, v) -> 2x
            H = Lift(Xtv, autonomous = false, variable = true)
            Test.@test H(1, 1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4], 1) == 22

            # overload
            F::Function = x -> 2x
            H_F(x, p) = Lift(F)(x, p)
            H_F(y) = H_F(y, y)
            Test.@test H_F(1) == 2
        end
    end # tests for Lift

    @testset "Directional derivative of a scalar function" begin

        # autonomous, dim 2
        φ = x -> [x[2], -x[1]]
        X = VectorField(φ)
        f = x -> x[1]^2 + x[2]^2
        Test.@test (X ⋅ f)([1, 2]) == 0
        Test.@test (X ⋅ f)([1, 2]) == Lie(X, f)([1, 2])
        Test.@test Lie(φ, f)([1, 2]) == 0

        # autonomous, dim 1
        φ = x -> 2x
        X = VectorField(φ)
        f = x -> x^2
        Test.@test (X ⋅ f)(1) == 4
        Test.@test (φ ⋅ f)(1) == 4
        Test.@test Lie(φ, f)(1) == 4

        # nonautonomous, dim 2
        φ = (t, x) -> [t + x[2], -x[1]]
        X = VectorField(φ, autonomous=false, variable=false)
        f = (t, x) -> t + x[1]^2 + x[2]^2
        Test.@test (X ⋅ f)(1, [1, 2]) == 2
        Test.@test Lie(φ, f, autonomous=false, variable=false)(1, [1, 2]) == 2

        # nonautonomous, dim 1
        φ = (t, x) -> 2x + t
        X = VectorField(φ, autonomous=false, variable=false)
        f = (t, x) -> t + x^2
        Test.@test (X ⋅ f)(1, 1) == 6
        Test.@test Lie(φ, f, autonomous=false, variable=false)(1, 1) == 6

        # autonomous, nonfixed, dim 2
        φ = (x, v) -> [x[2] + v[1], -x[1] + v[2]]
        X = VectorField(φ, autonomous=true, variable=true)
        f = (x, v) -> x[1]^2 + x[2]^2
        Test.@test (X ⋅ f)([1, 2], [2, 1]) == 8
        Test.@test Lie(φ, f, autonomous=true, variable=true)([1, 2], [2, 1]) == 8

        # autonomous, nonfixed, dim 1
        φ = (x, v) -> 2x + v
        X = VectorField(φ, autonomous=true, variable=true)
        f = (x, v) -> x^2
        Test.@test (X ⋅ f)(1, 1) == 6
        Test.@test Lie(φ, f, autonomous=true, variable=true)(1, 1) == 6

        # nonautonomous, nonfixed, dim 2
        φ = (t, x, v) -> [t + x[2] + v[1], -x[1] + v[2]]
        X = VectorField(φ, autonomous=false, variable=true)
        f = (t, x, v) -> t + x[1]^2 + x[2]^2
        Test.@test (X ⋅ f)(1, [1, 2], [2, 1]) == 10
        Test.@test Lie(φ, f, autonomous=false, variable=true)(1, [1, 2], [2, 1]) == 10

        # nonautonomous, nonfixed, dim 1
        φ = (t, x, v) -> 2x + t + v
        X = VectorField(φ, autonomous=false, variable=true)
        f = (t, x, v) -> t + x^2
        Test.@test (X ⋅ f)(1, 1, 1) == 8
        Test.@test Lie(φ, f, autonomous=false, variable=true)(1, 1, 1) == 8
    end

    @testset "Directional derivative of a vector field" begin

        # autonomous, dim 2
        X = VectorField(x -> [x[2], -x[1]])
        Y = VectorField(x -> [x[1], x[2]])
        Test.@test CTBase.:(⅋)(X, Y)([1, 2]) == [2, -1]

        # autonomous, dim 1
        X = VectorField(x -> 2x)
        Y = VectorField(x -> 3x)
        Test.@test CTBase.:(⅋)(X, Y)(1) == 6

        # nonautonomous, dim 2
        X = VectorField((t, x) -> [t + x[2], -x[1]], autonomous=false, variable=false)
        Y = VectorField((t, x) -> [t + x[1], x[2]], autonomous=false, variable=false)
        Test.@test CTBase.:(⅋)(X, Y)(1, [1, 2]) == [3, -1]

        # nonautonomous, dim 1
        X = VectorField((t, x) -> 2x + t, autonomous=false, variable=false)
        Y = VectorField((t, x) -> 3x + t, autonomous=false, variable=false)
        Test.@test CTBase.:(⅋)(X, Y)(1, 1) == 9

        # autonomous, nonfixed, dim 1
        X = VectorField((x, v) -> 2x + v, autonomous=true, variable=true)
        Y = VectorField((x, v) -> 3x + v, autonomous=true, variable=true)
        Test.@test CTBase.:(⅋)(X, Y)(1, 1) == 9

        # nonautonomous, nonfixed, dim 1
        X = VectorField((t, x, v) -> t + 2x + v, autonomous=false, variable=true)
        Y = VectorField((t, x, v) -> t + 3x + v, autonomous=false, variable=true)
        Test.@test CTBase.:(⅋)(X, Y)(1, 1, 1) == 12

        # autonomous, nonfixed, dim 2
        X = VectorField((x, v) -> [v[1] + v[2] + x[2], -x[1]], autonomous=true, variable=true)
        Y = VectorField((x, v) -> [v[1] + v[2] + x[1], x[2]], autonomous=true, variable=true)
        Test.@test CTBase.:(⅋)(X, Y)([1, 2], [2, 3]) == [7, -1]

        # nonautonomous, nonfixed, dim 2
        X = VectorField((t, x, v) -> [t + v[1] + v[2] + x[2], -x[1]], autonomous=false, variable=true)
        Y = VectorField((t, x, v) -> [v[1] + v[2] + x[1], x[2]], autonomous=false, variable=true)
        Test.@test CTBase.:(⅋)(X, Y)(1, [1, 2], [2, 3]) == [8, -1]
    end

    @testset "Lie bracket - length 2" begin
        @testset "autonomous case" begin
            f = x -> [x[2], 2x[1]]
            g = x -> [3x[2], -x[1]]
            X = VectorField(f)
            Y = VectorField(g)
            Test.@test Lie(X, Y)([1, 2]) == [7, -14]
        end

        @testset "nonautonomous case" begin
            f = (t, x) -> [t + x[2], -2x[1]]
            g = (t, x) -> [t + 3x[2], -x[1]]
            X = VectorField(f, autonomous=false, variable=false)
            Y = VectorField(g, autonomous=false, variable=false)
            Test.@test Lie(X, Y)(1, [1, 2]) == [-5, 11]
        end

        @testset "autonomous nonfixed case" begin
            f = (x, v) -> [x[2] + v, 2x[1]]
            g = (x, v) -> [3x[2], v - x[1]]
            X = VectorField(f, autonomous=true, variable=true)
            Y = VectorField(g, variable = true)
            Test.@test Lie(X, Y)([1, 2], 1) == [6, -15]
        end

        @testset "nonautonomous nonfixed case" begin
            f = (t, x, v) -> [t + x[2] + v, -2x[1] - v]
            g = (t, x, v) -> [t + 3x[2] + v, -x[1] - v]
            X = VectorField(f, autonomous=false, variable=true)
            Y = VectorField(g, autonomous=false, variable=true)
            Test.@test Lie(X, Y)(1, [1, 2], 1) == [-7, 12]
        end

        @testset "mri example" begin
            Γ = 2
            γ = 1
            δ = γ - Γ
            F0 = VectorField(x -> [-Γ * x[1], -Γ * x[2], γ * (1 - x[3])])
            F1 = VectorField(x -> [0, -x[3], x[2]])
            F2 = VectorField(x -> [x[3], 0, -x[1]])
            F01 = Lie(F0, F1)
            F02 = Lie(F0, F2)
            F12 = Lie(F1, F2)
            x = [1, 2, 3]
            Test.@test F01(x) ≈ -[0, γ - δ * x[3], -δ * x[2]] atol = 1e-6
            Test.@test F02(x) ≈ -[-γ + δ * x[3], 0, δ * x[1]] atol = 1e-6
            Test.@test F12(x) ≈ -[-x[2], x[1], 0] atol = 1e-6
        end

        @testset "intrinsic definition" begin
            X = VectorField(x -> [x[2]^2, -2x[1] * x[2]])
            Y = VectorField(x -> [x[1] * (1 + x[2]), 3x[2]^3])
            f = x -> x[1]^4 + 2x[2]^3
            x = [1, 2]

            # check real intrinsic order 2 definition of Lie bracket
            Test.@test ((@Lie [X, Y]) ⋅ f)(x) == ((X ⋅ (Y ⋅ f))(x) - (Y ⋅ (X ⋅ f))(x))
        end
    end

    @testset "Poisson bracket" begin
        @testset "autonomous case" begin
            f = (x, p) -> x[2]^2 + 2x[1]^2 + p[1]^2
            g = (x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1]
            h = (x, p) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2
            f₊g = (x, p) -> f(x, p) + g(x, p)
            fg = (x, p) -> f(x, p) * g(x, p)
            #
            F = Hamiltonian(f)
            G = Hamiltonian(g)
            H = Hamiltonian(h)
            F₊G = Hamiltonian(f₊g)
            FG = Hamiltonian(fg)
            #
            Test.@test Poisson(f, g)([1, 2], [2, 1]) == -20
            Test.@test Poisson(f, G)([1, 2], [2, 1]) == -20
            Test.@test Poisson(F, g)([1, 2], [2, 1]) == -20
            #
            Test.@test Poisson(F, Hamiltonian((x, p) -> 42))([1, 2], [2, 1]) == 0
            Test.@test Poisson(F, G)([1, 2], [2, 1]) == -20
            Test.@test Poisson(F, G)([1, 2], [2, 1]) == -Poisson(G, F)([1, 2], [2, 1]) # anticommutativity
            Test.@test Poisson(F₊G, H)([1, 2], [2, 1]) ==
                       Poisson(F, H)([1, 2], [2, 1]) + Poisson(G, H)([1, 2], [2, 1]) # bilinearity 1
            Test.@test Poisson(H, F₊G)([1, 2], [2, 1]) ==
                       Poisson(H, F)([1, 2], [2, 1]) + Poisson(H, G)([1, 2], [2, 1]) # bilinearity 2
            Test.@test Poisson(FG, H)([1, 2], [2, 1]) ==
                       Poisson(F, H)([1, 2], [2, 1]) * G([1, 2], [2, 1]) +
                       F([1, 2], [2, 1]) * Poisson(G, H)([1, 2], [2, 1]) # Liebniz's rule
            Test.@test Poisson(F, Poisson(G, H))([1, 2], [2, 1]) +
                       Poisson(G, Poisson(H, F))([1, 2], [2, 1]) +
                       Poisson(H, Poisson(F, G))([1, 2], [2, 1]) == 0 # Jacobi identity
        end

        @testset "nonautonomous case" begin
            f = (t, x, p) -> t * x[2]^2 + 2x[1]^2 + p[1]^2 + t
            g = (t, x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] - t
            h = (t, x, p) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2 + t
            f₊g = (t, x, p) -> f(t, x, p) + g(t, x, p)
            fg = (t, x, p) -> f(t, x, p) * g(t, x, p)
            F = Hamiltonian(f, autonomous = false)
            G = Hamiltonian(g, autonomous = false)
            H = Hamiltonian(h, autonomous = false)
            F₊G = Hamiltonian(f₊g, autonomous = false)
            FG = Hamiltonian(fg, autonomous = false)
            #
            Test.@test Poisson(f, g, autonomous = false)(2, [1, 2], [2, 1]) == -28
            Test.@test Poisson(f, G)(2, [1, 2], [2, 1]) == -28
            Test.@test Poisson(F, g)(2, [1, 2], [2, 1]) == -28
            #
            Test.@test Poisson(F, Hamiltonian((t, x, p) -> 42, autonomous = false))(
                2,
                [1, 2],
                [2, 1],
            ) == 0
            Test.@test Poisson(F, G)(2, [1, 2], [2, 1]) == -28
            Test.@test Poisson(F, G)(2, [1, 2], [2, 1]) == -Poisson(G, F)(2, [1, 2], [2, 1]) # anticommutativity
            Test.@test Poisson(F₊G, H)(2, [1, 2], [2, 1]) ==
                       Poisson(F, H)(2, [1, 2], [2, 1]) + Poisson(G, H)(2, [1, 2], [2, 1]) # bilinearity 1
            Test.@test Poisson(H, F₊G)(2, [1, 2], [2, 1]) ==
                       Poisson(H, F)(2, [1, 2], [2, 1]) + Poisson(H, G)(2, [1, 2], [2, 1]) # bilinearity 2
            Test.@test Poisson(FG, H)(2, [1, 2], [2, 1]) ==
                       Poisson(F, H)(2, [1, 2], [2, 1]) * G(2, [1, 2], [2, 1]) +
                       F(2, [1, 2], [2, 1]) * Poisson(G, H)(2, [1, 2], [2, 1]) # Liebniz's rule
            Test.@test Poisson(F, Poisson(G, H))(2, [1, 2], [2, 1]) +
                       Poisson(G, Poisson(H, F))(2, [1, 2], [2, 1]) +
                       Poisson(H, Poisson(F, G))(2, [1, 2], [2, 1]) == 0 # Jacobi identity
        end

        @testset "autonomous nonfixed case" begin
            f = (x, p, v) -> v[1] * x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
            g = (x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] - v[2]
            h = (x, p, v) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2 + v[2]
            f₊g = (x, p, v) -> f(x, p, v) + g(x, p, v)
            fg = (x, p, v) -> f(x, p, v) * g(x, p, v)
            F = Hamiltonian(f, variable = true)
            G = Hamiltonian(g, variable = true)
            H = Hamiltonian(h, variable = true)
            F₊G = Hamiltonian(f₊g, variable = true)
            FG = Hamiltonian(fg, variable = true)
            Test.@test Poisson(F, Hamiltonian((x, p, v) -> 42, variable = true))(
                [1, 2],
                [2, 1],
                [4, 4],
            ) == 0
            Test.@test Poisson(F, G)([1, 2], [2, 1], [4, 4]) == -44
            Test.@test Poisson(F, G)([1, 2], [2, 1], [4, 4]) ==
                       -Poisson(G, F)([1, 2], [2, 1], [4, 4]) # anticommutativity
            Test.@test Poisson(F₊G, H)([1, 2], [2, 1], [4, 4]) ==
                       Poisson(F, H)([1, 2], [2, 1], [4, 4]) + Poisson(G, H)([1, 2], [2, 1], [4, 4]) # bilinearity 1
            Test.@test Poisson(H, F₊G)([1, 2], [2, 1], [4, 4]) ==
                       Poisson(H, F)([1, 2], [2, 1], [4, 4]) + Poisson(H, G)([1, 2], [2, 1], [4, 4]) # bilinearity 2
            Test.@test Poisson(FG, H)([1, 2], [2, 1], [4, 4]) ==
                       Poisson(F, H)([1, 2], [2, 1], [4, 4]) * G([1, 2], [2, 1], [4, 4]) +
                       F([1, 2], [2, 1], [4, 4]) * Poisson(G, H)([1, 2], [2, 1], [4, 4]) # Liebniz's rule
            Test.@test Poisson(F, Poisson(G, H))([1, 2], [2, 1], [4, 4]) +
                       Poisson(G, Poisson(H, F))([1, 2], [2, 1], [4, 4]) +
                       Poisson(H, Poisson(F, G))([1, 2], [2, 1], [4, 4]) == 0 # Jacobi identity
        end

        @testset "nonautonomous nonfixed case" begin
            f = (t, x, p, v) -> t * v[1] * x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
            g = (t, x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] + t - v[2]
            h = (t, x, p, v) -> x[2]^2 + -2x[1]^2 + p[1]^2 - 2p[2]^2 + t + v[2]
            f₊g = (t, x, p, v) -> f(t, x, p, v) + g(t, x, p, v)
            fg = (t, x, p, v) -> f(t, x, p, v) * g(t, x, p, v)
            F = Hamiltonian(f, autonomous = false, variable = true)
            G = Hamiltonian(g, autonomous = false, variable = true)
            H = Hamiltonian(h, autonomous = false, variable = true)
            F₊G = Hamiltonian(f₊g, autonomous = false, variable = true)
            FG = Hamiltonian(fg, autonomous = false, variable = true)
            Test.@test Poisson(
                F,
                Hamiltonian((t, x, p, v) -> 42, autonomous = false, variable = true),
            )(
                2,
                [1, 2],
                [2, 1],
                [4, 4],
            ) == 0
            Test.@test Poisson(F, G)(2, [1, 2], [2, 1], [4, 4]) == -76
            Test.@test Poisson(F, G)(2, [1, 2], [2, 1], [4, 4]) ==
                       -Poisson(G, F)(2, [1, 2], [2, 1], [4, 4]) # anticommutativity
            Test.@test Poisson(F₊G, H)(2, [1, 2], [2, 1], [4, 4]) ==
                       Poisson(F, H)(2, [1, 2], [2, 1], [4, 4]) +
                       Poisson(G, H)(2, [1, 2], [2, 1], [4, 4]) # bilinearity 1
            Test.@test Poisson(H, F₊G)(2, [1, 2], [2, 1], [4, 4]) ==
                       Poisson(H, F)(2, [1, 2], [2, 1], [4, 4]) +
                       Poisson(H, G)(2, [1, 2], [2, 1], [4, 4]) # bilinearity 2
            Test.@test Poisson(FG, H)(2, [1, 2], [2, 1], [4, 4]) ==
                       Poisson(F, H)(2, [1, 2], [2, 1], [4, 4]) * G(2, [1, 2], [2, 1], [4, 4]) +
                       F(2, [1, 2], [2, 1], [4, 4]) * Poisson(G, H)(2, [1, 2], [2, 1], [4, 4]) # Liebniz's rule
            Test.@test Poisson(F, Poisson(G, H))(2, [1, 2], [2, 1], [4, 4]) +
                       Poisson(G, Poisson(H, F))(2, [1, 2], [2, 1], [4, 4]) +
                       Poisson(H, Poisson(F, G))(2, [1, 2], [2, 1], [4, 4]) == 0 # Jacobi identity
        end
    end

    @testset "poisson bracket of Lifts" begin
        @testset "autonomous case" begin
            f = x -> [x[1] + x[2]^2, x[1], 0]
            g = x -> [0, x[2], x[1]^2 + 4 * x[2]]
            F = Lift(f)
            G = Lift(g)
            F_ = (x, p) -> p' * f(x)
            G_ = (x, p) -> p' * g(x)
            Test.@test Poisson(F, G)([1, 2, 3], [4, 0, 4]) ≈ Poisson(F_, G_)([1, 2, 3], [4, 0, 4]) atol =
                1e-6
            Test.@test Poisson(F, G_)([1, 2, 3], [4, 0, 4]) ≈ Poisson(F_, G)([1, 2, 3], [4, 0, 4]) atol =
                1e-6
        end

        @testset "nonautonomous case" begin
            f = (t, x) -> [t * x[1] + x[2]^2, x[1], 0]
            g = (t, x) -> [0, x[2], t * x[1]^2 + 4 * x[2]]
            F = Lift(f, autonomous=false, variable=false)
            G = Lift(g, autonomous=false, variable=false)
            F_ = (t, x, p) -> p' * f(t, x)
            G_ = (t, x, p) -> p' * g(t, x)
            Test.@test Poisson(F, G, autonomous=false, variable=false)(2, [1, 2, 3], [4, 0, 4]) ≈
                       Poisson(F_, G_, autonomous=false, variable=false)(2, [1, 2, 3], [4, 0, 4]) atol = 1e-6
            Test.@test Poisson(F, G_, autonomous=false, variable=false)(2, [1, 2, 3], [4, 0, 4]) ≈
                       Poisson(F_, G, autonomous=false, variable=false)(2, [1, 2, 3], [4, 0, 4]) atol = 1e-6
        end

        @testset "autonomous nonfixed case" begin
            f = (x, v) -> [x[1] + v * x[2]^2, x[1], 0]
            g = (x, v) -> [0, x[2], x[1]^2 + v * 4 * x[2]]
            F = Lift(f, autonomous=true, variable=true)
            G = Lift(g, autonomous=true, variable=true)
            F_ = (x, p, v) -> p' * f(x, v)
            G_ = (x, p, v) -> p' * g(x, v)
            Test.@test Poisson(F, G, autonomous=true, variable=true)([1, 2, 3], [4, 0, 4], 1) ≈
                       Poisson(F_, G_, autonomous=true, variable=true)([1, 2, 3], [4, 0, 4], 1) atol = 1e-6
            Test.@test Poisson(F, G_, autonomous=true, variable=true)([1, 2, 3], [4, 0, 4], 1) ≈
                       Poisson(F_, G, autonomous=true, variable=true)([1, 2, 3], [4, 0, 4], 1) atol = 1e-6
        end

        @testset "nonautonomous nonfixed case" begin
            f = (t, x, v) -> [t * x[1] + v * x[2]^2, x[1], 0]
            g = (t, x, v) -> [0, x[2], t * x[1]^2 + v * 4 * x[2]]
            F = Lift(f, autonomous=false, variable=true)
            G = Lift(g, autonomous=false, variable=true)
            F_ = (t, x, p, v) -> p' * f(t, x, v)
            G_ = (t, x, p, v) -> p' * g(t, x, v)
            Test.@test Poisson(F, G, autonomous=false, variable=true)(2, [1, 2, 3], [4, 0, 4], 1) ≈
                       Poisson(F_, G_, autonomous=false, variable=true)(2, [1, 2, 3], [4, 0, 4], 1) atol =
                1e-6
            Test.@test Poisson(F, G_, autonomous=false, variable=true)(2, [1, 2, 3], [4, 0, 4], 1) ≈
                       Poisson(F_, G, autonomous=false, variable=true)(2, [1, 2, 3], [4, 0, 4], 1) atol =
                1e-6
        end
    end

    # macros

    @testset "lie macro" begin

        # parameters
        t = 1
        x = [1, 2, 3]
        Γ = 2
        γ = 1
        δ = γ - Γ
        v = 1

        # autonomous
        F0 = VectorField(x -> [-Γ * x[1], -Γ * x[2], γ * (1 - x[3])])
        F1 = VectorField(x -> [0, -x[3], x[2]])
        F2 = VectorField(x -> [x[3], 0, -x[1]])
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__ = @Lie [F0, F1]
        F011__ = @Lie [[F0, F1], F1]

        Test.@test F01_(x) ≈ F01__(x) atol = 1e-6
        Test.@test F011_(x) ≈ F011__(x) atol = 1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(x) ≈ F011___(x) atol = 1e-6

        # nonautonomous
        F0 = VectorField((t, x) -> [-Γ * x[1], -Γ * x[2], γ * (1 - x[3])], autonomous=false, variable=false)
        F1 = VectorField((t, x) -> [0, -x[3], x[2]], autonomous=false, variable=false)
        F2 = VectorField((t, x) -> [x[3], 0, -x[1]], autonomous=false, variable=false)
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__ = @Lie [F0, F1]
        F011__ = @Lie [[F0, F1], F1]

        Test.@test F01_(t, x) ≈ F01__(t, x) atol = 1e-6
        Test.@test F011_(t, x) ≈ F011__(t, x) atol = 1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(t, x) ≈ F011___(t, x) atol = 1e-6

        # autonomous nonfixed
        F0 = VectorField((x, v) -> [-Γ * x[1], -Γ * x[2], γ * (1 - x[3])], autonomous=true, variable=true)
        F1 = VectorField((x, v) -> [0, -x[3], x[2]], autonomous=true, variable=true)
        F2 = VectorField((x, v) -> [x[3], 0, -x[1]], autonomous=true, variable=true)
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__ = @Lie [F0, F1]
        F011__ = @Lie [[F0, F1], F1]

        Test.@test F01_(x, v) ≈ F01__(x, v) atol = 1e-6
        Test.@test F011_(x, v) ≈ F011__(x, v) atol = 1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(x, v) ≈ F011___(x, v) atol = 1e-6

        # nonautonomous nonfixed
        F0 = VectorField(
            (t, x, v) -> [-Γ * x[1], -Γ * x[2], γ * (1 - x[3])],
            autonomous=false,
            variable=true,
        )
        F1 = VectorField((t, x, v) -> [0, -x[3], x[2]], autonomous=false, variable=true)
        F2 = VectorField((t, x, v) -> [x[3], 0, -x[1]], autonomous=false, variable=true)
        F01_ = Lie(F0, F1)
        F011_ = Lie(F01_, F1)
        F01__ = @Lie [F0, F1]
        F011__ = @Lie [[F0, F1], F1]

        Test.@test F01_(t, x, v) ≈ F01__(t, x, v) atol = 1e-6
        Test.@test F011_(t, x, v) ≈ F011__(t, x, v) atol = 1e-6
        #
        get_F0 = () -> F0
        F011___ = @Lie [[get_F0(), F1], F1]
        Test.@test F011_(t, x, v) ≈ F011___(t, x, v) atol = 1e-6
    end

    @testset "poisson macro" begin
        # parameters
        t = 1
        x = [1, 2, 3]
        p = [1, 0, 7]
        Γ = 2
        γ = 1
        δ = γ - Γ
        v = 2

        # autonomous
        H0 = Hamiltonian((x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2))
        H1 = Hamiltonian((x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2))
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_ = @Lie {H0, H1}
        P011_ = @Lie {{H0, H1}, H1}
        Test.@test P01(x, p) ≈ P01_(x, p) atol = 1e-6
        Test.@test P011(x, p) ≈ P011_(x, p) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1}
        Test.@test P011_(x, p) ≈ P011__(x, p) atol = 1e-6

        # nonautonomous
        H0 = Hamiltonian((t, x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2), autonomous = false)
        H1 = Hamiltonian((t, x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2), autonomous=false, variable=false)
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_ = @Lie {H0, H1}
        P011_ = @Lie {{H0, H1}, H1}
        Test.@test P01(t, x, p) ≈ P01_(t, x, p) atol = 1e-6
        Test.@test P011(t, x, p) ≈ P011_(t, x, p) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1}
        Test.@test P011_(t, x, p) ≈ P011__(t, x, p) atol = 1e-6

        # autonomous nonfixed
        H0 = Hamiltonian((x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2 + v), variable = true)
        H1 = Hamiltonian((x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2 + v), variable = true)
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_ = @Lie {H0, H1}
        P011_ = @Lie {{H0, H1}, H1}
        Test.@test P01(x, p, v) ≈ P01_(x, p, v) atol = 1e-6
        Test.@test P011(x, p, v) ≈ P011_(x, p, v) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1}
        Test.@test P011_(x, p, v) ≈ P011__(x, p, v) atol = 1e-6

        # nonautonomous nonfixed
        H0 = Hamiltonian(
            (t, x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2 + v),
            autonomous = false,
            variable = true,
        )
        H1 = Hamiltonian(
            (t, x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2 + v),
            autonomous=false,
            variable=true,
        )
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_ = @Lie {H0, H1}
        P011_ = @Lie {{H0, H1}, H1}
        Test.@test P01(t, x, p, v) ≈ P01_(t, x, p, v) atol = 1e-6
        Test.@test P011(t, x, p, v) ≈ P011_(t, x, p, v) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1}
        Test.@test P011_(t, x, p, v) ≈ P011__(t, x, p, v) atol = 1e-6
    end

    @testset "poisson macro with functions" begin
        # parameters
        t = 1
        x = [1, 2, 3]
        p = [1, 0, 7]
        Γ = 2
        γ = 1
        δ = γ - Γ
        v = 2

        # autonomous
        H0 = (x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2)
        H1 = (x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2)
        P01 = Poisson(H0, H1)
        P011 = Poisson(P01, H1)
        P01_ = @Lie {H0, H1}
        P011_ = @Lie {{H0, H1}, H1}
        Test.@test P01(x, p) ≈ P01_(x, p) atol = 1e-6
        Test.@test P011(x, p) ≈ P011_(x, p) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1}
        Test.@test P011_(x, p) ≈ P011__(x, p) atol = 1e-6

        # nonautonomous
        H0 = (t, x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2)
        H1 = (t, x, p) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2)
        P01 = Poisson(H0, H1; autonomous = false)
        P011 = Poisson(P01, H1)
        P01_val = @Lie {H0, H1}(t, x, p) autonomous = false
        P01_ = @Lie {H0, H1} autonomous = false
        P011_ = @Lie {{H0, H1}, H1} autonomous = false
        Test.@test P01(t, x, p) ≈ P01_(t, x, p) atol = 1e-6
        Test.@test P01_val ≈ P01_(t, x, p) atol = 1e-6
        Test.@test P011(t, x, p) ≈ P011_(t, x, p) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1} autonomous=false variable=false
        Test.@test P011_(t, x, p) ≈ P011__(t, x, p) atol = 1e-6

        # autonomous nonfixed
        H0 = (x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2 + v)
        H1 = (x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2 + v)
        P01 = Poisson(H0, H1; variable = true)
        P011 = Poisson(P01, H1)
        P01_ = @Lie {H0, H1} variable = true
        P011_ = @Lie {{H0, H1}, H1} variable = true
        Test.@test P01(x, p, v) ≈ P01_(x, p, v) atol = 1e-6
        Test.@test P011(x, p, v) ≈ P011_(x, p, v) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1} autonomous=true variable=true
        Test.@test P011_(x, p, v) ≈ P011__(x, p, v) atol = 1e-6

        # nonautonomous nonfixed
        H0 = (t, x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[1]^2 + v)
        H1 = (t, x, p, v) -> 0.5 * (x[1]^2 + x[2]^2 + p[2]^2 + v)
        P01 = Poisson(H0, H1; autonomous = false, variable = true)
        P011 = Poisson(P01, H1)
        P01_ = @Lie {H0, H1} autonomous = false variable = true
        P011_ = @Lie {{H0, H1}, H1} autonomous=false variable=true
        Test.@test P01(t, x, p, v) ≈ P01_(t, x, p, v) atol = 1e-6
        Test.@test P011(t, x, p, v) ≈ P011_(t, x, p, v) atol = 1e-6
        get_H0 = () -> H0
        P011__ = @Lie {{get_H0(), H1}, H1} autonomous=false variable=true
        Test.@test P011_(t, x, p, v) ≈ P011__(t, x, p, v) atol = 1e-6
    end

    @testset "lie and poisson macros operation (sum,diff,...)" begin
        # parameters
        t = 1
        x = [1, 2, 3]
        p = [1, 0, 7]
        Γ = 2
        γ = 1
        δ = γ - Γ
        v = 1

        # lie
        # autonomous
        F0 = VectorField(x -> [-Γ * x[1], -Γ * x[2], γ * (1 - x[3])])
        F1 = VectorField(x -> [0, -x[3], x[2]])
        F2 = VectorField(x -> [x[3], 0, -x[1]])
        Test.@test @Lie [F0, F1](x) + 4 * [F1, F2](x) == [8, -8, -2]
        Test.@test @Lie [F0, F1](x) - [F1, F2](x) == [-2, -3, -2]
        Test.@test @Lie [F0, F1](x) .* [F1, F2](x) == [0, 4, 0]
        Test.@test @Lie [1, 1, 1] + ([[F0, F1], F1](x) + [F1, F2](x) + [1, 1, 1]) == [4, 5, -5]

        # nonautonomous nonfixed
        F0 = VectorField(
            (t, x, v) -> [-Γ * x[1], -Γ * x[2], γ * (1 - x[3])],
            autonomous=false,
            variable=true,
        )
        F1 = VectorField((t, x, v) -> [0, -x[3], x[2]], autonomous=false, variable=true)
        F2 = VectorField((t, x, v) -> [x[3], 0, -x[1]], autonomous=false, variable=true)
        Test.@test @Lie [F0, F1](t, x, v) + 4 * [F1, F2](t, x, v) == [8, -8, -2]
        Test.@test @Lie [F0, F1](t, x, v) - [F1, F2](t, x, v) == [-2, -3, -2]
        Test.@test @Lie [F0, F1](t, x, v) .* [F1, F2](t, x, v) == [0, 4, 0]
        Test.@test @Lie [1, 1, 1] + ([[F0, F1], F1](t, x, v) + [F1, F2](t, x, v) + [1, 1, 1]) ==
                        [4, 5, -5]

        # poisson
        # autonomous
        H0 = Hamiltonian((x, p) -> 0.5 * (2x[1]^2 + x[2]^2 + p[1]^2))
        H1 = Hamiltonian((x, p) -> 0.5 * (3x[1]^2 + x[2]^2 + p[2]^2))
        H2 = Hamiltonian((x, p) -> 0.5 * (4x[1]^2 + x[2]^2 + p[1]^3 + p[2]^2))
        Test.@test @Lie {H0, H1}(x, p) + 4 * {H1, H2}(x, p) == -15
        Test.@test @Lie {H0, H1}(x, p) - {H1, H2}(x, p) == 7.5
        Test.@test @Lie {H0, H1}(x, p) * {H1, H2}(x, p) == -13.5
        Test.@test @Lie 4 + ({{H0, H1}, H1}(x, p) + -2 * {H1, H2}(x, p) + 21) == 39

        # nonautonomous nonfixed
        H0 = Hamiltonian(
            (t, x, p, v) -> 0.5 * (2x[1]^2 + x[2]^2 + p[1]^2),
            autonomous = false,
            variable = true,
        )
        H1 = Hamiltonian(
            (t, x, p, v) -> 0.5 * (3x[1]^2 + x[2]^2 + p[2]^2),
            autonomous = false,
            variable = true,
        )
        H2 = Hamiltonian(
            (t, x, p, v) -> 0.5 * (4x[1]^2 + x[2]^2 + p[1]^3 + p[2]^2),
            autonomous = false,
            variable = true,
        )
        Test.@test @Lie {H0, H1}(t, x, p, v) + 4 * {H1, H2}(t, x, p, v) == -15
        Test.@test @Lie {H0, H1}(t, x, p, v) - {H1, H2}(t, x, p, v) == 7.5
        Test.@test @Lie {H0, H1}(t, x, p, v) * {H1, H2}(t, x, p, v) == -13.5
        Test.@test @Lie 4 + ({{H0, H1}, H1}(t, x, p, v) + -2 * {H1, H2}(t, x, p, v) + 21) == 39
    end
end # test_differential_geometry
