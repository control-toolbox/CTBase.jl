module TestPlottingLabels

using Test: Test
using CTBase: Plotting

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# state (2 comps, split) stacked over control (1 comp, split)
function _fig(; title=nothing)
    t = collect(range(0.0, 2.0, 11))
    px = Plotting.Panel(t, [t t]; title="state", labels=["q", "v"])
    pu = Plotting.Panel(t, reshape(t, :, 1); title="control", labels=["u"])
    root = Plotting.Stacked(
        Plotting.AbstractLayoutNode[
            Plotting.lower(px; layout=:split), Plotting.lower(pu; layout=:split)
        ],
    )
    return Plotting.Figure(root; title=title)
end

_xlabels(fig) = [l.axes.xlabel for l in Plotting.leaves(fig.root)]
_ylabels(fig) = [l.axes.ylabel for l in Plotting.leaves(fig.root)]
_titles(fig) = [l.axes.title for l in Plotting.leaves(fig.root)]

function test_labels()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting label keywords" begin
        Test.@testset "no label keyword: figure unchanged, other kwargs kept" begin
            fig = _fig()
            fig2, rest = Plotting._resolve_labels(fig; color=:red)
            Test.@test _xlabels(fig2) == _xlabels(fig)
            Test.@test fig2.title === nothing
            Test.@test rest == (; color=:red)
        end

        Test.@testset "xlabel only replaces the cells that carry an x label" begin
            fig = _fig()
            before = _xlabels(fig)
            fig2, rest = Plotting._resolve_labels(fig; xlabel="s")
            after = _xlabels(fig2)
            Test.@test rest == NamedTuple()
            Test.@test any(!isempty, before)
            for (b, a) in zip(before, after)
                Test.@test a == (isempty(b) ? "" : "s")
            end
            # titles and y labels are untouched
            Test.@test _titles(fig2) == _titles(fig)
            Test.@test _ylabels(fig2) == _ylabels(fig)
        end

        Test.@testset "title sets, overrides and clears the figure title" begin
            Test.@test Plotting._resolve_labels(_fig(); title="T")[1].title == "T"
            Test.@test Plotting._resolve_labels(_fig(; title="old"); title="T")[1].title ==
                "T"
            Test.@test Plotting._resolve_labels(_fig(; title="old"))[1].title == "old"
            Test.@test Plotting._resolve_labels(_fig(; title="old"); title="")[1].title ===
                nothing
            # cell titles are kept
            Test.@test _titles(Plotting._resolve_labels(_fig(); title="T")[1]) ==
                _titles(_fig())
        end

        Test.@testset "ylabel is not applied and warns" begin
            fig = _fig()
            res = Test.@test_logs (:warn, r"`ylabel` is ignored") Plotting._resolve_labels(
                fig; ylabel="y"
            )
            Test.@test _ylabels(res[1]) == _ylabels(fig)
            Test.@test res[2] == NamedTuple()
            # no warning without ylabel
            Test.@test_logs Plotting._resolve_labels(fig; xlabel="s", title="T")
        end
    end
    return nothing
end

end # module TestPlottingLabels

test_labels() = TestPlottingLabels.test_labels()
