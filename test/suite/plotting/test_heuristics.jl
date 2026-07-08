module TestPlottingHeuristics

using Test: Test
import CTBase.Plotting

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

_leaf() = Plotting.Leaf(Plotting.Axes([Plotting.Series([0.0, 1.0], [0.0, 1.0])]))
_col(k) = Plotting.VBox([_leaf() for _ in 1:k], ones(k))

function test_heuristics()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting heuristics" begin
        Test.@testset "grid_shape" begin
            Test.@test Plotting.grid_shape(_leaf()) == (1, 1)
            Test.@test Plotting.grid_shape(_col(3)) == (3, 1)          # VBox stacks rows
            Test.@test Plotting.grid_shape(Plotting.HBox([_leaf(), _leaf()])) == (1, 2)
            # paired columns: rows = max column height, cols = sum
            Test.@test Plotting.grid_shape(Plotting.HBox([_col(2), _col(3)])) == (3, 2)
            # nested group grid 2×2
            cells = reshape(
                Plotting.AbstractLayoutNode[_leaf(), _leaf(), _leaf(), _leaf()], 2, 2
            )
            Test.@test Plotting.grid_shape(Plotting.Grid(cells)) == (2, 2)
        end

        Test.@testset "default_size" begin
            # single column of 3 -> width 600, height 180*3 + 60
            Test.@test Plotting.default_size(_col(3)) == (600, 600)
            # two columns -> width 340*2, one row
            Test.@test Plotting.default_size(Plotting.HBox([_leaf(), _leaf()])) ==
                (680, 240)
            # Figure size override wins
            f = Plotting.Figure(_col(3); size=(800, 800))
            Test.@test Plotting.default_size(f) == (800, 800)
            Test.@test Plotting.default_size(Plotting.Figure(_col(3))) == (600, 600)
        end
    end
    return nothing
end

end # module TestPlottingHeuristics

test_heuristics() = TestPlottingHeuristics.test_heuristics()
