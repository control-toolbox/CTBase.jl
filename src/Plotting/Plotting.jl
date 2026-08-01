"""
    Plotting

Generic, domain-free plotting engine for the Control Toolbox.

It manipulates a backend-agnostic intermediate representation (IR): a weighted
tree ([`CTBase.Plotting.Leaf`](@extref)/[`CTBase.Plotting.HBox`](@extref)/[`CTBase.Plotting.VBox`](@extref)) of titled [`CTBase.Plotting.Axes`](@extref)
carrying [`CTBase.Plotting.Series`](@extref) and [`CTBase.Plotting.Decoration`](@extref)s. It knows nothing about
states, controls, costates, trajectories or optimal control — the *case layers*
(CTModels, CTFlows) build the IR and hand it to a backend via [`CTBase.Plotting.render`](@extref).

The IR and all its transforms live here in `src` (no backend dependency); only the
drawing lives in an extension (`CTBasePlots` for Plots.jl). See the design report
in `CTModels.jl/.reports/dev/plot_engine_ctbase_report.md`.

# Public API
- IR: [`CTBase.Plotting.Series`](@extref), [`CTBase.Plotting.HLine`](@extref), [`CTBase.Plotting.VLine`](@extref), [`CTBase.Plotting.Axes`](@extref),
  [`CTBase.Plotting.Leaf`](@extref), [`CTBase.Plotting.HBox`](@extref), [`CTBase.Plotting.VBox`](@extref), [`CTBase.Plotting.Figure`](@extref), [`CTBase.Plotting.leaves`](@extref)
- case-layer building blocks: [`CTBase.Plotting.Panel`](@extref), [`CTBase.Plotting.Stacked`](@extref), [`CTBase.Plotting.Paired`](@extref),
  [`CTBase.Plotting.Grid`](@extref)
- backend contract: [`CTBase.Plotting.AbstractPlottingBackend`](@extref), [`CTBase.Plotting.PlotsBackend`](@extref),
  [`CTBase.Plotting.render`](@extref), [`CTBase.Plotting.render!`](@extref)
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

using DocStringExtensions: TYPEDEF, TYPEDSIGNATURES, TYPEDFIELDS
using ..Exceptions
using ..Core: Core

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
