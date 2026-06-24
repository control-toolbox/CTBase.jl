module TestAbstractHamiltonianVectorField

import Test
import CTBase.Data
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake type for contract testing (defined at module top-level per testing-creation.md)
# ==============================================================================

struct FakeHamiltonianVectorField{TD, VD, MD} <: Data.AbstractHamiltonianVectorField{TD, VD, MD} end

# ==============================================================================
# Test function
# ==============================================================================

function test_abstract_hamiltonian_vector_field()
    Test.@testset "AbstractHamiltonianVectorField Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type Definition
        # ====================================================================

        Test.@testset "Abstract Type Definition" begin
            Test.@testset "AbstractHamiltonianVectorField exists" begin
                Test.@test isdefined(Data, :AbstractHamiltonianVectorField)
            end

            Test.@testset "AbstractHamiltonianVectorField is abstract" begin
                Test.@test isabstracttype(Data.AbstractHamiltonianVectorField)
            end

            Test.@testset "Subtypes AbstractVectorField" begin
                Test.@test Data.AbstractHamiltonianVectorField <: Data.AbstractVectorField
            end

            Test.@testset "FakeHamiltonianVectorField subtypes AbstractHamiltonianVectorField" begin
                fake = FakeHamiltonianVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test fake isa Data.AbstractHamiltonianVectorField
                Test.@test fake isa Data.AbstractVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Trait Accessors on Abstract Type
        # ====================================================================

        Test.@testset "Trait Accessors on Abstract Type" begin
            Test.@testset "has_*_trait return true (inherited from AbstractVectorField)" begin
                fake = FakeHamiltonianVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test Traits.has_time_dependence_trait(fake) === true
                Test.@test Traits.has_variable_dependence_trait(fake) === true
                Test.@test Traits.has_mutability_trait(fake) === true
            end

            Test.@testset "trait values are read from type parameters" begin
                fake = FakeHamiltonianVectorField{Traits.NonAutonomous, Traits.NonFixed, Traits.InPlace}()
                Test.@test Traits.time_dependence(fake) === Traits.NonAutonomous
                Test.@test Traits.variable_dependence(fake) === Traits.NonFixed
                Test.@test Traits.mutability(fake) === Traits.InPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - Dynamics Trait
        # ====================================================================

        Test.@testset "Dynamics Trait" begin
            Test.@testset "abstract type returns HamiltonianDynamics" begin
                fake = FakeHamiltonianVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test Traits.dynamics_trait(fake) === Traits.HamiltonianDynamics
            end

            Test.@testset "concrete HamiltonianVectorField returns HamiltonianDynamics" begin
                hvf = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
                Test.@test Traits.dynamics_trait(hvf) === Traits.HamiltonianDynamics
            end
        end

        # ====================================================================
        # UNIT TESTS - Liskov Substitution
        # ====================================================================

        Test.@testset "Liskov Substitution" begin
            Test.@testset "HamiltonianVectorField is an AbstractHamiltonianVectorField" begin
                hvf = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
                Test.@test hvf isa Data.AbstractHamiltonianVectorField
            end

            Test.@testset "HamiltonianVectorField type subtypes the abstract type" begin
                Test.@test Data.HamiltonianVectorField <: Data.AbstractHamiltonianVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@test isdefined(Data, :AbstractHamiltonianVectorField)
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_abstract_hamiltonian_vector_field() = TestAbstractHamiltonianVectorField.test_abstract_hamiltonian_vector_field()
