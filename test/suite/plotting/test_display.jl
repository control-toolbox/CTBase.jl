module TestPlottingDisplay

using Test: Test
import CTBase.Plotting

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# Helper: capture show output as a string (no color)
_sprint_show(x) = sprint(show, x)
_sprint_plain(x) = sprint(show, MIME"text/plain"(), x)

# Helper builders
_series(label="x(t)", n=3) = Plotting.Series(
    collect(Float64, 1:n), collect(Float64, 1:n); label=label,
)
_axes(; title="State", xlabel="t", ylabel="x", nseries=1) = Plotting.Axes(
    [_series("s$i") for i in 1:nseries]; title=title,
    xlabel=xlabel, ylabel=ylabel,
)
_leaf(; title="State") = Plotting.Leaf(_axes(; title=title))

function test_display()
    Test.@testset "Plotting Display" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ========================================================================
        # UNIT TESTS — compact show (one-line)
        # ========================================================================

        Test.@testset "Unit" begin
            Test.@testset "Series compact" begin
                s = _series("x(t)", 3)
                out = _sprint_show(s)
                Test.@test occursin("Series", out)
                Test.@test occursin("x(t)", out)
                Test.@test occursin("3", out)
                Test.@test occursin("pts", out)
            end

            Test.@testset "Series compact — single point" begin
                s = _series("pt", 1)
                out = _sprint_show(s)
                Test.@test occursin("1", out)
                Test.@test occursin("pts", out)
            end

            Test.@testset "HLine compact" begin
                h = Plotting.HLine(1.0)
                out = _sprint_show(h)
                Test.@test occursin("HLine", out)
                Test.@test occursin("1.0", out)
            end

            Test.@testset "VLine compact" begin
                v = Plotting.VLine(2.5)
                out = _sprint_show(v)
                Test.@test occursin("VLine", out)
                Test.@test occursin("2.5", out)
            end

            Test.@testset "Axes compact" begin
                ax = _axes(; title="State", nseries=2)
                out = _sprint_show(ax)
                Test.@test occursin("Axes", out)
                Test.@test occursin("State", out)
                Test.@test occursin("2", out)
                Test.@test occursin("series", out)
            end

            Test.@testset "Leaf compact" begin
                leaf = _leaf()
                out = _sprint_show(leaf)
                Test.@test occursin("Leaf", out)
                Test.@test occursin("Axes", out)
            end

            Test.@testset "HBox compact" begin
                box = Plotting.HBox([_leaf(), _leaf()])
                out = _sprint_show(box)
                Test.@test occursin("HBox", out)
                Test.@test occursin("2", out)
                Test.@test occursin("children", out)
            end

            Test.@testset "VBox compact" begin
                box = Plotting.VBox([_leaf(), _leaf()])
                out = _sprint_show(box)
                Test.@test occursin("VBox", out)
                Test.@test occursin("2", out)
                Test.@test occursin("children", out)
            end

            Test.@testset "Figure compact" begin
                fig = Plotting.Figure(
                    Plotting.VBox([_leaf()]); title="Solution",
                )
                out = _sprint_show(fig)
                Test.@test occursin("Figure", out)
                Test.@test occursin("Solution", out)
                Test.@test occursin("VBox", out)
            end

            Test.@testset "Figure compact — no title" begin
                fig = Plotting.Figure(Plotting.VBox([_leaf()]))
                out = _sprint_show(fig)
                Test.@test occursin("Figure", out)
                Test.@test occursin("VBox", out)
            end

            Test.@testset "Panel compact" begin
                t = collect(0.0:0.1:1.0)
                data = hcat(sin.(t), cos.(t))
                panel = Plotting.Panel(t, data; title="State")
                out = _sprint_show(panel)
                Test.@test occursin("Panel", out)
                Test.@test occursin("State", out)
                Test.@test occursin("2", out)
                Test.@test occursin("components", out)
                Test.@test occursin("11", out)
                Test.@test occursin("pts", out)
            end
        end

        # ========================================================================
        # UNIT TESTS — pretty show (text/plain, tree-style)
        # ========================================================================

        Test.@testset "Unit — pretty" begin
            Test.@testset "Series pretty" begin
                s = Plotting.Series(
                    [0.0, 1.0, 2.0], [0.0, 1.0, 0.0];
                    label="x(t)", style=(color=:blue, linewidth=2),
                )
                out = _sprint_plain(s)
                Test.@test occursin("Series", out)
                Test.@test occursin("x(t)", out)
                Test.@test occursin("3", out)
                Test.@test occursin("points", out)
                Test.@test occursin("style", out)
                Test.@test occursin("color", out)
            end

            Test.@testset "Series pretty — single point" begin
                s = _series("pt", 1)
                out = _sprint_plain(s)
                Test.@test occursin("1", out)
                Test.@test occursin("point)", out)
                Test.@test !occursin("points)", out)
            end

            Test.@testset "HLine pretty" begin
                h = Plotting.HLine(1.0; style=(color=:red,))
                out = _sprint_plain(h)
                Test.@test occursin("HLine", out)
                Test.@test occursin("1.0", out)
                Test.@test occursin("style", out)
            end

            Test.@testset "VLine pretty" begin
                v = Plotting.VLine(0.0)
                out = _sprint_plain(v)
                Test.@test occursin("VLine", out)
                Test.@test occursin("0.0", out)
            end

            Test.@testset "Axes pretty — series and labels" begin
                ax = Plotting.Axes(
                    [_series("x(t)", 3), _series("y(t)", 2)];
                    title="State", xlabel="t", ylabel="x",
                )
                out = _sprint_plain(ax)
                Test.@test occursin("Axes", out)
                Test.@test occursin("State", out)
                Test.@test occursin("2", out)
                Test.@test occursin("series", out)
                Test.@test occursin("x(t)", out)
                Test.@test occursin("y(t)", out)
                Test.@test occursin("xlabel", out)
                Test.@test occursin("ylabel", out)
            end

            Test.@testset "Axes pretty — decorations" begin
                ax = Plotting.Axes(
                    [_series("s1", 1)];
                    title="Titled",
                    decorations=[Plotting.HLine(1.0), Plotting.VLine(0.0)],
                )
                out = _sprint_plain(ax)
                Test.@test occursin("HLine", out)
                Test.@test occursin("VLine", out)
            end

            Test.@testset "Leaf pretty" begin
                leaf = _leaf(; title="State")
                out = _sprint_plain(leaf)
                Test.@test occursin("Leaf", out)
                Test.@test occursin("Axes", out)
                Test.@test occursin("State", out)
                Test.@test occursin("└─", out)
            end

            Test.@testset "VBox pretty — tree structure" begin
                tree = Plotting.VBox([_leaf(; title="A"), _leaf(; title="B")])
                out = _sprint_plain(tree)
                Test.@test occursin("VBox", out)
                Test.@test occursin("2", out)
                Test.@test occursin("children", out)
                Test.@test occursin("Leaf", out)
                Test.@test occursin("A", out)
                Test.@test occursin("B", out)
                Test.@test occursin("├─", out)
                Test.@test occursin("└─", out)
            end

            Test.@testset "HBox pretty — tree structure" begin
                box = Plotting.HBox([_leaf(; title="L"), _leaf(; title="R")])
                out = _sprint_plain(box)
                Test.@test occursin("HBox", out)
                Test.@test occursin("L", out)
                Test.@test occursin("R", out)
            end

            Test.@testset "Figure pretty — full tree" begin
                leaf1 = _leaf(; title="State")
                leaf2 = _leaf(; title="Control")
                fig = Plotting.Figure(
                    Plotting.VBox([leaf1, leaf2]); title="Solution",
                )
                out = _sprint_plain(fig)
                Test.@test occursin("Figure", out)
                Test.@test occursin("Solution", out)
                Test.@test occursin("VBox", out)
                Test.@test occursin("State", out)
                Test.@test occursin("Control", out)
            end

            Test.@testset "Figure pretty — size shown" begin
                fig = Plotting.Figure(
                    _leaf(); title="Fig", size=(800, 600),
                )
                out = _sprint_plain(fig)
                Test.@test occursin("size", out)
                Test.@test occursin("800", out)
            end

            Test.@testset "Panel pretty — labels shown" begin
                t = collect(0.0:0.1:1.0)
                data = hcat(sin.(t), cos.(t))
                panel = Plotting.Panel(t, data; title="State", labels=["x1", "x2"])
                out = _sprint_plain(panel)
                Test.@test occursin("Panel", out)
                Test.@test occursin("State", out)
                Test.@test occursin("2", out)
                Test.@test occursin("components", out)
                Test.@test occursin("11", out)
                Test.@test occursin("points", out)
                Test.@test occursin("x1", out)
                Test.@test occursin("x2", out)
            end

            Test.@testset "Panel pretty — no empty labels" begin
                t = collect(0.0:0.1:1.0)
                data = hcat(sin.(t), cos.(t))
                panel = Plotting.Panel(t, data; title="State")
                out = _sprint_plain(panel)
                lines = split(out, '\n')
                Test.@test length(lines) == 1
            end

            Test.@testset "Panel pretty — partial labels" begin
                t = collect(0.0:0.1:1.0)
                data = hcat(sin.(t), cos.(t), t)
                panel = Plotting.Panel(
                    t, data; title="Mix", labels=["a", "", "c"],
                )
                out = _sprint_plain(panel)
                Test.@test occursin("a", out)
                Test.@test occursin("c", out)
                lines = split(out, '\n')
                Test.@test length(lines) == 3
            end

            Test.@testset "Panel pretty — singular" begin
                panel = Plotting.Panel(
                    [0.0], reshape([1.0], :, 1);
                    title="S", labels=["u"],
                )
                out = _sprint_plain(panel)
                Test.@test occursin("1 component", out)
                Test.@test occursin("1 point", out)
                Test.@test !occursin("components", out)
                Test.@test !occursin("points", out)
            end
        end

        # ========================================================================
        # INTEGRATION TESTS — nested trees and truncation
        # ========================================================================

        Test.@testset "Integration" begin
            Test.@testset "Nested HBox in VBox" begin
                inner = Plotting.HBox([_leaf(; title="L"), _leaf(; title="R")])
                outer = Plotting.VBox([inner, _leaf(; title="B")])
                out = _sprint_plain(outer)
                Test.@test occursin("VBox", out)
                Test.@test occursin("HBox", out)
                Test.@test occursin("L", out)
                Test.@test occursin("R", out)
                Test.@test occursin("B", out)
            end

            Test.@testset "Truncation beyond limit" begin
                leaves = [
                    _leaf(; title="C$i") for i in 1:8
                ]
                box = Plotting.VBox(leaves)
                out = _sprint_plain(box)
                Test.@test occursin("8", out)
                Test.@test occursin("more", out)
                Test.@test occursin("C1", out)
                Test.@test occursin("C5", out)
                Test.@test !occursin("C6", out)
            end

            Test.@testset "Figure with nested tree" begin
                leaf1 = _leaf(; title="State")
                leaf2 = _leaf(; title="Costate")
                leaf3 = _leaf(; title="Control")
                tree = Plotting.VBox([
                    Plotting.HBox([leaf1, leaf2]),
                    leaf3,
                ])
                fig = Plotting.Figure(tree; title="Solution")
                out = _sprint_plain(fig)
                Test.@test occursin("Figure", out)
                Test.@test occursin("Solution", out)
                Test.@test occursin("VBox", out)
                Test.@test occursin("HBox", out)
                Test.@test occursin("State", out)
                Test.@test occursin("Costate", out)
                Test.@test occursin("Control", out)
            end

            Test.@testset "Axes with many series — no truncation" begin
                ss = [_series("s$i") for i in 1:7]
                ax = Plotting.Axes(ss; title="Many")
                out = _sprint_plain(ax)
                for i in 1:7
                    Test.@test occursin("s$i", out)
                end
                Test.@test occursin("7", out)
            end
        end
    end
    return nothing
end

end # module TestPlottingDisplay

test_display() = TestPlottingDisplay.test_display()
