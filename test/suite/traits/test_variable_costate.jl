module TestVariableCostate

import Test
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_variable_costate()
    Test.@testset "Variable Costate Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Types" begin
            Test.@testset "AbstractVariableCostateCapability" begin
                Test.@testset "AbstractVariableCostateCapability is exported" begin
                    Test.@test isdefined(Traits, :AbstractVariableCostateCapability)
                end

                Test.@testset "AbstractVariableCostateCapability is abstract" begin
                    Test.@test isabstracttype(Traits.AbstractVariableCostateCapability)
                end

                Test.@testset "AbstractVariableCostateCapability subtypes AbstractTrait" begin
                    Test.@test Traits.AbstractVariableCostateCapability <: Traits.AbstractTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Concrete Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Concrete Trait Types" begin
            Test.@testset "SupportsVariableCostate" begin
                Test.@testset "SupportsVariableCostate is exported" begin
                    Test.@test isdefined(Traits, :SupportsVariableCostate)
                end

                Test.@testset "SupportsVariableCostate is concrete" begin
                    Test.@test !isabstracttype(Traits.SupportsVariableCostate)
                end

                Test.@testset "SupportsVariableCostate instantiates" begin
                    svc = Traits.SupportsVariableCostate()
                    Test.@test svc isa Traits.SupportsVariableCostate
                end

                Test.@testset "SupportsVariableCostate subtypes AbstractVariableCostateCapability" begin
                    Test.@test Traits.SupportsVariableCostate <: Traits.AbstractVariableCostateCapability
                end
            end

            Test.@testset "NoVariableCostate" begin
                Test.@testset "NoVariableCostate is exported" begin
                    Test.@test isdefined(Traits, :NoVariableCostate)
                end

                Test.@testset "NoVariableCostate is concrete" begin
                    Test.@test !isabstracttype(Traits.NoVariableCostate)
                end

                Test.@testset "NoVariableCostate instantiates" begin
                    nvc = Traits.NoVariableCostate()
                    Test.@test nvc isa Traits.NoVariableCostate
                end

                Test.@testset "NoVariableCostate subtypes AbstractVariableCostateCapability" begin
                    Test.@test Traits.NoVariableCostate <: Traits.AbstractVariableCostateCapability
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "UNIT TESTS - Type Hierarchy" begin
            Test.@testset "All variable costate traits subtype AbstractTrait" begin
                Test.@test Traits.SupportsVariableCostate <: Traits.AbstractTrait
                Test.@test Traits.NoVariableCostate <: Traits.AbstractTrait
            end

            Test.@testset "Variable costate traits subtype AbstractVariableCostateCapability" begin
                Test.@test Traits.SupportsVariableCostate <: Traits.AbstractVariableCostateCapability
                Test.@test Traits.NoVariableCostate <: Traits.AbstractVariableCostateCapability
            end
        end

        # ====================================================================
        # UNIT TESTS - variable_costate_trait function
        # ====================================================================

        Test.@testset "UNIT TESTS - variable_costate_trait function" begin
            Test.@testset "variable_costate_trait default returns NoVariableCostate" begin
                Test.@test Traits.variable_costate_trait(42) === Traits.NoVariableCostate
                Test.@test Traits.variable_costate_trait("anything") === Traits.NoVariableCostate
                Test.@test Traits.variable_costate_trait(nothing) === Traits.NoVariableCostate
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported variable costate trait types" begin
                for sym in (:AbstractVariableCostateCapability, :SupportsVariableCostate, :NoVariableCostate)
                    Test.@test isdefined(Traits, sym)
                end
            end

            Test.@testset "Exported variable_costate_trait function" begin
                Test.@test isdefined(Traits, :variable_costate_trait)
            end
        end
    end
end

end # module

test_variable_costate() = TestVariableCostate.test_variable_costate()
