module TestCoreUtils

using Test: Test
import CTBase.Core

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_utils()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Default value of the display during resolution" begin
        Test.@test Core.__display()
    end
    return nothing
end

end # module

test_utils() = TestCoreUtils.test_utils()
