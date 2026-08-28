# Plotting Engine

```@meta
CurrentModule = CTBase
```

```@setup plot
using Plots
Base.showable(::MIME"image/png", ::Plots.Plot) = false
```

The [`CTBase.Plotting`](@ref) submodule is a generic, domain-free plotting engine.
It manipulates a backend-agnostic **intermediate representation** (IR): a weighted
tree of titled axes carrying series and decorations. The engine knows nothing about
states, controls, costates, or optimal control — case layers (CTModels, CTFlows)
build the IR and hand it to a backend via [`CTBase.Plotting.render`](@ref).

## Architecture Overview

```text
Case layer (CTModels, CTFlows, …)
    │
    │  builds
    ▼
Panel  ──lower──►  IR (Series, Axes, Leaf/HBox/VBox, Figure)
    │                           │
    │                           │  render / render!
    ▼                           ▼
Combinators                   Backend (Plots.jl via CTBasePlots extension)
(Stacked / Paired / Grid)
```

All IR types and transforms live in `src` (no backend dependency). Only the drawing
lives in a weak-dependency extension (`CTBasePlots`, loaded automatically when
`Plots` is available).

## Intermediate Representation

### Series and Decorations

A [`CTBase.Plotting.Series`](@ref) is one plotted curve: `(x, y)` points with an optional label and
a neutral style vocabulary (`color`, `linewidth`, `linestyle`, `alpha`, `seriestype`,
`z_order`). A `backend_kwargs` `NamedTuple` provides an escape hatch for
backend-specific attributes.

```@example plot
using CTBase

s = CTBase.Plotting.Series(
    [0.0, 1.0, 2.0],
    [0.0, 1.0, 0.0];
    label="x(t)",
    style=(color=:blue, linewidth=2),
)
```

[`CTBase.Plotting.HLine`](@ref) and [`CTBase.Plotting.VLine`](@ref) are reference lines drawn on top of series
(e.g. box bounds, initial/final time markers).

### Axes

An [`CTBase.Plotting.Axes`](@ref) is a single drawable cell: one axis system holding a list of
`Series`, optional decorations, labels, and y-limit settings.

```@example plot
ax = CTBase.Plotting.Axes(
    [s];
    title="State",
    xlabel="t",
    ylabel="x",
)
```

The `ylims` field supports:

- `nothing` — backend default
- `(lo, hi)` — fixed limits
- `:auto` — backend auto-scaling
- `:auto_guarded` — auto, but widen near-constant series so the axis does not collapse

### Layout Tree

The layout is a weighted tree with three node types:

| Node | Role |
| :--- | :--- |
| [`CTBase.Plotting.Leaf`](@ref) | A single cell wrapping one `Axes` |
| [`CTBase.Plotting.HBox`](@ref) | Columns side by side (weights = relative widths) |
| [`CTBase.Plotting.VBox`](@ref) | Rows stacked vertically (weights = relative heights) |

```@example plot
leaf1 = CTBase.Plotting.Leaf(ax)
leaf2 = CTBase.Plotting.Leaf(CTBase.Plotting.Axes(
    [CTBase.Plotting.Series([0.0, 1.0], [1.0, 0.0]; label="u(t)")];
    title="Control", xlabel="t", ylabel="u",
))

# Stack state above control
tree = CTBase.Plotting.VBox([leaf1, leaf2])
```

### Figure

A [`CTBase.Plotting.Figure`](@ref) bundles a layout root with optional overall `size` and `title`.
When `size === nothing`, the engine computes a default from the tree shape.

```@example plot
fig = CTBase.Plotting.Figure(tree; title="Solution")
```

## Case-Layer Building Blocks

### Panel

A [`CTBase.Plotting.Panel`](@ref) is the case layer's convenient input unit: a titled group of
components sharing one time grid. It is **not** part of the rendered IR — the
[`CTBase.Plotting.lower`](@ref) step turns it into `Leaf`/`Axes` nodes.

```@example plot
t = collect(0.0:0.1:1.0)
data = hcat(sin.(t), cos.(t))  # (n_times, 2)

panel = CTBase.Plotting.Panel(
    t, data;
    title="State",
    labels=["x₁", "x₂"],
)
```

### Lowering

[`CTBase.Plotting.lower`](@ref) turns a `Panel` into a layout node. Two layouts are available:

- `:split` (default) — one cell per component (ylabel = component name, xlabel on
  the bottom cell only, title on the top cell only, no legend).
- `:group` — one cell with all components overlaid and a legend.

```@example plot
node = CTBase.Plotting.lower(panel; layout=:split)
```

Optional keyword arguments:

- `time`: `:default` (real time) or `:normalize`/`:normalise` (rescale to `[0, 1]`).
- `time_name`: x-axis label for the bottom cell.
- `vlines`: vertical reference lines attached to every cell.
- `hlines`: per-component horizontal reference lines.

### Combinators

Level-2 declarative layout builders operate on already-lowered nodes:

| Combinator | Layout |
| :--- | :--- |
| [`CTBase.Plotting.Stacked`](@ref) | Vertical stack (`VBox`) with auto row weights |
| [`CTBase.Plotting.Paired`](@ref) | Side-by-side (`HBox`) with auto column weights |
| [`CTBase.Plotting.Grid`](@ref) | Rectangular grid of nodes |

With `weights=:auto` (default), each child's weight is its extent along the
combinator's axis — so cells stay uniform in size even when children have different
numbers of rows or columns.

```@example plot
state_node = CTBase.Plotting.lower(panel; layout=:split)
control_panel = CTBase.Plotting.Panel(
    t, reshape(t, :, 1);
    title="Control", labels=["u"],
)
control_node = CTBase.Plotting.lower(control_panel; layout=:split)

# Stack state above control
full = CTBase.Plotting.Stacked([state_node, control_node])
```

## Backend Contract

[`CTBase.Plotting.AbstractPlottingBackend`](@ref) is the supertype for rendering backends.
[`CTBase.Plotting.PlotsBackend`](@ref) is the concrete Plots.jl backend — its `render`/`render!`
methods live in the `CTBasePlots` extension.

[`CTBase.Plotting.MakieBackend`](@ref) is the [Makie.jl](https://docs.makie.org)
backend, at feature parity with the Plots backend; its `render` / `render!` methods
live in the `CTBaseMakie` extension, loaded automatically when `Makie` is available
(for example via `CairoMakie` or `GLMakie`).

[`CTBase.Plotting.render`](@ref) turns a `Figure` into a backend figure. [`CTBase.Plotting.render!`](@ref) overlays
a `Figure` onto an existing backend target, targeting cells by the deterministic
leaf order (see [`CTBase.Plotting.leaves`](@ref)).

Without a backend loaded, the fallback throws an
[`CTBase.Exceptions.ExtensionError`](@ref). This cannot be demonstrated
in these docs because `Plots` is loaded by `make.jl` to produce the
examples below, which causes the `CTBasePlots` extension to be active.

Once `Plots` is loaded, `render(fig)` produces a Plots.jl plot:

```@example plot
CTBase.Plotting.render(fig)
```

The same `fig` rendered through the Makie backend:

```@example plot
using CairoMakie: CairoMakie
CTBase.Plotting.render(CTBase.Plotting.MakieBackend(), fig)
```

## Leaf Traversal

[`CTBase.Plotting.leaves`](@ref) returns the `Leaf` nodes of a layout tree in deterministic
depth-first order. This order is the contract for targeting existing cells by
index when overlaying with `render!`.

## Function Reference

| Category | Symbols |
| :--- | :--- |
| IR | [`CTBase.Plotting.Series`](@ref), [`CTBase.Plotting.HLine`](@ref), [`CTBase.Plotting.VLine`](@ref), [`CTBase.Plotting.Axes`](@ref), [`CTBase.Plotting.Leaf`](@ref), [`CTBase.Plotting.HBox`](@ref), [`CTBase.Plotting.VBox`](@ref), [`CTBase.Plotting.Figure`](@ref), [`CTBase.Plotting.leaves`](@ref) |
| Building blocks | [`CTBase.Plotting.Panel`](@ref), [`CTBase.Plotting.lower`](@ref) |
| Combinators | [`CTBase.Plotting.Stacked`](@ref), [`CTBase.Plotting.Paired`](@ref), [`CTBase.Plotting.Grid`](@ref) |
| Backend | [`CTBase.Plotting.AbstractPlottingBackend`](@ref), [`CTBase.Plotting.PlotsBackend`](@ref), [`CTBase.Plotting.MakieBackend`](@ref), [`CTBase.Plotting.render`](@ref), [`CTBase.Plotting.render!`](@ref) |

## See Also

- [Exceptions guide](exceptions.md) — `ExtensionError` when no backend is loaded.
- [Traits guide](traits.md) — the trait-parameter pattern used by `Interpolant`.
