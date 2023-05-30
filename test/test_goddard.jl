test_goddard() = begin

# Parameters
Cd = 310
Tmax = 3.5
β = 500
b = 2
t0 = 0
r0 = 1
v0 = 0
vmax = 0.1
m0 = 1
mf = 0.6
x0 = [ r0, v0, m0 ]

# Abstract model
@def ocp begin

    tf, variable
    t ∈ [ t0, tf ], time
    x ∈ R³, state
    u ∈ R, control
    
    r = x₁
    v = x₂
    m = x₃
   
    x(t0) == [ r0, v0, m0 ]
    0  ≤ u(t) ≤ 1
    r(t) ≥ 0,            (1)
    0  ≤ v(t) ≤ vmax,    (2)
    mf ≤ m(t) ≤ m0,      (3)

    D = Cd * v² * exp(-β * (r - 1))

    ẋ(t) == [ v(t), -D(t)/m(t) - 1/r²(t), 0 ] + u(t) * [ 0, Tmax/m(t), -b * Tmax ]
 
    r(tf) → max
    
end

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β * (r - 1))
    F = [ v, -D/m - 1/r^2, 0 ]
    return F
end

F1(x) = begin
    r, v, m = x
    F = [ 0, Tmax/m, -b*Tmax ]
    return F
end

x = x0
u = 2
tf = 1
@test ocp.dynamics(x, u, tf) == F0(x) + u * F1(x)

end
