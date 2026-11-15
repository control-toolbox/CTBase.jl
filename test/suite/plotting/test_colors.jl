module TestPlottingColors

using Test: Test
using CTBase: Plotting

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_colors()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Plotting: shared colours" begin
        Test.@testset "COLORS names the roles drawn around the data" begin
            Test.@test keys(Plotting.COLORS) == (:bound, :time, :phase_label)
        end

        Test.@testset "no role is a palette index (#657)" begin
            # an integer is an index into the palette of a backend, and the palettes of
            # Plots and Makie differ: a role must be a concrete colour
            for c in values(Plotting.COLORS)
                Test.@test !(c isa Integer)
                Test.@test c isa Union{Symbol,AbstractString}
            end
        end

        Test.@testset "the roles are told apart" begin
            Test.@test length(unique(values(Plotting.COLORS))) == length(Plotting.COLORS)
        end

        Test.@testset "the phase labels are drawn in the phase_label colour" begin
            t = collect(range(0.0, 4.0, 9))
            a = Plotting.phase_annotations(t, [1.0, 3.0], ["a", "b", "c"])
            Test.@test all(x -> x.style.color === Plotting.COLORS.phase_label, a)
        end
    end
    return nothing
end

end # module TestPlottingColors

test_colors() = TestPlottingColors.test_colors()
