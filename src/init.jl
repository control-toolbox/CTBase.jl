"""
$(TYPEDSIGNATURES)

Initialization of the OCP solution that can be used when solving the discretized problem DOCP.

# Constructors:

- `OptimalControlInit()`: default initialization
- `OptimalControlInit(x_init, u_init, v_init)`: constant vector and/or function handles
- `OptimalControlInit(sol)`: from existing solution

# Examples

```julia-repl
julia> init = OptimalControlInit()
julia> init = OptimalControlInit(x_init=[0.1, 0.2], u_init=0.3)
julia> init = OptimalControlInit(x_init=[0.1, 0.2], u_init=0.3, v_init=0.5)
julia> init = OptimalControlInit(x_init=[0.1, 0.2], u_init=t->sin(t), v_init=0.5)
julia> init = OptimalControlInit(sol)
```

"""
mutable struct OptimalControlInit

    state_init::Function
    control_init::Function
    variable_init::Union{Nothing, ctVector}
    costate_init::Function
    multipliers_init::Union{Nothing, ctVector}
    info::Symbol

    # warm start from solution
    function OptimalControlInit(sol::OptimalControlSolution)

        init = new()
        init.info = :from_solution
        init.state_init    = t -> sol.state(t)
        init.control_init  = t -> sol.control(t)
        init.variable_init = sol.variable
        #+++ add costate and scalar multipliers

        return init
    end

    # constant / functional init with explicit arguments
    function OptimalControlInit(; state::Union{Nothing, ctVector, Function}=nothing, control::Union{Nothing, ctVector, Function}=nothing, variable::Union{Nothing, ctVector}=nothing)
        
        init = new()
        init.info = :constant_or_function
        init.state_init = (state isa Function) ? t -> state(t) : t -> state
        init.control_init = (control isa Function) ? t -> control(t) : t -> control
        init.variable_init = variable
        #+++ add costate and scalar multipliers
        
        return init
    end

    # version with arguments as collection/iterable
    # (may be fused with version above ?)
    function OptimalControlInit(init)

        x_init = :state    ∈ keys(init) ? init[:state]    : nothing
        u_init = :control  ∈ keys(init) ? init[:control]  : nothing
        v_init = :variable ∈ keys(init) ? init[:variable] : nothing
        return OptimalControlInit(state=x_init, control=u_init, variable=v_init)
    
    end

    # trivial version that just returns its argument
    # used for unified syntax in caller functions
    function OptimalControlInit(init::OptimalControlInit)
        return init
    end

end
