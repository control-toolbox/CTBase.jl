# Benchmarks for bench_nlp_constraints.jl

```julia
using BenchmarkTools
using CTBase
using MLStyle
rg(i::Integer, j::Integer) = begin
        if i == j
            i
        else
            i:j
        end
    end
$(Expr(:toplevel, :(ocp = Model()), :(time!(ocp, 0, 1)), :(state!(ocp, 2)), :(control!(ocp, 1))))
constraint!(ocp, :initial, Index(2), 10, :ci)
constraint!(ocp, :final, Index(1), 1, :cf)
constraint!(ocp, :control, 0, 1, :cu)
constraint!(ocp, :state, [0, 1], [1, 2], :cs)
constraint!(ocp, :boundary, ((x0, xf)->begin
            x0[2] + xf[2]
        end), 0, 1, :cb)
constraint!(ocp, :control, (u->begin
            u
        end), 0, 1, :cuu)
constraint!(ocp, :state, (x->begin
            x
        end), [0, 1], [1, 2], :css)
constraint!(ocp, :mixed, ((x, u)->begin
            x[1] + u
        end), 1, 1, :cm)
function nlp_constraints_original(ocp::OptimalControlModel)
    CTBase.__check_all_set(ocp)
    constraints = ocp.constraints
    ξf = Vector{ControlConstraint}()
    ξl = Vector{ctNumber}()
    ξu = Vector{ctNumber}()
    ηf = Vector{StateConstraint}()
    ηl = Vector{ctNumber}()
    ηu = Vector{ctNumber}()
    ψf = Vector{MixedConstraint}()
    ψl = Vector{ctNumber}()
    ψu = Vector{ctNumber}()
    ϕf = Vector{BoundaryConstraint}()
    ϕl = Vector{ctNumber}()
    ϕu = Vector{ctNumber}()
    θf = Vector{VariableConstraint}()
    θl = Vector{ctNumber}()
    θu = Vector{ctNumber}()
    uind = Vector{Int}()
    ul = Vector{ctNumber}()
    uu = Vector{ctNumber}()
    xind = Vector{Int}()
    xl = Vector{ctNumber}()
    xu = Vector{ctNumber}()
    vind = Vector{Int}()
    vl = Vector{ctNumber}()
    vu = Vector{ctNumber}()
    for (_, c) = constraints
        MLStyle.@match c begin
                (:initial, f::BoundaryConstraint, lb, ub) => begin
                        push!(ϕf, f)
                        append!(ϕl, lb)
                        append!(ϕu, ub)
                    end
                (:final, f::BoundaryConstraint, lb, ub) => begin
                        push!(ϕf, f)
                        append!(ϕl, lb)
                        append!(ϕu, ub)
                    end
                (:boundary, f::BoundaryConstraint, lb, ub) => begin
                        push!(ϕf, f)
                        append!(ϕl, lb)
                        append!(ϕu, ub)
                    end
                (:control, f::ControlConstraint, lb, ub) => begin
                        push!(ξf, f)
                        append!(ξl, lb)
                        append!(ξu, ub)
                    end
                (:control, rg, lb, ub) => begin
                        append!(uind, rg)
                        append!(ul, lb)
                        append!(uu, ub)
                    end
                (:state, f::StateConstraint, lb, ub) => begin
                        push!(ηf, f)
                        append!(ηl, lb)
                        append!(ηu, ub)
                    end
                (:state, rg, lb, ub) => begin
                        append!(xind, rg)
                        append!(xl, lb)
                        append!(xu, ub)
                    end
                (:mixed, f::MixedConstraint, lb, ub) => begin
                        push!(ψf, f)
                        append!(ψl, lb)
                        append!(ψu, ub)
                    end
                (:variable, f::VariableConstraint, lb, ub) => begin
                        push!(θf, f)
                        append!(θl, lb)
                        append!(θu, ub)
                    end
                (:variable, rg, lb, ub) => begin
                        append!(vind, rg)
                        append!(vl, lb)
                        append!(vu, ub)
                    end
                _ => error("Internal error")
            end
    end
    function ξ(t, u, v)
        val = Vector{ctNumber}()
        for i = 1:length(ξf)
            append!(val, (ξf[i])(t, u, v))
        end
        return val
    end
    function η(t, x, v)
        val = Vector{ctNumber}()
        for i = 1:length(ηf)
            append!(val, (ηf[i])(t, x, v))
        end
        return val
    end
    function ψ(t, x, u, v)
        val = Vector{ctNumber}()
        for i = 1:length(ψf)
            append!(val, (ψf[i])(t, x, u, v))
        end
        return val
    end
    function ϕ(x0, xf, v)
        val = Vector{ctNumber}()
        for i = 1:length(ϕf)
            append!(val, (ϕf[i])(x0, xf, v))
        end
        return val
    end
    function θ(v)
        val = Vector{ctNumber}()
        for i = 1:length(θf)
            append!(val, (θf[i])(v))
        end
        return val
    end
    return ((ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (θl, θ, θu), (ul, uind, uu), (xl, xind, xu), (vl, vind, vu))
end
function test_alloc_bad(ocp)
    function get_state(XU, i, n, m)
        return XU[rg((i - 1) * (n + m) + 1, (i - 1) * (n + m) + n)]
    end
    function get_control(XU, i, n, m)
        return XU[rg((i - 1) * (n + m) + n + 1, (i - 1) * (n + m) + n + m)]
    end
    function set_control_constraint!(C, i, ξ, nξ, nc)
        C[(i - 1) * nc + 1:(i - 1) * nc + nξ] = ξ
    end
    function set_state_constraint!(C, i, η, nη, nξ, nc)
        C[(i - 1) * nc + nξ + 1:(i - 1) * nc + nξ + nη] = η
    end
    function set_mixed_constraint!(C, i, ψ, nψ, nξ, nη, nc)
        C[(i - 1) * nc + nξ + nη + 1:(i - 1) * nc + nξ + nη + nψ] = ψ
    end
    ((ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (θl, θ, θu), (ul, uind, uu), (xl, xind, xu), (vl, vind, vu)) = nlp_constraints_original(ocp)
    v = Real[]
    n = 2
    m = 1
    N = 200
    times = LinRange(0, 1, N)
    XU = ones(N * (n + m))
    nξ = length(ξl)
    nη = length(ηl)
    nψ = length(ψl)
    nc = nξ + nη + nψ
    C = zeros(N * nc)
    for i = 1:N
        t = times[i]
        x = get_state(XU, i, n, m)
        u = get_control(XU, i, n, m)
        set_control_constraint!(C, i, ξ(t, u, v), nξ, nc)
        set_state_constraint!(C, i, η(t, x, v), nη, nξ, nc)
        set_mixed_constraint!(C, i, ψ(t, x, u, v), nψ, nξ, nη, nc)
    end
    nothing
end
function nlp_constraints_optimized(ocp::OptimalControlModel)
    CTBase.__check_all_set(ocp)
    constraints = ocp.constraints
    ξf = Vector{ControlConstraint}()
    ξl = Vector{ctNumber}()
    ξu = Vector{ctNumber}()
    ξn = Vector{Int}()
    ηf = Vector{StateConstraint}()
    ηl = Vector{ctNumber}()
    ηu = Vector{ctNumber}()
    ηn = Vector{Int}()
    ψf = Vector{MixedConstraint}()
    ψl = Vector{ctNumber}()
    ψu = Vector{ctNumber}()
    ψn = Vector{Int}()
    ϕf = Vector{BoundaryConstraint}()
    ϕl = Vector{ctNumber}()
    ϕu = Vector{ctNumber}()
    ϕn = Vector{Int}()
    θf = Vector{VariableConstraint}()
    θl = Vector{ctNumber}()
    θu = Vector{ctNumber}()
    θn = Vector{Int}()
    uind = Vector{Int}()
    ul = Vector{ctNumber}()
    uu = Vector{ctNumber}()
    xind = Vector{Int}()
    xl = Vector{ctNumber}()
    xu = Vector{ctNumber}()
    vind = Vector{Int}()
    vl = Vector{ctNumber}()
    vu = Vector{ctNumber}()
    for (_, c) = constraints
        MLStyle.@match c begin
                (:initial, f::BoundaryConstraint, lb, ub) => begin
                        append!(ϕn, length(lb))
                        push!(ϕf, f)
                        append!(ϕl, lb)
                        append!(ϕu, ub)
                    end
                (:final, f::BoundaryConstraint, lb, ub) => begin
                        append!(ϕn, length(lb))
                        push!(ϕf, f)
                        append!(ϕl, lb)
                        append!(ϕu, ub)
                    end
                (:boundary, f::BoundaryConstraint, lb, ub) => begin
                        append!(ϕn, length(lb))
                        push!(ϕf, f)
                        append!(ϕl, lb)
                        append!(ϕu, ub)
                    end
                (:control, f::ControlConstraint, lb, ub) => begin
                        append!(ξn, length(lb))
                        push!(ξf, f)
                        append!(ξl, lb)
                        append!(ξu, ub)
                    end
                (:control, rg, lb, ub) => begin
                        append!(uind, rg)
                        append!(ul, lb)
                        append!(uu, ub)
                    end
                (:state, f::StateConstraint, lb, ub) => begin
                        append!(ηn, length(lb))
                        push!(ηf, f)
                        append!(ηl, lb)
                        append!(ηu, ub)
                    end
                (:state, rg, lb, ub) => begin
                        append!(xind, rg)
                        append!(xl, lb)
                        append!(xu, ub)
                    end
                (:mixed, f::MixedConstraint, lb, ub) => begin
                        append!(ψn, length(lb))
                        push!(ψf, f)
                        append!(ψl, lb)
                        append!(ψu, ub)
                    end
                (:variable, f::VariableConstraint, lb, ub) => begin
                        append!(θn, length(lb))
                        push!(θf, f)
                        append!(θl, lb)
                        append!(θu, ub)
                    end
                (:variable, rg, lb, ub) => begin
                        append!(vind, rg)
                        append!(vl, lb)
                        append!(vu, ub)
                    end
                _ => error("Internal error")
            end
    end
    ξfn = length(ξf)
    ηfn = length(ηf)
    ψfn = length(ψf)
    ϕfn = length(ϕf)
    θfn = length(θf)
    function ξ!(val, t, u, v)
        offset = 0
        for i = 1:ξfn
            val[1 + offset:(ξn[i] + offset) - 1] = (ξf[i])(t, u, v)
            offset += ξn[i]
        end
        nothing
    end
    function η!(val, t, x, v)
        offset = 0
        for i = 1:ηfn
            val[1 + offset:(ηn[i] + offset) - 1] = (ηf[i])(t, x, v)
            offset += ηn[i]
        end
        nothing
    end
    function ψ!(val, t, x, u, v)
        offset = 0
        for i = 1:ψfn
            val[1 + offset:(ψn[i] + offset) - 1] = (ψf[i])(t, x, u, v)
            offset += ψn[i]
        end
        nothing
    end
    function ϕ!(val, x0, xf, v)
        offset = 0
        for i = 1:ϕfn
            val[1 + offset:(ϕn[i] + offset) - 1] = (ϕf[i])(x0, xf, v)
            offset += ϕn[i]
        end
        nothing
    end
    function θ!(val, v)
        offset = 0
        for i = 1:θfn
            val[1 + offset:(θn[i] + offset) - 1] = (θf[i])(v)
            offset += θn[i]
        end
        nothing
    end
    return ((ξl, ξ!, ξu), (ηl, η!, ηu), (ψl, ψ!, ψu), (ϕl, ϕ!, ϕu), (θl, θ!, θu), (uind, ul, uu), (xind, xl, xu), (vind, vl, vu))
end
function test_alloc_good(ocp)
    function get_state(XU, i, n, m)
        if n == 1
            return XU[(i - 1) * (n + m) + 1]
        else
            return @view(XU[rg((i - 1) * (n + m) + 1, (i - 1) * (n + m) + n)])
        end
    end
    function get_control(XU, i, n, m)
        if m == 1
            return XU[(i - 1) * (n + m) + n + 1]
        else
            return @view(XU[rg((i - 1) * (n + m) + n + 1, (i - 1) * (n + m) + n + m)])
        end
    end
    function set_control_constraint!(C, i, valξ, nξ, nc)
        C[(i - 1) * nc + 1:(i - 1) * nc + nξ] = valξ
    end
    function set_state_constraint!(C, i, valη, nη, nξ, nc)
        C[(i - 1) * nc + nξ + 1:(i - 1) * nc + nξ + nη] = valη
    end
    function set_mixed_constraint!(C, i, valψ, nψ, nξ, nη, nc)
        C[(i - 1) * nc + nξ + nη + 1:(i - 1) * nc + nξ + nη + nψ] = valψ
    end
    ((ξl, ξ!, ξu), (ηl, η!, ηu), (ψl, ψ!, ψu), (ϕl, ϕ!, ϕu), (θl, θ!, θu), (ul, uind, uu), (xl, xind, xu), (vl, vind, vu)) = nlp_constraints_optimized(ocp)
    v = Real[]
    n = 2
    m = 1
    N = 100
    times = LinRange(0, 1, N)
    XU = ones(N * (n + m))
    nξ = length(ξl)
    nη = length(ηl)
    nψ = length(ψl)
    nc = nξ + nη + nψ
    C = zeros(N * nc)
    valξ = zeros(nξ)
    valη = zeros(nη)
    valψ = zeros(nψ)
    for i = 1:N
        t = times[i]
        x = get_state(XU, i, n, m)
        u = get_control(XU, i, n, m)
        ξ!(valξ, t, u, v)
        η!(valη, t, x, v)
        ψ!(valψ, t, x, u, v)
        set_control_constraint!(C, i, valξ, nξ, nc)
        set_state_constraint!(C, i, valη, nη, nξ, nc)
        set_mixed_constraint!(C, i, valψ, nψ, nξ, nη, nc)
    end
    nothing
end
println("Allocations and times for good and bad code")
println()
println("good code")
t_good = @benchmark(test_alloc_good(ocp))
