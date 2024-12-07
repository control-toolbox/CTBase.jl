function test_function()
    ∅ = Vector{Real}()
    dummy_function() = nothing

    @testset "BoundaryConstraint" begin
        @test BoundaryConstraint(dummy_function, Fixed) ==
            BoundaryConstraint(dummy_function; variable=false)
        @test BoundaryConstraint(dummy_function, NonFixed) ==
            BoundaryConstraint(dummy_function; variable=true)

        B = BoundaryConstraint(
            (x0, xf) -> [xf[2] - x0[1], 2xf[1] + x0[2]^2]; variable=false
        )
        @test B([0, 0], [1, 1]) == [1, 2]
        @test B([0, 0], [1, 1], ∅) == [1, 2]
        B = BoundaryConstraint(
            (x0, xf, v) -> [v[3] + xf[2] - x0[1], v[1] - v[2] + 2xf[1] + x0[2]^2];
            variable=true,
        )
        @test B([0, 0], [1, 1], [1, 2, 3]) == [4, 1]
    end

    @testset "Mayer" begin
        @test Mayer(dummy_function, Fixed) == Mayer(dummy_function; variable=false)
        @test Mayer(dummy_function, NonFixed) == Mayer(dummy_function; variable=true)

        G = Mayer((x0, xf) -> [xf[2] - x0[1]]; variable=false)
        @test_throws MethodError G([0, 0], [1, 1])
        G = Mayer((x0, xf) -> xf[2] - x0[1]; variable=false)
        @test G([0, 0], [1, 1]) == 1
        @test G([0, 0], [1, 1], ∅) == 1
        G = Mayer((x0, xf, v) -> v[3] + xf[2] - x0[1]; variable=true)
        @test G([0, 0], [1, 1], [1, 2, 3]) == 4
    end

    @testset "Hamiltonian" begin
        @test Hamiltonian(dummy_function, Autonomous, Fixed) ==
            Hamiltonian(dummy_function; autonomous=true, variable=false)
        @test Hamiltonian(dummy_function, NonAutonomous, Fixed) ==
            Hamiltonian(dummy_function; autonomous=false, variable=false)
        @test Hamiltonian(dummy_function, Autonomous, NonFixed) ==
            Hamiltonian(dummy_function; autonomous=true, variable=true)
        @test Hamiltonian(dummy_function, NonAutonomous, NonFixed) ==
            Hamiltonian(dummy_function; autonomous=false, variable=true)

        H = Hamiltonian((x, p) -> [x[1]^2 + 2p[2]]; autonomous=true, variable=false)
        @test_throws MethodError H([1, 0], [0, 1])
        H = Hamiltonian((x, p) -> x[1]^2 + 2p[2]; autonomous=true, variable=false)
        @test H([1, 0], [0, 1]) == 3
        t = 1
        v = Real[]
        @test_throws MethodError H(t, [1, 0], [0, 1])
        @test_throws MethodError H([1, 0], [0, 1], v)
        @test H(t, [1, 0], [0, 1], v) == 3
        H = Hamiltonian((x, p, v) -> x[1]^2 + 2p[2] + v[3]; autonomous=true, variable=true)
        @test H([1, 0], [0, 1], [1, 2, 3]) == 6
        @test H(t, [1, 0], [0, 1], [1, 2, 3]) == 6
        H = Hamiltonian((t, x, p) -> t + x[1]^2 + 2p[2]; autonomous=false, variable=false)
        @test H(1, [1, 0], [0, 1]) == 4
        @test H(1, [1, 0], [0, 1], v) == 4
        H = Hamiltonian(
            (t, x, p, v) -> t + x[1]^2 + 2p[2] + v[3]; autonomous=false, variable=true
        )
        @test H(1, [1, 0], [0, 1], [1, 2, 3]) == 7
    end

    @testset "HamiltonianVectorField" begin
        @test HamiltonianVectorField(dummy_function, Autonomous, Fixed) ==
            HamiltonianVectorField(dummy_function; autonomous=true, variable=false)
        @test HamiltonianVectorField(dummy_function, NonAutonomous, Fixed) ==
            HamiltonianVectorField(dummy_function; autonomous=false, variable=false)
        @test HamiltonianVectorField(dummy_function, Autonomous, NonFixed) ==
            HamiltonianVectorField(dummy_function; autonomous=true, variable=true)
        @test HamiltonianVectorField(dummy_function, NonAutonomous, NonFixed) ==
            HamiltonianVectorField(dummy_function; autonomous=false, variable=true)

        Hv = HamiltonianVectorField(
            (x, p) -> ([x[1]^2 + 2p[2]], [x[2] - 3p[2]^2]); autonomous=true, variable=false
        )
        @test Hv([1, 0], [0, 1]) == ([3], [-3])
        t = 1
        v = Real[]
        @test_throws MethodError Hv(t, [1, 0], [0, 1])
        @test_throws MethodError Hv([1, 0], [0, 1], v)
        @test Hv(t, [1, 0], [0, 1], v) == ([3], [-3])
        Hv = HamiltonianVectorField(
            (x, p, v) -> ([x[1]^2 + 2p[2] + v[3]], [x[2] - 3p[2]^2]);
            autonomous=true,
            variable=true,
        )
        @test Hv([1, 0], [0, 1], [1, 2, 3]) == ([6], [-3])
        @test Hv(t, [1, 0], [0, 1], [1, 2, 3]) == ([6], [-3])
        Hv = HamiltonianVectorField(
            (t, x, p) -> ([t + x[1]^2 + 2p[2]], [x[2] - 3p[2]^2]);
            autonomous=false,
            variable=false,
        )
        @test Hv(1, [1, 0], [0, 1]) == ([4], [-3])
        @test Hv(1, [1, 0], [0, 1], v) == ([4], [-3])
        Hv = HamiltonianVectorField(
            (t, x, p, v) -> ([t + x[1]^2 + 2p[2] + v[3]], [x[2] - 3p[2]^2]);
            autonomous=false,
            variable=true,
        )
        @test Hv(1, [1, 0], [0, 1], [1, 2, 3]) == ([7], [-3])
    end

    @testset "VectorField" begin
        @test VectorField(dummy_function, Autonomous, Fixed) ==
            VectorField(dummy_function; autonomous=true, variable=false)
        @test VectorField(dummy_function, NonAutonomous, Fixed) ==
            VectorField(dummy_function; autonomous=false, variable=false)
        @test VectorField(dummy_function, Autonomous, NonFixed) ==
            VectorField(dummy_function; autonomous=true, variable=true)
        @test VectorField(dummy_function, NonAutonomous, NonFixed) ==
            VectorField(dummy_function; autonomous=false, variable=true)
        V = VectorField(x -> [x[1]^2, 2x[2]]; autonomous=true, variable=false)
        @test V([1, -1]) == [1, -2]
        t = 1
        v = Real[]
        @test_throws MethodError V(t, [1, -1])
        @test_throws MethodError V([1, -1], v)
        @test V(t, [1, -1], v) == [1, -2]
        V = VectorField((x, v) -> [x[1]^2, 2x[2] + v[3]]; autonomous=true, variable=true)
        @test V([1, -1], [1, 2, 3]) == [1, 1]
        @test V(t, [1, -1], [1, 2, 3]) == [1, 1]
        V = VectorField((t, x) -> [t + x[1]^2, 2x[2]]; autonomous=false, variable=false)
        @test V(1, [1, -1]) == [2, -2]
        @test V(1, [1, -1], v) == [2, -2]
        V = VectorField(
            (t, x, v) -> [t + x[1]^2, 2x[2] + v[3]]; autonomous=false, variable=true
        )
        @test V(1, [1, -1], [1, 2, 3]) == [2, 1]
    end

    @testset "Lagrange" begin
        @test Lagrange(dummy_function, Autonomous, Fixed) ==
            Lagrange(dummy_function; autonomous=true, variable=false)
        @test Lagrange(dummy_function, NonAutonomous, Fixed) ==
            Lagrange(dummy_function; autonomous=false, variable=false)
        @test Lagrange(dummy_function, Autonomous, NonFixed) ==
            Lagrange(dummy_function; autonomous=true, variable=true)
        @test Lagrange(dummy_function, NonAutonomous, NonFixed) ==
            Lagrange(dummy_function; autonomous=false, variable=true)

        L = Lagrange((x, u) -> [2x[2] - u[1]^2]; autonomous=true, variable=false)
        @test_throws MethodError L([1, 0], [1])
        L = Lagrange((x, u) -> 2x[2] - u[1]^2; autonomous=true, variable=false)
        @test L([1, 0], [1]) == -1
        t = 1
        v = Real[]
        @test_throws MethodError L(t, [1, 0], [1])
        @test_throws MethodError L([1, 0], [1], v)
        @test L(t, [1, 0], [1], v) == -1
        L = Lagrange((x, u, v) -> 2x[2] - u[1]^2 + v[3]; autonomous=true, variable=true)
        @test L([1, 0], [1], [1, 2, 3]) == 2
        @test L(t, [1, 0], [1], [1, 2, 3]) == 2
        L = Lagrange((t, x, u) -> t + 2x[2] - u[1]^2; autonomous=false, variable=false)
        @test L(1, [1, 0], [1]) == 0
        @test L(1, [1, 0], [1], v) == 0
        L = Lagrange(
            (t, x, u, v) -> t + 2x[2] - u[1]^2 + v[3]; autonomous=false, variable=true
        )
        @test L(1, [1, 0], [1], [1, 2, 3]) == 3
    end

    @testset "Dynamics" begin
        @test Dynamics(dummy_function, Autonomous, Fixed) ==
            Dynamics(dummy_function; autonomous=true, variable=false)
        @test Dynamics(dummy_function, NonAutonomous, Fixed) ==
            Dynamics(dummy_function; autonomous=false, variable=false)
        @test Dynamics(dummy_function, Autonomous, NonFixed) ==
            Dynamics(dummy_function; autonomous=true, variable=true)
        @test Dynamics(dummy_function, NonAutonomous, NonFixed) ==
            Dynamics(dummy_function; autonomous=false, variable=true)

        # Similar to Lagrange, but the function Dynamics is assumed to return a vector of the same dimension as the state x.
        # dim x = 2, dim u = 1
        # when a dim is 1, consider the element as a scalar
        D = Dynamics((x, u) -> [2x[2] - u^2, x[1]]; autonomous=true, variable=false)
        @test D([1, 0], 1) == [-1, 1]
        t = 1
        v = Real[]
        @test_throws MethodError D(t, [1, 0], 1)
        @test_throws MethodError D([1, 0], 1, v)
        @test D(t, [1, 0], 1, v) == [-1, 1]
        D = Dynamics(
            (x, u, v) -> [2x[2] - u^2 + v[3], x[1]]; autonomous=true, variable=true
        )
        @test D([1, 0], 1, [1, 2, 3]) == [2, 1]
        @test D(t, [1, 0], 1, [1, 2, 3]) == [2, 1]
        D = Dynamics((t, x, u) -> [t + 2x[2] - u^2, x[1]]; autonomous=false, variable=false)
        @test D(1, [1, 0], 1) == [0, 1]
        @test D(1, [1, 0], 1, v) == [0, 1]
        D = Dynamics(
            (t, x, u, v) -> [t + 2x[2] - u^2 + v[3], x[1]]; autonomous=false, variable=true
        )
        @test D(1, [1, 0], 1, [1, 2, 3]) == [3, 1]
    end

    @testset "StateConstraint" begin
        @test StateConstraint(dummy_function, Autonomous, Fixed) ==
            StateConstraint(dummy_function; autonomous=true, variable=false)
        @test StateConstraint(dummy_function, NonAutonomous, Fixed) ==
            StateConstraint(dummy_function; autonomous=false, variable=false)
        @test StateConstraint(dummy_function, Autonomous, NonFixed) ==
            StateConstraint(dummy_function; autonomous=true, variable=true)
        @test StateConstraint(dummy_function, NonAutonomous, NonFixed) ==
            StateConstraint(dummy_function; autonomous=false, variable=true)

        # Similar to `VectorField` in the usage, but the dimension of the output of the function StateConstraint is arbitrary.
        # dim x = 2
        S = StateConstraint(x -> [x[1]^2, 2x[2]]; autonomous=true, variable=false)
        @test S([1, -1]) == [1, -2]
        t = 1
        v = Real[]
        @test_throws MethodError S(t, [1, -1])
        @test_throws MethodError S([1, -1], v)
        @test S(t, [1, -1], v) == [1, -2]
        S = StateConstraint(
            (x, v) -> [x[1]^2, 2x[2] + v[3]]; autonomous=true, variable=true
        )
        @test S([1, -1], [1, 2, 3]) == [1, 1]
        @test S(t, [1, -1], [1, 2, 3]) == [1, 1]
        S = StateConstraint((t, x) -> [t + x[1]^2, 2x[2]]; autonomous=false, variable=false)
        @test S(1, [1, -1]) == [2, -2]
        @test S(1, [1, -1], v) == [2, -2]
        S = StateConstraint(
            (t, x, v) -> [t + x[1]^2, 2x[2] + v[3]]; autonomous=false, variable=true
        )
        @test S(1, [1, -1], [1, 2, 3]) == [2, 1]
    end

    @testset "ControlConstraint" begin
        @test ControlConstraint(dummy_function, Autonomous, Fixed) ==
            ControlConstraint(dummy_function; autonomous=true, variable=false)
        @test ControlConstraint(dummy_function, NonAutonomous, Fixed) ==
            ControlConstraint(dummy_function; autonomous=false, variable=false)
        @test ControlConstraint(dummy_function, Autonomous, NonFixed) ==
            ControlConstraint(dummy_function; autonomous=true, variable=true)
        @test ControlConstraint(dummy_function, NonAutonomous, NonFixed) ==
            ControlConstraint(dummy_function; autonomous=false, variable=true)

        # Similar to `VectorField` in the usage, but the dimension of the output of the function ControlConstraint is arbitrary.
        # dim u = 2
        C = ControlConstraint(u -> [u[1]^2, 2u[2]]; autonomous=true, variable=false)
        @test C([1, -1]) == [1, -2]
        t = 1
        v = Real[]
        @test_throws MethodError C(t, [1, -1])
        @test_throws MethodError C([1, -1], v)
        @test C(t, [1, -1], v) == [1, -2]
        C = ControlConstraint(
            (u, v) -> [u[1]^2, 2u[2] + v[3]]; autonomous=true, variable=true
        )
        @test C([1, -1], [1, 2, 3]) == [1, 1]
        @test C(t, [1, -1], [1, 2, 3]) == [1, 1]
        C = ControlConstraint(
            (t, u) -> [t + u[1]^2, 2u[2]]; autonomous=false, variable=false
        )
        @test C(1, [1, -1]) == [2, -2]
        @test C(1, [1, -1], v) == [2, -2]
        C = ControlConstraint(
            (t, u, v) -> [t + u[1]^2, 2u[2] + v[3]]; autonomous=false, variable=true
        )
        @test C(1, [1, -1], [1, 2, 3]) == [2, 1]
    end

    @testset "MixedConstraint" begin
        @test MixedConstraint(dummy_function, Autonomous, Fixed) ==
            MixedConstraint(dummy_function; autonomous=true, variable=false)
        @test MixedConstraint(dummy_function, NonAutonomous, Fixed) ==
            MixedConstraint(dummy_function; autonomous=false, variable=false)
        @test MixedConstraint(dummy_function, Autonomous, NonFixed) ==
            MixedConstraint(dummy_function; autonomous=true, variable=true)
        @test MixedConstraint(dummy_function, NonAutonomous, NonFixed) ==
            MixedConstraint(dummy_function; autonomous=false, variable=true)

        # Similar to `Lagrange` in the usage, but the dimension of the output of the function MixedConstraint is arbitrary.
        # dim x = 2, dim u = 1, dim output = 2
        M = MixedConstraint((x, u) -> [2x[2] - u^2, x[1]]; autonomous=true, variable=false)
        @test M([1, 0], 1) == [-1, 1]
        t = 1
        v = Real[]
        @test_throws MethodError M(t, [1, 0], 1)
        @test_throws MethodError M([1, 0], 1, v)
        @test M(t, [1, 0], 1, v) == [-1, 1]
        M = MixedConstraint(
            (x, u, v) -> [2x[2] - u^2 + v[3], x[1]]; autonomous=true, variable=true
        )
        @test M([1, 0], 1, [1, 2, 3]) == [2, 1]
        @test M(t, [1, 0], 1, [1, 2, 3]) == [2, 1]
        M = MixedConstraint(
            (t, x, u) -> [t + 2x[2] - u^2, x[1]]; autonomous=false, variable=false
        )
        @test M(1, [1, 0], 1) == [0, 1]
        @test M(1, [1, 0], 1, v) == [0, 1]
        M = MixedConstraint(
            (t, x, u, v) -> [t + 2x[2] - u^2 + v[3], x[1]]; autonomous=false, variable=true
        )
        @test M(1, [1, 0], 1, [1, 2, 3]) == [3, 1]
    end

    @testset "VariableConstraint" begin
        V = VariableConstraint(v -> [v[1]^2, 2v[2]])
        @test V([1, -1]) == [1, -2]
    end

    @testset "FeedbackControl" begin
        @test FeedbackControl(dummy_function, Autonomous, Fixed) ==
            FeedbackControl(dummy_function; autonomous=true, variable=false)
        @test FeedbackControl(dummy_function, NonAutonomous, Fixed) ==
            FeedbackControl(dummy_function; autonomous=false, variable=false)
        @test FeedbackControl(dummy_function, Autonomous, NonFixed) ==
            FeedbackControl(dummy_function; autonomous=true, variable=true)
        @test FeedbackControl(dummy_function, NonAutonomous, NonFixed) ==
            FeedbackControl(dummy_function; autonomous=false, variable=true)

        # Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.
        # dim x = 2, dim output = 1
        u = FeedbackControl(x -> x[1]^2 + 2x[2]; autonomous=true, variable=false)
        @test u([1, 0]) == 1
        t = 1
        v = Real[]
        @test_throws MethodError u(t, [1, 0])
        @test_throws MethodError u([1, 0], v)
        @test u(t, [1, 0], v) == 1
        u = FeedbackControl((x, v) -> x[1]^2 + 2x[2] + v[3]; autonomous=true, variable=true)
        @test u([1, 0], [1, 2, 3]) == 4
        @test u(t, [1, 0], [1, 2, 3]) == 4
        u = FeedbackControl((t, x) -> t + x[1]^2 + 2x[2]; autonomous=false, variable=false)
        @test u(1, [1, 0]) == 2
        @test u(1, [1, 0], v) == 2
        u = FeedbackControl(
            (t, x, v) -> t + x[1]^2 + 2x[2] + v[3]; autonomous=false, variable=true
        )
        @test u(1, [1, 0], [1, 2, 3]) == 5
    end

    @testset "ControlLaw" begin
        @test ControlLaw(dummy_function, Autonomous, Fixed) ==
            ControlLaw(dummy_function; autonomous=true, variable=false)
        @test ControlLaw(dummy_function, NonAutonomous, Fixed) ==
            ControlLaw(dummy_function; autonomous=false, variable=false)
        @test ControlLaw(dummy_function, Autonomous, NonFixed) ==
            ControlLaw(dummy_function; autonomous=true, variable=true)
        @test ControlLaw(dummy_function, NonAutonomous, NonFixed) ==
            ControlLaw(dummy_function; autonomous=false, variable=true)

        # Similar to `Hamiltonian` in the usage, but the dimension of the output of the function `ControlLaw` is arbitrary.
        # dim x = 2, dim p =2, dim output = 1
        u = ControlLaw((x, p) -> x[1]^2 + 2p[2]; autonomous=true, variable=false)
        @test u([1, 0], [0, 1]) == 3
        t = 1
        v = Real[]
        @test_throws MethodError u(t, [1, 0], [0, 1])
        @test_throws MethodError u([1, 0], [0, 1], v)
        @test u(t, [1, 0], [0, 1], v) == 3
        u = ControlLaw((x, p, v) -> x[1]^2 + 2p[2] + v[3]; autonomous=true, variable=true)
        @test u([1, 0], [0, 1], [1, 2, 3]) == 6
        @test u(t, [1, 0], [0, 1], [1, 2, 3]) == 6
        u = ControlLaw((t, x, p) -> t + x[1]^2 + 2p[2]; autonomous=false, variable=false)
        @test u(1, [1, 0], [0, 1]) == 4
        @test u(1, [1, 0], [0, 1], v) == 4
        u = ControlLaw(
            (t, x, p, v) -> t + x[1]^2 + 2p[2] + v[3]; autonomous=false, variable=true
        )
        @test u(1, [1, 0], [0, 1], [1, 2, 3]) == 7
    end

    @testset "Multiplier" begin
        @test Multiplier(dummy_function, Autonomous, Fixed) ==
            Multiplier(dummy_function; autonomous=true, variable=false)
        @test Multiplier(dummy_function, NonAutonomous, Fixed) ==
            Multiplier(dummy_function; autonomous=false, variable=false)
        @test Multiplier(dummy_function, Autonomous, NonFixed) ==
            Multiplier(dummy_function; autonomous=true, variable=true)
        @test Multiplier(dummy_function, NonAutonomous, NonFixed) ==
            Multiplier(dummy_function; autonomous=false, variable=true)

        # Similar to `ControlLaw` in the usage.
        # dim x = 2, dim p =2, dim output = 1
        μ = Multiplier((x, p) -> x[1]^2 + 2p[2]; autonomous=true, variable=false)
        @test μ([1, 0], [0, 1]) == 3
        t = 1
        v = Real[]
        @test_throws MethodError μ(t, [1, 0], [0, 1])
        @test_throws MethodError μ([1, 0], [0, 1], v)
        @test μ(t, [1, 0], [0, 1], v) == 3
        μ = Multiplier((x, p, v) -> x[1]^2 + 2p[2] + v[3]; autonomous=true, variable=true)
        @test μ([1, 0], [0, 1], [1, 2, 3]) == 6
        @test μ(t, [1, 0], [0, 1], [1, 2, 3]) == 6
        μ = Multiplier((t, x, p) -> t + x[1]^2 + 2p[2]; autonomous=false, variable=false)
        @test μ(1, [1, 0], [0, 1]) == 4
        @test μ(1, [1, 0], [0, 1], v) == 4
        μ = Multiplier(
            (t, x, p, v) -> t + x[1]^2 + 2p[2] + v[3]; autonomous=false, variable=true
        )
        @test μ(1, [1, 0], [0, 1], [1, 2, 3]) == 7
    end
end
