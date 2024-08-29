# using OptimalControl

# @def ocp begin

#     t ∈ [ 0, 1 ], time
#     x ∈ R, state
#     u ∈ R, control
#     x(0) == 0
#     -1 ≤ u(t) ≤ 1
#     ẋ(t) == -x(t) + u(t)
#     x(1) → min

# end

# sol = solve(ocp, grid_size=20, print_level=5)
# plt = plot(sol)

# a la main
using CTBase
using PlotUtils

n = 1
m = 1
t0 = 0
tf = 1
x0 = 0
x = t -> -1 + 1e-8 * rand()
p = t -> 0 + 1e-8 * rand()
u = t -> 0
objective = 1
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
sol.state_components_names = ["x"]
sol.costate = p
sol.control = u
sol.control_name = "u"
sol.control_components_names = ["u"]
sol.objective = objective
sol.iterations = 0
sol.stopping = :dummy
sol.message = "ceci est un test"
sol.success = true

plt = plot(sol)
