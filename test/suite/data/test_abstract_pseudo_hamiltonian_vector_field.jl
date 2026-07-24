module TestAbstractPseudoHamiltonianVectorField

using Test: Test
import CTBase.Data
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake type for contract testing (defined at module top-level per testing-creation.md)
# ==============================================================================

struct FakePseudoHamiltonianVectorField{TD,VD,MD} <:
       Data.AbstractPseudoHamiltonianVectorField{TD,VD,MD} end

# ==============================================================================
# Test function
# ==============================================================================

function test_abstract_pseudo_hamiltonian_vector_field()
    Test.@testset "AbstractPseudoHamiltonianVectorField Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type Definition
        # ====================================================================

        Test.@testset "Abstract Type Definition" begin
            Test.@testset "AbstractPseudoHamiltonianVectorField exists" begin
                Test.@test isdefined(Data, :AbstractPseudoHamiltonianVectorField)
            end

            Test.@testset "AbstractPseudoHamiltonianVectorField is abstract" begin
                Test.@test isabstracttype(Data.AbstractPseudoHamiltonianVectorField)
            end

            Test.@testset "Subtypes AbstractVectorField" begin
                Test.@test Data.AbstractPseudoHamiltonianVectorField <:
                    Data.AbstractVectorField
            end

            Test.@testset "Not a subtype of AbstractHamiltonianVectorField" begin
                # Sibling hierarchy, mirroring AbstractPseudoHamiltonian vs AbstractHamiltonian
                Test.@test !(
                    Data.AbstractPseudoHamiltonianVectorField <:
                    Data.AbstractHamiltonianVectorField
                )
            end

            Test.@testset "FakePseudoHamiltonianVectorField subtypes AbstractPseudoHamiltonianVectorField" begin
                fake = FakePseudoHamiltonianVectorField{
                    Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace
                }()
                Test.@test fake isa Data.AbstractPseudoHamiltonianVectorField
                Test.@test fake isa Data.AbstractVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Trait Accessors on Abstract Type
        # ====================================================================

        Test.@testset "Trait Accessors on Abstract Type" begin
            Test.@testset "has_*_trait return true (inherited from AbstractVectorField)" begin
                fake = FakePseudoHamiltonianVectorField{
                    Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace
                }()
                Test.@test Traits.has_time_dependence_trait(fake) === true
                Test.@test Traits.has_variable_dependence_trait(fake) === true
                Test.@test Traits.has_mutability_trait(fake) === true
            end

            Test.@testset "trait values are read from type parameters" begin
                fake = FakePseudoHamiltonianVectorField{
                    Traits.NonAutonomous,Traits.NonFixed,Traits.InPlace
                }()
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
                fake = FakePseudoHamiltonianVectorField{
                    Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace
                }()
                Test.@test Traits.dynamics_trait(fake) === Traits.HamiltonianDynamics
            end

            Test.@testset "concrete PseudoHamiltonianVectorField returns HamiltonianDynamics" begin
                h̃vf = Data.PseudoHamiltonianVectorField(
                    (x, p, u) -> (p .* u, -x); is_autonomous=true, is_variable=false
                )
                Test.@test Traits.dynamics_trait(h̃vf) === Traits.HamiltonianDynamics
            end
        end

        # ====================================================================
        # UNIT TESTS - Liskov Substitution
        # ====================================================================

        Test.@testset "Liskov Substitution" begin
            Test.@testset "PseudoHamiltonianVectorField is an AbstractPseudoHamiltonianVectorField" begin
                h̃vf = Data.PseudoHamiltonianVectorField(
                    (x, p, u) -> (p .* u, -x); is_autonomous=true, is_variable=false
                )
                Test.@test h̃vf isa Data.AbstractPseudoHamiltonianVectorField
            end

            Test.@testset "PseudoHamiltonianVectorField type subtypes the abstract type" begin
                Test.@test Data.PseudoHamiltonianVectorField <:
                    Data.AbstractPseudoHamiltonianVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@test isdefined(Data, :AbstractPseudoHamiltonianVectorField)
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
function test_abstract_pseudo_hamiltonian_vector_field()
    return TestAbstractPseudoHamiltonianVectorField.test_abstract_pseudo_hamiltonian_vector_field()
end
