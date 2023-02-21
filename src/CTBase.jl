module CTBase

# using
using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using Parameters # @with_kw: permit to have default values in struct
using Interpolations: linear_interpolation, Line, Interpolations # for default interpolation
using Printf # to print a OptimalControlModel
import Base: \, Base
using MacroTools

# --------------------------------------------------------------------------------------------------
# Aliases for types
# const AbstractVector{T} = AbstractArray{T,1}.
const MyNumber = Real
const MyVector = AbstractVector{<:MyNumber}

const Time = MyNumber
const Times = MyVector
const TimesDisc = Union{MyVector,StepRangeLen}

const State = MyVector
const Adjoint = MyVector # todo: ajouter type adjoint pour faire par exemple p*f(x, u) au lieu de p'*f(x,u)
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
include("utils.jl")
#include("algorithms.jl")
include("model.jl")
include("print.jl")
include("solutions.jl")
include("default.jl")

#
# Numeric types
export MyNumber, MyVector, Time, Times, TimesDisc
export States, Adjoints, Controls, State, Adjoint, Dimension

# callback
export CTCallback, CTCallbacks, PrintCallback, StopCallback
export get_priority_print_callbacks, get_priority_stop_callbacks

# exceptions
export CTException, AmbiguousDescription, InconsistentArgument, IncorrectMethod, IncorrectArgument

# description
export Description, makeDescription, add, getFullDescription

# utils
export Ad, Poisson, ctgradient, ctjacobian, ctinterpolate

# model
export AbstractOptimalControlModel, OptimalControlModel
export Model, time!, constraint!, objective!, state!, control!, remove_constraint!, constraint
export ismin, dynamics, lagrange, mayer, criterion, initial_time, final_time
export control_dimension, state_dimension, constraints
export initial_condition, final_condition, initial_constraint, final_constraint
export isautonomous, isnonautonomous

# solution
export AbstractOptimalControlSolution, DirectSolution, DirectShootingSolution
export time_steps_length, state_dimension, control_dimension
export time_steps, state, control, adjoint, objective
export iterations, success, message, stopping
export constraints_violation

# macros
export @callable, @ctfunction_td_sv, @ctfunction_sv

# functions
export Hamiltonian, HamiltonianVectorField, VectorField
export MayerFunction, LagrangeFunction, DynamicsFunction, ControlFunction, MultiplierFunction
export BoundaryConstraintFunction, StateConstraintFunction, ControlConstraintFunction, MixedConstraintFunction

end