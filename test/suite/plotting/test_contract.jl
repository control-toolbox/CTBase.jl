module TestPlottingContract

using Test: Test
using CTBase: Plotting
using CTBase: Exceptions
using Plots: Plots

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Fake backend at module top level (TST3: fake types never inside functions).
# Having no specific render method, it hits the abstract fallback -> ExtensionError,
# which is exactly the "no backend loaded" behaviour, testable with Plots present.
struct DummyBackend <: Plotting.AbstractPlottingBackend end
# A decoration the backend cannot draw.
struct FakeDecoration <: Plotting.AbstractDecoration end

# Build a small figure: state (2 comps) stacked over control (1 comp), decorated.
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

function test_contract()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting backend contract" begin
        Test.@testset "a decoration the backend cannot draw -> NotImplemented" begin
            ax = Plotting.Axes(
                [Plotting.Series([0.0, 1.0], [0.0, 1.0])]; decorations=[FakeDecoration()]
            )
            fig = Plotting.Figure(Plotting.Leaf(ax))
            Test.@test_throws Exceptions.NotImplemented Plotting.render(Plotting.PlotsBackend(), fig)
        end

        Test.@testset "unknown backend -> ExtensionError" begin
            fig = _figure()
            Test.@test_throws Exceptions.ExtensionError Plotting.render(DummyBackend(), fig)
            Test.@test_throws Exceptions.ExtensionError Plotting.render!(
                DummyBackend(), nothing, fig
            )
        end

        Test.@testset "render produces a Plots.Plot with the right cells" begin
            fig = _figure()
            plt = Plotting.render(fig)
            Test.@test plt isa Plots.Plot
            Test.@test length(plt.subplots) == 3            # 2 state + 1 control
            Test.@test plt.attr[:size] == (600, 600)        # heuristic
            # explicit backend and default backend agree on cell count
            Test.@test length(Plotting.render(Plotting.PlotsBackend(), fig).subplots) == 3
        end

        Test.@testset "figure title adds a title subplot" begin
            plt = Plotting.render(_figure(; title="min-time"))
            Test.@test length(plt.subplots) == 4            # 3 cells + title subplot
        end

        Test.@testset "size override" begin
            t = collect(range(0.0, 1.0, 11))
            p = Plotting.Panel(t, [t 2t]; labels=["a", "b"])
            fig = Plotting.Figure(Plotting.lower(p; layout=:split); size=(900, 400))
            Test.@test Plotting.render(fig).attr[:size] == (900, 400)
        end

        Test.@testset "group and paired layouts" begin
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
            Test.@test length(Plotting.render(Plotting.Figure(grid)).subplots) == 2
            paired = Plotting.Paired(
                Plotting.lower(px; layout=:split), Plotting.lower(px; layout=:split)
            )
            Test.@test length(Plotting.render(Plotting.Figure(paired)).subplots) == 4
        end

        Test.@testset "render! overlay keeps cell count and targets by leaf order" begin
            fig = _figure()
            plt = Plotting.render(fig)
            n = length(plt.subplots)
            out = Plotting.render!(plt, _figure(); color=1, linestyle=:dash)
            Test.@test out === plt
            Test.@test length(plt.subplots) == n            # no new subplots
        end

        Test.@testset "render! warns that label keywords are ignored (#569)" begin
            plt = Plotting.render(_figure())
            before = [sp[:xaxis][:guide] for sp in plt.subplots]
            Test.@test_logs (:warn, r"`title`, `xlabel` are ignored by `render!`") Plotting.render!(
                plt, _figure(); xlabel="s", title="T"
            )
            Test.@test [sp[:xaxis][:guide] for sp in plt.subplots] == before
            # no warning without a label keyword
            Test.@test_logs Plotting.render!(plt, _figure(); color=1)
        end

        Test.@testset "user kwargs: series vs subplot attributes" begin
            fig = _figure()
            # a mix of series (`color`) and non-series (`size`, `bins`) attributes must
            # render without error
            Test.@test Plotting.render(fig; color=3, size=(900, 600), bins=:auto) isa
                Plots.Plot
        end

        Test.@testset "user subplot attributes reach the cells (legend override)" begin
            # a :split figure has the legend off and empty series labels by default; a
            # user `legend`/`label` must override that on every cell.
            fig = _figure()
            plt = Plotting.render(fig; label="sol", legend=:bottomright, grid=false)
            for sp in plt.subplots
                Test.@test sp[:legend_position] == :bottomright
            end
            # the data series carries the user label (decorations keep an empty label)
            Test.@test any(s -> s[:label] == "sol", plt.subplots[1].series_list)
            Test.@test any(s -> s[:label] == "", plt.subplots[1].series_list)
        end

        Test.@testset "user xlabel / title are honoured, ylabel warns (#569)" begin
            fig = _figure()
            guide(sp) = sp[:xaxis][:guide]
            plain = Plotting.render(fig)
            # the x label of the cells carrying one is replaced, the others stay empty
            plt = Plotting.render(fig; xlabel="s")
            for (sp0, sp) in zip(plain.subplots, plt.subplots)
                Test.@test guide(sp) == (isempty(guide(sp0)) ? "" : "s")
            end
            Test.@test any(sp -> guide(sp) == "s", plt.subplots)
            # a user title becomes the overall title (extra title subplot)
            ptitle = Plotting.render(fig; title="T")
            Test.@test length(ptitle.subplots) == 4
            Test.@test ptitle.attr[:plot_title] == "T"
            # ylabel is ignored with a warning
            plt_y = Test.@test_logs (:warn, r"`ylabel` is ignored") Plotting.render(
                fig; ylabel="y"
            )
            Test.@test [sp[:yaxis][:guide] for sp in plt_y.subplots] == [sp[:yaxis][:guide] for sp in plain.subplots]
            # renderer-owned keys warn too
            Test.@test_logs (:warn, r"`titlefont`") Plotting.render(fig; titlefont=10)
            # no warning when nothing is ignored
            Test.@test_logs Plotting.render(fig; xlabel="s", title="T")
        end

        Test.@testset "a user label turns the legend on for a :split cell" begin
            # :split cells have the legend off by default; a user `label` makes it
            # visible so overlaid solutions can be told apart.
            fig = _figure()
            plain = Plotting.render(fig)
            Test.@test all(sp -> sp[:legend_position] === :none, plain.subplots)
            labelled = Plotting.render(fig; label="sol")
            Test.@test all(sp -> sp[:legend_position] !== :none, labelled.subplots)
        end

        Test.@testset "annotations: text at a relative height of the cell" begin
            t = collect(range(0.0, 2.0, 21))
            texts = [
                Plotting.Annotation(0.5, "bang"),
                Plotting.Annotation(
                    1.5,
                    "singular";
                    y=0.25,
                    style=(fontsize=12, color=:red, halign=:left, valign=:top),
                ),
            ]
            # fixed y-limits: the relative ordinate maps onto them exactly
            p = Plotting.Panel(t, [t 2t]; labels=["a", "b"])
            node = Plotting.lower(p; layout=:split, annotations=texts)
            plt = Plotting.render(Plotting.Figure(node); ylims=(-1.0, 3.0))
            ann = plt.subplots[1][:annotations]
            Test.@test length(ann) == 2
            Test.@test isempty(plt.subplots[2][:annotations])   # top cell only
            x1, y1, t1 = ann[1]
            Test.@test x1 ≈ 0.5
            Test.@test y1 ≈ -1.0 + 0.92 * 4.0
            Test.@test t1.str == "bang"
            # default style: the shared font size, black, centred
            Test.@test t1.font.pointsize == Plotting._ANNOTATION_FONT_SIZE
            Test.@test t1.font.halign === :hcenter
            Test.@test t1.font.valign === :vcenter
            x2, y2, t2 = ann[2]
            Test.@test (x2, y2) == (1.5, -1.0 + 0.25 * 4.0)
            Test.@test t2.font.pointsize == 12
            Test.@test t2.font.halign === :left
            Test.@test t2.font.valign === :top
            Test.@test t2.font.color == Plots.parse(Plots.Colorant, "red")
            # automatic y-limits: the text stays inside the final y-range
            plt_auto = Plotting.render(Plotting.Figure(node))
            lo, hi = Plots.ylims(plt_auto.subplots[1])
            _, ya, _ = plt_auto.subplots[1][:annotations][1]
            Test.@test ya ≈ lo + 0.92 * (hi - lo)
            Test.@test lo < ya < hi
            # room above the data (t ∈ [0, 2], so the first cell's data is in [0, 2])
            Test.@test hi ≥ 2.0 + 0.2 * 2.0 - 1e-8
            Test.@test ya > 2.0                     # the text is above the curves
            # no annotation, automatic limits: no extra room
            plain_hi = Plots.ylims(Plotting.render(Plotting.Figure(Plotting.lower(p))).subplots[1])[2]
            Test.@test plain_hi < 2.0 + 0.2 * 2.0
            # render! overlay also draws them, without new subplots
            n = length(plt_auto.subplots)
            Plotting.render!(plt_auto, Plotting.Figure(node))
            Test.@test length(plt_auto.subplots) == n
            Test.@test length(plt_auto.subplots[1][:annotations]) == 4
            # no annotation: none drawn
            plain = Plotting.render(_figure())
            Test.@test all(sp -> isempty(sp[:annotations]), plain.subplots)
        end
    end
    return nothing
end

end # module TestPlottingContract

test_contract() = TestPlottingContract.test_contract()
