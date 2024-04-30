"""
$(TYPEDSIGNATURES)

Initialization of the OCP solution that can be used when solving the discretized problem DOCP.

# Constructors:

- `OCPInit()`: default initialization
- `OCPInit(x_init, u_init, v_init)`: constant vector and/or function handles
- `OCPInit(sol)`: from existing solution

# Examples

```julia-repl
julia> init = OCPInit()
julia> init = OCPInit(x_init=[0.1, 0.2], u_init=0.3)
julia> init = OCPInit(x_init=[0.1, 0.2], u_init=0.3, v_init=0.5)
julia> init = OCPInit(x_init=[0.1, 0.2], u_init=t->sin(t), v_init=0.5)
julia> init = OCPInit(sol)
```

"""
mutable struct OCPInit

    state_init::Function
    control_init::Function
    variable_init::Union{Nothing, ctVector}
    costate_init::Function
    multipliers_init::Union{Nothing, ctVector}
    info::Symbol

#=
    +++add a third version that takes a single argument init ?

    if isnothing(init)
        init =  OCPInit()
    elseif init isa CTBase.OptimalControlSolution
        init = OCPInit(init)
    else
        x_init = :state    ∈ keys(init) ? init[:state]    : nothing
        u_init = :control  ∈ keys(init) ? init[:control]  : nothing
        v_init = :variable ∈ keys(init) ? init[:variable] : nothing
        init = OCPInit(state=x_init, control=u_init, variable=v_init)
    end
=#


    # constructor from constant vector or function handles
    function OCPInit(; state::Union{Nothing, ctVector, Function}=nothing, control::Union{Nothing, ctVector, Function}=nothing, variable::Union{Nothing, ctVector}=nothing, costate::Union{Nothing, ctVector, Function}=nothing, multipliers::Union{Nothing, ctVector}=nothing)

        init = new()
        init.info = :constant_or_function
        
        # use provided function or interpolate provided vector
        init.state_init = (state isa Function) ? t -> state(t) : t -> state
        init.control_init = (control isa Function) ? t -> control(t) : t -> control
        init.variable_init = variable
        
        init.costate_init = (costate isa Function) ? t -> costate(t) : t -> costate
        init.multipliers_init = multipliers

        return init
    end

    # constructor from existing solution
    function OCPInit(sol::OptimalControlSolution)

        init = new()
        init.info = :solution

        # Notes
        # - the possible internal state for Lagrange cost is not taken into account here
        # - set scalar format for dimension 1 case
        init.state_init    = t -> sol.state(t)
        init.control_init  = t -> sol.control(t)
        init.variable_init = sol.variable
        #+++ add costate and scalar multipliers

        return init
    end
end
