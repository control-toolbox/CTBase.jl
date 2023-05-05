function test_function()

@testset "BoundaryConstraint" begin
    @test_throws IncorrectArgument BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2], variable_dependence=:dummy)
    B = BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2], variable_dependence=:v_indep)
    @test B([0, 0], [1, 1]) == [1, 2]
    @test B([0, 0], [1, 1], []) == [1, 2]
    B = BoundaryConstraint((x0, xf, v) -> [v[3]+xf[2]-x0[1], v[1]-v[2]+2xf[1]+x0[2]^2], variable_dependence=:v_dep)
    @test B([0, 0], [1, 1], [1, 2, 3]) == [4, 1]
end

@testset "Mayer" begin
    @test_throws IncorrectArgument Mayer((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2], variable_dependence=:dummy)
    G = Mayer((x0, xf) -> [xf[2]-x0[1]], variable_dependence=:v_indep)
    @test_throws MethodError G([0, 0], [1, 1])
    G = Mayer((x0, xf) -> xf[2]-x0[1], variable_dependence=:v_indep)
    @test G([0, 0], [1, 1]) == 1
    @test G([0, 0], [1, 1], []) == 1
    G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], variable_dependence=:v_dep)
    @test G([0, 0], [1, 1], [1, 2, 3]) == 4
end

@testset "Hamiltonian" begin
    @test_throws IncorrectArgument Hamiltonian((x, p) -> x + p, time_dependence=:dummy)
    @test_throws IncorrectArgument Hamiltonian((x, p) -> x + p, variable_dependence=:dummy)
    H = Hamiltonian((x, p) -> [x[1]^2+2p[2]], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test_throws MethodError H([1, 0], [0, 1])
    H = Hamiltonian((x, p) -> x[1]^2+2p[2], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test H([1, 0], [0, 1]) == 3
    t = 1
    v = []
    @test_throws MethodError H(t, [1, 0], [0, 1])
    @test_throws MethodError H([1, 0], [0, 1], v)
    @test H(t, [1, 0], [0, 1], v) == 3
    H = Hamiltonian((x, p, v) -> x[1]^2+2p[2]+v[3], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test H([1, 0], [0, 1], [1, 2, 3]) == 6
    @test H(t, [1, 0], [0, 1], [1, 2, 3]) == 6
    H = Hamiltonian((t, x, p) -> t+x[1]^2+2p[2], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test H(1, [1, 0], [0, 1]) == 4
    @test H(1, [1, 0], [0, 1], v) == 4
    H = Hamiltonian((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test H(1, [1, 0], [0, 1], [1, 2, 3]) == 7
end

@testset "HamiltonianVectorField" begin
    @test_throws IncorrectArgument HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2], time_dependence=:dummy)
    @test_throws IncorrectArgument HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2], variable_dependence=:dummy)
    Hv = HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test Hv([1, 0], [0, 1]) == [3, -3]
    t = 1
    v = []
    @test_throws MethodError Hv(t, [1, 0], [0, 1])
    @test_throws MethodError Hv([1, 0], [0, 1], v)
    @test Hv(t, [1, 0], [0, 1], v) == [3, -3]
    Hv = HamiltonianVectorField((x, p, v) -> [x[1]^2+2p[2]+v[3], x[2]-3p[2]^2], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test Hv([1, 0], [0, 1], [1, 2, 3]) == [6, -3]
    @test Hv(t, [1, 0], [0, 1], [1, 2, 3]) == [6, -3]
    Hv = HamiltonianVectorField((t, x, p) -> [t+x[1]^2+2p[2], x[2]-3p[2]^2], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test Hv(1, [1, 0], [0, 1]) == [4, -3]
    @test Hv(1, [1, 0], [0, 1], v) == [4, -3]
    Hv = HamiltonianVectorField((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3], x[2]-3p[2]^2], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test Hv(1, [1, 0], [0, 1], [1, 2, 3]) == [7, -3]
end

@testset "VectorField" begin
    @test_throws IncorrectArgument VectorField(x -> [x[1]^2, 2x[2]], time_dependence=:dummy)
    @test_throws IncorrectArgument VectorField(x -> [x[1]^2, 2x[2]], variable_dependence=:dummy)
    V = VectorField(x -> [x[1]^2, 2x[2]], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test V([1, -1]) == [1, -2]
    t = 1
    v = []
    @test_throws MethodError V(t, [1, -1])
    @test_throws MethodError V([1, -1], v)
    @test V(t, [1, -1], v) == [1, -2]
    V = VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test V([1, -1], [1, 2, 3]) == [1, 1]
    @test V(t, [1, -1], [1, 2, 3]) == [1, 1]
    V = VectorField((t, x) -> [t+x[1]^2, 2x[2]], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test V(1, [1, -1]) == [2, -2]
    @test V(1, [1, -1], v) == [2, -2]
    V = VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test V(1, [1, -1], [1, 2, 3]) == [2, 1]
end

@testset "Lagrange" begin
    @test_throws IncorrectArgument Lagrange((x, u) -> 2x[2]-u[1]^2, time_dependence=:dummy)
    @test_throws IncorrectArgument Lagrange((x, u) -> 2x[2]-u[1]^2, variable_dependence=:dummy)
    L = Lagrange((x, u) -> [2x[2]-u[1]^2], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test_throws MethodError L([1, 0], [1])
    L = Lagrange((x, u) -> 2x[2]-u[1]^2, time_dependence=:t_indep, variable_dependence=:v_indep)
    @test L([1, 0], [1]) == -1
    t = 1
    v = []
    @test_throws MethodError L(t, [1, 0], [1])
    @test_throws MethodError L([1, 0], [1], v)
    @test L(t, [1, 0], [1], v) == -1
    L = Lagrange((x, u, v) -> 2x[2]-u[1]^2+v[3], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test L([1, 0], [1], [1, 2, 3]) == 2
    @test L(t, [1, 0], [1], [1, 2, 3]) == 2
    L = Lagrange((t, x, u) -> t+2x[2]-u[1]^2, time_dependence=:t_dep, variable_dependence=:v_indep)
    @test L(1, [1, 0], [1]) == 0
    @test L(1, [1, 0], [1], v) == 0
    L = Lagrange((t, x, u, v) -> t+2x[2]-u[1]^2+v[3], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test L(1, [1, 0], [1], [1, 2, 3]) == 3
end

@testset "Dynamics" begin
    # Similar to Lagrange, but the function Dynamics is assumed to return a vector of the same dimension as the state x.
    # dim x = 2, dim u = 1
    # when a dim is 1, consider the element as a scalar
    @test_throws IncorrectArgument Dynamics((x, u) -> [2x[2]-u^2, x[1]], time_dependence=:dummy)
    @test_throws IncorrectArgument Dynamics((x, u) -> [2x[2]-u^2, x[1]], variable_dependence=:dummy)
    D = Dynamics((x, u) -> [2x[2]-u^2, x[1]], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test D([1, 0], 1) == [-1, 1]
    t = 1
    v = []
    @test_throws MethodError D(t, [1, 0], 1)
    @test_throws MethodError D([1, 0], 1, v)
    @test D(t, [1, 0], 1, v) == [-1, 1]
    D = Dynamics((x, u, v) -> [2x[2]-u^2+v[3], x[1]], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test D([1, 0], 1, [1, 2, 3]) == [2, 1]
    @test D(t, [1, 0], 1, [1, 2, 3]) == [2, 1]
    D = Dynamics((t, x, u) -> [t+2x[2]-u^2, x[1]], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test D(1, [1, 0], 1) == [0, 1]
    @test D(1, [1, 0], 1, v) == [0, 1]
    D = Dynamics((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test D(1, [1, 0], 1, [1, 2, 3]) == [3, 1]
end

@testset "StateConstraint" begin
    # Similar to `VectorField` in the usage, but the dimension of the output of the function StateConstraint is arbitrary.
    # dim x = 2
    @test_throws IncorrectArgument StateConstraint(x -> [x[1]^2, 2x[2]], time_dependence=:dummy)
    @test_throws IncorrectArgument StateConstraint(x -> [x[1]^2, 2x[2]], variable_dependence=:dummy)
    S = StateConstraint(x -> [x[1]^2, 2x[2]], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test S([1, -1]) == [1, -2]
    t = 1
    v = []
    @test_throws MethodError S(t, [1, -1])
    @test_throws MethodError S([1, -1], v)
    @test S(t, [1, -1], v) == [1, -2]
    S = StateConstraint((x, v) -> [x[1]^2, 2x[2]+v[3]], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test S([1, -1], [1, 2, 3]) == [1, 1]
    @test S(t, [1, -1], [1, 2, 3]) == [1, 1]
    S = StateConstraint((t, x) -> [t+x[1]^2, 2x[2]], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test S(1, [1, -1]) == [2, -2]
    @test S(1, [1, -1], v) == [2, -2]
    S = StateConstraint((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test S(1, [1, -1], [1, 2, 3]) == [2, 1]
end

@testset "ControlConstraint" begin
    # Similar to `VectorField` in the usage, but the dimension of the output of the function ControlConstraint is arbitrary.
    # dim u = 2
    @test_throws IncorrectArgument ControlConstraint(u -> [u[1]^2, 2u[2]], time_dependence=:dummy)
    @test_throws IncorrectArgument ControlConstraint(u -> [u[1]^2, 2u[2]], variable_dependence=:dummy)
    C = ControlConstraint(u -> [u[1]^2, 2u[2]], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test C([1, -1]) == [1, -2]
    t = 1
    v = []
    @test_throws MethodError C(t, [1, -1])
    @test_throws MethodError C([1, -1], v)
    @test C(t, [1, -1], v) == [1, -2]
    C = ControlConstraint((u, v) -> [u[1]^2, 2u[2]+v[3]], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test C([1, -1], [1, 2, 3]) == [1, 1]
    @test C(t, [1, -1], [1, 2, 3]) == [1, 1]
    C = ControlConstraint((t, u) -> [t+u[1]^2, 2u[2]], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test C(1, [1, -1]) == [2, -2]
    @test C(1, [1, -1], v) == [2, -2]
    C = ControlConstraint((t, u, v) -> [t+u[1]^2, 2u[2]+v[3]], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test C(1, [1, -1], [1, 2, 3]) == [2, 1]
end

@testset "MixedConstraint" begin
    # Similar to `Lagrange` in the usage, but the dimension of the output of the function MixedConstraint is arbitrary.
    # dim x = 2, dim u = 1, dim output = 2
    @test_throws IncorrectArgument MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], time_dependence=:dummy)
    @test_throws IncorrectArgument MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], variable_dependence=:dummy)
    M = MixedConstraint((x, u) -> [2x[2]-u^2, x[1]], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test M([1, 0], 1) == [-1, 1]
    t = 1
    v = []
    @test_throws MethodError M(t, [1, 0], 1)
    @test_throws MethodError M([1, 0], 1, v)
    @test M(t, [1, 0], 1, v) == [-1, 1]
    M = MixedConstraint((x, u, v) -> [2x[2]-u^2+v[3], x[1]], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test M([1, 0], 1, [1, 2, 3]) == [2, 1]
    @test M(t, [1, 0], 1, [1, 2, 3]) == [2, 1]
    M = MixedConstraint((t, x, u) -> [t+2x[2]-u^2, x[1]], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test M(1, [1, 0], 1) == [0, 1]
    @test M(1, [1, 0], 1, v) == [0, 1]
    M = MixedConstraint((t, x, u, v) -> [t+2x[2]-u^2+v[3], x[1]], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test M(1, [1, 0], 1, [1, 2, 3]) == [3, 1]
end

@testset "VariableConstraint" begin
    V = VariableConstraint(v -> [v[1]^2, 2v[2]])
    @test V([1, -1]) == [1, -2]
end

@testset "FeedbackControl" begin
    # Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.
    # dim x = 2, dim output = 1
    @test_throws IncorrectArgument FeedbackControl(x -> x[1]^2+2x[2], time_dependence=:dummy)
    @test_throws IncorrectArgument FeedbackControl(x -> x[1]^2+2x[2], variable_dependence=:dummy)
    u = FeedbackControl(x -> x[1]^2+2x[2], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test u([1, 0]) == 1
    t = 1
    v = []
    @test_throws MethodError u(t, [1, 0])
    @test_throws MethodError u([1, 0], v)
    @test u(t, [1, 0], v) == 1
    u = FeedbackControl((x, v) -> x[1]^2+2x[2]+v[3], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test u([1, 0], [1, 2, 3]) == 4
    @test u(t, [1, 0], [1, 2, 3]) == 4
    u = FeedbackControl((t, x) -> t+x[1]^2+2x[2], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test u(1, [1, 0]) == 2
    @test u(1, [1, 0], v) == 2
    u = FeedbackControl((t, x, v) -> t+x[1]^2+2x[2]+v[3], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test u(1, [1, 0], [1, 2, 3]) == 5
end


@testset "ControlLaw" begin
    # Similar to `Hamiltonian` in the usage, but the dimension of the output of the function `ControlLaw` is arbitrary.
    # dim x = 2, dim p =2, dim output = 1
    @test_throws IncorrectArgument ControlLaw((x, p) -> x[1]^2+2p[2], time_dependence=:dummy)
    @test_throws IncorrectArgument ControlLaw((x, p) -> x[1]^2+2p[2], variable_dependence=:dummy)
    u = ControlLaw((x, p) -> x[1]^2+2p[2], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test u([1, 0], [0, 1]) == 3
    t = 1
    v = []
    @test_throws MethodError u(t, [1, 0], [0, 1])
    @test_throws MethodError u([1, 0], [0, 1], v)
    @test u(t, [1, 0], [0, 1], v) == 3
    u = ControlLaw((x, p, v) -> x[1]^2+2p[2]+v[3], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test u([1, 0], [0, 1], [1, 2, 3]) == 6
    @test u(t, [1, 0], [0, 1], [1, 2, 3]) == 6
    u = ControlLaw((t, x, p) -> t+x[1]^2+2p[2], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test u(1, [1, 0], [0, 1]) == 4
    @test u(1, [1, 0], [0, 1], v) == 4
    u = ControlLaw((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test u(1, [1, 0], [0, 1], [1, 2, 3]) == 7
end

@testset "Multiplier" begin
    # Similar to `ControlLaw` in the usage.
    # dim x = 2, dim p =2, dim output = 1
    @test_throws IncorrectArgument Multiplier((x, p) -> x[1]^2+2p[2], time_dependence=:dummy)
    @test_throws IncorrectArgument Multiplier((x, p) -> x[1]^2+2p[2], variable_dependence=:dummy)
    μ = Multiplier((x, p) -> x[1]^2+2p[2], time_dependence=:t_indep, variable_dependence=:v_indep)
    @test μ([1, 0], [0, 1]) == 3
    t = 1
    v = []
    @test_throws MethodError μ(t, [1, 0], [0, 1])
    @test_throws MethodError μ([1, 0], [0, 1], v)
    @test μ(t, [1, 0], [0, 1], v) == 3
    μ = Multiplier((x, p, v) -> x[1]^2+2p[2]+v[3], time_dependence=:t_indep, variable_dependence=:v_dep)
    @test μ([1, 0], [0, 1], [1, 2, 3]) == 6
    @test μ(t, [1, 0], [0, 1], [1, 2, 3]) == 6
    μ = Multiplier((t, x, p) -> t+x[1]^2+2p[2], time_dependence=:t_dep, variable_dependence=:v_indep)
    @test μ(1, [1, 0], [0, 1]) == 4
    @test μ(1, [1, 0], [0, 1], v) == 4
    μ = Multiplier((t, x, p, v) -> t+x[1]^2+2p[2]+v[3], time_dependence=:t_dep, variable_dependence=:v_dep)
    @test μ(1, [1, 0], [0, 1], [1, 2, 3]) == 7
end

end
