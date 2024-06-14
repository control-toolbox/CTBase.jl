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
using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using Interpolations: linear_interpolation, Line, Interpolations # for default interpolation
using MLStyle # pattern matching
using Parameters # @with_kw: to have default values in struct
using Plots
import Plots: plot, plot! # import instead of using to overload the plot and plot! functions
using Printf # to print an OptimalControlModel
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
"""
const ctNumber = Real
"""
Type alias for a vector of real numbers.
"""
const ctVector = Union{ctNumber, AbstractVector{<:ctNumber}} # [] must be defined as Vector{Real}()
"""
Type alias for a time.
"""
const Time = ctNumber
"""
Type alias for a vector of times.
"""
const Times = AbstractVector{<:Time}
"""
Type alias for a grid of times.
"""
const TimesDisc = Union{Times, StepRangeLen}
"""
Type alias for a state.
"""
const State = ctVector
"""
Type alias for an costate.
"""
const Costate = ctVector # todo: add ajoint to write p*f(x, u) instead of p'*f(x,u)
"""
Type alias for a control.
"""
const Control = ctVector
"""
Type alias for a variable.
"""
const Variable = ctVector
"""
Type alias for a vector of states.
"""
const States = AbstractVector{<:State}
"""
Type alias for a vector of costates.
"""
const Costates = AbstractVector{<:Costate}
"""
Type alias for a vector of controls.
"""
const Controls = AbstractVector{<:Control}
"""
Type alias for a dimension.
"""
const Dimension = Integer

#
"""
Type alias for a tangent vector to the state space.
"""
const DState     = ctVector
"""
Type alias for a tangent vector to the costate space.
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
include("plot.jl")
#
include("functions.jl")
include("model.jl")
include("differential_geometry.jl")
#
include("ctparser_utils.jl")
##include("ctparser.jl")
include("onepass.jl")
include("repl.jl")
#
include("init.jl")

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
export Description, add, getFullDescription

# exceptions
export CTException, ParsingError, AmbiguousDescription, IncorrectMethod
export IncorrectArgument, IncorrectOutput, NotImplemented, UnauthorizedCall

# checking

# functions
export Hamiltonian, HamiltonianVectorField, VectorField
export Mayer, Lagrange, Dynamics, ControlLaw, FeedbackControl, Multiplier
export BoundaryConstraint, StateConstraint, ControlConstraint, MixedConstraint, VariableConstraint

# model
export OptimalControlModel
export Model
export variable!, time!, constraint!, dynamics!, objective!, state!, control!, remove_constraint!, constraint
export is_time_independent, is_time_dependent, is_min, is_max, is_variable_dependent, is_variable_independent
export nlp_constraints, constraints_labels
export has_free_final_time, has_free_initial_time, has_lagrange_cost, has_mayer_cost

# solution
export OptimalControlSolution
export plot, plot!

# initialization
export OCPInit

# utils
export ctgradient, ctjacobian, ctinterpolate, ctindices, ctupperscripts

# differential geometry
export Lie, @Lie, Poisson, HamiltonianLift, AbstractHamiltonian, Lift, ⋅, ∂ₜ

# ctparser_utils
export replace_call, constraint_type

# onepass
export @def

# repl
export ct_repl
isdefined(Base, :active_repl) && ct_repl()

end
