module TestAbstractTraits

using Test: Test
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_abstract_traits()
    Test.@testset "Abstract Traits Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Types" begin
            Test.@testset "AbstractTrait" begin
                Test.@testset "AbstractTrait is exported" begin
                    Test.@test isdefined(Traits, :AbstractTrait)
                end

                Test.@testset "AbstractTrait is abstract" begin
                    Test.@test isabstracttype(Traits.AbstractTrait)
                end
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported abstract trait" begin
                Test.@test isdefined(Traits, :AbstractTrait)
            end
        end
    end
end

end # module

test_abstract_traits() = TestAbstractTraits.test_abstract_traits()
