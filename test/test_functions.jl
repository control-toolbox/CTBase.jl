function test_functions()

@testset "_Time" begin
    @test _Time(1) + _Time(2) == _Time(3)
    @test _Time(1) - _Time(2) == _Time(-1)
    @test _Time(1) * _Time(2) == _Time(2)
    @test _Time(1) / _Time(2) == _Time(0.5)
    @test _Time(1)^2 == _Time(1)
    @test _Time(1) + 1 == _Time(2)
    @test _Time(1) - 1 == _Time(0)
    @test _Time(1) * 2 == _Time(2)
    @test _Time(1) / 2 == _Time(0.5)
    @test 1 + _Time(1) == _Time(2)
    @test 1 - _Time(1) == _Time(0)
    @test 2 * _Time(1) == _Time(2)
    @test 2 / _Time(1) == _Time(2.0)
    @test -_Time(1) == _Time(-1)
    @test _Time(1) ≤ _Time(2)
    @test _Time(1) < _Time(2)
    @test _Time(1) ≥ _Time(1)
    @test _Time(1) > _Time(0)
    @test _Time(1) == _Time(1)
end

# test BoundaryConstraint
@testset "BoundaryConstraint" begin
    @testset "Classical calls" begin
        B = BoundaryConstraint((x0, xf) -> xf - x0)
        @test B(0, 1) == 1
        @test B([0], [1]) == [1]
        B = BoundaryConstraint((x0, xf) -> [xf - x0, x0 + xf])
        @test B(0, 1) == [1, 1]
        @test_throws MethodError B([0], [1])
        B = BoundaryConstraint((x0, xf) -> xf - x0)
        @test B([1, 0], [0, 1]) == [ -1, 1 ]
        B = BoundaryConstraint((x0, xf) -> [x0[1], xf[1] - x0[2]])
        @test B([1, 0], [1, 0]) == [1, 1]
    end
    @testset "Specific calls" begin
        B = BoundaryConstraint((x0, xf) -> xf - x0, state_dimension=1, constraint_dimension=1)
        @test_throws MethodError B(0, 1)
        @test B([0], [1]) == [1]
        B = BoundaryConstraint((x0, xf) -> [xf - x0, x0 - xf], state_dimension=1, constraint_dimension=2)
        @test_throws MethodError B(0, 1)
        @test B([0], [1]) == [1, -1]
        B = BoundaryConstraint((x0, xf) -> xf[1] - x0[1], state_dimension=2, constraint_dimension=1)
        @test B([1, 0], [0, 1]) == [-1]
        B = BoundaryConstraint((x0, xf) -> [xf[1] + x0[1], xf[1] - x0[2]], state_dimension=2, constraint_dimension=2)
        @test B([1, 0], [1, 0]) == [1, 1]
    end
end

@testset "Mayer" begin
    @testset "Classical calls" begin
        G = Mayer((t0, x0, tf, xf) -> xf - x0)
        @test G(0, 0, 1, 1) == 1
        @test_throws MethodError G(0, [0], 1, [1])
        G = Mayer((t0, x0, tf, xf) -> tf - t0)
        @test G(0, [1, 0], 1, [0, 1]) == 1
    end
    @testset "Specific calls" begin
        G = Mayer((t0, x0, tf, xf) -> xf - x0, state_dimension=1)
        @test_throws MethodError G(_Time(0), 0, _Time(1), 1)
        @test G(_Time(0), [0], _Time(1), [1]) == 1
        G = Mayer((t0, x0, tf, xf) -> tf - t0, state_dimension=2)
        @test G(_Time(0), [1, 0], _Time(1), [0, 1]) == 1
    end
end

@testset "Hamiltonian" begin
    @test_throws InconsistentArgument Hamiltonian((x, p) -> x + p, time_dependence=:dummy)
    @testset "Classical calls" begin
        H = Hamiltonian((x, p) -> x + p)
        @test H(1, 1) == 2
        @test_throws MethodError H([1], [1])
        H = Hamiltonian((x, p) -> x + p, time_dependence=:autonomous)
        @test H(1, 1) == 2
        @test_throws MethodError H([1], [1])
        H = Hamiltonian((t, x, p) -> x + p, time_dependence=:nonautonomous)
        @test H(1, 1, 1) == 2
        @test_throws MethodError H(1, [1], [1])
        H = Hamiltonian((x, p) -> x[1]^2 + p[2]^2) # or time_dependence=:autonomous
        @test H([1, 0], [0, 1]) == 2
        H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, time_dependence=:nonautonomous)
        @test H(1, [1, 0], [0, 1]) == 3
    end
    @testset "Specific calls" begin
        H = Hamiltonian((x, p) -> x + p, state_dimension=1)
        @test_throws MethodError H(_Time(0), 1, 1)
        @test H(_Time(0), [1], [1]) == 2
        H = Hamiltonian((t, x, p) -> t + x + p, state_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError H(_Time(1), 1, 1)
        @test H(_Time(1), [1], [1]) == 3
        H = Hamiltonian((x, p) -> x[1]^2 + p[2]^2, state_dimension=2)
        @test H(_Time(0), [1, 0], [0, 1]) == 2
        H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, state_dimension=2, time_dependence=:nonautonomous)
        @test H(_Time(1), [1, 0], [0, 1]) == 3
    end
end

@testset "HamiltonianVectorField" begin
    @test_throws InconsistentArgument HamiltonianVectorField((x, p) -> [x + p, x - p], time_dependence=:dummy)
    @testset "Classical calls" begin
        Hv = HamiltonianVectorField((x, p) -> [x + p, x - p])
        @test Hv(1, 1) == [2, 0]
        @test_throws MethodError Hv([1], [1])
        Hv = HamiltonianVectorField((x, p) -> [x + p, x - p], time_dependence=:autonomous)
        @test Hv(1, 1) == [2, 0]
        @test_throws MethodError Hv([1], [1])
        Hv = HamiltonianVectorField((t, x, p) -> [x + p, x - p], time_dependence=:nonautonomous)
        @test Hv(1, 1, 1) == [2, 0]
        @test_throws MethodError Hv(1, [1], [1])
        Hv = HamiltonianVectorField((x, p) -> [x[1]^2 + p[2]^2, x[2]^2 - p[1]^2]) # or time_dependence=:autonomous
        @test Hv([1, 0], [0, 1]) == [2, 0]
        Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], time_dependence=:nonautonomous)
        @test Hv(1, [1, 0], [0, 1]) == [3, 0]
    end
    @testset "Specific calls" begin
        Hv = HamiltonianVectorField((x, p) -> [x + p, x - p], state_dimension=1)
        @test_throws MethodError Hv(_Time(0), 1, 1)
        @test Hv(_Time(0), [1], [1]) == [2, 0]
        Hv = HamiltonianVectorField((t, x, p) -> [t + x + p, x - p], state_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError Hv(_Time(1), 1, 1)
        @test Hv(_Time(1), [1], [1]) == [3, 0]
        Hv = HamiltonianVectorField((x, p) -> [x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], state_dimension=2)
        @test Hv(_Time(0), [1, 0], [0, 1]) == [2, 0]
        Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], state_dimension=2, time_dependence=:nonautonomous)
        @test Hv(_Time(1), [1, 0], [0, 1]) == [3, 0]
    end
end

@testset "VectorField" begin
    @test_throws InconsistentArgument VectorField(x -> 2x, time_dependence=:dummy)
    @testset "Classical calls" begin
        V = VectorField(x -> 2x)
        @test V(1) == 2
        @test V([1]) == [2]
        V = VectorField(x -> 2x, time_dependence=:autonomous)
        @test V(1) == 2
        @test V([1]) == [2]
        V = VectorField((t, x) -> t+2x, time_dependence=:nonautonomous)
        @test V(1, 1) == 3
        @test_throws MethodError V(1, [1])
        V = VectorField(x -> [x[1]^2, x[2]^2]) # or time_dependence=:autonomous
        @test V([1, 0]) == [1, 0]
        V = VectorField((t, x) -> [t + x[1]^2, x[2]^2], time_dependence=:nonautonomous)
        @test V(1, [1, 0]) == [2, 0]
    end
    @testset "Specific calls" begin
        V = VectorField(x -> 2x, state_dimension=1)
        @test_throws MethodError V(_Time(0), 1)
        @test V(_Time(0), [1]) == [2]
        V = VectorField((t, x) -> t + x, state_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError V(_Time(1), 1)
        @test V(_Time(1), [1]) == [2]
        V = VectorField(x -> [x[1]^2, -x[2]^2], state_dimension=2)
        @test V(_Time(0), [1, 2]) == [1, -4]
        V = VectorField((t, x) -> [t + x[1]^2, -x[2]^2], state_dimension=2, time_dependence=:nonautonomous)
        @test V(_Time(1), [1, 2]) == [2, -4]
    end
end

@testset "Lagrange" begin
    @test_throws InconsistentArgument Lagrange((x, u) -> x + u, time_dependence=:dummy)
    @testset "Classical calls" begin
        L = Lagrange((x, u) -> x + u, time_dependence=:autonomous)
        @test L(1, 1) == 2
        @test_throws MethodError L([1], [1])
        L = Lagrange((t, x, u) -> x + u, time_dependence=:nonautonomous)
        @test L(1, 1, 1) == 2
        @test_throws MethodError L(1, [1], [1])

        L = Lagrange((x, u) -> x[1]^2 + u^2) # or time_dependence=:autonomous
        @test L([1, 0], 1) == 2
        L = Lagrange((t, x, u) -> x[1]^2 + u^2, time_dependence=:nonautonomous)
        @test L(1, [1, 0], 1) == 2

        L = Lagrange((x, u) -> x^2 + u[2]^2) # or time_dependence=:autonomous
        @test L(1, [1, 2]) == 5
        L = Lagrange((t, x, u) -> t + x^2 + u[2]^2, time_dependence=:nonautonomous)
        @test L(1, 1, [1, 2]) == 6

        L = Lagrange((x, u) -> x[1]^2 + u[2]^2) # or time_dependence=:autonomous
        @test L([1, 2], [1, 2]) == 5
        L = Lagrange((t, x, u) -> t + x[1]^2 + u[2]^2, time_dependence=:nonautonomous)
        @test L(1, [1, 2], [1, 2]) == 6
    end
    @testset "Specific calls" begin
        L = Lagrange((x, u) -> x + u, state_dimension=1, control_dimension=1)
        @test_throws MethodError L(_Time(0), 1, 1)
        @test L(_Time(0), [1], [1]) == 2
        L = Lagrange((t, x, u) -> x + u, state_dimension=1, control_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError L(_Time(1), 1, 1)
        @test L(_Time(1), [1], [1]) == 2

        L = Lagrange((x, u) -> x[1]^2 + u, state_dimension=2, control_dimension=1)
        @test_throws MethodError L(_Time(0), [1, 0], 1)
        @test L(_Time(0), [1, 0], [1]) == 2
        L = Lagrange((t, x, u) -> t + x[1]^2 + u, state_dimension=2, control_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError L(_Time(1), [1, 0], 1)
        @test L(_Time(1), [1, 0], [1]) == 3

        L = Lagrange((x, u) -> x + u[1], state_dimension=1, control_dimension=2)
        @test_throws MethodError L(_Time(0), 1, [1, 0])
        @test L(_Time(0), [1], [1, 0]) == 2
        L = Lagrange((t, x, u) -> t + x + u[1], state_dimension=1, control_dimension=2, time_dependence=:nonautonomous)
        @test_throws MethodError L(_Time(1), 1, [1, 0])
        @test L(_Time(1), [1], [1, 0]) == 3

        L = Lagrange((x, u) -> x[1]^2 + u[1], state_dimension=2, control_dimension=2)
        @test L(_Time(0), [1, 0], [1, 0]) == 2
        L = Lagrange((t, x, u) -> t + x[1]^2 + u[1], state_dimension=2, control_dimension=2, time_dependence=:nonautonomous)
        @test L(_Time(1), [1, 0], [1, 0]) == 3
    end
end

@testset "Dynamics" begin
    @test_throws InconsistentArgument Dynamics((x, u) -> x + u, time_dependence=:dummy)
    @testset "Classical calls" begin
        F = Dynamics((x, u) -> x + u)
        @test F(1, 1) == 2
        @test F([1], [1]) == [2]
        F = Dynamics((x, u) -> x + u, time_dependence=:autonomous)
        @test F(1, 1) == 2
        @test F([1], [1]) == [2]
        F = Dynamics((t, x, u) -> x + u, time_dependence=:nonautonomous)
        @test F(1, 1, 1) == 2
        @test F(1, [1], [1]) == [2]
        F = Dynamics((x, u) -> [x[1]^2 + u^2, x[2]]) # or time_dependence=:autonomous
        @test F([1, 0], 1) == [2, 0]
        F = Dynamics((x, u) -> x^2 + u[2]^2) # or time_dependence=:autonomous
        @test F(1, [0, 1]) == 2
        F = Dynamics((x, u) -> [x[1]^2 + u[2]^2, x[2]]) # or time_dependence=:autonomous
        @test F([1, 0], [0, 1]) == [2, 0]
        F = Dynamics((t, x, u) -> [t + x[1]^2 + u[2]^2, x[2]], time_dependence=:nonautonomous)
        @test F(1, [1, 0], [0, 1]) == [3, 0]
    end
    @testset "Specific calls" begin
        F = Dynamics((x, u) -> x + u, state_dimension=1, control_dimension=1)
        @test_throws MethodError F(_Time(0), 1, 1)
        @test F(_Time(0), [1], [1]) == [2]
        F = Dynamics((t, x, u) -> x + u, state_dimension=1, control_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError F(_Time(1), 1, 1)
        @test F(_Time(1), [1], [1]) == [2]
        F = Dynamics((x, u) -> [x[1]^2 + u, x[2]], state_dimension=2, control_dimension=1)
        @test_throws MethodError F(_Time(0), [1, 0], 1)
        @test F(_Time(0), [1, 0], [1]) == [2, 0]
        F = Dynamics((t, x, u) -> [t + x[1]^2 + u, x[2]], state_dimension=2, control_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError F(_Time(1), [1, 0], 1)
        @test F(_Time(1), [1, 0], [1]) == [3, 0]
        F = Dynamics((x, u) -> x + u[1], state_dimension=1, control_dimension=2)
        @test_throws MethodError F(_Time(0), 1, [1, 0])
        @test F(_Time(0), [1], [1, 0]) == [2]
        F = Dynamics((t, x, u) -> t + x + u[1], state_dimension=1, control_dimension=2, time_dependence=:nonautonomous)
        @test_throws MethodError F(_Time(1), 1, [1, 0])
        @test F(_Time(1), [1], [1, 0]) == [3]
        F = Dynamics((x, u) -> [x[1]^2 + u[1], x[2]], state_dimension=2, control_dimension=2)
        @test F(_Time(0), [1, 0], [1, 0]) == [2, 0]
        F = Dynamics((t, x, u) -> [t + x[1]^2 + u[1], x[2]], state_dimension=2, control_dimension=2, time_dependence=:nonautonomous)
        @test F(_Time(1), [1, 0], [1, 0]) == [3, 0]
    end
end

@testset "StateConstraint" begin
    @test_throws InconsistentArgument StateConstraint(x -> x, time_dependence=:dummy)
    @testset "Classical calls" begin
        S = StateConstraint(x -> x^2) 
        @test S(1) == 1
        @test_throws MethodError S([1])
        S = StateConstraint(x -> x^2, time_dependence=:autonomous)
        @test S(1) == 1
        @test_throws MethodError S([1])
        S = StateConstraint((t, x) -> x^2, time_dependence=:nonautonomous)
        @test S(1, 1) == 1
        @test_throws MethodError S(1, [1])
        S = StateConstraint(x -> x[1])
        @test S([1, 0]) == 1
        S = StateConstraint((t, x) -> x[1], time_dependence=:nonautonomous)
        @test S(1, [1, 0]) == 1
        S = StateConstraint(x -> [x[1], x[2]^2])
        @test S([1, 0]) == [1, 0]
        S = StateConstraint((t, x) -> [x[1], x[2]^2], time_dependence=:nonautonomous)
        @test S(1, [1, 0]) == [1, 0]
    end
    @testset "Specific calls" begin
        S = StateConstraint(x -> x^2, state_dimension=1, constraint_dimension=1)
        @test_throws MethodError S(_Time(0), 1)
        @test S(_Time(0), [1]) == [1]
        S = StateConstraint(x -> x^2, state_dimension=1, constraint_dimension=1, time_dependence=:autonomous)
        @test_throws MethodError S(_Time(0), 1)
        @test S(_Time(0), [1]) == [1]
        S = StateConstraint((t, x) -> x^2, state_dimension=1, constraint_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError S(_Time(1), 1)
        @test S(_Time(1), [1]) == [1]
        S = StateConstraint(x -> x[1], state_dimension=2, constraint_dimension=1)
        @test S(_Time(0), [1, 0]) == [1]
        S = StateConstraint((t, x) -> x[1], state_dimension=2, constraint_dimension=1, time_dependence=:nonautonomous)
        @test S(_Time(1), [1, 0]) == [1]
        S = StateConstraint(x -> [x[1], x[2]^2], state_dimension=2, constraint_dimension=2)
        @test S(_Time(0), [1, 0]) == [1, 0]
        S = StateConstraint((t, x) -> [x[1], x[2]^2], state_dimension=2, constraint_dimension=2, time_dependence=:nonautonomous)
        @test S(_Time(1), [1, 0]) == [1, 0]
        S = StateConstraint(x -> [x, x^2], state_dimension=1, constraint_dimension=2)
        @test_throws MethodError S(_Time(0), 1)
        @test S(_Time(0), [1]) == [1, 1]
        S = StateConstraint((t, x) -> [x, x^2], state_dimension=1, constraint_dimension=2, time_dependence=:nonautonomous)
        @test_throws MethodError S(_Time(1), 1)
        @test S(_Time(1), [1]) == [1, 1]
    end
end

@testset "ControlConstraint" begin
    @test_throws InconsistentArgument ControlConstraint(u -> u, time_dependence=:dummy)
    @testset "Classical calls" begin
        C = ControlConstraint(u -> u^2)
        @test C(1) == 1
        @test_throws MethodError C([1])
        C = ControlConstraint(u -> u^2, time_dependence=:autonomous)
        @test C(1) == 1
        @test_throws MethodError C([1])
        C = ControlConstraint((t, u) -> u^2, time_dependence=:nonautonomous)
        @test C(1, 1) == 1
        @test_throws MethodError C(1, [1])
        C = ControlConstraint(u -> u[1])
        @test C([1, 0]) == 1
        C = ControlConstraint((t, u) -> u[1], time_dependence=:nonautonomous)
        @test C(1, [1, 0]) == 1
        C = ControlConstraint(u -> [u[1], u[2]^2])
        @test C([1, 0]) == [1, 0]
        C = ControlConstraint((t, u) -> [u[1], u[2]^2], time_dependence=:nonautonomous)
        @test C(1, [1, 0]) == [1, 0]
    end
    @testset "Specific calls" begin
        C = ControlConstraint(u -> u^2, control_dimension=1, constraint_dimension=1)
        @test_throws MethodError C(_Time(0), 1)
        @test C(_Time(0), [1]) == [1]
        C = ControlConstraint(u -> u^2, control_dimension=1, constraint_dimension=1, time_dependence=:autonomous)
        @test_throws MethodError C(_Time(0), 1)
        @test C(_Time(0), [1]) == [1]
        C = ControlConstraint((t, u) -> u^2, control_dimension=1, constraint_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError C(_Time(1), 1)
        @test C(_Time(1), [1]) == [1]
        C = ControlConstraint(u -> u[1], control_dimension=2, constraint_dimension=1)
        @test C(_Time(0), [1, 0]) == [1]
        C = ControlConstraint((t, u) -> u[1], control_dimension=2, constraint_dimension=1, time_dependence=:nonautonomous)
        @test C(_Time(1), [1, 0]) == [1]
        C = ControlConstraint(u -> [u[1], u[2]^2], control_dimension=2, constraint_dimension=2)
        @test C(_Time(0), [1, 0]) == [1, 0]
        C = ControlConstraint((t, u) -> [u[1], u[2]^2], control_dimension=2, constraint_dimension=2, time_dependence=:nonautonomous)
        @test C(_Time(1), [1, 0]) == [1, 0]
        C = ControlConstraint(u -> [u, u^2], control_dimension=1, constraint_dimension=2)
        @test_throws MethodError C(_Time(0), 1)
        @test C(_Time(0), [1]) == [1, 1]
        C = ControlConstraint((t, u) -> [u, u^2], control_dimension=1, constraint_dimension=2, time_dependence=:nonautonomous)
        @test_throws MethodError C(_Time(1), 1)
        @test C(_Time(1), [1]) == [1, 1]
    end
end

@testset "MixedConstraint" begin
    @test_throws InconsistentArgument MixedConstraint((x, u) -> x, time_dependence=:dummy)
    @testset "Classical calls" begin
        M = MixedConstraint((x, u) -> x^2 + u^2)
        @test M(1, 1) == 2
        @test_throws MethodError M([1], [1])
        M = MixedConstraint((x, u) -> x^2 + u^2, time_dependence=:autonomous)
        @test M(1, 1) == 2
        @test_throws MethodError M([1], [1])
        M = MixedConstraint((t, x, u) -> x^2 + u^2, time_dependence=:nonautonomous)
        @test M(1, 1, 1) == 2
        @test_throws MethodError M(1, [1], [1])
        M = MixedConstraint((x, u) -> [x, u^2])
        @test M(1, 1) == [1, 1]
        M = MixedConstraint((t, x, u) -> [x, u^2], time_dependence=:nonautonomous)
        @test M(1, 1, 1) == [1, 1]
        M = MixedConstraint((x, u) -> [x, u^2])
        @test M(1, 1) == [1, 1]
        M = MixedConstraint((t, x, u) -> [x, u^2], time_dependence=:nonautonomous)
        @test M(1, 1, 1) == [1, 1]
    end
    @testset "Specific calls" begin
        M = MixedConstraint((x, u) -> x^2 + u^2, state_dimension=1, control_dimension=1, constraint_dimension=1)
        @test_throws MethodError M(_Time(0), 1, 1)
        @test M(_Time(0), [1], [1]) == [2]
        M = MixedConstraint((x, u) -> x^2 + u^2, state_dimension=1, control_dimension=1, constraint_dimension=1, time_dependence=:autonomous)
        @test_throws MethodError M(_Time(0), 1, 1)
        @test M(_Time(0), [1], [1]) == [2]
        M = MixedConstraint((t, x, u) -> x^2 + u^2, state_dimension=1, control_dimension=1, constraint_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError M(_Time(1), 1, 1)
        @test M(_Time(1), [1], [1]) == [2]

        M = MixedConstraint((x, u) -> [x, u^2], state_dimension=1, control_dimension=1, constraint_dimension=2)
        @test M(_Time(0), [1], [1]) == [1, 1]
        M = MixedConstraint((t, x, u) -> [x, u^2], state_dimension=1, control_dimension=1, constraint_dimension=2, time_dependence=:nonautonomous)
        @test M(_Time(1), [1], [1]) == [1, 1]

        M = MixedConstraint((x, u) -> [x[1], u^2], state_dimension=2, control_dimension=1, constraint_dimension=2)
        @test M(_Time(0), [1, 0], [1]) == [1, 1]
        M = MixedConstraint((t, x, u) -> [x[1], u^2], state_dimension=2, control_dimension=1, constraint_dimension=2, time_dependence=:nonautonomous)
        @test M(_Time(1), [1, 0], [1]) == [1, 1]

        M = MixedConstraint((x, u) -> [x, u[1]^2], state_dimension=1, control_dimension=2, constraint_dimension=2)
        @test M(_Time(0), [1], [1, 0]) == [1, 1]
        M = MixedConstraint((t, x, u) -> [x, u[1]^2], state_dimension=1, control_dimension=2, constraint_dimension=2, time_dependence=:nonautonomous)
        @test M(_Time(1), [1], [1, 0]) == [1, 1]

        M = MixedConstraint((x, u) -> [x[1], u[1]^2], state_dimension=2, control_dimension=2, constraint_dimension=2)
        @test M(_Time(0), [1, 0], [1, 0]) == [1, 1]
        M = MixedConstraint((t, x, u) -> [x[1], u[1]^2], state_dimension=2, control_dimension=2, constraint_dimension=2, time_dependence=:nonautonomous)
        @test M(_Time(1), [1, 0], [1, 0]) == [1, 1]

        M = MixedConstraint((x, u) -> u[1]^2, state_dimension=1, control_dimension=2, constraint_dimension=1)
        @test M(_Time(0), [1], [1, 0]) == [1]
        M = MixedConstraint((t, x, u) -> u[1]^2, state_dimension=1, control_dimension=2, constraint_dimension=1, time_dependence=:nonautonomous)
        @test M(_Time(1), [1], [1, 0]) == [1]

        M = MixedConstraint((x, u) -> x[1]^2+u, state_dimension=2, control_dimension=1, constraint_dimension=1)
        @test M(_Time(0), [1, 0], [1]) == [2]
        M = MixedConstraint((t, x, u) -> x[1]^2+u, state_dimension=2, control_dimension=1, constraint_dimension=1, time_dependence=:nonautonomous)
        @test M(_Time(1), [1, 0], [1]) == [2]

        M = MixedConstraint((x, u) -> x[1]^2+u[1], state_dimension=2, control_dimension=2, constraint_dimension=1)
        @test M(_Time(0), [1, 0], [1, 0]) == [2]
        M = MixedConstraint((t, x, u) -> x[1]^2+u[1], state_dimension=2, control_dimension=2, constraint_dimension=1, time_dependence=:nonautonomous)
        @test M(_Time(1), [1, 0], [1, 0]) == [2]

        M = MixedConstraint((x, u) -> [x, u[1]^2], state_dimension=1, control_dimension=2, constraint_dimension=2)
        @test M(_Time(0), [1], [1, 0]) == [1, 1]
        M = MixedConstraint((t, x, u) -> [x, u[1]^2], state_dimension=1, control_dimension=2, constraint_dimension=2, time_dependence=:nonautonomous)
        @test M(_Time(1), [1], [1, 0]) == [1, 1]
    end
end

@testset "FeedbackControl" begin
    @test_throws InconsistentArgument FeedbackControl(x -> x^2, time_dependence=:dummy)
    @testset "Classical calls" begin
        u = FeedbackControl(x -> x^2)
        @test u(1) == 1
        u = FeedbackControl((t, x) -> t+x^2, time_dependence=:nonautonomous)
        @test u(1, 1) == 2
        u = FeedbackControl(x -> [x^2, 2x])
        @test u(1) == [1, 2]
        u = FeedbackControl((t, x) -> [t+x^2, 2x], time_dependence=:nonautonomous)
        @test u(1, 1) == [2, 2]
        u = FeedbackControl(x -> [x[1]^2, 2x[2]])
        @test u([1, 0]) == [1, 0]
        u = FeedbackControl((t, x) -> [t+x[1]^2, 2x[2]], time_dependence=:nonautonomous)
        @test u(1, [1, 0]) == [2, 0]
        u = FeedbackControl(x -> x[1]^2 + 2x[2])
        @test u([1, 0]) == 1
        u = FeedbackControl((t, x) -> t+x[1]^2 + 2x[2], time_dependence=:nonautonomous)
    end
end

@testset "ControlLaw" begin
    @test_throws InconsistentArgument ControlLaw((x, p) -> x^2, time_dependence=:dummy)
    @testset "Classical calls" begin
        u = ControlLaw((x, p) -> x^2)
        @test u(1, 1) == 1
        u = ControlLaw((t, x, p) -> t+x^2, time_dependence=:nonautonomous)
        @test u(1, 1, 1) == 2
        u = ControlLaw((x, p) -> [x^2, 2x])
        @test u(1, 1) == [1, 2]
        u = ControlLaw((t, x, p) -> [t+x^2, 2x], time_dependence=:nonautonomous)
        @test u(1, 1, 1) == [2, 2]
        u = ControlLaw((x, p) -> [x[1]^2, 2x[2]])
        @test u([1, 0], 1) == [1, 0]
        u = ControlLaw((t, x, p) -> [t+x[1]^2, 2x[2]], time_dependence=:nonautonomous)
        @test u(1, [1, 0], 1) == [2, 0]
        u = ControlLaw((x, p) -> x[1]^2 + 2x[2])
        @test u([1, 0], 1) == 1
        u = ControlLaw((t, x, p) -> t+x[1]^2 + 2x[2], time_dependence=:nonautonomous)
        @test u(1, [1, 0], 1) == 2
    end
end

@testset "Multiplier" begin
    @test_throws InconsistentArgument Multiplier((x, p) -> x^2, time_dependence=:dummy)
    @testset "Classical calls" begin
        μ = Multiplier((x, p) -> x^2)
        @test μ(1, 1) == 1
        μ = Multiplier((t, x, p) -> t+x^2, time_dependence=:nonautonomous)
        @test μ(1, 1, 1) == 2
        μ = Multiplier((x, p) -> [x^2, 2x])
        @test μ(1, 1) == [1, 2]
        μ = Multiplier((t, x, p) -> [t+x^2, 2x], time_dependence=:nonautonomous)
        @test μ(1, 1, 1) == [2, 2]
        μ = Multiplier((x, p) -> [x[1]^2, 2x[2]])
        @test μ([1, 0], 1) == [1, 0]
        μ = Multiplier((t, x, p) -> [t+x[1]^2, 2x[2]], time_dependence=:nonautonomous)
        @test μ(1, [1, 0], 1) == [2, 0]
        μ = Multiplier((x, p) -> x[1]^2 + 2x[2])
        @test μ([1, 0], 1) == 1
        μ = Multiplier((t, x, p) -> t+x[1]^2 + 2x[2], time_dependence=:nonautonomous)
        @test μ(1, [1, 0], 1) == 2
    end
end

end
