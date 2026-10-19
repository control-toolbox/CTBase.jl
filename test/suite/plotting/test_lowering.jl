module TestPlottingLowering

using Test: Test
using CTBase: Plotting
using CTBase: Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_lowering()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting lowering" begin
        t = collect(range(0.0, 2.0, 11))

        Test.@testset "Panel construction guards" begin
            Test.@test_throws Exceptions.IncorrectArgument Plotting.Panel(
                [0.0, 1.0], [0.0 1.0]
            )  # x length ≠ rows
            Test.@test_throws Exceptions.IncorrectArgument Plotting.Panel(
                t, [t t]; labels=["only-one"]
            )
            Test.@test_throws Exceptions.IncorrectArgument Plotting.Panel(
                t,
                [t t];
                styles=[(color=1,)],  # one style, two components
            )
            p = Plotting.Panel(t, [t 2t]; labels=["a", "b"])
            Test.@test Plotting.n_components(p) == 2
            Test.@test Plotting.component_style(p, 1) == NamedTuple()
        end

        Test.@testset "split: one cell per component, labels placed" begin
            p = Plotting.Panel(t, [t 2t 3t]; title="state", labels=["a", "b", "c"])
            node = Plotting.lower(p; layout=:split)
            Test.@test node isa Plotting.VBox
            ls = Plotting.leaves(node)
            Test.@test length(ls) == 3
            Test.@test ls[1].axes.title == "state"       # title on top cell only
            Test.@test ls[2].axes.title == ""
            Test.@test ls[1].axes.ylabel == "a"
            Test.@test ls[1].axes.xlabel == ""           # xlabel on bottom only
            Test.@test ls[3].axes.xlabel == "t"
            Test.@test all(l -> l.axes.legend == false, ls)
        end

        Test.@testset "split with a single component returns a Leaf" begin
            p = Plotting.Panel(t, reshape(t, :, 1); labels=["u"])
            Test.@test Plotting.lower(p; layout=:split) isa Plotting.Leaf
        end

        Test.@testset "group: one cell, components overlaid, legend on" begin
            p = Plotting.Panel(t, [t 2t]; title="state", labels=["a", "b"])
            node = Plotting.lower(p; layout=:group)
            Test.@test node isa Plotting.Leaf
            Test.@test length(node.axes.series) == 2
            Test.@test node.axes.legend == true
            Test.@test [s.label for s in node.axes.series] == ["a", "b"]
        end

        Test.@testset "time transform" begin
            p = Plotting.Panel(t, reshape(t, :, 1); labels=["u"])
            def = Plotting.lower(p; layout=:split, time=:default)
            Test.@test def.axes.series[1].x == t
            nrm = Plotting.lower(p; layout=:split, time=:normalize)
            Test.@test nrm.axes.series[1].x[1] == 0.0
            Test.@test nrm.axes.series[1].x[end] == 1.0
            Test.@test_throws Exceptions.IncorrectArgument Plotting.lower(p; time=:bogus)
        end

        Test.@testset "layout guard" begin
            p = Plotting.Panel(t, reshape(t, :, 1); labels=["u"])
            Test.@test_throws Exceptions.IncorrectArgument Plotting.lower(p; layout=:bogus)
        end

        Test.@testset "ylims guard for a constant series" begin
            p = Plotting.Panel(t, reshape(fill(5.0, length(t)), :, 1); labels=["c"])
            leaf = Plotting.lower(p; layout=:split)
            Test.@test leaf.axes.ylims == (4.0, 6.0)     # widened around 5
            p2 = Plotting.Panel(t, reshape(t, :, 1); labels=["u"])
            Test.@test Plotting.lower(p2; layout=:split).axes.ylims === :auto
        end

        Test.@testset "decorations: vlines on every cell, hlines per component" begin
            p = Plotting.Panel(t, [t 2t]; labels=["a", "b"])
            node = Plotting.lower(
                p;
                layout=:split,
                vlines=[Plotting.VLine(0.0), Plotting.VLine(2.0)],
                hlines=[[Plotting.HLine(-1.0)], Plotting.HLine[]],
            )
            ls = Plotting.leaves(node)
            # cell 1: its hline + the two vlines ; cell 2: only the two vlines
            Test.@test length(ls[1].axes.decorations) == 3
            Test.@test length(ls[2].axes.decorations) == 2
            Test.@test count(d -> d isa Plotting.VLine, ls[1].axes.decorations) == 2
            # group merges everything into the single cell
            g = Plotting.lower(
                p;
                layout=:group,
                vlines=[Plotting.VLine(0.0)],
                hlines=[[Plotting.HLine(-1.0)], [Plotting.HLine(1.0)]],
            )
            Test.@test length(g.axes.decorations) == 3
        end

        Test.@testset "annotations: top cell in split, the cell in group" begin
            p = Plotting.Panel(t, [t 2t 3t]; labels=["a", "b", "c"])
            texts = [Plotting.Annotation(0.5, "bang"), Plotting.Annotation(1.5, "singular")]
            node = Plotting.lower(
                p; layout=:split, vlines=[Plotting.VLine(1.0)], annotations=texts
            )
            ls = Plotting.leaves(node)
            # top cell: the shared vline, then the annotations, in order
            Test.@test ls[1].axes.decorations ==
                Plotting.Decoration[Plotting.VLine(1.0), texts...]
            # the other cells carry no annotation
            for k in 2:3
                Test.@test !any(d -> d isa Plotting.Annotation, ls[k].axes.decorations)
                Test.@test count(d -> d isa Plotting.VLine, ls[k].axes.decorations) == 1
            end
            # a single-component split is a Leaf that carries them
            leaf = Plotting.lower(Plotting.Panel(t, t[:, :]); annotations=texts)
            Test.@test leaf isa Plotting.Leaf
            Test.@test count(d -> d isa Plotting.Annotation, leaf.axes.decorations) == 2
            # group: hlines, vlines, then annotations, all in the single cell
            g = Plotting.lower(
                p;
                layout=:group,
                vlines=[Plotting.VLine(1.0)],
                hlines=[[Plotting.HLine(0.0)], Plotting.HLine[], Plotting.HLine[]],
                annotations=texts,
            )
            Test.@test g.axes.decorations == Plotting.Decoration[
                Plotting.HLine(0.0), Plotting.VLine(1.0), texts...
            ]
            # no annotation by default: the decorations are unchanged
            Test.@test Plotting.leaves(Plotting.lower(p; layout=:split))[1].axes.decorations ==
                Plotting.Decoration[]
        end

        Test.@testset "per-component style" begin
            p = Plotting.Panel(
                t, [t 2t]; labels=["a", "b"], styles=[(color=1,), (color=2,)]
            )
            ls = Plotting.leaves(Plotting.lower(p; layout=:split))
            Test.@test ls[1].axes.series[1].style == (color=1,)
            Test.@test ls[2].axes.series[1].style == (color=2,)
        end
    end
    return nothing
end

end # module TestPlottingLowering

test_lowering() = TestPlottingLowering.test_lowering()
