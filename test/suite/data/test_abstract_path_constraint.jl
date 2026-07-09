module TestAbstractPathConstraint

using Test: Test
import CTBase.Data
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake type for contract testing (defined at module top-level per testing-creation.md)
# ==============================================================================

struct FakePathConstraint{K,TD,VD} <: Data.AbstractPathConstraint{K,TD,VD} end

# ==============================================================================
# Test function
# ==============================================================================

function test_abstract_path_constraint()
    Test.@testset "AbstractPathConstraint Tests" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type Definition
        # ====================================================================

        Test.@testset "Abstract Type Definition" begin
            Test.@test isdefined(Data, :AbstractPathConstraint)
            Test.@test isabstracttype(Data.AbstractPathConstraint)

            fake = FakePathConstraint{
                Traits.StateConstraintKind,Traits.Autonomous,Traits.Fixed
            }()
            Test.@test fake isa Data.AbstractPathConstraint
        end

        # ====================================================================
        # UNIT TESTS - Trait Accessors on Abstract Type
        # ====================================================================

        Test.@testset "Trait Accessors on Abstract Type" begin
            Test.@testset "has_*_trait return true" begin
                fake = FakePathConstraint{
                    Traits.StateConstraintKind,Traits.Autonomous,Traits.Fixed
                }()
                Test.@test Traits.has_time_dependence_trait(fake) === true
                Test.@test Traits.has_variable_dependence_trait(fake) === true
            end

            Test.@testset "constraint_kind returns correct trait" begin
                fs = FakePathConstraint{
                    Traits.StateConstraintKind,Traits.Autonomous,Traits.Fixed
                }()
                fc = FakePathConstraint{
                    Traits.ControlConstraintKind,Traits.Autonomous,Traits.Fixed
                }()
                fm = FakePathConstraint{
                    Traits.MixedConstraintKind,Traits.Autonomous,Traits.Fixed
                }()
                Test.@test Traits.constraint_kind(fs) === Traits.StateConstraintKind
                Test.@test Traits.constraint_kind(fc) === Traits.ControlConstraintKind
                Test.@test Traits.constraint_kind(fm) === Traits.MixedConstraintKind
            end

            Test.@testset "time/variable dependence return correct trait" begin
                fake = FakePathConstraint{
                    Traits.MixedConstraintKind,Traits.NonAutonomous,Traits.NonFixed
                }()
                Test.@test Traits.time_dependence(fake) === Traits.NonAutonomous
                Test.@test Traits.variable_dependence(fake) === Traits.NonFixed
            end

            Test.@testset "predicates dispatch on the K parameter" begin
                fs = FakePathConstraint{
                    Traits.StateConstraintKind,Traits.Autonomous,Traits.Fixed
                }()
                fc = FakePathConstraint{
                    Traits.ControlConstraintKind,Traits.Autonomous,Traits.Fixed
                }()
                fm = FakePathConstraint{
                    Traits.MixedConstraintKind,Traits.Autonomous,Traits.Fixed
                }()
                Test.@test Traits.is_state_constraint(fs)
                Test.@test !Traits.is_control_constraint(fs)
                Test.@test !Traits.is_mixed_constraint(fs)

                Test.@test Traits.is_control_constraint(fc)
                Test.@test !Traits.is_state_constraint(fc)

                Test.@test Traits.is_mixed_constraint(fm)
                Test.@test !Traits.is_state_constraint(fm)
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Stability
        # ====================================================================

        Test.@testset "Type Stability" begin
            fake = FakePathConstraint{
                Traits.StateConstraintKind,Traits.Autonomous,Traits.Fixed
            }()
            Test.@test Test.@inferred(Traits.constraint_kind(fake)) ===
                Traits.StateConstraintKind
            Test.@test Test.@inferred(Traits.time_dependence(fake)) === Traits.Autonomous
            Test.@test Test.@inferred(Traits.variable_dependence(fake)) === Traits.Fixed
        end

        # ====================================================================
        # UNIT TESTS - Liskov Substitution
        # ====================================================================

        Test.@testset "Liskov Substitution" begin
            g = Data.StateConstraint(x -> x[1])
            Test.@test g isa Data.AbstractPathConstraint
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_abstract_path_constraint() = TestAbstractPathConstraint.test_abstract_path_constraint()
