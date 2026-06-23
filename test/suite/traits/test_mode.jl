module TestMode

import Test
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_mode()
    Test.@testset "Mode Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Types" begin
            Test.@testset "AbstractModeTrait" begin
                Test.@testset "AbstractModeTrait is exported" begin
                    Test.@test isdefined(Traits, :AbstractModeTrait)
                end

                Test.@testset "AbstractModeTrait is abstract" begin
                    Test.@test isabstracttype(Traits.AbstractModeTrait)
                end

                Test.@testset "AbstractModeTrait subtypes AbstractTrait" begin
                    Test.@test Traits.AbstractModeTrait <: Traits.AbstractTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Concrete Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Concrete Trait Types" begin
            Test.@testset "EndPointMode" begin
                Test.@testset "EndPointMode is exported" begin
                    Test.@test isdefined(Traits, :EndPointMode)
                end

                Test.@testset "EndPointMode is concrete" begin
                    Test.@test !isabstracttype(Traits.EndPointMode)
                end

                Test.@testset "EndPointMode instantiates" begin
                    pt = Traits.EndPointMode()
                    Test.@test pt isa Traits.EndPointMode
                end

                Test.@testset "EndPointMode subtypes AbstractModeTrait" begin
                    Test.@test Traits.EndPointMode <: Traits.AbstractModeTrait
                end
            end

            Test.@testset "TrajectoryMode" begin
                Test.@testset "TrajectoryMode is exported" begin
                    Test.@test isdefined(Traits, :TrajectoryMode)
                end

                Test.@testset "TrajectoryMode is concrete" begin
                    Test.@test !isabstracttype(Traits.TrajectoryMode)
                end

                Test.@testset "TrajectoryMode instantiates" begin
                    traj = Traits.TrajectoryMode()
                    Test.@test traj isa Traits.TrajectoryMode
                end

                Test.@testset "TrajectoryMode subtypes AbstractModeTrait" begin
                    Test.@test Traits.TrajectoryMode <: Traits.AbstractModeTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "UNIT TESTS - Type Hierarchy" begin
            Test.@testset "All mode traits subtype AbstractTrait" begin
                Test.@test Traits.EndPointMode <: Traits.AbstractTrait
                Test.@test Traits.TrajectoryMode <: Traits.AbstractTrait
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported mode trait types" begin
                for sym in (:AbstractModeTrait, :EndPointMode, :TrajectoryMode)
                    Test.@test isdefined(Traits, sym)
                end
            end
        end
    end
end

end # module

test_mode() = TestMode.test_mode()
