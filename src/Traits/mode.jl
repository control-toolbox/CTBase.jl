"""
$(TYPEDEF)

Abstract base type for mode traits (Point vs Trajectory).

Mode traits encode the integration mode in configuration types, distinguishing
between point-to-point integration (single endpoint evaluation) and trajectory
integration (full time evolution).

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> EndPointMode <: Traits.AbstractModeTrait
true

julia> TrajectoryMode <: Traits.AbstractModeTrait
true

\`\`\`

# Notes
- Point mode indicates integration from a single initial condition to a specific final time
- Trajectory mode indicates integration over a continuous time interval

See also: [`CTBase.Traits.EndPointMode`](@ref), [`CTBase.Traits.TrajectoryMode`](@ref).
"""
abstract type AbstractModeTrait <: AbstractTrait end

"""
$(TYPEDEF)

Trait for point integration mode (single endpoint evaluation).

Used as a type parameter in `AbstractConfig` to indicate point integration,
which computes the solution at a specific final time from a single initial condition.

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> pt = EndPointMode()
EndPointMode()

julia> pt isa Traits.AbstractModeTrait
true

\`\`\`

# Notes
- Point mode configurations store `t0` and `tf` as separate fields
- This mode is suitable for boundary value problems and shooting methods
- The `tspan` accessor returns `(c.t0, c.tf)` for point configurations

See also: [`CTBase.Traits.TrajectoryMode`](@ref), [`CTBase.Traits.AbstractModeTrait`](@ref).
"""
struct EndPointMode <: AbstractModeTrait end

"""
$(TYPEDEF)

Trait for trajectory integration mode (full time evolution).

Used as a type parameter in `AbstractConfig` to indicate trajectory integration,
which computes the full solution trajectory over a continuous time interval.

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> traj = TrajectoryMode()
TrajectoryMode()

julia> traj isa Traits.AbstractModeTrait
true

\`\`\`

# Notes
- Trajectory mode configurations store `tspan` as a tuple field
- This mode is suitable for generating full time evolution and visualization
- The `tspan` accessor returns `c.tspan` directly for trajectory configurations

See also: [`CTBase.Traits.EndPointMode`](@ref), [`CTBase.Traits.AbstractModeTrait`](@ref).
"""
struct TrajectoryMode <: AbstractModeTrait end
