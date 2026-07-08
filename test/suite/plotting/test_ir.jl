module TestPlottingIR

using Test: Test
import CTBase.Plotting
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

_leaf(v=[0.0, 1.0]) = Plotting.Leaf(Plotting.Axes([Plotting.Series([0.0, 1.0], v)]))

function test_ir()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting IR" begin
        Test.@testset "Series" begin
            s = Plotting.Series([0.0, 1.0], [2.0, 3.0])
            Test.@test s.label == ""
            Test.@test s.style == NamedTuple()
            Test.@test s.x == [0.0, 1.0]
            s2 = Plotting.Series(1:3, [1, 2, 3]; label="u", style=(color=2,))
            Test.@test s2.label == "u"
            Test.@test s2.x == [1.0, 2.0, 3.0]
            Test.@test eltype(s2.y) === Float64
            Test.@test_throws Exceptions.IncorrectArgument Plotting.Series(
                [1.0], [1.0, 2.0]
            )
        end

        Test.@testset "HLine / VLine / Decoration" begin
            Test.@test Plotting.HLine(1).value === 1.0
            Test.@test Plotting.VLine(2.0; style=(color=:red,)).style == (color=:red,)
            Test.@test Plotting.HLine(0) isa Plotting.Decoration
            Test.@test Plotting.VLine(0) isa Plotting.Decoration
        end

        Test.@testset "Axes defaults" begin
            ax = Plotting.Axes([Plotting.Series([0.0], [0.0])])
            Test.@test ax.title == "" && ax.xlabel == "" && ax.ylabel == ""
            Test.@test ax.legend == false
            Test.@test ax.decorations == Plotting.Decoration[]
            Test.@test ax.ylims === :auto_guarded
            ax2 = Plotting.Axes(
                Plotting.Series[]; title="t", ylabel="y", legend=true, ylims=(0, 1)
            )
            Test.@test ax2.ylims === (0.0, 1.0)
            Test.@test ax2.legend == true
        end

        Test.@testset "Leaf / HBox / VBox construction" begin
            a, b = _leaf(), _leaf()
            Test.@test Plotting.HBox([a, b]).weights == [1.0, 1.0]   # equal default
            Test.@test Plotting.VBox([a, b], [2, 1]).weights == [2.0, 1.0]
            # one weight per child
            Test.@test_throws Exceptions.IncorrectArgument Plotting.HBox([a, b], [1.0])
            # positive weights
            Test.@test_throws Exceptions.IncorrectArgument Plotting.VBox([a, b], [1.0, 0.0])
            # non-empty
            Test.@test_throws Exceptions.IncorrectArgument Plotting.HBox(
                Plotting.AbstractLayoutNode[]
            )
        end

        Test.@testset "deterministic leaf traversal" begin
            a, b, c = _leaf([1.0, 1.0]), _leaf([2.0, 2.0]), _leaf([3.0, 3.0])
            tree = Plotting.VBox([Plotting.HBox([a, b]), c], [2, 1])
            ls = Plotting.leaves(tree)
            Test.@test length(ls) == 3
            Test.@test Plotting.n_leaves(tree) == 3
            # depth-first, children in stored order: a, b, then c
            Test.@test [l.axes.series[1].y[1] for l in ls] == [1.0, 2.0, 3.0]
            Test.@test Plotting.leaves(a) == [a]
        end

        Test.@testset "Figure" begin
            f = Plotting.Figure(_leaf())
            Test.@test f.size === nothing && f.title === nothing
            f2 = Plotting.Figure(_leaf(); size=(800, 600), title="fig")
            Test.@test f2.size === (800, 600)
            Test.@test f2.title == "fig"
            Test.@test Plotting.n_leaves(f2) == 1
        end
    end
    return nothing
end

end # module TestPlottingIR

test_ir() = TestPlottingIR.test_ir()
