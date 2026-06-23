module TestDynamics

import Test
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_dynamics()
    Test.@testset "Dynamics Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Abstract Types" begin
            Test.@testset "AbstractDynamicsTrait" begin
                Test.@testset "AbstractDynamicsTrait is exported" begin
                    Test.@test isdefined(Traits, :AbstractDynamicsTrait)
                end

                Test.@testset "AbstractDynamicsTrait is abstract" begin
                    Test.@test isabstracttype(Traits.AbstractDynamicsTrait)
                end

                Test.@testset "AbstractDynamicsTrait subtypes AbstractTrait" begin
                    Test.@test Traits.AbstractDynamicsTrait <: Traits.AbstractTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Concrete Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Concrete Trait Types" begin
            Test.@testset "StateDynamics" begin
                Test.@testset "StateDynamics is exported" begin
                    Test.@test isdefined(Traits, :StateDynamics)
                end

                Test.@testset "StateDynamics is concrete" begin
                    Test.@test !isabstracttype(Traits.StateDynamics)
                end

                Test.@testset "StateDynamics instantiates" begin
                    st = Traits.StateDynamics()
                    Test.@test st isa Traits.StateDynamics
                end

                Test.@testset "StateDynamics subtypes AbstractDynamicsTrait" begin
                    Test.@test Traits.StateDynamics <: Traits.AbstractDynamicsTrait
                end
            end

            Test.@testset "HamiltonianDynamics" begin
                Test.@testset "HamiltonianDynamics is exported" begin
                    Test.@test isdefined(Traits, :HamiltonianDynamics)
                end

                Test.@testset "HamiltonianDynamics is concrete" begin
                    Test.@test !isabstracttype(Traits.HamiltonianDynamics)
                end

                Test.@testset "HamiltonianDynamics instantiates" begin
                    ham = Traits.HamiltonianDynamics()
                    Test.@test ham isa Traits.HamiltonianDynamics
                end

                Test.@testset "HamiltonianDynamics subtypes AbstractDynamicsTrait" begin
                    Test.@test Traits.HamiltonianDynamics <: Traits.AbstractDynamicsTrait
                end
            end

            Test.@testset "AugmentedHamiltonianDynamics" begin
                Test.@testset "AugmentedHamiltonianDynamics is exported" begin
                    Test.@test isdefined(Traits, :AugmentedHamiltonianDynamics)
                end

                Test.@testset "AugmentedHamiltonianDynamics is concrete" begin
                    Test.@test !isabstracttype(Traits.AugmentedHamiltonianDynamics)
                end

                Test.@testset "AugmentedHamiltonianDynamics instantiates" begin
                    aug = Traits.AugmentedHamiltonianDynamics()
                    Test.@test aug isa Traits.AugmentedHamiltonianDynamics
                end

                Test.@testset "AugmentedHamiltonianDynamics subtypes AbstractDynamicsTrait" begin
                    Test.@test Traits.AugmentedHamiltonianDynamics <: Traits.AbstractDynamicsTrait
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================

        Test.@testset "UNIT TESTS - Type Hierarchy" begin
            Test.@testset "All dynamics traits subtype AbstractTrait" begin
                Test.@test Traits.StateDynamics <: Traits.AbstractTrait
                Test.@test Traits.HamiltonianDynamics <: Traits.AbstractTrait
                Test.@test Traits.AugmentedHamiltonianDynamics <: Traits.AbstractTrait
            end

            Test.@testset "Dynamics traits are distinct from mode traits" begin
                Test.@test !(Traits.StateDynamics <: Traits.AbstractModeTrait)
                Test.@test !(Traits.HamiltonianDynamics <: Traits.AbstractModeTrait)
                Test.@test !(Traits.AugmentedHamiltonianDynamics <: Traits.AbstractModeTrait)
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported dynamics trait types" begin
                for sym in (:AbstractDynamicsTrait, :StateDynamics, :HamiltonianDynamics, :AugmentedHamiltonianDynamics)
                    Test.@test isdefined(Traits, sym)
                end
            end
        end
    end
end

end # module

test_dynamics() = TestDynamics.test_dynamics()
