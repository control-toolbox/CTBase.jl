module TestMutability

using Test: Test
import CTBase.Exceptions
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake types for contract testing
# ==============================================================================

"""
Fake type for testing mutability trait pattern with InPlace.
"""
struct FakeInPlace end

Traits.has_mutability_trait(::FakeInPlace) = true
Traits.mutability(::FakeInPlace) = Traits.InPlace

"""
Fake type for testing mutability trait pattern with OutOfPlace.
"""
struct FakeOutOfPlace end

Traits.has_mutability_trait(::FakeOutOfPlace) = true
Traits.mutability(::FakeOutOfPlace) = Traits.OutOfPlace

"""
Fake type for testing mutability trait without the trait.
"""
struct FakeNoMutability end

function test_mutability()
    Test.@testset "Mutability Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Types" begin
            Test.@testset "AbstractMutabilityTrait" begin
                Test.@testset "AbstractMutabilityTrait is exported" begin
                    Test.@test isdefined(Traits, :AbstractMutabilityTrait)
                end

                Test.@testset "AbstractMutabilityTrait is abstract" begin
                    Test.@test isabstracttype(Traits.AbstractMutabilityTrait)
                end

                Test.@testset "AbstractMutabilityTrait subtypes AbstractTrait" begin
                    Test.@test Traits.AbstractMutabilityTrait <: Traits.AbstractTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Concrete Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Concrete Trait Types" begin
            Test.@testset "InPlace" begin
                Test.@testset "InPlace is exported" begin
                    Test.@test isdefined(Traits, :InPlace)
                end

                Test.@testset "InPlace is concrete" begin
                    Test.@test !isabstracttype(Traits.InPlace)
                end

                Test.@testset "InPlace instantiates" begin
                    ip = Traits.InPlace()
                    Test.@test ip isa Traits.InPlace
                end

                Test.@testset "InPlace subtypes AbstractMutabilityTrait" begin
                    Test.@test Traits.InPlace <: Traits.AbstractMutabilityTrait
                end
            end

            Test.@testset "OutOfPlace" begin
                Test.@testset "OutOfPlace is exported" begin
                    Test.@test isdefined(Traits, :OutOfPlace)
                end

                Test.@testset "OutOfPlace is concrete" begin
                    Test.@test !isabstracttype(Traits.OutOfPlace)
                end

                Test.@testset "OutOfPlace instantiates" begin
                    oop = Traits.OutOfPlace()
                    Test.@test oop isa Traits.OutOfPlace
                end

                Test.@testset "OutOfPlace subtypes AbstractMutabilityTrait" begin
                    Test.@test Traits.OutOfPlace <: Traits.AbstractMutabilityTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "UNIT TESTS - Type Hierarchy" begin
            Test.@testset "All mutability traits subtype AbstractTrait" begin
                Test.@test Traits.InPlace <: Traits.AbstractTrait
                Test.@test Traits.OutOfPlace <: Traits.AbstractTrait
            end
        end

        # ====================================================================
        # ERROR TESTS - Fallback Methods
        # ====================================================================

        Test.@testset "ERROR TESTS - Fallback Methods" begin
            Test.@testset "has_mutability_trait throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.has_mutability_trait(
                    obj
                )
            end

            Test.@testset "mutability throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.mutability(obj)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - Mutability Trait Pattern
        # ====================================================================

        Test.@testset "CONTRACT TESTS - Mutability Trait Pattern" begin
            Test.@testset "FakeInPlace trait implementation" begin
                obj = FakeInPlace()
                Test.@test Traits.has_mutability_trait(obj) === true
                Test.@test Traits.mutability(obj) === Traits.InPlace
                Test.@test Traits.is_inplace(obj) === true
                Test.@test Traits.is_outofplace(obj) === false
            end

            Test.@testset "FakeOutOfPlace trait implementation" begin
                obj = FakeOutOfPlace()
                Test.@test Traits.has_mutability_trait(obj) === true
                Test.@test Traits.mutability(obj) === Traits.OutOfPlace
                Test.@test Traits.is_inplace(obj) === false
                Test.@test Traits.is_outofplace(obj) === true
            end

            Test.@testset "FakeNoMutability throws errors" begin
                obj = FakeNoMutability()
                Test.@test_throws Exceptions.IncorrectArgument Traits.is_inplace(obj)
                Test.@test_throws Exceptions.IncorrectArgument Traits.mutability(obj)
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported mutability trait types" begin
                for sym in (:AbstractMutabilityTrait, :InPlace, :OutOfPlace)
                    Test.@test isdefined(Traits, sym)
                end
            end

            Test.@testset "Exported mutability trait functions" begin
                for sym in (:has_mutability_trait, :mutability, :is_inplace, :is_outofplace)
                    Test.@test isdefined(Traits, sym)
                end
            end
        end
    end
end

end # module

test_mutability() = TestMutability.test_mutability()
