"""
$(TYPEDSIGNATURES)

Check if actual dimension is equal to target dimension, error otherwise
"""
function checkDim(actual_dim, target_dim)
    if !isnothing(target_dim) && actual_dim != target_dim
        error("Init dimension mismatch: got ",actual_dim," instead of ",target_dim )
    end
end

"""
$(TYPEDSIGNATURES)

Return true if argument is a vector of vectors
"""
function isaVectVect(data)
    return (data isa Vector) && (data[1] isa ctVector)
end

"""
$(TYPEDSIGNATURES)

Convert matrix to vector of vectors (could be expanded)
"""
function formatData(data)
    if data isa Matrix
        return matrix2vec(data,1)
    else
        return data
    end
end

"""
$(TYPEDSIGNATURES)

Convert matrix time-grid to vector
"""
function formatTimeGrid(time)
    if isnothing(time)
        return nothing
    elseif time isa ctVector
        return time
    else
        return vec(time)
    end
end

"""
$(TYPEDSIGNATURES)

Build functional initialization: default case
"""
function buildFunctionalInit(data::Nothing, time, dim)
    # fallback to method-dependent default initialization
    return t-> nothing
end

"""
$(TYPEDSIGNATURES)

Build functional initialization: function case
"""
function buildFunctionalInit(data::Function, time, dim)
    # functional initialization
    checkDim(length(data(0)),dim)
    return t -> data(t)
end

"""
$(TYPEDSIGNATURES)

Build functional initialization: constant / 1D interpolation
"""
function buildFunctionalInit(data::ctVector, time, dim)
    if !isnothing(time) && (length(data) == length(time))
        # interpolation vs time, dim 1 case
        itp = ctinterpolate(time, data)
        return t -> itp(t)
    else
        # constant initialization
        checkDim(length(data), dim)
        return t -> data
    end
end

"""
$(TYPEDSIGNATURES)

Build functional initialization: general interpolation case
"""
function buildFunctionalInit(data, time, dim)
    if isaVectVect(data)
        # interpolation vs time, general case
        itp = ctinterpolate(time, data)
        checkDim(length(itp(0)), dim)
        return t -> itp(t)
    else
        error("Unrecognized initialization argument: ",typeof(data))
    end
end

"""
$(TYPEDSIGNATURES)

Build vector initialization: default / vector case
"""
function buildVectorInit(data, dim)
    if isnothing(data)
        return data
    else
        checkDim(length(data),dim)
        return data
    end
end

"""
$(TYPEDSIGNATURES)

Initial guess for OCP, contains
- functions of time for the state and control variables
- vector for optimization variables
Initialization data for each field can be left to default or: 
- vector for optimization variables
- constant / vector / function for state and control  
- existing solution ('warm start') for all fields

# Constructors:

- `OptimalControlInit()`: default initialization
- `OptimalControlInit(state, control, variable, time)`: constant vector, function handles and / or matrices / vectors interpolated along given time grid
- `OptimalControlInit(sol)`: from existing solution

# Examples

```julia-repl
julia> init = OptimalControlInit()
julia> init = OptimalControlInit(state=[0.1, 0.2], control=0.3)
julia> init = OptimalControlInit(state=[0.1, 0.2], control=0.3, variable=0.5)
julia> init = OptimalControlInit(state=[0.1, 0.2], controlt=t->sin(t), variable=0.5)
julia> init = OptimalControlInit(state=[[0, 0], [1, 2], [5, -1]], time=[0, .3, 1.], controlt=t->sin(t))
julia> init = OptimalControlInit(sol)
```

"""
mutable struct OptimalControlInit
   
    state_init::Function
    control_init::Function
    variable_init::Union{Nothing, ctVector}
    #costate_init::Function
    #multipliers_init::Union{Nothing, ctVector}

    """
    $(TYPEDSIGNATURES)

    OptimalControlInit base constructor with separate explicit arguments
    """
    function OptimalControlInit(; state=nothing, control=nothing, variable=nothing, time=nothing, state_dim=nothing, control_dim=nothing, variable_dim=nothing)
        
        init = new()
    
        # some matrix / vector conversions
        time = formatTimeGrid(time)
        state = formatData(state)
        control = formatData(control)
        
        # set initialization for x, u, v
        init.state_init = buildFunctionalInit(state, time, state_dim)
        init.control_init = buildFunctionalInit(control, time, control_dim)
        init.variable_init = buildVectorInit(variable, variable_dim)

        return init

    end

    """
    $(TYPEDSIGNATURES)

    OptimalControlInit constructor with arguments grouped as named tuple or dict
    """
    function OptimalControlInit(init_data; state_dim=nothing, control_dim=nothing, variable_dim=nothing)

        # trivial case: default init
        x_init = nothing
        u_init = nothing
        v_init = nothing
        t_init = nothing
        x_dim = nothing
        u_dim = nothing
        v_dim = nothing

        # parse arguments
        if !isnothing(init_data)
            for key in keys(init_data)
                if key == :state
                    x_init = init_data[:state]
                elseif key == :control
                    u_init = init_data[:control]
                elseif key == :variable
                    v_init = init_data[:variable]
                elseif key == :time
                    t_init = init_data[:time]
                else
                    error("Unknown key in initialization data (allowed: state, control, variable, time, state_dim, control_dim, variable_dim): ", key)
                end
            end
        end

        # call base constructor
        return OptimalControlInit(state=x_init, control=u_init, variable=v_init, time=t_init, state_dim=state_dim, control_dim=control_dim, variable_dim=variable_dim)
    
    end

    """
    $(TYPEDSIGNATURES)

    OptimalControlInit constructor with solution as argument (warm start)
    """
    function OptimalControlInit(sol::OptimalControlSolution; unused_kwargs...)
        return OptimalControlInit(state=sol.state, control=sol.control, variable=sol.variable, state_dim=sol.state_dimension, control_dim=sol.control_dimension, variable_dim=sol.variable_dimension)
    end

end