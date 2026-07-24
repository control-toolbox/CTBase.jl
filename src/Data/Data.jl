"""
    Data

Data structures including vector fields and Hamiltonian vector fields with traits.

This module defines the `VectorField` and `HamiltonianVectorField` types which encapsulate
vector-field functions together with their time-dependence and variable-dependence traits.
"""
module Data

# 1. External-package imports (qualified, pollution-free)
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import CTBase.Exceptions
import CTBase.Traits

# ==============================================================================
# Include files
# ==============================================================================

include(joinpath(@__DIR__, "default.jl"))
include(joinpath(@__DIR__, "helpers.jl"))
include(joinpath(@__DIR__, "abstract_vector_field.jl"))
include(joinpath(@__DIR__, "vector_field.jl"))
include(joinpath(@__DIR__, "abstract_hamiltonian.jl"))
include(joinpath(@__DIR__, "hamiltonian.jl"))
include(joinpath(@__DIR__, "abstract_control_law.jl"))
include(joinpath(@__DIR__, "control_law.jl"))
include(joinpath(@__DIR__, "abstract_path_constraint.jl"))
include(joinpath(@__DIR__, "path_constraint.jl"))
include(joinpath(@__DIR__, "abstract_multiplier.jl"))
include(joinpath(@__DIR__, "multiplier.jl"))
include(joinpath(@__DIR__, "abstract_pseudo_hamiltonian.jl"))
include(joinpath(@__DIR__, "pseudo_hamiltonian.jl"))
include(joinpath(@__DIR__, "composed_hamiltonian.jl"))
include(joinpath(@__DIR__, "abstract_controlled_vector_field.jl"))
include(joinpath(@__DIR__, "controlled_vector_field.jl"))
include(joinpath(@__DIR__, "composed_vector_field.jl"))
include(joinpath(@__DIR__, "abstract_hamiltonian_vector_field.jl"))
include(joinpath(@__DIR__, "hamiltonian_vector_field.jl"))
include(joinpath(@__DIR__, "abstract_pseudo_hamiltonian_vector_field.jl"))
include(joinpath(@__DIR__, "pseudo_hamiltonian_vector_field.jl"))

# ==============================================================================
# Module exports
# ==============================================================================

export AbstractVectorField
export VectorField
export HamiltonianVectorField
export AbstractHamiltonianVectorField
export AbstractHamiltonian
export Hamiltonian
export AbstractControlLaw
export ControlLaw
export OpenLoop
export ClosedLoop
export DynClosedLoop
export AbstractPathConstraint
export PathConstraint
export StateConstraint
export ControlConstraint
export MixedConstraint
export AbstractMultiplier
export Multiplier
export AbstractPseudoHamiltonian
export PseudoHamiltonian
export AbstractPseudoHamiltonianVectorField
export PseudoHamiltonianVectorField
export ComposedHamiltonian
export pseudo_hamiltonian
export control_law
export AbstractControlledVectorField
export ControlledVectorField
export ComposedVectorField
export controlled_vector_field

end # module Data
