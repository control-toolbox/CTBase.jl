function test_functions()
#
t = 1
x = 2
p = 3
u = 4
f(t, x, u) = t+x+u

#
H(t, x, p) = t + x^2+p^2
@test_throws ErrorException Hamiltonian{:ttt, :scalar}(H) # :autonomous or :nonautonomous
@test_throws ErrorException Hamiltonian{:ttt}(H) # :autonomous or :nonautonomous
@test_throws ErrorException Hamiltonian{:autonomous, :ttt}(H) # :scalar or :vectorial

# boundary constraint
b(t0, x0, tf, xf) = (tf*xf) / (t0*x0) # scalar case
B1 = BoundaryConstraintFunction{:scalar}(b)
@test_throws ErrorException BoundaryConstraintFunction{:ttt}(b)
@test B1(1.0, 1.0, 1.0, 1.0) == 1.0 # call as b
@test B1(1.0, [1.0], 1.0, [1.0]) ≈ [1.0] atol=1e-6 # call as a BoundaryConstraintFunction
Be = BoundaryConstraintFunction{:scalar}((t0, x0, tf, xf) -> [b(t0, x0, tf, xf)])
@test_throws IncorrectOutput Be(1.0, [1.0], 1.0, [1.0]) # if output and usage are scalar, return a scalar 

# Mayer
g(t0, x0, tf, xf) = (tf*xf[1]) / (t0*x0[1])
G1 = MayerFunction{:vectorial}(g)
@test G1(1.0, [1.0], 1.0, [1.0]) ≈ 1.0 atol=1e-6
Ge = MayerFunction((t0, x0, tf, xf) -> [g(t0, x0, tf, xf)]) # default is :scalar
@test_throws IncorrectOutput Ge(1.0, [1.0], 1.0, [1.0])

# HamiltonianVectorField: the name is not important since here we have Hamiltonians
H1 = HamiltonianVectorField{:nonautonomous}(H)
H2 = HamiltonianVectorField((x, p) -> H(0.0, x, p))
@test H1(t, x, p) == 14
@test H2(t, x, p) == 13
Hs = HamiltonianVectorField{:nonautonomous, :scalar}(H)
@test Hs(t, [x], [p]) == 14

# dim 2
Hd2 = HamiltonianVectorField((x,p) -> x[1]^2+x[2]^2+p[1]^2+p[2]^2)
@test Hd2(t, [0, 1], [1, 0]) == 2

# Hamiltonian
H1 = Hamiltonian{:nonautonomous}(H)
H2 = Hamiltonian((x, p) -> H(0.0, x, p))
@test H1(t, x, p) == 14
@test H2(t, x, p) == 13
Hs = Hamiltonian{:nonautonomous, :scalar}(H)
@test Hs(t, [x], [p]) == 14
He = Hamiltonian((x, p) -> [H(0, x, p)])
@test_throws IncorrectOutput He(t, [x], [p])

Hvec = Hamiltonian((x, p) -> H(0, x[1], p[1]))
@test Hvec([x], [p]) == 13 # for basic usage, the input is a vector since otherwise
# it is considered as a time

# dim 2
Hd2 = Hamiltonian((x,p) -> x[1]^2+x[2]^2+p[1]^2+p[2]^2)
@test Hd2(t, [0, 1], [1, 0]) == 2

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
H3 = Hamiltonian{:nonautonomous}(myH)
@test H3(t, x, p) == 6

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