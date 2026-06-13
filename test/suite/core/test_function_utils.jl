module TestCoreFunctionUtils

using Test: Test
import CTBase.Core

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_function_utils()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "to_out_of_place" begin
        Test.@testset "to_out_of_place - basic conversion" begin
            f!(r, x) = (r[1]=sin(x); r[2]=cos(x))
            f = Core.to_out_of_place(f!, 2)
            result = f(π / 4)
            Test.@test result isa Vector
            Test.@test length(result) == 2
            Test.@test result[1] ≈ sin(π / 4)
            Test.@test result[2] ≈ cos(π / 4)
        end

        Test.@testset "to_out_of_place - scalar output (n=1)" begin
            g!(r, x) = (r[1] = x^2)
            g = Core.to_out_of_place(g!, 1)
            result = g(3.0)
            Test.@test result isa Float64
            Test.@test result ≈ 9.0
        end

        Test.@testset "to_out_of_place - with kwargs" begin
            h!(r, x; scale=1.0) = (r[1]=x * scale; r[2]=x^2 * scale)
            h = Core.to_out_of_place(h!, 2)
            Test.@test h(2.0)[1] ≈ 2.0
            Test.@test h(2.0)[2] ≈ 4.0
            Test.@test h(2.0; scale=3.0)[1] ≈ 6.0
            Test.@test h(2.0; scale=3.0)[2] ≈ 12.0
        end

        Test.@testset "to_out_of_place - multiple arguments" begin
            k!(r, x, y) = (r[1]=x + y; r[2]=x * y)
            k = Core.to_out_of_place(k!, 2)
            result = k(3.0, 4.0)
            Test.@test result[1] ≈ 7.0
            Test.@test result[2] ≈ 12.0
        end

        Test.@testset "to_out_of_place - custom type" begin
            m!(r, x) = (r[1]=x + 1; r[2]=x + 2)
            m = Core.to_out_of_place(m!, 2; T=Int)
            result = m(5)
            Test.@test result isa Vector{Int}
            Test.@test result[1] == 6
            Test.@test result[2] == 7
        end

        Test.@testset "to_out_of_place - nothing input" begin
            Test.@test Core.to_out_of_place(nothing, 2) === nothing
        end

        Test.@testset "to_out_of_place - larger output" begin
            big!(r, x) = (
                for i in 1:5
                    ;
                    r[i] = x * i;
                end
            )
            big = Core.to_out_of_place(big!, 5)
            result = big(2.0)
            Test.@test length(result) == 5
            Test.@test result == [2.0, 4.0, 6.0, 8.0, 10.0]
        end
    end
    return nothing
end

end # module TestCoreFunctionUtils

test_function_utils() = TestCoreFunctionUtils.test_function_utils()
