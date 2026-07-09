module TestPlottingContract

using Test: Test
import CTBase.Plotting
import CTBase.Exceptions
using Plots: Plots

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Fake backend at module top level (Handbook: fake types never inside functions).
# Having no specific render method, it hits the abstract fallback -> ExtensionError,
# which is exactly the "no backend loaded" behaviour, testable with Plots present.
struct DummyBackend <: Plotting.AbstractPlottingBackend end

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
    end
    return nothing
end

end # module TestPlottingContract

test_contract() = TestPlottingContract.test_contract()
