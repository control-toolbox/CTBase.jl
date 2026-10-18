# [Plotting Engine](@id guide-plotting)

```@meta
CurrentModule = CTBase
```

```@setup plot
using Plots: Plots
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
Combinators                   Backend
(Stacked / Paired / Grid)     ├─ Plots.jl  →  CTBasePlots extension
                              └─ Makie.jl  →  CTBaseMakie extension
```

All IR types and transforms live in `src` (no backend dependency). Only the drawing
lives in weak-dependency extensions — `CTBasePlots` for [Plots.jl](https://docs.juliaplots.org)
and `CTBaseMakie` for [Makie.jl](https://docs.makie.org) — each loaded automatically
when its backend package (`Plots`, or `CairoMakie` / `GLMakie`) is available.

## Intermediate Representation

### Series and Decorations

A [`CTBase.Plotting.Series`](@ref) is one plotted curve: `(x, y)` points with an optional label and
a neutral style vocabulary (`color`, `linewidth`, `linestyle`, `alpha`, `seriestype`,
`z_order`). A `backend_kwargs` `NamedTuple` provides an escape hatch for
backend-specific attributes.

```@example plot
using CTBase: CTBase

s = CTBase.Plotting.Series(
    [0.0, 1.0, 2.0],
    [0.0, 1.0, 0.0];
    label="x(t)",
    style=(color=:blue, linewidth=2),
)
```

[`CTBase.Plotting.HLine`](@ref) and [`CTBase.Plotting.VLine`](@ref) are reference lines drawn on top of series
(e.g. box bounds, initial/final time markers).

An [`CTBase.Plotting.Annotation`](@ref) is a text drawn in a cell, for example the label of a
phase. Its abscissa is a data coordinate, but its ordinate is **relative** to the y-axis
range: `0` is the bottom of the axis, `1` its top, and the default `0.92` sits near the
top. The text therefore keeps its place whatever the data. The style accepts `fontsize`,
`color`, `halign` (`:left`, `:center`, `:right`) and `valign` (`:bottom`, `:center`,
`:top`).

```@example plot
a = CTBase.Plotting.Annotation(0.5, "bang"; style=(color=:gray,))
```

Lines and annotations are both [`CTBase.Plotting.Decoration`](@ref)s.

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
- `annotations`: texts attached to the top cell in `:split` (the one with the title),
  or to the single cell in `:group`. Like `vlines`, their abscissae are in the plotted
  time, already normalised when `time=:normalize`.

```@example plot
labelled = CTBase.Plotting.lower(
    panel;
    vlines=[CTBase.Plotting.VLine(1.0)],
    annotations=[
        CTBase.Plotting.Annotation(0.5, "phase 1"),
        CTBase.Plotting.Annotation(1.5, "phase 2"),
    ],
)
```

### Trajectories made of phases

A trajectory computed phase by phase has switching times, at which the state, costate
or control may jump, and a label per phase. Three building blocks turn this structure
into plot data; the case layer reads the switching times, the limits and the labels, and
passes them as plain data:

- [`CTBase.Plotting.splice_jumps`](@ref) inserts the left and right limits at every
  switching time into the samples of a panel, so that a jump is drawn as a vertical
  segment;
- [`CTBase.Plotting.switching_vlines`](@ref) returns the vertical lines at the switching
  times, for the `vlines` of `lower`;
- [`CTBase.Plotting.phase_annotations`](@ref) returns the labels as texts centred on each
  phase, for the `annotations` of `lower`. A phase with an empty label gets no text.

The last two take `time` like `lower`, and return abscissae in the plotted time.

```@example plot
t = collect(range(0.0, 2.0, 21))
x = reshape([s < 1 ? s : s + 1 for s in t], :, 1)     # a jump of +1 at t = 1
xs, data = CTBase.Plotting.splice_jumps(t, x, [1.0], [1.0;;], [2.0;;])
jump_panel = CTBase.Plotting.Panel(xs, data; title="state", labels=["x"])
CTBase.Plotting.lower(
    jump_panel;
    vlines=CTBase.Plotting.switching_vlines(t, [1.0]; style=(linestyle=:dash,)),
    annotations=CTBase.Plotting.phase_annotations(t, [1.0], ["phase 1", "phase 2"]),
)
```

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
in these docs because `make.jl` loads both `Plots` and `CairoMakie` to
produce the examples below, so the `CTBasePlots` and `CTBaseMakie`
extensions are both active.

Once `Plots` is loaded, `render(fig)` produces a Plots.jl plot:

```@example plot
CTBase.Plotting.render(fig)
```

The same `fig` rendered through the Makie backend:

```@example plot
using CairoMakie: CairoMakie
CTBase.Plotting.render(CTBase.Plotting.MakieBackend(), fig)
```

## User Attributes

`render(fig; kwargs...)` and `render!` accept extra keyword arguments. The label
keywords are resolved first, on the IR; the rest are split into **series attributes**
— forwarded to every curve — and **axis attributes** — applied to every cell.

### Labels: `title`, `xlabel`, `ylabel`

The cell labels are computed from the IR, so a label keyword cannot simply be
forwarded to the backend — it would hit every cell. `render` resolves them once on
the backend-agnostic IR (`Plotting._resolve_labels`), so both backends agree:

- `xlabel` replaces the x label of the cells that already carry one (the bottom cell
  of a split panel, the time label of a group cell);
- `title` replaces the overall figure title (an empty string removes it);
- `ylabel` is **not** applied — each cell carries one name per component — and a
  warning suggests changing it after rendering with the backend's own API.

```@example plot
CTBase.Plotting.render(fig; title="Relabelled", xlabel="time")
```

`render!` overlays onto existing axes and leaves them untouched: it warns that
`title`, `xlabel` and `ylabel` are ignored.

### Series vs axis attributes

`legend` and `ylims` are special-cased: a user value overrides the IR default. The
two backends split the remaining keywords differently.

The **Plots backend** (`CTBasePlots._partition_user`) asks Plots itself:
`Plots.attributes(:Series)` is the authoritative set of series-attribute names, so
any kwarg in it goes to the series and everything else to the subplot. A key Plots
does not recognise still reaches Plots, which emits its own warning. Layout keys the
renderer owns (`CTBasePlots._RESERVED_AXES_KEYS`: `subplot`, `legend`, `ylims`,
`titlefont`, `guidefontsize`) are protected so the computed layout survives;
`subplot`, `titlefont` and `guidefontsize` are ignored with a warning.

The **Makie backend** (`CTBaseMakie._partition_user`) has nothing to introspect —
Makie exposes no `attributes(:Series)` analogue — so it carries curated whitelists:
`CTBaseMakie._SERIES_USER_KEYS` (`color`, `linewidth`, `linestyle`, `alpha`,
`marker`, `markersize`, `label`) for series, `CTBaseMakie._AXIS_USER_KEYS` (a fixed
list of `Makie.Axis` constructor keys) plus `legend` / `ylims` for cells, with
`CTBaseMakie._RESERVED_AXES_KEYS` protected. **A kwarg in neither whitelist is
silently dropped** — a bare `Makie.Axis` throws on an unknown keyword, so unknown
keys cannot be forwarded the way Plots tolerates.

For a case layer or a caller this means:

- The portable surface is the neutral style vocabulary (`color`, `linewidth`,
  `linestyle`, `alpha`, `seriestype`, `z_order`) plus `legend`, `ylims`, `title` and
  `xlabel` — these behave identically on both backends.
- A genuinely backend-specific option belongs in a [`CTBase.Plotting.Series`](@ref)
  style's `backend_kwargs` escape hatch, not in a `render` kwarg: only the matching
  backend honours it, and the Makie whitelist would drop it from a `render` call
  anyway.

## Leaf Traversal

[`CTBase.Plotting.leaves`](@ref) returns the `Leaf` nodes of a layout tree in deterministic
depth-first order. This order is the contract for targeting existing cells by
index when overlaying with `render!`.

## Function Reference

| Category | Symbols |
| :--- | :--- |
| IR | [`CTBase.Plotting.Series`](@ref), [`CTBase.Plotting.HLine`](@ref), [`CTBase.Plotting.VLine`](@ref), [`CTBase.Plotting.Annotation`](@ref), [`CTBase.Plotting.Axes`](@ref), [`CTBase.Plotting.Leaf`](@ref), [`CTBase.Plotting.HBox`](@ref), [`CTBase.Plotting.VBox`](@ref), [`CTBase.Plotting.Figure`](@ref), [`CTBase.Plotting.leaves`](@ref) |
| Building blocks | [`CTBase.Plotting.Panel`](@ref), [`CTBase.Plotting.lower`](@ref) |
| Phases | [`CTBase.Plotting.splice_jumps`](@ref), [`CTBase.Plotting.switching_vlines`](@ref), [`CTBase.Plotting.phase_annotations`](@ref) |
| Combinators | [`CTBase.Plotting.Stacked`](@ref), [`CTBase.Plotting.Paired`](@ref), [`CTBase.Plotting.Grid`](@ref) |
| Backend | [`CTBase.Plotting.AbstractPlottingBackend`](@ref), [`CTBase.Plotting.PlotsBackend`](@ref), [`CTBase.Plotting.MakieBackend`](@ref), [`CTBase.Plotting.render`](@ref), [`CTBase.Plotting.render!`](@ref) |

## See Also

- [Exceptions guide](@ref guide-exceptions) — `ExtensionError` when no backend is loaded.
- [Color System](@ref guide-color-system) — the palette used by the text display of the IR types.
