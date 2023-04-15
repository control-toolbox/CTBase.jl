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

#=
#
t = 1
x = 2
p = 3
u = 4
f(t, x, u) = t+x+u

#
H(t, x, p) = t + x^2+p^2

# VectorField
F(t, x) = t + x^2
F1 = VectorField{:nonautonomous}(F)
F2 = VectorField(x -> F(0.0, x))
@test F1(t, x) == 5
@test F2(t, x) == 4
Fs = VectorField{:nonautonomous, :scalar}(F)
@test Fs(t, [x]) isa Vector{<:ctNumber}
@test Fs(t, [x]) ≈ [5] atol=1e-6 # should return a vector
Fe = VectorField((x) -> [F(0, x)])
@test_throws IncorrectOutput Fe(t, [x])

# dim 2
Fd2 = VectorField(x -> x[1]^2+x[2]^2)
@test Fd2(t, [0, 1]) == 1

#
whoami(h::Hamiltonian) = 1
whoami(v::VectorField) = 2

@test whoami(F1) == 2

# LagrangeFunction
L(t, x, u) = t+x+u
L1 = LagrangeFunction{:nonautonomous}(L)
L2 = LagrangeFunction((x, u) -> L(0, x, u))
@test L1(t, x, u) == 7
@test L2(t, x, u) == 6
Ls = LagrangeFunction{:nonautonomous, :scalar}(L)
@test Ls(t, [x], [u]) == 7
Le = LagrangeFunction((x, u) -> [L(0, x, u)])
@test_throws IncorrectOutput Le(t, [x], [u])

# DynamicsFunction
F1 = DynamicsFunction{:nonautonomous}(f)
F2 = DynamicsFunction((x, u) -> f(0.0, x, u))
@test F1(t, x, u) == 7
@test F2(t, x, u) == 6
Fs = DynamicsFunction{:nonautonomous, :scalar}(f)
@test Fs(t, [x], [u]) ≈ [7] atol=1e-6
Fe = DynamicsFunction{:nonautonomous, :scalar}((t, x, u) -> [f(0, x, u)])
@test_throws IncorrectOutput Fe(t, [x], [u])

# dim 2
Fd2 = DynamicsFunction((x, u) -> [x[1]^2+x[2]^2, u])
@test Fd2(t, [0, 1], [1]) == [1, 1]

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