module TestCoreTypes

using Test: Test
import CTBase.Core

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_types()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Type aliases" begin
        Test.@test Core.ctNumber == Real
        Test.@test Core.ctNumber === Real
        Test.@test 1 isa Core.ctNumber
        Test.@test 1.0 isa Core.ctNumber
    end
    return nothing
end

end # module

test_core_types() = TestCoreTypes.test_types()
