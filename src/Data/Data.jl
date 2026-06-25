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
include(joinpath(@__DIR__, "abstract_hamiltonian_vector_field.jl"))
include(joinpath(@__DIR__, "hamiltonian_vector_field.jl"))

# ==============================================================================
# Module exports
# ==============================================================================

export AbstractVectorField
export VectorField
export HamiltonianVectorField
export AbstractHamiltonianVectorField
export AbstractHamiltonian
export Hamiltonian

end # module Data
