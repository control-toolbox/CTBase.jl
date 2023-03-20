module CTBase

# using
import Base: show, \, Base
using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using Interpolations: linear_interpolation, Line, Interpolations # for default interpolation
using MLStyle
using Parameters # @with_kw: permit to have default values in struct
using Plots
import Plots: plot, plot! # import instead of using to overload the plot and plot! functions
using Printf # to print a OptimalControlModel
using Reexport

# --------------------------------------------------------------------------------------------------
# Aliases for types
# const AbstractVector{T} = AbstractArray{T,1}.
const MyNumber = Real
const MyVector = AbstractVector{<:MyNumber}

const Time = MyNumber
const Times = MyVector
const TimesDisc = Union{MyVector,StepRangeLen}

const State = MyVector
const Adjoint = MyVector # todo: add ajoint to write p*f(x, u) instead of p'*f(x,u)
const Control = MyVector

const States = Vector{<:State}
const Adjoints = Vector{<:Adjoint}
const Controls = Vector{<:Control}

const Dimension = Integer

# General abstract type for callbacks
abstract type CTCallback end
const CTCallbacks = Tuple{Vararg{CTCallback}}

# A desription is a tuple of symbols
const DescVarArg = Vararg{Symbol} # or Symbol...
const Description = Tuple{DescVarArg}

#
include("exceptions.jl")
include("descriptions.jl")
include("callbacks.jl")
include("macros.jl")
include("functions.jl")
#
include("default.jl")
include("utils.jl")
#include("algorithms.jl")
include("model.jl")
#
include("ctparser-utils.jl")
#include("ctparser.jl")
#@reexport using .CtParser
#
include("print.jl")
include("solution.jl")
include("plot.jl")

#
# Numeric types
export MyNumber, MyVector, Time, Times, TimesDisc
export States, Adjoints, Controls, State, Adjoint, Dimension

# callback
export CTCallback, CTCallbacks, PrintCallback, StopCallback
export get_priority_print_callbacks, get_priority_stop_callbacks

# exceptions
export CTException, AmbiguousDescription, InconsistentArgument, IncorrectMethod, IncorrectArgument, IncorrectOutput

# description
export Description, makeDescription, add, getFullDescription

# utils
export Ad, Poisson, ctgradient, ctjacobian, ctinterpolate, ctindices

# model
export AbstractOptimalControlModel, OptimalControlModel
export Model, time!, constraint!, objective!, state!, control!, remove_constraint!, constraint
export ismin, dynamics, lagrange, mayer, criterion, initial_time, final_time
export control_dimension, state_dimension, constraints
export initial_condition, final_condition, initial_constraint, final_constraint
export isautonomous, isnonautonomous
export control_labels, state_labels

# solution
export AbstractOptimalControlSolution, OptimalControlSolution
#export time_steps_length, state_dimension, control_dimension
#export time_steps, state, control, adjoint, objective
#export iterations, success, message, stopping
#export constraints_violation
export plot, plot!

# macros
export @ctfunction_td_sv, @ctfunction_sv

# functions
export Hamiltonian, HamiltonianVectorField, VectorField
export MayerFunction, LagrangeFunction, DynamicsFunction, ControlFunction, MultiplierFunction
export BoundaryConstraintFunction, StateConstraintFunction, ControlConstraintFunction, MixedConstraintFunction

# ctparser-utils
export prune_call, subs, constraint_type, has

end
