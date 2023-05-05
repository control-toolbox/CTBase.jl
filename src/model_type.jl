"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)
"""
mutable struct Index
    val::Integer
    Index(v::Integer) = v ≥ 1 ? new(v) : error("index must be at least 1")
end
Base.:(==)(i::Index, j::Index) = i.val == j.val # needed, as this is not the default behaviour for composite types
Base.to_index(i::Index) = i.val
Base.getindex(x::AbstractArray, i::Index) = x[i.val]
Base.getindex(x::Real, i::Index) = x[i.val]
Base.isless(i::Index, j::Index) = i.val ≤ j.val
Base.isless(i::Index, j::Real) = i.val ≤ j
Base.isless(i::Real, j::Index) = i ≤ j.val
Base.length(i::Index) = 1
Base.iterate(i::Index, state=0) = state == 0 ? (i, 1) : nothing
Base.IteratorSize(::Type{Index}) = Base.HasLength()

"""
Type alias for an index or range.
"""
const RangeConstraint = Union{Index, OrdinalRange{<:Integer}}

"""
$(TYPEDEF)
"""
abstract type AbstractOptimalControlModel end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)
"""
@with_kw mutable struct OptimalControlModel{time_dependence, variable_dependence} <: AbstractOptimalControlModel
    initial_time::Union{Time,Index,Nothing}=nothing
    final_time::Union{Time,Index,Nothing}=nothing
    time_name::Union{String, Nothing}=nothing
    lagrange::Union{Lagrange,Nothing}=nothing
    mayer::Union{Mayer,Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{Dynamics,Nothing}=nothing
    variable_dimension::Union{Dimension,Nothing}=nothing
    variable_names::Union{Vector{String}, Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    state_names::Union{Vector{String}, Nothing}=nothing
    control_dimension::Union{Dimension, Nothing}=nothing
    control_names::Union{Vector{String}, Nothing}=nothing
    constraints::Dict{Symbol, Tuple{Vararg{Any}}}=Dict{Symbol, Tuple{Vararg{Any}}}()
end

# used for checkings
state_not_set(ocp::OptimalControlModel) = isnothing(ocp.state_dimension)
control_not_set(ocp::OptimalControlModel) = isnothing(ocp.control_dimension)
variable_not_set(ocp::OptimalControlModel) = isnothing(ocp.variable_dimension)
time_not_set(ocp::OptimalControlModel) = isnothing(ocp.initial_time) && isnothing(ocp.final_time)
time_set(ocp::OptimalControlModel) = !time_not_set(ocp)
