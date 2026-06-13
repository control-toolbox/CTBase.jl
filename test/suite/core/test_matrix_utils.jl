module TestCoreMatrixUtils

using Test: Test
import CTBase.Core

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_matrix_utils()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "matrix2vec" begin
        Test.@testset "matrix2vec - dimension 1 (rows)" begin
            A = [0 1; 2 3]
            V = Core.matrix2vec(A)
            Test.@test V isa Vector{<:Vector}
            Test.@test length(V) == 2
            Test.@test V[1] == [0, 1]
            Test.@test V[2] == [2, 3]
            V1 = Core.matrix2vec(A, 1)
            Test.@test V1 == V
        end

        Test.@testset "matrix2vec - dimension 2 (columns)" begin
            A = [0 1; 2 3]
            W = Core.matrix2vec(A, 2)
            Test.@test W isa Vector{<:Vector}
            Test.@test length(W) == 2
            Test.@test W[1] == [0, 2]
            Test.@test W[2] == [1, 3]
        end

        Test.@testset "matrix2vec - larger matrix" begin
            B = [1 2 3; 4 5 6]
            rows = Core.matrix2vec(B, 1)
            Test.@test length(rows) == 2
            Test.@test rows[1] == [1, 2, 3]
            Test.@test rows[2] == [4, 5, 6]
            cols = Core.matrix2vec(B, 2)
            Test.@test length(cols) == 3
            Test.@test cols[1] == [1, 4]
            Test.@test cols[2] == [2, 5]
            Test.@test cols[3] == [3, 6]
        end

        Test.@testset "matrix2vec - single row/column" begin
            R = [1 2 3]
            Test.@test length(Core.matrix2vec(R, 1)) == 1
            Test.@test Core.matrix2vec(R, 1)[1] == [1, 2, 3]
            Test.@test length(Core.matrix2vec(R, 2)) == 3
            C = reshape([1, 2, 3], 3, 1)
            Test.@test length(Core.matrix2vec(C, 1)) == 3
            Test.@test length(Core.matrix2vec(C, 2)) == 1
            Test.@test Core.matrix2vec(C, 2)[1] == [1, 2, 3]
        end

        Test.@testset "matrix2vec - Float64 matrix" begin
            F = [1.5 2.5; 3.5 4.5]
            V = Core.matrix2vec(F, 1)
            Test.@test V[1] ≈ [1.5, 2.5]
            Test.@test V[2] ≈ [3.5, 4.5]
            W = Core.matrix2vec(F, 2)
            Test.@test W[1] ≈ [1.5, 3.5]
            Test.@test W[2] ≈ [2.5, 4.5]
        end
    end
    return nothing
end

end # module TestCoreMatrixUtils

test_matrix_utils() = TestCoreMatrixUtils.test_matrix_utils()
