function test_functions()

# pour le model, demander à avoir les dimensions 
# cas où ne donne pas les dimensions : user doit être cohérent
# passer les dimensions en arguments nommés au lieu de paramètres
# => pas besoin alors de tester les exceptions car fonctions non existantes

# test BoundaryConstraintFunction
@testset "BoundaryConstraintFunction" begin
    B = BoundaryConstraintFunction((t0, x0, tf, xf) -> xf - x0, state_dimension = 1, constraint_dimension = 1)
    @test B(0, 0, 1, 1) == 1 # classical call 
    @test B(0, [0], 1, [1]) == [1] # call as a BoundaryConstraintFunction
    B = BoundaryConstraintFunction((t0, x0, tf, xf) -> [xf - x0, t0 - tf], state_dimension = 1, constraint_dimension = 2)
    @test B(0, 0, 1, 1) == [1, -1] # classical call
    @test B(0, [0], 1, [1]) == [1, -1] # call as a BoundaryConstraintFunction
    B = BoundaryConstraintFunction((t0, x0, tf, xf) -> tf - t0, state_dimension = 2, constraint_dimension = 1)
    @test B(0, [1, 0], 1, [0, 1]) == [1] # call as a BoundaryConstraintFunction
    B = BoundaryConstraintFunction((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]], state_dimension = 2, constraint_dimension = 2)
    @test B(0, [1, 0], 1, [1, 0]) == [1, 1] # call as a BoundaryConstraintFunction
    B = BoundaryConstraintFunction((t0, x0, tf, xf) -> xf - x0)
    @test B(0, 0, 1, 1) == 1
    B = BoundaryConstraintFunction((t0, x0, tf, xf) -> [xf - x0, t0 - tf])
    @test B(0, 0, 1, 1) == [1, -1]
    B = BoundaryConstraintFunction((t0, x0, tf, xf) -> xf[2] - x0[1])
    @test B(0, [1, 0], 1, [0, 1]) == 0
end

@testset "MayerFunction" begin
    G = MayerFunction{1}((t0, x0, tf, xf) -> xf - x0)
    @test G(0, 0, 1, 1) == 1 # classical call
    @test G(0, [0], 1, [1]) == 1 # call as a MayerFunction
    G = MayerFunction{2}((t0, x0, tf, xf) -> xf[2] - x0[1])
    @test G(0, [1, 0], 1, [0, 1]) == 0 # call as a MayerFunction
    @test_throws ErrorException MayerFunction{:dum}((t0, x0, tf, xf) -> xf - x0)
end

@testset "Hamiltonian" begin
    H = Hamiltonian{:autonomous, 1}((x, p) -> p^2/2 - x)
    @test H(0, 1) == 0.5 # classical call
    @test H(0, [0], [1]) == 0.5 # call as a Hamiltonian
    H = Hamiltonian{:nonautonomous, 1}((t, x, p) -> t + p^2/2 - x)
    @test H(1, 0, 1) == 1.5 # classical call
    @test H(1, [0], [1]) == 1.5 # call as a Hamiltonian
    H = Hamiltonian{:autonomous, 2}((x, p) -> p[1]^2/2 - x[1] + p[2]^2/2 - x[2])
    @test H([0, 0], [1, 1]) == 1 # call as a Hamiltonian
    H = Hamiltonian{:nonautonomous, 2}((t, x, p) -> t + p[1]^2/2 - x[1] + p[2]^2/2 - x[2])
    @test H(1, [0, 0], [1, 1]) == 2 # call as a Hamiltonian
    @test_throws ErrorException Hamiltonian{1111, 1}((x, p) -> p^2/2 - x)
    @test_throws ErrorException Hamiltonian{:autonomous, :dum}((x, p) -> p^2/2 - x)
end

@testset "HamiltonianVectorField" begin
    Hv = HamiltonianVectorField{:autonomous, 1}((x, p) -> [p^2/2 - x, p^2/2 + x])
    @test Hv(0, 1) == [0.5, 0.5] # classical call
    @test Hv(0, [0], [1]) == [0.5, 0.5] # call as a HamiltonianVectorField
    Hv = HamiltonianVectorField{:nonautonomous, 1}((t, x, p) -> [t + p^2/2 - x, t + p^2/2 + x])
    @test Hv(1, 0, 1) == [1.5, 1.5] # classical call
    @test Hv(1, [0], [1]) == [1.5, 1.5] # call as a HamiltonianVectorField
    Hv = HamiltonianVectorField{:autonomous, 2}((x, p) -> [p[1]^2/2 - x[1] + p[2]^2/2 - x[2], p[1]^2/2 + x[1] + p[2]^2/2 + x[2]])
    @test Hv([0, 0], [1, 1]) == [1, 1] # call as a HamiltonianVectorField
    Hv = HamiltonianVectorField{:nonautonomous, 2}((t, x, p) -> [t + p[1]^2/2 - x[1] + p[2]^2/2 - x[2], t + p[1]^2/2 + x[1] + p[2]^2/2 + x[2]])
    @test Hv(1, [0, 0], [1, 1]) == [2, 2] # call as a HamiltonianVectorField
    @test_throws ErrorException HamiltonianVectorField{1111, 1}((x, p) -> [p^2/2 - x, p^2/2 + x])
    @test_throws ErrorException HamiltonianVectorField{:autonomous, :dum}((x, p) -> [p^2/2 - x, p^2/2 + x])
end



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
@test Fs(t, [x]) isa Vector{<:MyNumber}
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

end