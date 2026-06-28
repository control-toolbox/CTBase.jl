module TestControlDependence

using Test: Test
import CTBase.Exceptions
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake types for contract testing
# ==============================================================================

"""
Fake type for testing control-dependence trait pattern.
Implements both required methods: has_control_dependence_trait and control_dependence.
"""
struct FakeControlFree end

Traits.has_control_dependence_trait(::FakeControlFree) = true
Traits.control_dependence(::FakeControlFree) = Traits.ControlFree

"""
Fake type for testing control-dependence trait pattern with WithControl.
"""
struct FakeWithControl end

Traits.has_control_dependence_trait(::FakeWithControl) = true
Traits.control_dependence(::FakeWithControl) = Traits.WithControl

function test_control_dependence()
    Test.@testset "Control Dependence Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Trait Types" begin
            Test.@testset "ControlDependence abstract type" begin
                Test.@test isdefined(Traits, :ControlDependence)
                Test.@test Traits.ControlFree <: Traits.ControlDependence
                Test.@test Traits.WithControl <: Traits.ControlDependence
                Test.@test Traits.ControlDependence <: Traits.AbstractTrait
            end

            Test.@testset "Concrete trait types" begin
                Test.@test Traits.ControlFree() isa Traits.ControlFree
                Test.@test Traits.WithControl() isa Traits.WithControl
            end
        end

        # ====================================================================
        # ERROR TESTS - Fallback Methods
        # ====================================================================

        Test.@testset "ERROR TESTS - Fallback Methods" begin
            Test.@testset "has_control_dependence_trait throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.has_control_dependence_trait(
                    obj
                )
            end

            Test.@testset "control_dependence throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.control_dependence(
                    obj
                )
            end

            Test.@testset "predicates throw on objects without the trait" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.is_control_free(obj)
                Test.@test_throws Exceptions.IncorrectArgument Traits.has_control(obj)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - Control-Dependence Trait Pattern
        # ====================================================================

        Test.@testset "CONTRACT TESTS - Control-Dependence Trait Pattern" begin
            Test.@testset "FakeControlFree trait implementation" begin
                obj = FakeControlFree()
                Test.@test Traits.has_control_dependence_trait(obj) === true
                Test.@test Traits.control_dependence(obj) === Traits.ControlFree
                Test.@test Traits.is_control_free(obj) === true
                Test.@test Traits.has_control(obj) === false
            end

            Test.@testset "FakeWithControl trait implementation" begin
                obj = FakeWithControl()
                Test.@test Traits.has_control_dependence_trait(obj) === true
                Test.@test Traits.control_dependence(obj) === Traits.WithControl
                Test.@test Traits.is_control_free(obj) === false
                Test.@test Traits.has_control(obj) === true
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported control-dependence trait types" begin
                for sym in (:ControlDependence, :ControlFree, :WithControl)
                    Test.@test isdefined(Traits, sym)
                end
            end

            Test.@testset "Exported control-dependence trait functions" begin
                for sym in (
                    :has_control_dependence_trait,
                    :control_dependence,
                    :is_control_free,
                    :has_control,
                )
                    Test.@test isdefined(Traits, sym)
                end
            end
        end
    end
end

end # module

test_control_dependence() = TestControlDependence.test_control_dependence()
