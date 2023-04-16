# test onepass

function test_onepass()

t0 = 0
o = @def1 t ∈ [ t0, t0 + 4 ], time
@test o.initial_time == t0
@test o.final_time == t0 + 4 
@test o.parsed.t == :t

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
@test o.initial_time == nothing
@test o.final_time == 1

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
println("x = ", x) # debug
println("u = ", u) # debug
@test o.dynamics(x, u) == [ x[1] + 2u[2], 2x[3], x[1] + u[2] ]

@def1 o r = x[1]
@test o.parsed.aliases[:r] == :( x[1] )
# todo: TBC

end
