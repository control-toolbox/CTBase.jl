using OptimalControl: solve
using CTBase

tf = 2.0

@def ocp begin
    t ∈ [0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(tf) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end

sol = solve(ocp; display=false)

@def ocp begin
    t ∈ [0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-0.5, -0.5]
    x(tf) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end

sol2 = solve(ocp; display=false)

# first plot
plt = plot(sol; size=(700, 450), time=:default)

# second plot
style = (linestyle=:dash,)
plot!(plt, sol2; time=:default, state_style=style, costate_style=style, control_style=style)
