module TestCore

import Test
import CTBase.Core

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_core()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Core" begin
        Test.@testset "Default value of the display during resolution" begin
            Test.@test Core.__display()
        end

        Test.@testset "Type aliases" begin
            Test.@test Core.ctNumber === Real
            Test.@test Core.ctNumber === Real
        end
    end
end

end # module

test_core() = TestCore.test_core()
