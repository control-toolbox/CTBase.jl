using CTBase
using Plots

layout = :split
size = (900, 600)
control_plt = :all

#
do_plot_2 = true

# ----------------------------------------
# SOL 1
n = 2
m = 1
t0 = 0.0
tf = 1.0
x0 = [-1.0, 0.0]
xf = [0.0, 0.0]
a = x0[1]
b = x0[2]
C = [
    -(tf - t0)^3/6.0 (tf - t0)^2/2.0
    -(tf - t0)^2/2.0 (tf-t0)
]
D = [-a - b * (tf - t0), -b] + xf
p0 = C \ D
α = p0[1]
β = p0[2]
x =
    t -> [
        a + b * (t - t0) + β * (t - t0)^2 / 2.0 - α * (t - t0)^3 / 6.0,
        b + β * (t - t0) - α * (t - t0)^2 / 2.0,
    ]
p = t -> [α, -α * (t - t0) + β]
u = t -> [p(t)[2]]
objective = 0.5 * (α^2 * (tf - t0)^3 / 3 + β^2 * (tf - t0) - α * β * (tf - t0)^2)
#
N = 201
times = range(t0, tf, N)
#

sol = OptimalControlSolution()
sol.state_dimension = n
sol.control_dimension = m
sol.time_grid = times
sol.time_name = "t"
sol.state = x
sol.state_name = "x"
sol.state_components_names = ["x" * ctindices(i) for i ∈ range(1, n)]
sol.costate = p
sol.control = u
sol.control_name = "u"
sol.control_components_names = ["u"]
sol.objective = objective
sol.iterations = 0
sol.stopping = :dummy
sol.message = "ceci est un test"
sol.success = true

#
plt = plot(
    sol,
    layout = layout,
    control = control_plt,
    size = size,
    flip = true,
    linewidth = 5,
    solution_label = "sol1",
)
#plot(sol, layout=:group)
#ps=plot(sol, :time, (:state, 1))
#plot!(ps, sol, :time, (:control, 1))

# ----------------------------------------
# SOL 2
n = 2
m = 1
t0 = 0.0
tf = 1.0
x0 = [-1.0, -1.0]
xf = [0.0, 0.0]
a = x0[1]
b = x0[2]
C = [
    -(tf - t0)^3/6.0 (tf - t0)^2/2.0
    -(tf - t0)^2/2.0 (tf-t0)
]
D = [-a - b * (tf - t0), -b] + xf
p0 = C \ D
α = p0[1]
β = p0[2]
x =
    t -> [
        a + b * (t - t0) + β * (t - t0)^2 / 2.0 - α * (t - t0)^3 / 6.0,
        b + β * (t - t0) - α * (t - t0)^2 / 2.0,
    ]
p = t -> [α, -α * (t - t0) + β]
u = t -> [p(t)[2]]
objective = 0.5 * (α^2 * (tf - t0)^3 / 3 + β^2 * (tf - t0) - α * β * (tf - t0)^2)
#
N = 201
times = range(t0, tf, N)
#

sol = OptimalControlSolution()
sol.state_dimension = n
sol.control_dimension = m
sol.time_grid = times
sol.time_name = "t"
sol.state = x
sol.state_name = "y"
sol.state_components_names = ["y" * ctindices(i) for i ∈ range(1, n)]
sol.costate = p
sol.control = u
sol.control_name = "v"
sol.control_components_names = ["v"]
sol.objective = objective
sol.iterations = 0
sol.stopping = :dummy
sol.message = "ceci est un test"
sol.success = true

if do_plot_2
    plot!(plt, sol, layout = layout, size = size, control = control_plt, solution_label = "sol2")
else
    plt
end

# ----------------------------------------
# Orbital transfer consumption
#=
n=4
m=2

x0 = [-42272.67, 0, 0, -5796.72]
μ      = 5.1658620912*1e12
rf     = 42165.0 ;
rf3    = rf^3  ;
m0     = 2000.0
F_max = 100.0
γ_max  = F_max*3600.0^2/(m0*10^3)
t0     = 0.0
α      = sqrt(μ/rf3);
β      = 0.0

tol    = 1e-9;

F_max_100  = 100.0

tf_min = 13.40318195708344 # minimal time for Fmax = 100 N
tf = 1.5*tf_min

Th(F) = F*3600.0^2/(10^3)
u_max = Th(F_max)

# the solution
x0 = [x0; 0]

u0(x,p) = [0, 0]
u1(x,p) = p[3:4]/norm(p[3:4])

Hc(x,p) = p[1]*x[3] + p[2]*x[4] + p[3]*(-μ*x[1]/norm(x[1:2])^3) + p[4]*(-μ*x[2]/norm(x[1:2])^3)
H(x,p,u) = -norm(u) + Hc(x,p) + u[1]*p[3]*γ_max + u[2]*p[4]*γ_max + p[5]*norm(u)
H0(x,p) = H(x,p,u0(x,p)) 
H1(x,p) = H(x,p,u1(x,p))

# Flow
f0 = Flow(Hamiltonian(H0));
f1 = Flow(Hamiltonian(H1));

# Initial guess
p0_guess = [0.02698412111231433, 0.006910835140705538, 0.050397371862031096, -0.0032972040120747836, -1.0076835239866583e-23]
ti_guess = [0.4556797711668658, 3.6289692721936913, 11.683607683450061, 12.505465498856514]
ξ_guess  = [p0_guess;ti_guess]

p0 = p0_guess
t1, t2, t3, t4 = ti_guess

# computing x, p, u
f = f1 * (t1, f0) * (t2, f1) * (t3, f0) * (t4, f1)
ode_sol  = f((t0, tf), x0, p0)

x = t -> ode_sol(t)[1:4]
p = t -> ode_sol(t)[6:9]
u = t -> [0,0]*(t ∈ Interval(t1,t2)∪Interval(t3,t4)) +
         p(t)[3:4]/norm(p(t)[3:4])*(t ∈ Interval(t0,t1)∪Interval(t2,t3)∪Interval(t4,tf))
objective = ode_sol(tf)[5]

#
N=201
times = range(t0, tf, N)
#
sol = OptimalControlSolution() #n, m, times, x, p, u)
sol.state_dimension = n
sol.control_dimension = m
sol.time_grid = times
sol.state = x
sol.state_name = "y"
sol.state_components_names = [ "x" * ctindices(1), "x" * ctindices(2), "v" * ctindices(1), "v" * ctindices(2)]
sol.adjoint = p
sol.control = u
sol.control_name = "u"
sol.control_components_names = [ "u" * ctindices(i) for i ∈ range(1, m)]
sol.objective = objective
sol.iterations = 0
sol.message = "structure: B+B0B+B0B+"
sol.success = true
sol.infos[:resolution] = :numerical

plt_transfert = plot(sol, layout=:split, size=(900, 600))
=#
