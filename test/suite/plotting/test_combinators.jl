module TestPlottingCombinators

using Test: Test
import CTBase.Plotting
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

_leaf() = Plotting.Leaf(Plotting.Axes([Plotting.Series([0.0, 1.0], [0.0, 1.0])]))
_col(k) = Plotting.VBox([_leaf() for _ in 1:k], ones(k))   # a column of k cells

function test_combinators()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting combinators" begin
        Test.@testset "Stacked :auto weights ∝ rows" begin
            # a 2-cell column and a single leaf -> auto weights [2, 1]
            s = Plotting.Stacked(Plotting.AbstractLayoutNode[_col(2), _leaf()])
            Test.@test s isa Plotting.VBox
            Test.@test s.weights == [2.0, 1.0]
            Test.@test Plotting.n_leaves(s) == 3

            # discriminating case: a paired block (2 columns of 2 cells) stacked over a
            # single leaf. Row-based auto gives [2, 1] (the block is 2 rows tall), NOT
            # the leaf count [4, 1] — this is the CTModels state|costate / control case.
            block = Plotting.Paired(_col(2), _col(2))
            s2 = Plotting.Stacked(Plotting.AbstractLayoutNode[block, _leaf()])
            Test.@test s2.weights == [2.0, 1.0]
            Test.@test Plotting.n_leaves(s2) == 5
        end

        Test.@testset "Stacked explicit weights" begin
            s = Plotting.Stacked(
                Plotting.AbstractLayoutNode[_leaf(), _leaf()]; weights=[3, 1]
            )
            Test.@test s.weights == [3.0, 1.0]
            Test.@test_throws Exceptions.IncorrectArgument Plotting.Stacked(
                Plotting.AbstractLayoutNode[_leaf(), _leaf()]; weights=[1.0]
            )
        end

        Test.@testset "Paired" begin
            # two single columns -> one column each -> equal widths [1, 1], whatever
            # their heights (width follows columns, not cell counts).
            p = Plotting.Paired(_col(2), _col(2))
            Test.@test p isa Plotting.HBox
            Test.@test p.weights == [1.0, 1.0]
            Test.@test Plotting.n_leaves(p) == 4
            p2 = Plotting.Paired(_col(3), _col(1))
            Test.@test p2.weights == [1.0, 1.0]

            # discriminating case: a 2-column block beside a single column -> auto
            # widths [2, 1] (columns), not the leaf count.
            block = Plotting.Paired(_col(1), _col(1))          # 2 columns wide
            p3 = Plotting.Paired(Plotting.AbstractLayoutNode[block, _col(1)])
            Test.@test p3.weights == [2.0, 1.0]
        end

        Test.@testset "Grid" begin
            cells = reshape(
                Plotting.AbstractLayoutNode[_leaf(), _leaf(), _leaf(), _leaf()], 2, 2
            )
            g = Plotting.Grid(cells)
            Test.@test g isa Plotting.VBox
            Test.@test length(g.children) == 2        # two rows
            Test.@test all(c -> c isa Plotting.HBox, g.children)
            Test.@test Plotting.n_leaves(g) == 4
            # a 1×n group grid
            row = reshape(Plotting.AbstractLayoutNode[_leaf(), _leaf(), _leaf()], 1, 3)
            gr = Plotting.Grid(row)
            Test.@test Plotting.grid_shape(gr) == (1, 3)
            Test.@test_throws Exceptions.IncorrectArgument Plotting.Grid(
                row; col_weights=[1.0, 1.0]
            )
        end
    end
    return nothing
end

end # module TestPlottingCombinators

test_combinators() = TestPlottingCombinators.test_combinators()
