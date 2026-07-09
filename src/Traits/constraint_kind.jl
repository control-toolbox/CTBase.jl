"""
$(TYPEDEF)

Abstract base type for constraint-kind traits.

Constraint-kind traits encode, at the type level, which primal variables a path
constraint `g(...)` depends on. They distinguish between pure state constraints,
pure control constraints, and mixed state–control constraints.

# Trait Pattern

This trait follows the **type-parameter-only** contract (like
[`CTBase.Traits.AbstractFeedback`](@ref)): the trait value is read from a type parameter
of the concrete data type (e.g. `PathConstraint{F,K,TD,VD}`) by the `constraint_kind`
accessor. No `has_constraint_kind_trait` guard is provided; calling `constraint_kind`
on a type that does not implement it yields a standard `MethodError`.

See also: [`CTBase.Traits.StateConstraintKind`](@ref), [`CTBase.Traits.ControlConstraintKind`](@ref),
[`CTBase.Traits.MixedConstraintKind`](@ref), [`CTBase.Traits.constraint_kind`](@ref).
"""
abstract type AbstractConstraintKind <: AbstractTrait end

"""
$(TYPEDEF)

Trait indicating a pure state path constraint: `g` depends on the state (and
optionally time and variable), but not on the control.

A state constraint has the form `g(x)` (or `g(t, x)`, `g(x, v)`, `g(t, x, v)`).

See also: [`CTBase.Traits.ControlConstraintKind`](@ref), [`CTBase.Traits.MixedConstraintKind`](@ref),
[`CTBase.Traits.AbstractConstraintKind`](@ref).
"""
struct StateConstraintKind <: AbstractConstraintKind end

"""
$(TYPEDEF)

Trait indicating a pure control path constraint: `g` depends on the control (and
optionally time and variable), but not on the state.

A control constraint has the form `g(u)` (or `g(t, u)`, `g(u, v)`, `g(t, u, v)`).

See also: [`CTBase.Traits.StateConstraintKind`](@ref), [`CTBase.Traits.MixedConstraintKind`](@ref),
[`CTBase.Traits.AbstractConstraintKind`](@ref).
"""
struct ControlConstraintKind <: AbstractConstraintKind end

"""
$(TYPEDEF)

Trait indicating a mixed state–control path constraint: `g` depends on both the
state and the control (and optionally time and variable).

A mixed constraint has the form `g(x, u)` (or `g(t, x, u)`, `g(x, u, v)`,
`g(t, x, u, v)`).

See also: [`CTBase.Traits.StateConstraintKind`](@ref), [`CTBase.Traits.ControlConstraintKind`](@ref),
[`CTBase.Traits.AbstractConstraintKind`](@ref).
"""
struct MixedConstraintKind <: AbstractConstraintKind end

"""
$(TYPEDSIGNATURES)

Return the constraint-kind trait of `x`.

Methods are defined on concrete types in `Data` (e.g. `AbstractPathConstraint`).
The trait value is one of [`CTBase.Traits.StateConstraintKind`](@ref),
[`CTBase.Traits.ControlConstraintKind`](@ref), or [`CTBase.Traits.MixedConstraintKind`](@ref).

See also: [`CTBase.Traits.AbstractConstraintKind`](@ref), [`CTBase.Traits.StateConstraintKind`](@ref),
[`CTBase.Traits.ControlConstraintKind`](@ref), [`CTBase.Traits.MixedConstraintKind`](@ref).
"""
function constraint_kind end

"""
$(TYPEDSIGNATURES)

Return `true` if `x` is a pure state path constraint.

Methods are defined on concrete types in `Data` (e.g. `AbstractPathConstraint`).

# Returns
- `Bool`: `true` if the constraint-kind trait is `StateConstraintKind`, `false` otherwise.

See also: [`CTBase.Traits.StateConstraintKind`](@ref), [`CTBase.Traits.constraint_kind`](@ref).
"""
function is_state_constraint end

"""
$(TYPEDSIGNATURES)

Return `true` if `x` is a pure control path constraint.

Methods are defined on concrete types in `Data` (e.g. `AbstractPathConstraint`).

# Returns
- `Bool`: `true` if the constraint-kind trait is `ControlConstraintKind`, `false` otherwise.

See also: [`CTBase.Traits.ControlConstraintKind`](@ref), [`CTBase.Traits.constraint_kind`](@ref).
"""
function is_control_constraint end

"""
$(TYPEDSIGNATURES)

Return `true` if `x` is a mixed state–control path constraint.

Methods are defined on concrete types in `Data` (e.g. `AbstractPathConstraint`).

# Returns
- `Bool`: `true` if the constraint-kind trait is `MixedConstraintKind`, `false` otherwise.

See also: [`CTBase.Traits.MixedConstraintKind`](@ref), [`CTBase.Traits.constraint_kind`](@ref).
"""
function is_mixed_constraint end
