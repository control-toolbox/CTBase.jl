module TestFeedback

using Test: Test
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestTraits) ? Main.TestTraits.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestTraits) ? Main.TestTraits.SHOWTIMING : true

function test_feedback()
    Test.@testset "Feedback Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Type" begin
            Test.@testset "AbstractFeedback is exported" begin
                Test.@test isdefined(Traits, :AbstractFeedback)
            end

            Test.@testset "AbstractFeedback is abstract" begin
                Test.@test isabstracttype(Traits.AbstractFeedback)
            end

            Test.@testset "AbstractFeedback subtypes AbstractTrait" begin
                Test.@test Traits.AbstractFeedback <: Traits.AbstractTrait
            end
        end

        # ====================================================================
        # UNIT TESTS - Concrete Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Concrete Trait Types" begin
            Test.@testset "OpenLoopFeedback" begin
                Test.@testset "is exported" begin
                    Test.@test isdefined(Traits, :OpenLoopFeedback)
                end

                Test.@testset "is concrete" begin
                    Test.@test !isabstracttype(Traits.OpenLoopFeedback)
                end

                Test.@testset "instantiates" begin
                    fb = Traits.OpenLoopFeedback()
                    Test.@test fb isa Traits.OpenLoopFeedback
                end

                Test.@testset "subtypes AbstractFeedback" begin
                    Test.@test Traits.OpenLoopFeedback <: Traits.AbstractFeedback
                end
            end

            Test.@testset "ClosedLoopFeedback" begin
                Test.@testset "is exported" begin
                    Test.@test isdefined(Traits, :ClosedLoopFeedback)
                end

                Test.@testset "is concrete" begin
                    Test.@test !isabstracttype(Traits.ClosedLoopFeedback)
                end

                Test.@testset "instantiates" begin
                    fb = Traits.ClosedLoopFeedback()
                    Test.@test fb isa Traits.ClosedLoopFeedback
                end

                Test.@testset "subtypes AbstractFeedback" begin
                    Test.@test Traits.ClosedLoopFeedback <: Traits.AbstractFeedback
                end
            end

            Test.@testset "DynClosedLoopFeedback" begin
                Test.@testset "is exported" begin
                    Test.@test isdefined(Traits, :DynClosedLoopFeedback)
                end

                Test.@testset "is concrete" begin
                    Test.@test !isabstracttype(Traits.DynClosedLoopFeedback)
                end

                Test.@testset "instantiates" begin
                    fb = Traits.DynClosedLoopFeedback()
                    Test.@test fb isa Traits.DynClosedLoopFeedback
                end

                Test.@testset "subtypes AbstractFeedback" begin
                    Test.@test Traits.DynClosedLoopFeedback <: Traits.AbstractFeedback
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "UNIT TESTS - Type Hierarchy" begin
            Test.@testset "All feedback traits subtype AbstractTrait" begin
                Test.@test Traits.OpenLoopFeedback <: Traits.AbstractTrait
                Test.@test Traits.ClosedLoopFeedback <: Traits.AbstractTrait
                Test.@test Traits.DynClosedLoopFeedback <: Traits.AbstractTrait
            end

            Test.@testset "Feedback traits are distinct from dynamics traits" begin
                Test.@test !(Traits.OpenLoopFeedback <: Traits.AbstractDynamicsTrait)
                Test.@test !(Traits.ClosedLoopFeedback <: Traits.AbstractDynamicsTrait)
                Test.@test !(Traits.DynClosedLoopFeedback <: Traits.AbstractDynamicsTrait)
            end

            Test.@testset "Feedback traits are distinct from control-dependence traits" begin
                Test.@test !(Traits.OpenLoopFeedback <: Traits.ControlDependence)
                Test.@test !(Traits.ClosedLoopFeedback <: Traits.ControlDependence)
                Test.@test !(Traits.DynClosedLoopFeedback <: Traits.ControlDependence)
            end
        end

        # ====================================================================
        # UNIT TESTS - feedback accessor
        # ====================================================================

        Test.@testset "UNIT TESTS - feedback accessor" begin
            Test.@testset "feedback is exported" begin
                Test.@test isdefined(Traits, :feedback)
            end

            Test.@testset "feedback is a generic function" begin
                Test.@test isa(Traits.feedback, Function)
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported feedback trait types" begin
                for sym in (
                    :AbstractFeedback,
                    :OpenLoopFeedback,
                    :ClosedLoopFeedback,
                    :DynClosedLoopFeedback,
                    :feedback,
                )
                    Test.@test isdefined(Traits, sym)
                end
            end
        end
    end
end

end # module

test_feedback() = TestFeedback.test_feedback()
