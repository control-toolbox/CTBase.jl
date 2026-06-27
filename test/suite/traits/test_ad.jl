module TestAD

using Test: Test
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_ad()
    Test.@testset "AD Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Types" begin
            Test.@testset "AbstractADTrait" begin
                Test.@testset "AbstractADTrait is exported" begin
                    Test.@test isdefined(Traits, :AbstractADTrait)
                end

                Test.@testset "AbstractADTrait is abstract" begin
                    Test.@test isabstracttype(Traits.AbstractADTrait)
                end

                Test.@testset "AbstractADTrait subtypes AbstractTrait" begin
                    Test.@test Traits.AbstractADTrait <: Traits.AbstractTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Concrete Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Concrete Trait Types" begin
            Test.@testset "WithAD" begin
                Test.@testset "WithAD is exported" begin
                    Test.@test isdefined(Traits, :WithAD)
                end

                Test.@testset "WithAD is concrete" begin
                    Test.@test !isabstracttype(Traits.WithAD)
                end

                Test.@testset "WithAD instantiates" begin
                    with = Traits.WithAD()
                    Test.@test with isa Traits.WithAD
                end

                Test.@testset "WithAD subtypes AbstractADTrait" begin
                    Test.@test Traits.WithAD <: Traits.AbstractADTrait
                end
            end

            Test.@testset "WithoutAD" begin
                Test.@testset "WithoutAD is exported" begin
                    Test.@test isdefined(Traits, :WithoutAD)
                end

                Test.@testset "WithoutAD is concrete" begin
                    Test.@test !isabstracttype(Traits.WithoutAD)
                end

                Test.@testset "WithoutAD instantiates" begin
                    without = Traits.WithoutAD()
                    Test.@test without isa Traits.WithoutAD
                end

                Test.@testset "WithoutAD subtypes AbstractADTrait" begin
                    Test.@test Traits.WithoutAD <: Traits.AbstractADTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "UNIT TESTS - Type Hierarchy" begin
            Test.@testset "All AD traits subtype AbstractTrait" begin
                Test.@test Traits.WithAD <: Traits.AbstractTrait
                Test.@test Traits.WithoutAD <: Traits.AbstractTrait
            end
        end

        # ====================================================================
        # UNIT TESTS - ad_trait function
        # ====================================================================

        Test.@testset "UNIT TESTS - ad_trait function" begin
            Test.@testset "ad_trait default returns WithoutAD" begin
                Test.@test Traits.ad_trait(42) === Traits.WithoutAD
                Test.@test Traits.ad_trait("anything") === Traits.WithoutAD
                Test.@test Traits.ad_trait(nothing) === Traits.WithoutAD
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported AD trait types" begin
                for sym in (:AbstractADTrait, :WithAD, :WithoutAD)
                    Test.@test isdefined(Traits, sym)
                end
            end

            Test.@testset "Exported ad_trait function" begin
                Test.@test isdefined(Traits, :ad_trait)
            end
        end
    end
end

end # module

test_ad() = TestAD.test_ad()
