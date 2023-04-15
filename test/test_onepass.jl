# test onepass
function test_onepass()

t0 = 0

o = @def1 t ∈ [ t0, t0 + 4 ], time
@test o.initial_time == t0
@test o.final_time == t0 + 4 
@test o.parsed.t == :t

o = @def1 begin
    λ ∈ R^2,  variable
    tf ∈ R,  variable
end
@def1 o t ∈ [ 0, tf ], time
@test :λ ∈ keys(o.parsed.vars)
@test :tf ∈ keys(o.parsed.vars)
@test o.initial_time == 0
@test o.final_time == nothing

o = @def1 begin
    t0 ∈ R,  variable
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

@def1 o begin
    x ∈ R^3, state
    u ∈ R^2, control
end
@test o.state_dimension == 3
@test o.control_dimension == 2

end
