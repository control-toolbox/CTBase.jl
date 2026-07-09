module TestAbstractMultiplier

using Test: Test
import CTBase.Data
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake type for contract testing (defined at module top-level per testing-creation.md)
# ==============================================================================

struct FakeMultiplier{TD,VD} <: Data.AbstractMultiplier{TD,VD} end

# ==============================================================================
# Test function
# ==============================================================================

function test_abstract_multiplier()
    Test.@testset "AbstractMultiplier Tests" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type Definition
        # ====================================================================

        Test.@testset "Abstract Type Definition" begin
            Test.@test isdefined(Data, :AbstractMultiplier)
            Test.@test isabstracttype(Data.AbstractMultiplier)

            fake = FakeMultiplier{Traits.Autonomous,Traits.Fixed}()
            Test.@test fake isa Data.AbstractMultiplier
        end

        # ====================================================================
        # UNIT TESTS - Trait Accessors on Abstract Type
        # ====================================================================

        Test.@testset "Trait Accessors on Abstract Type" begin
            Test.@testset "has_*_trait return true" begin
                fake = FakeMultiplier{Traits.Autonomous,Traits.Fixed}()
                Test.@test Traits.has_time_dependence_trait(fake) === true
                Test.@test Traits.has_variable_dependence_trait(fake) === true
            end

            Test.@testset "time/variable dependence return correct trait" begin
                fake_aut = FakeMultiplier{Traits.Autonomous,Traits.Fixed}()
                fake_nonaut = FakeMultiplier{Traits.NonAutonomous,Traits.NonFixed}()
                Test.@test Traits.time_dependence(fake_aut) === Traits.Autonomous
                Test.@test Traits.time_dependence(fake_nonaut) === Traits.NonAutonomous
                Test.@test Traits.variable_dependence(fake_aut) === Traits.Fixed
                Test.@test Traits.variable_dependence(fake_nonaut) === Traits.NonFixed
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Stability
        # ====================================================================

        Test.@testset "Type Stability" begin
            fake = FakeMultiplier{Traits.Autonomous,Traits.Fixed}()
            Test.@test Test.@inferred(Traits.time_dependence(fake)) === Traits.Autonomous
            Test.@test Test.@inferred(Traits.variable_dependence(fake)) === Traits.Fixed
        end

        # ====================================================================
        # UNIT TESTS - Liskov Substitution
        # ====================================================================

        Test.@testset "Liskov Substitution" begin
            m = Data.Multiplier((x, p) -> x[1])
            Test.@test m isa Data.AbstractMultiplier
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_abstract_multiplier() = TestAbstractMultiplier.test_abstract_multiplier()
