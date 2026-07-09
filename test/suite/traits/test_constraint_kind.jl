module TestConstraintKind

using Test: Test
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestTraits) ? Main.TestTraits.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestTraits) ? Main.TestTraits.SHOWTIMING : true

function test_constraint_kind()
    Test.@testset "Constraint-Kind Trait Tests" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Type
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Type" begin
            Test.@test isdefined(Traits, :AbstractConstraintKind)
            Test.@test isabstracttype(Traits.AbstractConstraintKind)
            Test.@test Traits.AbstractConstraintKind <: Traits.AbstractTrait
        end

        # ====================================================================
        # UNIT TESTS - Concrete Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Concrete Trait Types" begin
            for K in (
                Traits.StateConstraintKind,
                Traits.ControlConstraintKind,
                Traits.MixedConstraintKind,
            )
                Test.@testset "$(K)" begin
                    Test.@test isdefined(Traits, nameof(K))
                    Test.@test !isabstracttype(K)
                    Test.@test K() isa K
                    Test.@test K <: Traits.AbstractConstraintKind
                    Test.@test K <: Traits.AbstractTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "UNIT TESTS - Type Hierarchy" begin
            Test.@testset "Distinct from feedback traits" begin
                Test.@test !(Traits.StateConstraintKind <: Traits.AbstractFeedback)
                Test.@test !(Traits.ControlConstraintKind <: Traits.AbstractFeedback)
                Test.@test !(Traits.MixedConstraintKind <: Traits.AbstractFeedback)
            end
        end

        # ====================================================================
        # UNIT TESTS - accessor and predicates
        # ====================================================================

        Test.@testset "UNIT TESTS - accessor and predicates" begin
            Test.@test isdefined(Traits, :constraint_kind)
            Test.@test isa(Traits.constraint_kind, Function)
            Test.@test isdefined(Traits, :is_state_constraint)
            Test.@test isdefined(Traits, :is_control_constraint)
            Test.@test isdefined(Traits, :is_mixed_constraint)
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            for sym in (
                :AbstractConstraintKind,
                :StateConstraintKind,
                :ControlConstraintKind,
                :MixedConstraintKind,
                :constraint_kind,
                :is_state_constraint,
                :is_control_constraint,
                :is_mixed_constraint,
            )
                Test.@test isdefined(Traits, sym)
            end
        end
    end
end

end # module

test_constraint_kind() = TestConstraintKind.test_constraint_kind()
