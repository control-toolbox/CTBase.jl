"""
[`CTBase`](@ref) module.

Lists all the imported modules and packages:

$(IMPORTS)

List of all the exported names:

$(EXPORTS)
"""
module CTBase

# using
import Base
using DocStringExtensions
using DifferentiationInterface: AutoForwardDiff, derivative, gradient, jacobian, prepare_derivative, prepare_gradient, prepare_jacobian
import ForwardDiff
using Interpolations: linear_interpolation, Line, Interpolations # for default interpolation
using MLStyle # pattern matching
using Parameters # @with_kw: to have default values in struct
using Printf # to print an Opt imalControlModel
using DataStructures # OrderedDict for aliases
using Unicode # unicode primitives
using PrettyTables # to print a table
using ReplMaker
using MacroTools: @capture, postwalk, striplines
using LinearAlgebra

# --------------------------------------------------------------------------------------------------
# Aliases for types
# const AbstractVector{T} = AbstractArray{T,1}.
"""
Type alias for a real number.

```@example
julia> const ctNumber = Real
```
"""
const ctNumber = Real

"""
Type alias for a vector of real numbers.

```@example
julia> const ctVector = Union{ctNumber, AbstractVector{<:ctNumber}}
```

See also: [`ctNumber`](@ref), [`State`](@ref), [`Costate`](@ref), [`Control`](@ref), [`Variable`](@ref).
"""
const ctVector = Union{ctNumber, AbstractVector{<:ctNumber}} # [] must be defined as Vector{Real}()

"""
Type alias for a time.

```@example
julia> const Time = ctNumber
```

See also: [`ctNumber`](@ref), [`Times`](@ref), [`TimesDisc`](@ref).
"""
const Time = ctNumber

"""
Type alias for a vector of times.

```@example
julia> const Times = AbstractVector{<:Time}
```

See also: [`Time`](@ref), [`TimesDisc`](@ref).
"""
const Times = AbstractVector{<:Time}

"""
Type alias for a grid of times. This is used to define a discretization of time interval given to solvers.

```@example
julia> const TimesDisc = Union{Times, StepRangeLen}
```

See also: [`Time`](@ref), [`Times`](@ref).
"""
const TimesDisc = Union{Times, StepRangeLen}

"""
Type alias for a state in Rⁿ.

```@example
julia> const State = ctVector
```

See also: [`ctVector`](@ref), [`Costate`](@ref), [`Control`](@ref), [`Variable`](@ref).
"""
const State = ctVector

"""
Type alias for a costate in Rⁿ.

```@example
julia> const Costate = ctVector
```

See also: [`ctVector`](@ref), [`State`](@ref), [`Control`](@ref), [`Variable`](@ref).
"""
const Costate = ctVector # todo: add adjoint to write p*f(x, u) instead of p'*f(x,u)

"""
Type alias for a control in Rᵐ.

```@example
julia> const Control = ctVector
```

See also: [`ctVector`](@ref), [`State`](@ref), [`Costate`](@ref), [`Variable`](@ref).
"""
const Control = ctVector

"""
Type alias for a variable in Rᵏ.

```@example
julia> const Variable = ctVector
```

See also: [`ctVector`](@ref), [`State`](@ref), [`Costate`](@ref), [`Control`](@ref).
"""
const Variable = ctVector

"""
Type alias for a vector of states.

```@example
julia> const States = AbstractVector{<:State}
```

See also: [`State`](@ref), [`Costates`](@ref), [`Controls`](@ref).
"""
const States = AbstractVector{<:State}

"""
Type alias for a vector of costates.

```@example
julia> const Costates = AbstractVector{<:Costate}
```

See also: [`Costate`](@ref), [`States`](@ref), [`Controls`](@ref).
"""
const Costates = AbstractVector{<:Costate}

"""
Type alias for a vector of controls.

```@example
julia> const Controls = AbstractVector{<:Control}
```

See also: [`Control`](@ref), [`States`](@ref), [`Costates`](@ref).
"""
const Controls = AbstractVector{<:Control}

"""
Type alias for a dimension. This is used to define the dimension of the state space, 
the costate space, the control space, etc.

```@example
julia> const Dimension = Integer
```
"""
const Dimension = Integer

#
"""
Type alias for a tangent vector to the state space.

```@example
julia> const DState = ctVector
```

See also: [`ctVector`](@ref), [`DCostate`](@ref).
"""
const DState     = ctVector

"""
Type alias for a tangent vector to the costate space.

```@example
julia> const DCostate = ctVector
```

See also: [`ctVector`](@ref), [`DState`](@ref).
"""
const DCostate   = ctVector

#
include("exception.jl")
include("description.jl")
include("callback.jl")
include("default.jl")
include("types.jl")
include("utils.jl")
#
include("checking.jl")
#
include("print.jl")
#
include("functions.jl")
include("model.jl")
include("differential_geometry.jl")
#
include("ctparser_utils.jl")
include("onepass.jl")
include("repl.jl")
#
include("init.jl")

# to be extended
plot(sol::OptimalControlSolution, args...; kwargs...) = throw(ExtensionError(:Plots))

#
export plot

# numeric types
export ctNumber, ctVector, Time, Times, TimesDisc

export States, Costates, Controls, State, Costate, Control, Variable, Dimension, Index
export DState, DCostate
export TimeDependence, Autonomous, NonAutonomous
export VariableDependence, NonFixed, Fixed

# callback
export CTCallback, CTCallbacks, PrintCallback, StopCallback
export get_priority_print_callbacks, get_priority_stop_callbacks

# description
export Description, add, getFullDescription, remove

# exceptions
export CTException, ParsingError, AmbiguousDescription, IncorrectMethod
export IncorrectArgument, IncorrectOutput, NotImplemented, UnauthorizedCall
export ExtensionError

# AD
export set_AD_backend

# functions
export Hamiltonian, HamiltonianVectorField, VectorField
export Mayer, Lagrange, Dynamics, ControlLaw, FeedbackControl, Multiplier
export BoundaryConstraint, StateConstraint, ControlConstraint, MixedConstraint, VariableConstraint

# model
export OptimalControlModel
export Model
export __OCPModel # redirection to Model to avoid confusion with other Model functions from other packages. Due to @def macro
export variable!, time!, constraint!, dynamics!, objective!, state!, control!, remove_constraint!, constraint
export is_autonomous, is_fixed, is_time_independent, is_time_dependent, is_min, is_max, is_variable_dependent, is_variable_independent
export nlp_constraints!, constraints_labels
export has_free_final_time, has_free_initial_time, has_lagrange_cost, has_mayer_cost
export dim_control_constraints, dim_state_constraints, dim_mixed_constraints, dim_path_constraints, dim_boundary_constraints, dim_variable_constraints, dim_control_range, dim_state_range, dim_variable_range
export model_expression, initial_time, initial_time_name, final_time, final_time_name, time_name
export control_dimension, control_components_names, control_name
export state_dimension, state_components_names, state_name
export variable_dimension, variable_components_names, variable_name
export lagrange, mayer, criterion, dynamics

# solution
export OptimalControlSolution

# initialization
export OptimalControlInit

# utils
export ctgradient, ctjacobian, ctinterpolate, ctindices, ctupperscripts

# differential geometry
export Lie, @Lie, Poisson, HamiltonianLift, AbstractHamiltonian, Lift, ⋅, ∂ₜ

# ctparser_utils
export replace_call, constraint_type

# onepass
export @def

# repl
export ct_repl, ct_repl_update_model
isdefined(Base, :active_repl) && ct_repl()

end
