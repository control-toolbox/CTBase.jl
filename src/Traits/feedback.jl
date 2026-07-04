"""
$(TYPEDEF)

Abstract base type for feedback traits.

Feedback traits encode, at the type level, the kind of control law used to close
the loop in an optimal control flow. They distinguish between open-loop control
(time-only dependence), closed-loop control (state dependence), and dynamic
closed-loop control (state and costate dependence).

# Trait Pattern

This trait follows the **type-parameter-only** contract (like
[`CTBase.Traits.AbstractDynamicsTrait`](@ref)): the trait value is read from a type parameter
of the concrete data type (e.g. `ControlLaw{F,FB,TD,VD}`) by the `feedback`
accessor. No `has_feedback_trait` guard is provided; calling `feedback` on a
type that does not implement it yields a standard `MethodError`.

# See also

- [`CTBase.Traits.OpenLoopFeedback`](@ref)
- [`CTBase.Traits.ClosedLoopFeedback`](@ref)
- [`CTBase.Traits.DynClosedLoopFeedback`](@ref)
- [`CTBase.Traits.feedback`](@ref)
"""
abstract type AbstractFeedback <: AbstractTrait end

"""
$(TYPEDEF)

Trait indicating open-loop feedback: the control depends only on time (and
optionally the variable), not on the state or costate.

An open-loop control law has the form `u(t)` (or `u(t, v)` for variable
problems). The trajectory is determined entirely by the pre-specified control
function, without feedback from the current state.

# See also

- [`CTBase.Traits.ClosedLoopFeedback`](@ref)
- [`CTBase.Traits.DynClosedLoopFeedback`](@ref)
- [`CTBase.Traits.AbstractFeedback`](@ref)
"""
struct OpenLoopFeedback <: AbstractFeedback end

"""
$(TYPEDEF)

Trait indicating closed-loop feedback: the control depends on the state (and
optionally time and variable), but not on the costate.

A closed-loop control law has the form `u(t, x)` (or `u(t, x, v)` for variable
problems). The control is a function of the current state, providing static
state feedback without costate information.

# See also

- [`CTBase.Traits.OpenLoopFeedback`](@ref)
- [`CTBase.Traits.DynClosedLoopFeedback`](@ref)
- [`CTBase.Traits.AbstractFeedback`](@ref)
"""
struct ClosedLoopFeedback <: AbstractFeedback end

"""
$(TYPEDEF)

Trait indicating dynamic closed-loop feedback: the control depends on both the
state and the costate (and optionally time and variable).

A dynamic closed-loop control law has the form `u(t, x, p)` (or `u(t, x, p, v)`
for variable problems). The control is a function of the full Hamiltonian state,
providing dynamic feedback that uses costate information — typically derived
from the pseudo-Hamiltonian maximisation condition.

# See also

- [`CTBase.Traits.OpenLoopFeedback`](@ref)
- [`CTBase.Traits.ClosedLoopFeedback`](@ref)
- [`CTBase.Traits.AbstractFeedback`](@ref)
"""
struct DynClosedLoopFeedback <: AbstractFeedback end

"""
$(TYPEDSIGNATURES)

Return the feedback trait of `x`.

Methods are defined on concrete types in `Data` (e.g. `AbstractControlLaw`).
The trait value is one of [`CTBase.Traits.OpenLoopFeedback`](@ref), [`CTBase.Traits.ClosedLoopFeedback`](@ref),
or [`CTBase.Traits.DynClosedLoopFeedback`](@ref).

# See also

- [`CTBase.Traits.AbstractFeedback`](@ref)
- [`CTBase.Traits.OpenLoopFeedback`](@ref)
- [`CTBase.Traits.ClosedLoopFeedback`](@ref)
- [`CTBase.Traits.DynClosedLoopFeedback`](@ref)
"""
function feedback end

"""
$(TYPEDSIGNATURES)

Return `true` if `x` has open-loop feedback.

Methods are defined on concrete types in `Data` (e.g. `AbstractControlLaw`).

See also: [`CTBase.Traits.OpenLoopFeedback`](@ref), [`CTBase.Traits.feedback`](@ref).
"""
function is_open_loop end

"""
$(TYPEDSIGNATURES)

Return `true` if `x` has closed-loop feedback.

Methods are defined on concrete types in `Data` (e.g. `AbstractControlLaw`).

See also: [`CTBase.Traits.ClosedLoopFeedback`](@ref), [`CTBase.Traits.feedback`](@ref).
"""
function is_closed_loop end

"""
$(TYPEDSIGNATURES)

Return `true` if `x` has dynamic closed-loop feedback.

Methods are defined on concrete types in `Data` (e.g. `AbstractControlLaw`).

See also: [`CTBase.Traits.DynClosedLoopFeedback`](@ref), [`CTBase.Traits.feedback`](@ref).
"""
function is_dyn_closed_loop end
