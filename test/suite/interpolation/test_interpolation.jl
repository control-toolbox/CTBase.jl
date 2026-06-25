module TestInterpolation

using Test: Test
import CTBase.Interpolation

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_interpolation()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Interpolation" begin
        Test.@testset "ctinterpolate - basic linear interpolation" begin
            x = [0.0, 1.0, 2.0]
            f = [0.0, 1.0, 0.0]
            interp = Interpolation.ctinterpolate(x, f)
            Test.@test interp(0.0) ≈ 0.0
            Test.@test interp(1.0) ≈ 1.0
            Test.@test interp(2.0) ≈ 0.0
            Test.@test interp(0.5) ≈ 0.5
            Test.@test interp(1.5) ≈ 0.5
        end

        Test.@testset "ctinterpolate - extrapolation" begin
            x = [0.0, 1.0, 2.0]
            f = [1.0, 2.0, 3.0]
            interp = Interpolation.ctinterpolate(x, f)
            Test.@test interp(-1.0) ≈ 1.0
            Test.@test interp(3.0) ≈ 3.0
        end

        Test.@testset "ctinterpolate - constant function" begin
            x = [0.0, 1.0, 2.0, 3.0]
            f = [5.0, 5.0, 5.0, 5.0]
            interp = Interpolation.ctinterpolate(x, f)
            Test.@test interp(0.5) ≈ 5.0
            Test.@test interp(1.5) ≈ 5.0
            Test.@test interp(2.5) ≈ 5.0
        end

        Test.@testset "ctinterpolate - non-uniform grid" begin
            x = [0.0, 0.1, 0.5, 1.0, 2.0]
            f = [0.0, 1.0, 2.0, 3.0, 4.0]
            interp = Interpolation.ctinterpolate(x, f)
            Test.@test interp(0.05) ≈ 0.5
            Test.@test interp(0.3) ≈ 1.5
            Test.@test interp(1.5) ≈ 3.5
        end

        Test.@testset "ctinterpolate - vector values" begin
            x = [0.0, 1.0, 2.0]
            f = [[0.0, 0.0], [1.0, 2.0], [2.0, 4.0]]
            interp = Interpolation.ctinterpolate(x, f)
            Test.@test interp(0.0) ≈ [0.0, 0.0]
            Test.@test interp(1.0) ≈ [1.0, 2.0]
            Test.@test interp(2.0) ≈ [2.0, 4.0]
            Test.@test interp(0.5) ≈ [0.5, 1.0]
        end

        Test.@testset "ctinterpolate_constant - basic piecewise constant" begin
            x = [0.0, 1.0, 2.0]
            f = [1.0, 2.0, 3.0]
            interp = Interpolation.ctinterpolate_constant(x, f)
            Test.@test interp(0.0) ≈ 1.0
            Test.@test interp(1.0) ≈ 2.0
            Test.@test interp(2.0) ≈ 3.0
            Test.@test interp(0.5) ≈ 1.0
            Test.@test interp(0.9) ≈ 1.0
            Test.@test interp(1.5) ≈ 2.0
        end

        Test.@testset "ctinterpolate_constant - extrapolation" begin
            x = [0.0, 1.0, 2.0]
            f = [1.0, 2.0, 3.0]
            interp = Interpolation.ctinterpolate_constant(x, f)
            Test.@test interp(-1.0) ≈ 1.0
            Test.@test interp(-0.5) ≈ 1.0
            Test.@test interp(3.0) ≈ 3.0
            Test.@test interp(5.0) ≈ 3.0
        end

        Test.@testset "ctinterpolate_constant - control-like data" begin
            x = [0.0, 0.1, 0.5, 1.0]
            f = [5.0, 4.0, 3.0, 2.0]
            interp = Interpolation.ctinterpolate_constant(x, f)
            Test.@test interp(0.0) ≈ 5.0
            Test.@test interp(0.05) ≈ 5.0
            Test.@test interp(0.1) ≈ 4.0
            Test.@test interp(0.3) ≈ 4.0
            Test.@test interp(0.5) ≈ 3.0
            Test.@test interp(0.75) ≈ 3.0
            Test.@test interp(1.0) ≈ 2.0
        end

        Test.@testset "ctinterpolate_constant - vector values" begin
            x = [0.0, 1.0, 2.0]
            f = [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]]
            interp = Interpolation.ctinterpolate_constant(x, f)
            Test.@test interp(0.0) ≈ [1.0, 2.0]
            Test.@test interp(1.0) ≈ [3.0, 4.0]
            Test.@test interp(2.0) ≈ [5.0, 6.0]
            Test.@test interp(0.5) ≈ [1.0, 2.0]
            Test.@test interp(1.5) ≈ [3.0, 4.0]
        end

        Test.@testset "ctinterpolate_constant - constant function" begin
            x = [0.0, 1.0, 2.0, 3.0]
            f = [7.0, 7.0, 7.0, 7.0]
            interp = Interpolation.ctinterpolate_constant(x, f)
            Test.@test interp(0.5) ≈ 7.0
            Test.@test interp(1.5) ≈ 7.0
            Test.@test interp(2.5) ≈ 7.0
            Test.@test interp(-1.0) ≈ 7.0
            Test.@test interp(5.0) ≈ 7.0
        end

        Test.@testset "Interpolant type & show" begin
            interp = Interpolation.ctinterpolate([0.0, 1.0, 2.0], [0.0, 1.0, 0.0])
            Test.@test interp isa Function
            Test.@test interp isa Interpolation.Interpolant
            Test.@test interp isa Interpolation.LinearInterpolant
            Test.@test Interpolation.method(interp) === Interpolation.Linear
            Test.@test occursin("linear", sprint(show, interp))
            Test.@test occursin("3 nodes", sprint(show, interp))

            c = Interpolation.ctinterpolate_constant([0.0, 1.0, 2.0], [1.0, 2.0, 3.0])
            Test.@test c isa Function
            Test.@test c isa Interpolation.ConstantInterpolant
            Test.@test Interpolation.method(c) === Interpolation.Constant
            Test.@test occursin("constant", sprint(show, c))

            # type stability of the call (philosophy: @inferred on the call)
            Test.@test_nowarn Test.@inferred interp(0.5)
            Test.@test_nowarn Test.@inferred c(0.5)
        end
    end
    return nothing
end

end # module TestInterpolation

test_interpolation() = TestInterpolation.test_interpolation()
