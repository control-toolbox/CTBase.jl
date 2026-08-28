module TestPlottingContractMakie

# =============================================================================
# Contract tests for the Makie backend (CTBaseMakie extension).
#
# Loaded with CairoMakie so `Makie` is present and the extension is active.
# The IR itself is tested in test_ir / test_lowering; here we check that
# `Plotting.render(MakieBackend(), fig)` turns the weighted tree into a laid-out
# `Makie.Figure` with the right axes, weights, size, title, series types,
# decorations and forwarded attributes, that `render!` overlays onto an existing
# figure, and that an unknown backend errors as specified. Parity target:
# test_contract.jl (the Plots backend) on the same `_figure()` IR.
# =============================================================================

using Test: Test
using CTBase: Plotting
using CTBase: Exceptions
using CairoMakie: CairoMakie
using CairoMakie: Makie

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Fake backend at module top level (Handbook: fake types never inside functions).
struct DummyBackend <: Plotting.AbstractPlottingBackend end

# state (2 comps) stacked over control (1 comp), decorated — same shape as
# test_contract.jl so the two backends are compared on the same IR.
function _figure(; title=nothing)
    t = collect(range(0.0, 2.0, 51))
    px = Plotting.Panel(t, [(t .^ 2) ./ 2 t]; title="state", labels=["q", "v"])
    pu = Plotting.Panel(
        t,
        reshape([x < 1 ? 1.0 : -1.0 for x in t], :, 1);
        title="control",
        labels=["u"],
        style=(seriestype=:steppost,),
    )
    nx = Plotting.lower(
        px; layout=:split, vlines=[Plotting.VLine(0.0), Plotting.VLine(2.0)]
    )
    nu = Plotting.lower(
        pu; layout=:split, hlines=[[Plotting.HLine(-1.0), Plotting.HLine(1.0)]]
    )
    root = Plotting.Stacked(Plotting.AbstractLayoutNode[nx, nu])
    return Plotting.Figure(root; title=title)
end

_axes(f) = [x for x in f.content if x isa Makie.Axis]
_n_axes(f) = length(_axes(f))
_n_legends(f) = count(x -> x isa Makie.Legend, f.content)
_n_labels(f) = count(x -> x isa Makie.Label, f.content)
_count_plots(axis, ::Type{T}) where {T} = count(p -> p isa T, axis.scene.plots)

function test_contract_makie()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting Makie backend contract" begin
        Test.@testset "MakieBackend is a registered backend type" begin
            Test.@test Plotting.MakieBackend <: Plotting.AbstractPlottingBackend
            Test.@test isdefined(Plotting, :MakieBackend)
        end

        Test.@testset "render produces a Makie.Figure with one axis per leaf" begin
            fig = _figure()
            f = Plotting.render(Plotting.MakieBackend(), fig)
            Test.@test f isa Makie.Figure
            Test.@test _n_axes(f) == Plotting.n_leaves(fig)   # 2 state + 1 control
        end

        Test.@testset "group / paired / grid layouts" begin
            t = collect(range(0.0, 1.0, 11))
            px = Plotting.Panel(t, [t 2t]; labels=["a", "b"])
            pu = Plotting.Panel(t, reshape(t, :, 1); labels=["u"])
            grid = Plotting.Grid(
                reshape(
                    Plotting.AbstractLayoutNode[
                        Plotting.lower(px; layout=:group), Plotting.lower(pu; layout=:group)
                    ],
                    1,
                    2,
                ),
            )
            Test.@test _n_axes(
                Plotting.render(Plotting.MakieBackend(), Plotting.Figure(grid))
            ) == 2
            paired = Plotting.Paired(
                Plotting.lower(px; layout=:split), Plotting.lower(px; layout=:split)
            )
            Test.@test _n_axes(
                Plotting.render(Plotting.MakieBackend(), Plotting.Figure(paired))
            ) == 4
        end

        Test.@testset "weighted rows map to Makie.Auto weights" begin
            t = collect(range(0.0, 1.0, 6))
            a = Plotting.lower(
                Plotting.Panel(t, reshape(t, :, 1); labels=["a"]); layout=:split
            )
            b = Plotting.lower(
                Plotting.Panel(t, reshape(t, :, 1); labels=["b"]); layout=:split
            )
            root = Plotting.VBox(Plotting.AbstractLayoutNode[a, b], [3.0, 1.0])
            f = Plotting.render(Plotting.MakieBackend(), Plotting.Figure(root))
            gl = only(Makie.GridLayoutBase.contents(f.layout[1, 1]; exact=true))
            Test.@test all(s -> s isa Makie.GridLayoutBase.Auto, gl.rowsizes)
            ratios = Float64[s.ratio for s in gl.rowsizes]   # Auto(trydetermine, ratio)
            Test.@test ratios[1] / ratios[2] ≈ 3.0
        end

        Test.@testset "figure size: heuristic and override" begin
            fig = _figure()
            f = Plotting.render(Plotting.MakieBackend(), fig)
            Test.@test size(f.scene) == Plotting.default_size(fig)
            t = collect(range(0.0, 1.0, 11))
            p = Plotting.Panel(t, [t 2t]; labels=["a", "b"])
            over = Plotting.Figure(Plotting.lower(p; layout=:split); size=(900, 400))
            Test.@test size(Plotting.render(Plotting.MakieBackend(), over).scene) ==
                (900, 400)
        end

        Test.@testset "figure title adds a spanning Label" begin
            Test.@test _n_labels(Plotting.render(Plotting.MakieBackend(), _figure())) == 0
            Test.@test _n_labels(
                Plotting.render(Plotting.MakieBackend(), _figure(; title="min-time"))
            ) == 1
        end

        Test.@testset "group layout draws a legend" begin
            t = collect(range(0.0, 1.0, 11))
            p = Plotting.Panel(t, [t 2t]; labels=["a", "b"])
            f = Plotting.render(
                Plotting.MakieBackend(), Plotting.Figure(Plotting.lower(p; layout=:group))
            )
            Test.@test _n_legends(f) == 1
        end

        Test.@testset "ylims guard pins a constant series" begin
            t = collect(range(0.0, 1.0, 11))
            p = Plotting.Panel(t, reshape(fill(2.0, length(t)), :, 1); labels=["c"])
            f = Plotting.render(
                Plotting.MakieBackend(), Plotting.Figure(Plotting.lower(p; layout=:split))
            )
            axis = first(x for x in f.content if x isa Makie.Axis)
            Test.@test axis.limits[][2] !== nothing            # y-range was pinned
        end

        Test.@testset "series style reaches the Lines plot" begin
            t = collect(range(0.0, 1.0, 11))
            s = Plotting.Series(t, t; style=(color=:red, linewidth=3, linestyle=:dash))
            ax = Plotting.Axes([s]; title="x")
            f = Plotting.render(Plotting.MakieBackend(), Plotting.Figure(Plotting.Leaf(ax)))
            line = first(
                pl for pl in first(x for x in f.content if x isa Makie.Axis).scene.plots if
                pl isa Makie.Lines
            )
            Test.@test line.linewidth[] == 3
            Test.@test line.linestyle[] !== nothing        # :dash expands to a dash pattern
        end

        Test.@testset "steppost and scatter series map to Stairs / Scatter" begin
            # the control panel of `_figure()` is `seriestype=:steppost`
            f = Plotting.render(Plotting.MakieBackend(), _figure())
            ctrl = _axes(f)[3]                              # 2 state cells, then control
            Test.@test _count_plots(ctrl, Makie.Stairs) == 1
            Test.@test _count_plots(ctrl, Makie.Lines) == 0
            t = collect(range(0.0, 1.0, 11))
            sc = Plotting.Series(t, t; style=(seriestype=:scatter,))
            g = Plotting.render(
                Plotting.MakieBackend(), Plotting.Figure(Plotting.Leaf(Plotting.Axes([sc])))
            )
            Test.@test _count_plots(_axes(g)[1], Makie.Scatter) == 1
        end

        Test.@testset "decorations are drawn as hlines / vlines" begin
            f = Plotting.render(Plotting.MakieBackend(), _figure())
            axs = _axes(f)
            # each state cell carries the two shared VLines
            Test.@test _count_plots(axs[1], Makie.VLines) == 2
            Test.@test _count_plots(axs[2], Makie.VLines) == 2
            # the control cell carries the two HLines
            Test.@test _count_plots(axs[3], Makie.HLines) == 2
        end

        Test.@testset "user kwargs: series vs axis attributes" begin
            fig = _figure()
            Test.@test Plotting.render(Plotting.MakieBackend(), fig; color=:green) isa
                Makie.Figure
            # an unknown kwarg is dropped, not an error
            Test.@test Plotting.render(
                Plotting.MakieBackend(), fig; color=3, bins=:auto
            ) isa Makie.Figure
            # series color and label reach the Lines plot
            g = Plotting.render(Plotting.MakieBackend(), fig; color=:red, label="sol")
            line = first(p for p in _axes(g)[1].scene.plots if p isa Makie.Lines)
            Test.@test line.color[] == Makie.to_color(:red)
            Test.@test line.label[] == "sol"
            # an axis attribute reaches every cell
            h = Plotting.render(Plotting.MakieBackend(), fig; ygridvisible=false)
            Test.@test all(ax -> ax.ygridvisible[] == false, _axes(h))
            # a user `label` on a legend-less :split figure turns the legend on
            Test.@test _n_legends(Plotting.render(Plotting.MakieBackend(), _figure())) == 0
            Test.@test _n_legends(
                Plotting.render(Plotting.MakieBackend(), _figure(); label="sol")
            ) >= 1
        end

        Test.@testset "render! overlay keeps axis count and targets by leaf order" begin
            fig = _figure()
            f = Plotting.render(Plotting.MakieBackend(), fig)
            n = _n_axes(f)
            nlines = _count_plots(_axes(f)[1], Makie.Lines)
            out = Plotting.render!(
                Plotting.MakieBackend(), f, _figure(); color=1, linestyle=:dash
            )
            Test.@test out === f
            Test.@test _n_axes(f) == n                       # no new axes
            Test.@test _count_plots(_axes(f)[1], Makie.Lines) == nlines + 1
        end

        Test.@testset "render! fills an empty figure as if by render" begin
            f = Makie.Figure()
            Plotting.render!(Plotting.MakieBackend(), f, _figure())
            Test.@test _n_axes(f) == Plotting.n_leaves(_figure())
        end

        Test.@testset "unknown backend still errors (guards the fallback refactor)" begin
            Test.@test_throws Exceptions.ExtensionError Plotting.render(
                DummyBackend(), _figure()
            )
            Test.@test_throws Exceptions.ExtensionError Plotting.render!(
                DummyBackend(), nothing, _figure()
            )
        end
    end
    return nothing
end

end # module TestPlottingContractMakie

test_contract_makie() = TestPlottingContractMakie.test_contract_makie()
