# =============================================================================
# contract.jl — the backend contract (types + stubs live in src).
#
# `render`/`render!` are owned here so any package can call them on the always-
# available `Plotting` types. Backends add methods on their concrete backend type
# from a weak-dependency extension (function ownership pattern). With no backend
# loaded, the fallback throws a structured `ExtensionError` telling the user what
# to load. See ext/CTBasePlots.jl for the Plots methods.
# =============================================================================

"""
$(TYPEDEF)

Supertype of rendering backends. A backend adds methods to [`CTBase.Plotting.render`](@extref) /
[`CTBase.Plotting.render!`](@extref) on its concrete type from a weak-dependency extension; the
fallback here errors when no backend is loaded.
"""
abstract type AbstractPlottingBackend end

"""
$(TYPEDEF)

The [Plots.jl](https://docs.juliaplots.org) backend. The type lives here in `src`;
its [`CTBase.Plotting.render`](@extref)/[`CTBase.Plotting.render!`](@extref) methods live in the `CTBasePlots`
extension, loaded automatically once `Plots` is available.
"""
struct PlotsBackend <: AbstractPlottingBackend end

"""
$(TYPEDEF)

The [Makie.jl](https://docs.makie.org) backend, at feature parity with
[`CTBase.Plotting.PlotsBackend`](@extref). The type lives here in `src`; its
[`CTBase.Plotting.render`](@extref) / [`CTBase.Plotting.render!`](@extref) methods live in the
`CTBaseMakie` extension, loaded automatically once `Makie` is available (e.g. via
`CairoMakie` / `GLMakie`).
"""
struct MakieBackend <: AbstractPlottingBackend end

"""
$(TYPEDSIGNATURES)

Return the default rendering backend used when a caller does not pass one explicitly.
Currently returns [`CTBase.Plotting.PlotsBackend`](@extref).
"""
default_backend() = PlotsBackend()

"""
$(TYPEDSIGNATURES)

Return the weak-dependency symbol a backend needs loaded, used to build the
`ExtensionError` thrown by the no-backend fallback.
"""
_weakdep(::AbstractPlottingBackend) = :Plots
_weakdep(::PlotsBackend) = :Plots
_weakdep(::MakieBackend) = :Makie

"""
$(TYPEDSIGNATURES)

Render `fig` into a backend figure. Fallback (backend extension not loaded) errors
with an `ExtensionError`; a backend extension overrides this on its concrete type.
"""
function render(b::AbstractPlottingBackend, ::Figure; kwargs...)
    return throw(Exceptions.ExtensionError(_weakdep(b)))
end

"""
$(TYPEDSIGNATURES)

Overlay `fig` onto an existing backend `target`, targeting existing cells by the
deterministic leaf order (see [`CTBase.Plotting.leaves`](@extref)).
"""
function render!(b::AbstractPlottingBackend, target, ::Figure; kwargs...)
    return throw(Exceptions.ExtensionError(_weakdep(b)))
end

# Default-backend conveniences.
render(fig::Figure; kwargs...) = render(default_backend(), fig; kwargs...)
render!(target, fig::Figure; kwargs...) = render!(default_backend(), target, fig; kwargs...)
