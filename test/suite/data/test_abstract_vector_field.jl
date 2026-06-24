module TestAbstractVectorField

import Test
import CTBase.Data
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake type for contract testing (defined at module top-level per testing-creation.md)
# ==============================================================================

struct FakeVectorField{TD, VD, MD} <: Data.AbstractVectorField{TD, VD, MD} end

# ==============================================================================
# Test function
# ==============================================================================

function test_abstract_vector_field()
    Test.@testset "AbstractVectorField Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type Definition
        # ====================================================================

        Test.@testset "Abstract Type Definition" begin
            Test.@testset "AbstractVectorField exists" begin
                Test.@test isdefined(Data, :AbstractVectorField)
            end

            Test.@testset "AbstractVectorField is exported" begin
                Test.@test isdefined(Data, :AbstractVectorField)
            end

            Test.@testset "FakeVectorField subtypes AbstractVectorField" begin
                fake = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test fake isa Data.AbstractVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Trait Accessors on Abstract Type
        # ====================================================================

        Test.@testset "Trait Accessors on Abstract Type" begin
            Test.@testset "has_time_dependence_trait returns true" begin
                fake = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test Traits.has_time_dependence_trait(fake) === true
                Test.@test Base.invokelatest(Traits.has_time_dependence_trait, fake) === true
            end

            Test.@testset "has_variable_dependence_trait returns true" begin
                fake = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test Traits.has_variable_dependence_trait(fake) === true
                Test.@test Base.invokelatest(Traits.has_variable_dependence_trait, fake) === true
            end

            Test.@testset "has_mutability_trait returns true" begin
                fake = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test Traits.has_mutability_trait(fake) === true
                Test.@test Base.invokelatest(Traits.has_mutability_trait, fake) === true
            end

            Test.@testset "time_dependence returns correct trait" begin
                fake_aut = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                fake_nonaut = FakeVectorField{Traits.NonAutonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test Traits.time_dependence(fake_aut) === Traits.Autonomous
                Test.@test Traits.time_dependence(fake_nonaut) === Traits.NonAutonomous
            end

            Test.@testset "variable_dependence returns correct trait" begin
                fake_fixed = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                fake_nonfixed = FakeVectorField{Traits.Autonomous, Traits.NonFixed, Traits.OutOfPlace}()
                Test.@test Traits.variable_dependence(fake_fixed) === Traits.Fixed
                Test.@test Traits.variable_dependence(fake_nonfixed) === Traits.NonFixed
            end

            Test.@testset "mutability returns correct trait" begin
                fake_oop = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                fake_ip = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.InPlace}()
                Test.@test Traits.mutability(fake_oop) === Traits.OutOfPlace
                Test.@test Traits.mutability(fake_ip) === Traits.InPlace
            end

            Test.@testset "explicit dispatch on AbstractVectorField methods" begin
                fake = FakeVectorField{Traits.NonAutonomous, Traits.NonFixed, Traits.InPlace}()

                Test.@test invoke(
                    Traits.has_time_dependence_trait,
                    Tuple{Data.AbstractVectorField},
                    fake,
                ) === true

                Test.@test invoke(
                    Traits.has_variable_dependence_trait,
                    Tuple{Data.AbstractVectorField},
                    fake,
                ) === true

                Test.@test invoke(
                    Traits.has_mutability_trait,
                    Tuple{Data.AbstractVectorField},
                    fake,
                ) === true

                Test.@test invoke(
                    Traits.time_dependence,
                    Tuple{Data.AbstractVectorField{Traits.NonAutonomous, Traits.NonFixed, Traits.InPlace}},
                    fake,
                ) === Traits.NonAutonomous

                Test.@test invoke(
                    Traits.variable_dependence,
                    Tuple{Data.AbstractVectorField{Traits.NonAutonomous, Traits.NonFixed, Traits.InPlace}},
                    fake,
                ) === Traits.NonFixed

                Test.@test invoke(
                    Traits.mutability,
                    Tuple{Data.AbstractVectorField{Traits.NonAutonomous, Traits.NonFixed, Traits.InPlace}},
                    fake,
                ) === Traits.InPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - Dynamics Trait
        # ====================================================================

        Test.@testset "Dynamics Trait" begin
            Test.@testset "abstract type returns StateDynamics" begin
                fake = FakeVectorField{Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace}()
                Test.@test Traits.dynamics_trait(fake) === Traits.StateDynamics
            end

            Test.@testset "concrete VectorField returns StateDynamics" begin
                vf = Data.VectorField(x -> -x; is_autonomous=true, is_variable=false)
                Test.@test Traits.dynamics_trait(vf) === Traits.StateDynamics
            end
        end

        # ====================================================================
        # UNIT TESTS - Liskov Substitution
        # ====================================================================

        Test.@testset "Liskov Substitution" begin
            Test.@testset "VectorField is an AbstractVectorField" begin
                vf = Data.VectorField(x -> -x; is_autonomous=true, is_variable=false)
                Test.@test vf isa Data.AbstractVectorField
            end

            Test.@testset "HamiltonianVectorField is an AbstractVectorField" begin
                hvf = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
                Test.@test hvf isa Data.AbstractVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported types" begin
                Test.@test isdefined(Data, :AbstractVectorField)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_abstract_vector_field() = TestAbstractVectorField.test_abstract_vector_field()
