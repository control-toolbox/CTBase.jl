"""
[`CTBase`](@ref) module.

Lists all the imported modules and packages:

$(IMPORTS)

List of all the exported names:

$(EXPORTS)
"""
module CTBase

# using
import Base: show, \, Base
using DocStringExtensions
using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using Interpolations: linear_interpolation, Line, Interpolations # for default interpolation
using MLStyle
using Parameters # @with_kw: to have default values in struct
using Plots
import Plots: plot, plot! # import instead of using to overload the plot and plot! functions
using Printf # to print an OptimalControlModel
using Reexport

# --------------------------------------------------------------------------------------------------
# Aliases for types
# const AbstractVector{T} = AbstractArray{T,1}.
"""
Type alias for a real number.
"""
const MyNumber = Real
"""
Type alias for a vector of real numbers.
"""
const MyVector = AbstractVector{<:MyNumber}
"""
Type alias for a time.
"""
const Time = MyNumber
"""
Type alias for a vector of times.
"""
const Times = AbstractVector{<:Time}
"""
Type alias for a grid of times.
"""
const TimesDisc = Union{MyVector, StepRangeLen}
"""
Type alias for a state.
"""
const State = MyVector
"""
Type alias for an adjoint.
"""
const Adjoint = MyVector # todo: add ajoint to write p*f(x, u) instead of p'*f(x,u)
"""
Type alias for a control.
"""
const Control = MyVector
"""
Type alias for a vector of states.
"""
const States = Vector{<:State}
"""
Type alias for a vector of adjoints.
"""
const Adjoints = Vector{<:Adjoint}
"""
Type alias for a vector of controls.
"""
const Controls = Vector{<:Control}
"""
Type alias for a dimension.
"""
const Dimension = Integer

#
include("exceptions.jl")
include("description.jl")
include("callbacks.jl")
include("functions.jl")
#
include("default.jl")
include("utils.jl")
include("model.jl")
#
include("ctparser_utils.jl")
#include("ctparser.jl")
#@reexport using .CtParser
#
include("print.jl")
include("solution.jl")
include("plot.jl")

# numeric types
export MyNumber, MyVector, Time, Times, TimesDisc
export States, Adjoints, Controls, State, Adjoint, Dimension, Index

# callback
export CTCallback, CTCallbacks, PrintCallback, StopCallback
export get_priority_print_callbacks, get_priority_stop_callbacks

# description
export Description, makeDescription, add, getFullDescription, \

# exceptions
export CTException, AmbiguousDescription, InconsistentArgument, IncorrectMethod, IncorrectArgument, IncorrectOutput

# functions
export Hamiltonian, HamiltonianVectorField, VectorField
export MayerFunction, LagrangeFunction, DynamicsFunction, ControlFunction, MultiplierFunction
export BoundaryConstraintFunction, StateConstraintFunction, ControlConstraintFunction, MixedConstraintFunction

# model
export OptimalControlModel
export Model
export time!, constraint!, objective!, state!, control!, remove_constraint!, constraint
export isautonomous, isnonautonomous, ismin, ismax
export nlp_constraints, constraints_labels
export @__def

# solution
export OptimalControlSolution
export plot

# utils
export Ad, Poisson, ctgradient, ctjacobian, ctinterpolate, ctindices, ctupperscripts

end
