# =============================================================================
# contract.jl — the backend contract (types + stubs live in src).
#
# `render`/`render!` are owned here so any package can call them on the always-
# available `Plotting` types. Backends add methods on their concrete backend type
# from a weak-dependency extension (function ownership pattern). With no backend
# loaded, the fallback throws a structured `ExtensionError` telling the user what
# to load. See ext/CTBasePlots.jl for the Plots methods.
#
# Docstrings deferred (Handbook convention).
# =============================================================================

"""
$(TYPEDEF)

Supertype of rendering backends. A backend adds methods to [`render`](@ref) /
[`render!`](@ref) on its concrete type from a weak-dependency extension; the
fallback here errors when no backend is loaded.
"""
abstract type AbstractPlottingBackend end

"""
$(TYPEDEF)

The [Plots.jl](https://docs.juliaplots.org) backend. The type lives here in `src`;
its [`render`](@ref)/[`render!`](@ref) methods live in the `CTBasePlots`
extension, loaded automatically once `Plots` is available.
"""
struct PlotsBackend <: AbstractPlottingBackend end

# Backend used when a caller does not pass one explicitly.
default_backend() = PlotsBackend()

"""
$(TYPEDSIGNATURES)

Render `fig` into a backend figure. Fallback (no backend loaded) errors with an
`ExtensionError`; a backend extension overrides this on its concrete type.
"""
function render(::AbstractPlottingBackend, ::Figure; kwargs...)
    return throw(Exceptions.ExtensionError(:Plots))
end

"""
$(TYPEDSIGNATURES)

Overlay `fig` onto an existing backend `target`, targeting existing cells by the
deterministic leaf order (see [`leaves`](@ref)).
"""
function render!(::AbstractPlottingBackend, target, ::Figure; kwargs...)
    return throw(Exceptions.ExtensionError(:Plots))
end

# Default-backend conveniences.
render(fig::Figure; kwargs...) = render(default_backend(), fig; kwargs...)
render!(target, fig::Figure; kwargs...) = render!(default_backend(), target, fig; kwargs...)
