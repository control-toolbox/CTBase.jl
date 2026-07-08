"""
    Plotting

Generic, domain-free plotting engine for the Control Toolbox.

It manipulates a backend-agnostic intermediate representation (IR): a weighted
tree ([`Leaf`](@ref)/[`HBox`](@ref)/[`VBox`](@ref)) of titled [`Axes`](@ref)
carrying [`Series`](@ref) and [`Decoration`](@ref)s. It knows nothing about
states, controls, costates, trajectories or optimal control — the *case layers*
(CTModels, CTFlows) build the IR and hand it to a backend via [`render`](@ref).

The IR and all its transforms live here in `src` (no backend dependency); only the
drawing lives in an extension (`CTBasePlots` for Plots.jl). See the design report
in `CTModels.jl/.reports/dev/plot_engine_ctbase_report.md`.

# Public API
- IR: [`Series`](@ref), [`HLine`](@ref), [`VLine`](@ref), [`Axes`](@ref),
  [`Leaf`](@ref), [`HBox`](@ref), [`VBox`](@ref), [`Figure`](@ref), [`leaves`](@ref)
- case-layer building blocks: [`Panel`](@ref), [`Stacked`](@ref), [`Paired`](@ref),
  [`Grid`](@ref)
- backend contract: [`AbstractPlottingBackend`](@ref), [`PlotsBackend`](@ref),
  [`render`](@ref), [`render!`](@ref)
"""
module Plotting

# =============================================================================
# Files (all backend-free, live in `src`):
#   - ir.jl          : the IR itself (pure data): Series, HLine/VLine, Axes,
#                      Leaf/HBox/VBox, Figure — plus deterministic leaf traversal.
#   - panel.jl       : Panel (a titled group of components, with its own x grid
#                      and optional per-component style) + replaceable defaults.
#   - combinators.jl : level-2 declarative layout: Stacked / Paired / Grid.
#   - lowering.jl    : Panel/combinator -> Axes/tree (weights, ylims guard, time).
#   - heuristics.jl  : figure-size heuristics driven by the weighted tree.
#   - contract.jl    : AbstractPlottingBackend, PlotsBackend, render/render! (stubs here;
#                      the Plots methods live in ext/CTBasePlots.jl).
#
# Only the drawing lives in the extension. See the design report in
# CTModels.jl/.reports/dev/plot_engine_ctbase_report.md.
# =============================================================================

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES, TYPEDFIELDS
import CTBase.Exceptions

include(joinpath(@__DIR__, "ir.jl"))
include(joinpath(@__DIR__, "panel.jl"))
include(joinpath(@__DIR__, "combinators.jl"))
include(joinpath(@__DIR__, "lowering.jl"))
include(joinpath(@__DIR__, "heuristics.jl"))
include(joinpath(@__DIR__, "contract.jl"))

# --- IR ----------------------------------------------------------------------
export Series, HLine, VLine, Axes
export AbstractLayoutNode, Leaf, HBox, VBox, Figure
export leaves

# --- case-layer building blocks ----------------------------------------------
export Panel
export Stacked, Paired, Grid

# --- backend contract --------------------------------------------------------
export AbstractPlottingBackend, PlotsBackend
export render, render!

end # module Plotting
