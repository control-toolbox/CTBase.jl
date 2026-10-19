module TestPlottingSwitching

using Test: Test
using CTBase: Plotting
using CTBase: Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_switching()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting: phases" begin
        # ====================================================================
        # UNIT TESTS - splice_jumps
        # ====================================================================

        Test.@testset "splice_jumps: a sample at the switching time is replaced" begin
            x, d = Plotting.splice_jumps(
                [0.0, 1.0, 2.0], [0.0; 1.0; 2.0;;], [1.0], [1.0;;], [3.0;;]
            )
            Test.@test x == [0.0, 1.0, 1.0, 2.0]
            Test.@test vec(d) == [0.0, 1.0, 3.0, 2.0]
            Test.@test x isa Vector{Float64}
            Test.@test d isa Matrix{Float64}
        end

        Test.@testset "splice_jumps: switching times between and after the samples" begin
            # τ = 0.5 between two samples, τ = 3 after the last one
            x, d = Plotting.splice_jumps(
                [0, 1, 2], [0 10; 1 11; 2 12], [0.5, 3.0], [5 15; 7 17], [6 16; 8 18]
            )
            Test.@test x == [0.0, 0.5, 0.5, 1.0, 2.0, 3.0, 3.0]
            Test.@test d == [0 10; 5 15; 6 16; 1 11; 2 12; 7 17; 8 18]
        end

        Test.@testset "splice_jumps: several switching times, in order" begin
            t = collect(range(0.0, 3.0, 7))
            M = reshape(t, :, 1)
            x, d = Plotting.splice_jumps(t, M, [1.0, 2.0], [1.0; 2.0;;], [5.0; 6.0;;])
            Test.@test issorted(x)
            Test.@test count(==(1.0), x) == 2
            Test.@test count(==(2.0), x) == 2
            k = findfirst(==(1.0), x)
            Test.@test d[k:(k + 1), 1] == [1.0, 5.0]
            k = findfirst(==(2.0), x)
            Test.@test d[k:(k + 1), 1] == [2.0, 6.0]
            Test.@test length(x) == length(t) + 2
        end

        Test.@testset "splice_jumps: connect=false breaks the curve" begin
            x, d = Plotting.splice_jumps(
                [0.0, 1.0, 2.0],
                [0.0 10; 1 11; 2 12],
                [1.0],
                [1.0 11;],
                [3.0 13;];
                connect=false,
            )
            Test.@test x == [0.0, 1.0, 1.0, 1.0, 2.0]
            Test.@test d[2, :] == [1.0, 11.0]
            Test.@test all(isnan, d[3, :])
            Test.@test d[4, :] == [3.0, 13.0]
            # the y-limits guard ignores the NaN rows
            Test.@test Plotting._ylims_guard(d[:, 1]) === :auto
            Test.@test Plotting._ylims_guard([1.0, NaN, 1.0]) == (0.0, 2.0)
            # lowered and rendered: the NaN row reaches the series
            node = Plotting.lower(Plotting.Panel(x, d; labels=["a", "b"]))
            s = first(Plotting.leaves(node)).axes.series[1]
            Test.@test count(isnan, s.y) == 1
        end

        Test.@testset "splice_jumps: unchanged without switching time or limits" begin
            t, M = [0.0, 1.0], [1.0 2.0; 3.0 4.0]
            Test.@test Plotting.splice_jumps(t, M, Float64[], zeros(0, 2), zeros(0, 2)) ==
                (t, M)
            Test.@test Plotting.splice_jumps(t, M, [0.5], zeros(1, 0), zeros(1, 0)) ==
                (t, M)
        end

        # ====================================================================
        # UNIT TESTS - switching_vlines and phase_annotations
        # ====================================================================

        Test.@testset "switching_vlines" begin
            t = [1.0, 2.0, 3.0]
            v = Plotting.switching_vlines(t, [1.5, 2.5]; style=(color=:red,))
            Test.@test v isa Vector{Plotting.VLine}
            Test.@test [l.value for l in v] == [1.5, 2.5]
            Test.@test all(l -> l.style == (color=:red,), v)
            # normalised time, over the grid of the trajectory
            Test.@test only(Plotting.switching_vlines(t, [1.5]; time=:normalize)).value ≈
                0.25
            Test.@test only(Plotting.switching_vlines(t, [1.5]; time=:normalise)).value ≈
                0.25
            Test.@test isempty(Plotting.switching_vlines(t, Float64[]))
        end

        Test.@testset "phase_annotations: centred on the phases" begin
            t = collect(range(0.0, 4.0, 9))
            a = Plotting.phase_annotations(t, [1.0, 3.0], ["a", "b", "c"])
            Test.@test a isa Vector{Plotting.Annotation}
            Test.@test [x.x for x in a] == [0.5, 2.0, 3.5]
            Test.@test [x.text for x in a] == ["a", "b", "c"]
            # default style (grey), merged with the user style
            Test.@test a[1].style == (color=:gray30,)
            s = Plotting.phase_annotations(t, [1.0], ["a", "b"]; style=(fontsize=12,))
            Test.@test s[1].style == (color=:gray30, fontsize=12)
            r = Plotting.phase_annotations(t, [1.0], ["a", "b"]; style=(color=:red,))
            Test.@test r[1].style.color === :red
            # normalised time
            n = Plotting.phase_annotations(t, [2.0], ["a", "b"]; time=:normalize)
            Test.@test [x.x for x in n] ≈ [0.25, 0.75]
        end

        Test.@testset "phase_annotations: empty labels get no text" begin
            t = [0.0, 1.0, 2.0]
            a = Plotting.phase_annotations(t, [1.0], ["", "b"])
            Test.@test [x.text for x in a] == ["b"]
            Test.@test only(a).x == 1.5
            Test.@test isempty(Plotting.phase_annotations(t, [1.0], ["", ""]))
            Test.@test isempty(Plotting.phase_annotations(t, [1.0], String[]))
            # a single labelled phase, no switching time
            Test.@test only(Plotting.phase_annotations(t, Float64[], ["arc"])).x == 1.0
        end

        # ====================================================================
        # ERROR TESTS
        # ====================================================================

        Test.@testset "errors" begin
            t, M = [0.0, 1.0, 2.0], reshape([0.0, 1.0, 2.0], :, 1)
            # limits: one row per switching time, the columns of the samples
            Test.@test_throws Exceptions.IncorrectArgument Plotting.splice_jumps(
                t, M, [1.0], zeros(2, 1), zeros(2, 1)
            )
            Test.@test_throws Exceptions.IncorrectArgument Plotting.splice_jumps(
                t, M, [1.0], zeros(1, 2), zeros(1, 2)
            )
            Test.@test_throws Exceptions.IncorrectArgument Plotting.splice_jumps(
                t, M, [1.0], zeros(1, 1), zeros(1, 0)
            )
            # one label per phase
            err = try
                Plotting.phase_annotations(t, [1.0], ["a"])
            catch e
                e
            end
            Test.@test err isa Exceptions.IncorrectArgument
            Test.@test occursin("one label per phase", err.msg)
            # an unknown time normalisation
            Test.@test_throws Exceptions.IncorrectArgument Plotting.switching_vlines(
                t, [1.0]; time=:bad
            )
            Test.@test_throws Exceptions.IncorrectArgument Plotting.phase_annotations(
                t, [1.0], ["a", "b"]; time=:bad
            )
        end

        # ====================================================================
        # INTEGRATION TESTS - with lower
        # ====================================================================

        Test.@testset "with lower: jump, lines and labels reach the cell" begin
            t = collect(range(0.0, 2.0, 21))
            x = reshape([s < 1 ? s : s + 1 for s in t], :, 1)
            xs, d = Plotting.splice_jumps(t, x, [1.0], [1.0;;], [2.0;;])
            node = Plotting.lower(
                Plotting.Panel(xs, d; title="state", labels=["x"]);
                vlines=Plotting.switching_vlines(t, [1.0]),
                annotations=Plotting.phase_annotations(t, [1.0], ["p1", "p2"]),
            )
            ax = only(Plotting.leaves(node)).axes
            s = only(ax.series)
            k = findfirst(==(1.0), s.x)
            Test.@test s.x[k + 1] == 1.0
            Test.@test s.y[k + 1] - s.y[k] ≈ 1.0
            Test.@test count(d -> d isa Plotting.VLine, ax.decorations) == 1
            Test.@test [d.text for d in ax.decorations if d isa Plotting.Annotation] == ["p1", "p2"]
        end
    end
    return nothing
end

end # module TestPlottingSwitching

test_switching() = TestPlottingSwitching.test_switching()
