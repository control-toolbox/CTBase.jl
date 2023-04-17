# test onepass

A = [ 0 1
      0 0 ]
B = [ 0
      1 ]

function test_onepass()

t0 = 0
o = @def1 t ∈ [ t0, t0 + 4 ], time
@test o.initial_time == t0
@test o.final_time == t0 + 4 
@test o.parsed.t == :t
@test o.parsed.t0 == :t0
@test o.parsed.tf == :(t0 + 4)

o = @def1 begin
    λ ∈ R^2, variable
    tf ∈ R, variable
end
@def1 o t ∈ [ 0, tf ], time
@test :λ ∈ keys(o.parsed.vars)
@test :tf ∈ keys(o.parsed.vars)
@test o.initial_time == 0
@test o.final_time == nothing

o = @def1 begin
    t0 ∈ R, variable
    end
@def1 o t ∈ [ t0, 1 ], time
@test :t0 ∈ keys(o.parsed.vars)
@test o.parsed.t0 == :t0
@test o.parsed.tf == 1
@test o.initial_time == nothing
@test o.final_time == 1

o = @def1 begin
    tf ∈ R, variable
    end
@def1 o t ∈ [ 0, tf ], time
@test :tf ∈ keys(o.parsed.vars)
@test o.parsed.t0 == t0
@test o.parsed.tf == :tf
@test o.initial_time == 0
@test o.final_time == nothing

@def1 o begin
    x ∈ R, state
    u ∈ R, control
    end
@test o.state_dimension == 1
@test o.control_dimension == 1
@test o.parsed.x == :x
@test o.parsed.u == :u

o = @def1 begin
    t ∈ [ 0, 1 ], time
    x ∈ R^3, state
    u ∈ R^2, control
    end
@test o.state_dimension == 3
@test o.control_dimension == 2

x = [ 1, 2, 3 ]; u = [ -1, 2 ]
@def1 o x'(t) == [ x[1](t) + 2u[2](t), 2x[3](t), x[1](t) + u[2](t) ]
@test o.dynamics(x, u) == [ x[1] + 2u[2], 2x[3], x[1] + u[2] ]

t0 = 0
tf = 1
o = @def1 begin
    t ∈ [ t0, tf ], time
    x ∈ R^2, state
    u ∈ R, control
    x(t0) == [ -1, 0 ] 
    x(tf) == [  0, 0 ] 
    x'(t) == A * x(t) + B * u(t) # debug: A and B declared in the global scope
    ∫( 0.5u(t)^2 ) → min
end
x = [ 1, 2 ]; u = -1 
@test o.dynamics(x, u) == A * x + B * u
@test o.lagrange(x, u) == 0.5u^2 
@test o.criterion == :min

@def1 o r = x[1]
@test o.parsed.aliases[:r] == :( x[1] )
# todo: TBC

end
