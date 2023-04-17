function test_functions()

#
_Time = CTBase._Time

# test BoundaryConstraint
@testset "BoundaryConstraint" begin
    @testset "Classical calls" begin
        B = BoundaryConstraint((t0, x0, tf, xf) -> xf - x0)
        @test B(0, 0, 1, 1) == 1
        @test B(0, [0], 1, [1]) == [1]
        B = BoundaryConstraint((t0, x0, tf, xf) -> [xf - x0, t0 - tf])
        @test B(0, 0, 1, 1) == [1, -1]
        @test_throws MethodError B(0, [0], 1, [1])
        B = BoundaryConstraint((t0, x0, tf, xf) -> tf - t0)
        @test B(0, [1, 0], 1, [0, 1]) == 1
        B = BoundaryConstraint((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]])
        @test B(0, [1, 0], 1, [1, 0]) == [1, 1]
    end
    @testset "Specific calls" begin
        B = BoundaryConstraint((t0, x0, tf, xf) -> xf - x0, state_dimension=1, constraint_dimension=1)
        @test_throws MethodError B(_Time(0), 0, _Time(1), 1)
        @test B(_Time(0), [0], _Time(1), [1]) == [1]
        B = BoundaryConstraint((t0, x0, tf, xf) -> [xf - x0, t0 - tf], state_dimension=1, constraint_dimension=2)
        @test_throws MethodError B(_Time(0), 0, _Time(1), 1)
        @test B(_Time(0), [0], _Time(1), [1]) == [1, -1]
        B = BoundaryConstraint((t0, x0, tf, xf) -> tf - t0, state_dimension=2, constraint_dimension=1)
        @test B(_Time(0), [1, 0], _Time(1), [0, 1]) == [1]
        B = BoundaryConstraint((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]], state_dimension=2, constraint_dimension=2)
        @test B(_Time(0), [1, 0], _Time(1), [1, 0]) == [1, 1]
    end
end

@testset "MayerObjective" begin
    @testset "Classical calls" begin
        G = MayerObjective((t0, x0, tf, xf) -> xf - x0)
        @test G(0, 0, 1, 1) == 1
        @test_throws MethodError G(0, [0], 1, [1])
        G = MayerObjective((t0, x0, tf, xf) -> tf - t0)
        @test G(0, [1, 0], 1, [0, 1]) == 1
    end
    @testset "Specific calls" begin
        G = MayerObjective((t0, x0, tf, xf) -> xf - x0, state_dimension=1)
        @test_throws MethodError G(_Time(0), 0, _Time(1), 1)
        @test G(_Time(0), [0], _Time(1), [1]) == 1
        G = MayerObjective((t0, x0, tf, xf) -> tf - t0, state_dimension=2)
        @test G(_Time(0), [1, 0], _Time(1), [0, 1]) == 1
    end
end

@testset "Hamiltonian" begin
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

@testset "LagrangeObjective" begin
    @testset "Classical calls" begin
        L = LagrangeObjective((x, u) -> x + u)
        @test L(1, 1) == 2
        @test_throws MethodError L([1], [1])
        L = LagrangeObjective((x, u) -> x + u, time_dependence=:autonomous)
        @test L(1, 1) == 2
        @test_throws MethodError L([1], [1])
        L = LagrangeObjective((t, x, u) -> x + u, time_dependence=:nonautonomous)
        @test L(1, 1, 1) == 2
        @test_throws MethodError L(1, [1], [1])
        L = LagrangeObjective((x, u) -> x[1]^2 + u^2) # or time_dependence=:autonomous
        @test L([1, 0], 1) == 2
        L = LagrangeObjective((x, u) -> x^2 + u[2]^2) # or time_dependence=:autonomous
        @test L(1, [0, 1]) == 2
        L = LagrangeObjective((x, u) -> x[1]^2 + u[2]^2) # or time_dependence=:autonomous
        @test L([1, 0], [0, 1]) == 2
        L = LagrangeObjective((t, x, u) -> t + x[1]^2 + u[2]^2, time_dependence=:nonautonomous)
        @test L(1, [1, 0], [0, 1]) == 3
    end
    @testset "Specific calls" begin
        L = LagrangeObjective((x, u) -> x + u, state_dimension=1, control_dimension=1)
        @test_throws MethodError L(_Time(0), 1, 1)
        @test L(_Time(0), [1], [1]) == 2
        L = LagrangeObjective((t, x, u) -> x + u, state_dimension=1, control_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError L(_Time(1), 1, 1)
        @test L(_Time(1), [1], [1]) == 2
        L = LagrangeObjective((x, u) -> x[1]^2 + u, state_dimension=2, control_dimension=1)
        @test_throws MethodError L(_Time(0), [1, 0], 1)
        @test L(_Time(0), [1, 0], [1]) == 2
        L = LagrangeObjective((t, x, u) -> t + x[1]^2 + u, state_dimension=2, control_dimension=1, time_dependence=:nonautonomous)
        @test_throws MethodError L(_Time(1), [1, 0], 1)
        @test L(_Time(1), [1, 0], [1]) == 3
        L = LagrangeObjective((x, u) -> x + u[1], state_dimension=1, control_dimension=2)
        @test_throws MethodError L(_Time(0), 1, [1, 0])
        @test L(_Time(0), [1], [1, 0]) == 2
        L = LagrangeObjective((t, x, u) -> t + x + u[1], state_dimension=1, control_dimension=2, time_dependence=:nonautonomous)
        @test_throws MethodError L(_Time(1), 1, [1, 0])
        @test L(_Time(1), [1], [1, 0]) == 3
        L = LagrangeObjective((x, u) -> x[1]^2 + u[1], state_dimension=2, control_dimension=2)
        @test L(_Time(0), [1, 0], [1, 0]) == 2
        L = LagrangeObjective((t, x, u) -> t + x[1]^2 + u[1], state_dimension=2, control_dimension=2, time_dependence=:nonautonomous)
        @test L(_Time(1), [1, 0], [1, 0]) == 3
    end
end

@testset "Dynamics" begin
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

#=
#
t = 1
x = 2
p = 3
u = 4
f(t, x, u) = t+x+u

#
H(t, x, p) = t + x^2+p^2

#
whoami(h::Hamiltonian) = 1
whoami(v::VectorField) = 2

@test whoami(F1) == 2

# constructor
makeH(f::Function, u::Function) = (t,x,p) -> f(t, x, u(t, x, p))
control(t, x, p) = p
myH = makeH(F1, control)

# StateConstraintFunction
f1 = StateConstraintFunction{:nonautonomous}((t, x) -> f(t, x, u))
f2 = StateConstraintFunction(x -> f(0.0, x, u))
@test f1(t, x) == 7
@test f2(t, x) == 6
fs = StateConstraintFunction{:nonautonomous, :scalar}((t, x) -> f(t, x, u))
@test fs(t, [x]) ≈ [7] atol=1e-6
fe = StateConstraintFunction{:nonautonomous, :scalar}((t, x) -> [f(t, x, u)])
@test_throws IncorrectOutput fe(t, [x])

# ControlConstraintFunction
f1 = ControlConstraintFunction{:nonautonomous}((t, u) -> f(t, x, u))
f2 = ControlConstraintFunction(u -> f(0.0, x, u))
@test f1(t, u) == 7
@test f2(t, u) == 6
fs = ControlConstraintFunction{:nonautonomous, :scalar}((t, u) -> f(t, x, u))
@test fs(t, [u]) ≈ [7] atol=1e-6
fe = ControlConstraintFunction{:nonautonomous, :scalar}((t, x) -> [f(t, x, u)])
@test_throws IncorrectOutput fe(t, [u])

# MixedConstraintFunction
f1 = MixedConstraintFunction{:nonautonomous}(f)
f2 = MixedConstraintFunction((x, u) -> f(0.0, x, u))
@test f1(t, x, u) == 7
@test f2(t, x, u) == 6
fs = MixedConstraintFunction{:nonautonomous, :scalar}(f)
@test fs(t, [x], [u]) ≈ [7] atol=1e-6
fe = MixedConstraintFunction{:nonautonomous, :scalar}((t, x, u) -> [f(t, x, u)])
@test_throws IncorrectOutput fe(t, [x], [u])

# ControlFunction
u1 = ControlFunction{:nonautonomous}(H)
u2 = ControlFunction((x, p) -> H(0.0, x, p))
@test u1(t, x, p) == 14
@test u2(t, x, p) == 13
us = ControlFunction{:nonautonomous, :scalar}(H)
@test us(t, [x], [p]) ≈ [14] atol=1e-6
ue = ControlFunction{:nonautonomous, :scalar}((t, x, p) -> [H(t, x, u)])
@test_throws IncorrectOutput ue(t, [x], [p])

# dim 2
ud2 = ControlFunction((x,p) -> x[1]^2+x[2]^2+p[1]^2+p[2]^2)
@test ud2(t, [0, 1], [1, 0]) == [2]

# MultiplierFunction
μ1 = MultiplierFunction{:nonautonomous}(H)
μ2 = MultiplierFunction((x, p) -> H(0.0, x, p))
@test μ1(t, x, p) == 14
@test μ2(t, x, p) == 13
μs = MultiplierFunction{:nonautonomous, :scalar}(H)
@test μs(t, [x], [p]) ≈ [14] atol=1e-6
μe = MultiplierFunction{:nonautonomous, :scalar}((t, x, p) -> [H(t, x, u)])
@test_throws IncorrectOutput μe(t, [x], [p])

# dim 2
μd2 = MultiplierFunction((x,p) -> x[1]^2+x[2]^2+p[1]^2+p[2]^2)
@test μd2(t, [0, 1], [1, 0]) == [2]
=#

end