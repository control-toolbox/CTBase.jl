# =============================================================================
# Colours shared by the case layers (CTModels, CTFlows) and the backends.
#
# A colour given as an integer is an index into the palette of the backend, and the
# two palettes differ (Plots cycles over a longer list than Makie's seven colours): the
# same index draws two unrelated colours. A role that must look the same everywhere is
# therefore given as a concrete colour, from here.
# =============================================================================

"""
    COLORS

Concrete colours of the elements drawn around the data, the same in every backend.

- `bound`: the bounds of a box constraint, drawn as horizontal lines;
- `time`: the initial and final times, drawn as vertical lines;
- `phase_label`: the labels of the phases of a trajectory (see
  [`CTBase.Plotting.phase_annotations`](@extref)).

The colour of the curves is not set here: each backend gives the successive curves the
colours of its own palette, and the user can override it with `color=`.

A colour given as an integer is an index into the palette of the backend, and the
palettes differ from one backend to the other: use an entry of `COLORS` for a colour
that must look the same everywhere.
"""
const COLORS = (bound="#dd65b6", time=:black, phase_label=:gray30)
