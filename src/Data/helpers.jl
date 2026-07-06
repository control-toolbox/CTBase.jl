"""
Internal helper functions for display formatting.

This module provides helper functions for generating user-friendly display
representations of VectorField and HamiltonianVectorField types.
"""

# =============================================================================
# Shared label helpers
# =============================================================================

"""
    _td_label(::Type{Traits.Autonomous}) -> String
    _td_label(::Type{Traits.NonAutonomous}) -> String

Return a user-friendly label for time dependence traits.

# Arguments
- `TD`: Type parameter for time dependence (`Autonomous` or `NonAutonomous`)

# Returns
- `String`: User-friendly label ("autonomous" or "non-autonomous")

See also: [`CTBase.Data._vd_label`](@ref), [`CTBase.Data._md_label`](@ref).
"""
function _td_label(::Type{Traits.Autonomous})
    return "autonomous"
end
function _td_label(::Type{Traits.NonAutonomous})
    return "non-autonomous"
end

"""
    _vd_label(::Type{Traits.Fixed}) -> String
    _vd_label(::Type{Traits.NonFixed}) -> String

Return a user-friendly label for variable dependence traits.

# Arguments
- `VD`: Type parameter for variable dependence (`Fixed` or `NonFixed`)

# Returns
- `String`: User-friendly label ("fixed (no variable)" or "variable")

See also: [`CTBase.Data._td_label`](@ref), [`CTBase.Data._md_label`](@ref).
"""
function _vd_label(::Type{Traits.Fixed})
    return "fixed (no variable)"
end
function _vd_label(::Type{Traits.NonFixed})
    return "variable"
end

"""
    _md_label(::Type{OutOfPlace}) -> String
    _md_label(::Type{InPlace}) -> String

Return a user-friendly label for mutability traits.

# Arguments
- `MD`: Type parameter for mutability (`OutOfPlace` or `InPlace`)

# Returns
- `String`: User-friendly label ("out-of-place" or "in-place")

See also: [`CTBase.Data._td_label`](@ref), [`CTBase.Data._vd_label`](@ref).
"""
function _md_label(::Type{Traits.OutOfPlace})
    return "out-of-place"
end
function _md_label(::Type{Traits.InPlace})
    return "in-place"
end

# =============================================================================
# VectorField-specific signature helpers
# =============================================================================

"""
    _natural_sig_vf(::Type{TD}, ::Type{VD}, ::Type{Traits.OutOfPlace}) where {TD, VD} -> String
    _natural_sig_vf(::Type{TD}, ::Type{VD}, ::Type{Traits.InPlace}) where {TD, VD} -> String

Return the natural call signature for a VectorField based on its traits.

# Arguments
- `TD`: Time dependence type (`Autonomous` or `NonAutonomous`)
- `VD`: Variable dependence type (`Fixed` or `NonFixed`)
- `MD`: Mutability type (`Traits.OutOfPlace` or `Traits.InPlace`)

# Returns
- `String`: Natural call signature (e.g., "f(x)", "f(t, x)", "f(dx, x)")

# Example
\`\`\`julia
_natural_sig_vf(Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace)  # Returns "f(x)"
_natural_sig_vf(Traits.NonAutonomous, Traits.Fixed, Traits.OutOfPlace)  # Returns "f(t, x)"
_natural_sig_vf(Traits.Autonomous, Traits.Fixed, Traits.InPlace)  # Returns "f(dx, x)"
\`\`\`

See also: [`CTBase.Data._uniform_sig_vf`](@ref).
"""
function _natural_sig_vf(::Type{TD}, ::Type{VD}, ::Type{Traits.OutOfPlace}) where {TD,VD}
    args = String[]
    TD === Traits.NonAutonomous && push!(args, "t")
    push!(args, "x")
    VD === Traits.NonFixed && push!(args, "v")
    return "f(" * join(args, ", ") * ")"
end

function _natural_sig_vf(::Type{TD}, ::Type{VD}, ::Type{Traits.InPlace}) where {TD,VD}
    args = ["dx"]
    TD === Traits.NonAutonomous && push!(args, "t")
    push!(args, "x")
    VD === Traits.NonFixed && push!(args, "v")
    return "f(" * join(args, ", ") * ")"
end

"""
    _uniform_sig_vf(::Type{Traits.OutOfPlace}) -> String
    _uniform_sig_vf(::Type{Traits.InPlace}) -> String

Return the uniform call signature for a VectorField.

The uniform signature always includes all arguments (t, x, v) regardless of traits,
and includes the derivative buffer (dx) for in-place variants.

# Arguments
- `MD`: Mutability type (`Traits.OutOfPlace` or `Traits.InPlace`)

# Returns
- `String`: Uniform call signature ("f(t, x, v)" or "f(dx, t, x, v)")

See also: [`CTBase.Data._natural_sig_vf`](@ref).
"""
function _uniform_sig_vf(::Type{Traits.OutOfPlace})
    return "f(t, x, v)"
end
function _uniform_sig_vf(::Type{Traits.InPlace})
    return "f(dx, t, x, v)"
end

# =============================================================================
# HamiltonianVectorField-specific signature helpers
# =============================================================================

"""
    _natural_sig_hvf(::Type{TD}, ::Type{VD}, ::Type{Traits.OutOfPlace}) where {TD, VD} -> String
    _natural_sig_hvf(::Type{TD}, ::Type{VD}, ::Type{Traits.InPlace}) where {TD, VD} -> String

Return the natural call signature for a HamiltonianVectorField based on its traits.

# Arguments
- `TD`: Time dependence type (`Autonomous` or `NonAutonomous`)
- `VD`: Variable dependence type (`Fixed` or `NonFixed`)
- `MD`: Mutability type (`Traits.OutOfPlace` or `Traits.InPlace`)

# Returns
- `String`: Natural call signature (e.g., "f(x, p)", "f(t, x, p)", "f(dx, dp, x, p)")

# Example
\`\`\`julia
_natural_sig_hvf(Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace)  # Returns "f(x, p)"
_natural_sig_hvf(Traits.NonAutonomous, Traits.Fixed, Traits.OutOfPlace)  # Returns "f(t, x, p)"
_natural_sig_hvf(Traits.Autonomous, Traits.Fixed, Traits.InPlace)  # Returns "f(dx, dp, x, p)"
\`\`\`

See also: [`CTBase.Data._uniform_sig_hvf`](@ref).
"""
function _natural_sig_hvf(::Type{TD}, ::Type{VD}, ::Type{Traits.OutOfPlace}) where {TD,VD}
    args = String[]
    TD === Traits.NonAutonomous && push!(args, "t")
    push!(args, "x")
    push!(args, "p")
    VD === Traits.NonFixed && push!(args, "v")
    return "f(" * join(args, ", ") * ")"
end

function _natural_sig_hvf(::Type{TD}, ::Type{VD}, ::Type{Traits.InPlace}) where {TD,VD}
    args = ["dx", "dp"]
    TD === Traits.NonAutonomous && push!(args, "t")
    push!(args, "x")
    push!(args, "p")
    VD === Traits.NonFixed && push!(args, "v")
    return "f(" * join(args, ", ") * ")"
end

"""
    _uniform_sig_hvf(::Type{Traits.OutOfPlace}) -> String
    _uniform_sig_hvf(::Type{Traits.InPlace}) -> String

Return the uniform call signature for a HamiltonianVectorField.

The uniform signature always includes all arguments (t, x, p, v) regardless of traits,
and includes the derivative buffers (dx, dp) for in-place variants.

# Arguments
- `MD`: Mutability type (`Traits.OutOfPlace` or `Traits.InPlace`)

# Returns
- `String`: Uniform call signature ("f(t, x, p, v)" or "f(dx, dp, t, x, p, v)")

See also: [`CTBase.Data._natural_sig_hvf`](@ref).
"""
function _uniform_sig_hvf(::Type{Traits.OutOfPlace})
    return "f(t, x, p, v)"
end
function _uniform_sig_hvf(::Type{Traits.InPlace})
    return "f(dx, dp, t, x, p, v)"
end

# =============================================================================
# Hamiltonian-specific signature helpers
# =============================================================================

"""
    _natural_sig_h(::Type{TD}, ::Type{VD}) where {TD, VD} -> String

Return the natural call signature for a Hamiltonian based on its traits.

# Arguments
- `TD`: Time dependence type (`Autonomous` or `NonAutonomous`)
- `VD`: Variable dependence type (`Fixed` or `NonFixed`)

# Returns
- `String`: Natural call signature (e.g., "h(x, p)", "h(t, x, p)")

# Example
\`\`\`julia
_natural_sig_h(Autonomous, Fixed)  # Returns "h(x, p)"
_natural_sig_h(NonAutonomous, Fixed)  # Returns "h(t, x, p)"
\`\`\`

See also: [`CTBase.Data._uniform_sig_h`](@ref).
"""
function _natural_sig_h(::Type{TD}, ::Type{VD}) where {TD,VD}
    args = String[]
    TD === Traits.NonAutonomous && push!(args, "t")
    push!(args, "x")
    push!(args, "p")
    VD === Traits.NonFixed && push!(args, "v")
    return "h(" * join(args, ", ") * ")"
end

"""
    _uniform_sig_h() -> String

Return the uniform call signature for a Hamiltonian.

The uniform signature always includes all arguments (t, x, p, v) regardless of traits.

# Returns
- `String`: Uniform call signature ("h(t, x, p, v)")

See also: [`CTBase.Data._natural_sig_h`](@ref).
"""
function _uniform_sig_h()
    return "h(t, x, p, v)"
end

# =============================================================================
# Feedback label helpers
# =============================================================================

"""
    _fb_label(::Type{Traits.OpenLoopFeedback}) -> String
    _fb_label(::Type{Traits.ClosedLoopFeedback}) -> String
    _fb_label(::Type{Traits.DynClosedLoopFeedback}) -> String

Return a user-friendly label for feedback traits.

# Returns
- `String`: "open-loop", "closed-loop", or "dyn-closed-loop".

See also: [`CTBase.Data._td_label`](@ref), [`CTBase.Data._vd_label`](@ref).
"""
function _fb_label(::Type{Traits.OpenLoopFeedback})
    return "open-loop"
end
function _fb_label(::Type{Traits.ClosedLoopFeedback})
    return "closed-loop"
end
function _fb_label(::Type{Traits.DynClosedLoopFeedback})
    return "dyn-closed-loop"
end

# =============================================================================
# ControlLaw-specific signature helpers
# =============================================================================

"""
    _natural_sig_cl(::Type{FB}, ::Type{TD}, ::Type{VD}) where {FB, TD, VD} -> String

Return the natural call signature for a `ControlLaw` based on its traits.

The arguments depend on the feedback type:
- `OpenLoop`: `u([t][, v])`
- `ClosedLoop`: `u([t, ]x[, v])`
- `DynClosedLoop`: `u([t, ]x, p[, v])`

See also: [`CTBase.Data._uniform_sig_cl`](@ref).
"""
function _natural_sig_cl(
    ::Type{FB}, ::Type{TD}, ::Type{VD}
) where {
    FB<:Traits.AbstractFeedback,TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
}
    args = String[]
    TD === Traits.NonAutonomous && push!(args, "t")
    append!(args, _natural_args_cl(FB))
    VD === Traits.NonFixed && push!(args, "v")
    return "u(" * join(args, ", ") * ")"
end

"""
    _natural_args_cl(::Type{FB}) where {FB} -> Vector{String}

Return the feedback-dependent argument names (excluding `t` and `v`) for the
natural call signature of a `ControlLaw`.

- `OpenLoopFeedback`: empty (no state or costate).
- `ClosedLoopFeedback`: `["x"]`.
- `DynClosedLoopFeedback`: `["x", "p"]`.

See also: [`CTBase.Data._natural_sig_cl`](@ref).
"""
function _natural_args_cl(::Type{Traits.OpenLoopFeedback})
    return String[]
end

function _natural_args_cl(::Type{Traits.ClosedLoopFeedback})
    return ["x"]
end

function _natural_args_cl(::Type{Traits.DynClosedLoopFeedback})
    return ["x", "p"]
end

"""
    _uniform_sig_cl(::Type{FB}) where {FB} -> String

Return the uniform call signature for a `ControlLaw` based on its feedback trait.

- OpenLoop: `u(t, v)` — no state, no costate (open-loop by definition)
- ClosedLoop: `u(t, x, v)` — state but no costate (controlled dynamics flow)
- DynClosedLoop: `u(t, x, p, v)` — costate needed (Hamiltonian flow)

See also: [`CTBase.Data._natural_sig_cl`](@ref).
"""
function _uniform_sig_cl(::Type{Traits.OpenLoopFeedback})
    return "u(t, v)"
end

function _uniform_sig_cl(::Type{Traits.ClosedLoopFeedback})
    return "u(t, x, v)"
end

function _uniform_sig_cl(::Type{Traits.DynClosedLoopFeedback})
    return "u(t, x, p, v)"
end

# =============================================================================
# PseudoHamiltonian-specific signature helpers
# =============================================================================

"""
    _natural_sig_ph(::Type{TD}, ::Type{VD}) where {TD, VD} -> String

Return the natural call signature for a `PseudoHamiltonian` based on its traits.

The arguments always include `x, p, u`, with `t` prepended for non-autonomous
and `v` appended for variable.

See also: [`CTBase.Data._uniform_sig_ph`](@ref).
"""
function _natural_sig_ph(::Type{TD}, ::Type{VD}) where {TD,VD}
    args = String[]
    TD === Traits.NonAutonomous && push!(args, "t")
    push!(args, "x")
    push!(args, "p")
    push!(args, "u")
    VD === Traits.NonFixed && push!(args, "v")
    return "h̃(" * join(args, ", ") * ")"
end

"""
    _uniform_sig_ph() -> String

Return the uniform call signature for a `PseudoHamiltonian`.

The uniform signature always includes all arguments `(t, x, p, u, v)` regardless of traits.

See also: [`CTBase.Data._natural_sig_ph`](@ref).
"""
function _uniform_sig_ph()
    return "h̃(t, x, p, u, v)"
end
