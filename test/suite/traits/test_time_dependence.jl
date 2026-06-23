module TestTimeDependence

import Test
import CTBase.Exceptions
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ==============================================================================
# Fake types for contract testing
# ==============================================================================

"""
Fake type for testing time-dependence trait pattern.
Implements both required methods: has_time_dependence_trait and time_dependence.
"""
struct FakeAutonomous end

Traits.has_time_dependence_trait(::FakeAutonomous; kwargs...) = true
Traits.time_dependence(::FakeAutonomous) = Traits.Autonomous

"""
Fake type for testing time-dependence trait pattern with NonAutonomous.
"""
struct FakeNonAutonomous end

Traits.has_time_dependence_trait(::FakeNonAutonomous) = true
Traits.time_dependence(::FakeNonAutonomous) = Traits.NonAutonomous

function test_time_dependence()
    Test.@testset "Time Dependence Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Trait Types" begin
            Test.@testset "TimeDependence abstract type" begin
                Test.@test isdefined(Traits, :TimeDependence)
                Test.@test Traits.Autonomous <: Traits.TimeDependence
                Test.@test Traits.NonAutonomous <: Traits.TimeDependence
            end
        end

        # ====================================================================
        # ERROR TESTS - Fallback Methods
        # ====================================================================

        Test.@testset "ERROR TESTS - Fallback Methods" begin
            Test.@testset "has_time_dependence_trait throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.has_time_dependence_trait(obj)
            end

            Test.@testset "time_dependence throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.time_dependence(obj)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - Time-Dependence Trait Pattern
        # ====================================================================

        Test.@testset "CONTRACT TESTS - Time-Dependence Trait Pattern" begin
            Test.@testset "FakeAutonomous trait implementation" begin
                obj = FakeAutonomous()
                Test.@test Traits.has_time_dependence_trait(obj) === true
                Test.@test Traits.time_dependence(obj) === Traits.Autonomous
                Test.@test Traits.is_autonomous(obj) === true
                Test.@test Traits.is_nonautonomous(obj) === false
            end

            Test.@testset "FakeNonAutonomous trait implementation" begin
                obj = FakeNonAutonomous()
                Test.@test Traits.has_time_dependence_trait(obj) === true
                Test.@test Traits.time_dependence(obj) === Traits.NonAutonomous
                Test.@test Traits.is_autonomous(obj) === false
                Test.@test Traits.is_nonautonomous(obj) === true
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported time-dependence trait functions" begin
                for sym in (:has_time_dependence_trait, :time_dependence)
                    Test.@test isdefined(Traits, sym)
                end
            end
        end
    end
end

end # module

test_time_dependence() = TestTimeDependence.test_time_dependence()
