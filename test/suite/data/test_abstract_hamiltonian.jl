module TestAbstractHamiltonian

using Test: Test
import CTBase.Data
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake type for contract testing (defined at module top-level per testing-creation.md)
# ==============================================================================

struct FakeHamiltonian{TD,VD} <: Data.AbstractHamiltonian{TD,VD} end

# ==============================================================================
# Test function
# ==============================================================================

function test_abstract_hamiltonian()
    Test.@testset "AbstractHamiltonian Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type Definition
        # ====================================================================

        Test.@testset "Abstract Type Definition" begin
            Test.@testset "AbstractHamiltonian exists" begin
                Test.@test isdefined(Data, :AbstractHamiltonian)
            end

            Test.@testset "AbstractHamiltonian is exported" begin
                Test.@test isdefined(Data, :AbstractHamiltonian)
            end

            Test.@testset "FakeHamiltonian subtypes AbstractHamiltonian" begin
                fake = FakeHamiltonian{Traits.Autonomous,Traits.Fixed}()
                Test.@test fake isa Data.AbstractHamiltonian
            end
        end

        # ====================================================================
        # UNIT TESTS - Trait Accessors on Abstract Type
        # ====================================================================

        Test.@testset "Trait Accessors on Abstract Type" begin
            Test.@testset "has_time_dependence_trait returns true" begin
                fake = FakeHamiltonian{Traits.Autonomous,Traits.Fixed}()
                Test.@test Traits.has_time_dependence_trait(fake) === true
                Test.@test Base.invokelatest(Traits.has_time_dependence_trait, fake) ===
                    true
            end

            Test.@testset "has_variable_dependence_trait returns true" begin
                fake = FakeHamiltonian{Traits.Autonomous,Traits.Fixed}()
                Test.@test Traits.has_variable_dependence_trait(fake) === true
                Test.@test Base.invokelatest(Traits.has_variable_dependence_trait, fake) ===
                    true
            end

            Test.@testset "time_dependence returns correct trait" begin
                fake_aut = FakeHamiltonian{Traits.Autonomous,Traits.Fixed}()
                fake_nonaut = FakeHamiltonian{Traits.NonAutonomous,Traits.Fixed}()
                Test.@test Traits.time_dependence(fake_aut) === Traits.Autonomous
                Test.@test Traits.time_dependence(fake_nonaut) === Traits.NonAutonomous
            end

            Test.@testset "variable_dependence returns correct trait" begin
                fake_fixed = FakeHamiltonian{Traits.Autonomous,Traits.Fixed}()
                fake_nonfixed = FakeHamiltonian{Traits.Autonomous,Traits.NonFixed}()
                Test.@test Traits.variable_dependence(fake_fixed) === Traits.Fixed
                Test.@test Traits.variable_dependence(fake_nonfixed) === Traits.NonFixed
            end

            Test.@testset "explicit dispatch on AbstractHamiltonian methods" begin
                fake = FakeHamiltonian{Traits.NonAutonomous,Traits.NonFixed}()

                Test.@test invoke(
                    Traits.has_time_dependence_trait, Tuple{Data.AbstractHamiltonian}, fake
                ) === true

                Test.@test invoke(
                    Traits.has_variable_dependence_trait,
                    Tuple{Data.AbstractHamiltonian},
                    fake,
                ) === true

                Test.@test invoke(
                    Traits.time_dependence,
                    Tuple{Data.AbstractHamiltonian{Traits.NonAutonomous,Traits.NonFixed}},
                    fake,
                ) === Traits.NonAutonomous

                Test.@test invoke(
                    Traits.variable_dependence,
                    Tuple{Data.AbstractHamiltonian{Traits.NonAutonomous,Traits.NonFixed}},
                    fake,
                ) === Traits.NonFixed
            end
        end

        # ====================================================================
        # UNIT TESTS - Dynamics Trait
        # ====================================================================

        Test.@testset "Dynamics Trait" begin
            Test.@testset "abstract type returns HamiltonianDynamics" begin
                fake = FakeHamiltonian{Traits.Autonomous,Traits.Fixed}()
                Test.@test Traits.dynamics_trait(fake) === Traits.HamiltonianDynamics
            end

            Test.@testset "concrete Hamiltonian returns HamiltonianDynamics" begin
                h = Data.Hamiltonian((x, p) -> x + p; is_autonomous=true, is_variable=false)
                Test.@test Traits.dynamics_trait(h) === Traits.HamiltonianDynamics
            end
        end

        # ====================================================================
        # UNIT TESTS - Liskov Substitution
        # ====================================================================

        Test.@testset "Liskov Substitution" begin
            Test.@testset "Hamiltonian is an AbstractHamiltonian" begin
                h = Data.Hamiltonian((x, p) -> x + p; is_autonomous=true, is_variable=false)
                Test.@test h isa Data.AbstractHamiltonian
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Stability
        # ====================================================================

        Test.@testset "Type Stability" begin
            Test.@testset "Trait accessors are type-stable" begin
                fake = FakeHamiltonian{Traits.Autonomous,Traits.Fixed}()
                Test.@test Test.@inferred(Traits.has_time_dependence_trait(fake)) === true
                Test.@test Test.@inferred(Traits.has_variable_dependence_trait(fake)) ===
                    true
                Test.@test Test.@inferred(Traits.time_dependence(fake)) ===
                    Traits.Autonomous
                Test.@test Test.@inferred(Traits.variable_dependence(fake)) === Traits.Fixed
            end
        end

        # ====================================================================
        # UNIT TESTS - Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported types" begin
                Test.@test isdefined(Data, :AbstractHamiltonian)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_abstract_hamiltonian() = TestAbstractHamiltonian.test_abstract_hamiltonian()
