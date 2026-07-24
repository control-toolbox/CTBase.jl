module TestPseudoHamiltonianVectorField

using Test: Test
import CTBase.Data: Data
import CTBase.Traits: Traits
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Fake function with multiple methods for testing
_multi_method_phvf(x::Int, p, u) = (p .* u, -x)
_multi_method_phvf(x::Float64, p, u) = (p .* u, -x)
_multi_method_phvf(x::AbstractVector, p, u) = (p .* u, -x)

# TOP-LEVEL: Fake function with invalid arity for testing error branches
_bad_arity_phvf(x) = (x, -x)

function test_pseudo_hamiltonian_vector_field()
    Test.@testset "Pseudo-Hamiltonian Vector Field Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Construction
        # ====================================================================

        Test.@testset "Construction" begin
            # Autonomous, Fixed
            phvf_autonomous_fixed = Data.PseudoHamiltonianVectorField(
                (x, p, u) -> (x .+ u, -p); is_autonomous=true, is_variable=false
            )
            Test.@test phvf_autonomous_fixed isa Data.PseudoHamiltonianVectorField
            Test.@test Traits.time_dependence(phvf_autonomous_fixed) == Traits.Autonomous
            Test.@test Traits.variable_dependence(phvf_autonomous_fixed) == Traits.Fixed

            # NonAutonomous, Fixed
            phvf_nonautonomous_fixed = Data.PseudoHamiltonianVectorField(
                (t, x, p, u) -> (t .* x .+ u, -p); is_autonomous=false, is_variable=false
            )
            Test.@test phvf_nonautonomous_fixed isa Data.PseudoHamiltonianVectorField
            Test.@test Traits.time_dependence(phvf_nonautonomous_fixed) ==
                Traits.NonAutonomous
            Test.@test Traits.variable_dependence(phvf_nonautonomous_fixed) == Traits.Fixed

            # Autonomous, NonFixed
            phvf_autonomous_nonfixed = Data.PseudoHamiltonianVectorField(
                (x, p, u, v) -> (x .* v .+ u, -p); is_autonomous=true, is_variable=true
            )
            Test.@test phvf_autonomous_nonfixed isa Data.PseudoHamiltonianVectorField
            Test.@test Traits.time_dependence(phvf_autonomous_nonfixed) ==
                Traits.Autonomous
            Test.@test Traits.variable_dependence(phvf_autonomous_nonfixed) ==
                Traits.NonFixed

            # NonAutonomous, NonFixed
            phvf_nonautonomous_nonfixed = Data.PseudoHamiltonianVectorField(
                (t, x, p, u, v) -> (t .* x .* v .+ u, -p);
                is_autonomous=false,
                is_variable=true,
            )
            Test.@test phvf_nonautonomous_nonfixed isa Data.PseudoHamiltonianVectorField
            Test.@test Traits.time_dependence(phvf_nonautonomous_nonfixed) ==
                Traits.NonAutonomous
            Test.@test Traits.variable_dependence(phvf_nonautonomous_nonfixed) ==
                Traits.NonFixed
        end

        # ====================================================================
        # UNIT TESTS - Natural signatures
        # ====================================================================

        Test.@testset "Natural Signatures" begin
            # (x, p, u) for Autonomous, Fixed
            phvf1 = Data.PseudoHamiltonianVectorField(
                (x, p, u) -> (x .+ u, -p); is_autonomous=true, is_variable=false
            )
            dx, dp = phvf1([1.0, 2.0], [3.0, 4.0], [0.5, 0.5])
            Test.@test dx == [1.5, 2.5]
            Test.@test dp == [-3.0, -4.0]

            # (t, x, p, u) for NonAutonomous, Fixed
            phvf2 = Data.PseudoHamiltonianVectorField(
                (t, x, p, u) -> (t .* x .+ u, -p); is_autonomous=false, is_variable=false
            )
            dx, dp = phvf2(2.0, [1.0, 2.0], [3.0, 4.0], [0.5, 0.5])
            Test.@test dx == [2.5, 4.5]
            Test.@test dp == [-3.0, -4.0]

            # (x, p, u, v) for Autonomous, NonFixed
            phvf3 = Data.PseudoHamiltonianVectorField(
                (x, p, u, v) -> (x .* v .+ u, -p); is_autonomous=true, is_variable=true
            )
            dx, dp = phvf3([1.0, 2.0], [3.0, 4.0], [0.5, 0.5], 2.0)
            Test.@test dx == [2.5, 4.5]
            Test.@test dp == [-3.0, -4.0]

            # (t, x, p, u, v) for NonAutonomous, NonFixed
            phvf4 = Data.PseudoHamiltonianVectorField(
                (t, x, p, u, v) -> (t .* x .* v .+ u, -p);
                is_autonomous=false,
                is_variable=true,
            )
            dx, dp = phvf4(2.0, [1.0, 2.0], [3.0, 4.0], [0.5, 0.5], 2.0)
            Test.@test dx == [4.5, 8.5]
            Test.@test dp == [-3.0, -4.0]
        end

        # ====================================================================
        # UNIT TESTS - Uniform signature
        # ====================================================================

        Test.@testset "Uniform Signature" begin
            phvf_autonomous_fixed = Data.PseudoHamiltonianVectorField(
                (x, p, u) -> (x .+ u, -p); is_autonomous=true, is_variable=false
            )
            dx, dp = phvf_autonomous_fixed(0.0, [1.0, 2.0], [3.0, 4.0], [0.5, 0.5], nothing)
            Test.@test dx == [1.5, 2.5]
            Test.@test dp == [-3.0, -4.0]

            phvf_nonautonomous_fixed = Data.PseudoHamiltonianVectorField(
                (t, x, p, u) -> (t .* x .+ u, -p); is_autonomous=false, is_variable=false
            )
            dx, dp = phvf_nonautonomous_fixed(
                2.0, [1.0, 2.0], [3.0, 4.0], [0.5, 0.5], nothing
            )
            Test.@test dx == [2.5, 4.5]
            Test.@test dp == [-3.0, -4.0]

            phvf_autonomous_nonfixed = Data.PseudoHamiltonianVectorField(
                (x, p, u, v) -> (x .* v .+ u, -p); is_autonomous=true, is_variable=true
            )
            dx, dp = phvf_autonomous_nonfixed(0.0, [1.0, 2.0], [3.0, 4.0], [0.5, 0.5], 2.0)
            Test.@test dx == [2.5, 4.5]
            Test.@test dp == [-3.0, -4.0]

            # Test variable_costate kwarg for NonFixed
            dx, dp = phvf_autonomous_nonfixed(
                0.0, [1.0, 2.0], [3.0, 4.0], [0.5, 0.5], 2.0; variable_costate=false
            )
            Test.@test dx == [2.5, 4.5]
            Test.@test dp == [-3.0, -4.0]
        end

        # ====================================================================
        # UNIT TESTS - Trait accessors
        # ====================================================================

        Test.@testset "Trait Accessors" begin
            phvf = Data.PseudoHamiltonianVectorField(
                (x, p, u) -> (x .+ u, -p); is_autonomous=true, is_variable=false
            )
            Test.@test Traits.has_time_dependence_trait(phvf) == true
            Test.@test Traits.has_variable_dependence_trait(phvf) == true
            Test.@test Traits.time_dependence(phvf) == Traits.Autonomous
            Test.@test Traits.variable_dependence(phvf) == Traits.Fixed
        end

        # ====================================================================
        # UNIT TESTS - Typed constructor (trait types passed positionally)
        # ====================================================================

        Test.@testset "Typed constructor" begin
            phvf = Data.PseudoHamiltonianVectorField(
                (x, p, u) -> (x .+ u, -p),
                Traits.Autonomous,
                Traits.Fixed,
                Traits.OutOfPlace,
            )
            Test.@test phvf isa Data.PseudoHamiltonianVectorField
            Test.@test Traits.time_dependence(phvf) === Traits.Autonomous
            Test.@test Traits.variable_dependence(phvf) === Traits.Fixed
            Test.@test Traits.mutability(phvf) === Traits.OutOfPlace
            dx, dp = phvf([1.0, 2.0], [3.0, 4.0], [0.5, 0.5])
            Test.@test dx == [1.5, 2.5]
            Test.@test dp == [-3.0, -4.0]
        end

        # ====================================================================
        # UNIT TESTS - Subtyping
        # ====================================================================

        Test.@testset "Subtyping" begin
            Test.@testset "PseudoHamiltonianVectorField is an AbstractVectorField" begin
                phvf = Data.PseudoHamiltonianVectorField(
                    (x, p, u) -> (x .+ u, -p); is_autonomous=true, is_variable=false
                )
                Test.@test phvf isa Data.AbstractVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Base.show
        # ====================================================================

        Test.@testset "Base.show" begin
            phvf = Data.PseudoHamiltonianVectorField(
                (x, p, u) -> (x .+ u, -p); is_autonomous=true, is_variable=false
            )
            # Just check that show doesn't throw
            Test.@test_nowarn sprint(show, phvf)
        end

        # ====================================================================
        # UNIT TESTS - Explicit is_inplace parameter
        # ====================================================================

        Test.@testset "Explicit is_inplace parameter" begin
            Test.@testset "is_inplace=true creates InPlace PseudoHamiltonianVectorField" begin
                # Define an out-of-place function but force InPlace
                f(x, p, u) = (x .+ u, -p)
                phvf = Data.PseudoHamiltonianVectorField(f; is_inplace=true)
                Test.@test Traits.mutability(phvf) === Traits.InPlace
            end

            Test.@testset "is_inplace=false creates OutOfPlace PseudoHamiltonianVectorField" begin
                # Define an in-place function but force OutOfPlace
                f(x, p, u) = (x .+ u, -p)
                phvf = Data.PseudoHamiltonianVectorField(f; is_inplace=false)
                Test.@test Traits.mutability(phvf) === Traits.OutOfPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - PreconditionError for multiple methods
        # ====================================================================

        Test.@testset "PreconditionError for multiple methods" begin
            Test.@testset "Throws PreconditionError when is_inplace is not specified" begin
                Test.@test_throws Exceptions.PreconditionError Data.PseudoHamiltonianVectorField(
                    _multi_method_phvf
                )
            end

            Test.@testset "No error when is_inplace is explicitly specified" begin
                phvf = Data.PseudoHamiltonianVectorField(
                    _multi_method_phvf; is_inplace=false
                )
                Test.@test Traits.mutability(phvf) === Traits.OutOfPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - Internal Helpers
        # ====================================================================

        Test.@testset "Internal Helpers" begin
            Test.@testset "_oop_arity_phvf" begin
                Test.@test Data._oop_arity_phvf(Traits.Autonomous, Traits.Fixed) == 3
                Test.@test Data._oop_arity_phvf(Traits.NonAutonomous, Traits.Fixed) == 4
                Test.@test Data._oop_arity_phvf(Traits.Autonomous, Traits.NonFixed) == 4
                Test.@test Data._oop_arity_phvf(Traits.NonAutonomous, Traits.NonFixed) == 5
            end

            Test.@testset "_natural_sig_phvf helpers" begin
                Test.@test Data._natural_sig_phvf(
                    Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace
                ) == "f(x, p, u)"
                Test.@test Data._natural_sig_phvf(
                    Traits.NonAutonomous, Traits.Fixed, Traits.OutOfPlace
                ) == "f(t, x, p, u)"
                Test.@test Data._natural_sig_phvf(
                    Traits.Autonomous, Traits.Fixed, Traits.InPlace
                ) == "f(dx, dp, x, p, u)"
                Test.@test Data._uniform_sig_phvf(Traits.OutOfPlace) == "f(t, x, p, u, v)"
                Test.@test Data._uniform_sig_phvf(Traits.InPlace) ==
                    "f(dx, dp, t, x, p, u, v)"
            end

            Test.@testset "_detect_mutability_phvf invalid arity" begin
                Test.@test_throws Exceptions.IncorrectArgument Data._detect_mutability_phvf(
                    _bad_arity_phvf, Traits.Autonomous, Traits.Fixed
                )
            end
        end

        # ====================================================================
        # UNIT TESTS - InPlace Call Signatures
        # ====================================================================

        Test.@testset "InPlace Call Signatures" begin
            Test.@testset "Autonomous Fixed - (dx, dp, x, p, u)" begin
                f(dx, dp, x, p, u) = (dx.=(-x .+ u); dp.=(-p))
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=true, is_variable=false, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    phvf(dx, dp, 3.0, 1.0, 0.5)
                    Test.@test dx[1] == -2.5
                    Test.@test dp[1] == -1.0
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    phvf(dx, dp, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1])
                    Test.@test dx == [-0.9, -1.9]
                    Test.@test dp == [-0.5, -1.0]
                end
            end

            Test.@testset "NonAutonomous Fixed - (dx, dp, t, x, p, u)" begin
                f(dx, dp, t, x, p, u) = (dx.=t .* x .+ u; dp.=t .* p)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=false, is_variable=false, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    phvf(dx, dp, 2.0, 3.0, 1.0, 0.5)
                    Test.@test dx[1] == 6.5
                    Test.@test dp[1] == 2.0
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    phvf(dx, dp, 2.0, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1])
                    Test.@test dx == [2.1, 4.1]
                    Test.@test dp == [1.0, 2.0]
                end
            end

            Test.@testset "Autonomous NonFixed - (dx, dp, x, p, u, v)" begin
                f(dx, dp, x, p, u, v) = (dx.=x .+ v .+ u; dp.=p .+ v)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=true, is_variable=true, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    phvf(dx, dp, 3.0, 1.0, 0.5, 0.5)
                    Test.@test dx[1] == 4.0
                    Test.@test dp[1] == 1.5
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    phvf(dx, dp, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1], 0.5)
                    Test.@test dx == [1.6, 2.6]
                    Test.@test dp == [1.0, 1.5]
                end
            end

            Test.@testset "NonAutonomous NonFixed - (dx, dp, t, x, p, u, v)" begin
                f(dx, dp, t, x, p, u, v) = (dx.=t .* x .+ v .+ u; dp.=t .* p .+ v)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=false, is_variable=true, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    phvf(dx, dp, 2.0, 3.0, 1.0, 0.5, 0.5)
                    Test.@test dx[1] == 7.0
                    Test.@test dp[1] == 2.5
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    phvf(dx, dp, 2.0, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1], 0.5)
                    Test.@test dx == [2.6, 4.6]
                    Test.@test dp == [1.5, 2.5]
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Uniform InPlace Call Signature
        # ====================================================================

        Test.@testset "Uniform InPlace Signature" begin
            Test.@testset "Autonomous Fixed InPlace uniform" begin
                f(dx, dp, x, p, u) = (dx.=(-x .+ u); dp.=(-p))
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=true, is_variable=false, is_inplace=true
                )

                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                phvf(dx, dp, 0.0, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1], 0.0)
                Test.@test dx == [-0.9, -1.9]
                Test.@test dp == [-0.5, -1.0]
            end

            Test.@testset "NonAutonomous Fixed InPlace uniform" begin
                f(dx, dp, t, x, p, u) = (dx.=t .* x .+ u; dp.=t .* p)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=false, is_variable=false, is_inplace=true
                )

                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                phvf(dx, dp, 2.0, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1], 0.0)
                Test.@test dx == [2.1, 4.1]
                Test.@test dp == [1.0, 2.0]
            end

            Test.@testset "Autonomous NonFixed InPlace uniform" begin
                f(dx, dp, x, p, u, v) = (dx.=x .+ v .+ u; dp.=p .+ v)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=true, is_variable=true, is_inplace=true
                )

                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                phvf(dx, dp, 0.0, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1], 0.5)
                Test.@test dx == [1.6, 2.6]
                Test.@test dp == [1.0, 1.5]

                # Test variable_costate kwarg
                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                phvf(dx, dp, 0.0, [1.0, 2.0], [0.5, 1.0], [0.1, 0.1], 0.5; variable_costate=false)
                Test.@test dx == [1.6, 2.6]
                Test.@test dp == [1.0, 1.5]
            end
        end

        Test.@testset "Show Methods" begin
            phvf = Data.PseudoHamiltonianVectorField(
                (x, p, u) -> (x .+ u, -p); is_autonomous=true, is_variable=false
            )

            Test.@testset "Base.show (compact)" begin
                io = IOBuffer()
                show(io, phvf)
                str = String(take!(io))
                Test.@test occursin("PseudoHamiltonianVectorField", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
                Test.@test occursin("out-of-place", str)
                Test.@test occursin("natural call", str)
                Test.@test occursin("uniform call", str)
            end

            Test.@testset "Base.show (text/plain)" begin
                io = IOBuffer()
                show(io, MIME("text/plain"), phvf)
                str = String(take!(io))
                Test.@test occursin("PseudoHamiltonianVectorField", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
            end
        end

        # ====================================================================
        # UNIT TESTS - variable_costate kwarg on user-built PHVF
        # ====================================================================

        Test.@testset "variable_costate kwarg on user-built PHVF" begin
            Test.@testset "OOP NonFixed: variable_costate=true on user-built PHVF throws PreconditionError" begin
                f = (x, p, u, v) -> (p, -x)   # no variable_costate kwarg
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=true, is_variable=true
                )
                x = [1.0];
                p = [0.5];
                u = [0.2];
                v = [0.1]
                Test.@test_throws Exception phvf(x, p, u, v; variable_costate=true)
            end

            Test.@testset "IP NonFixed: variable_costate=true on user-built PHVF throws PreconditionError" begin
                f = (dx, dp, x, p, u, v) -> (dx.=p; dp.=(.-x); nothing)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=true, is_variable=true, is_inplace=true
                )
                x = [1.0];
                p = [0.5];
                u = [0.2];
                v = [0.1]
                dx = similar(x);
                dp = similar(p)
                Test.@test_throws Exception phvf(dx, dp, x, p, u, v; variable_costate=true)
            end

            Test.@testset "OOP NonAutonomous NonFixed: variable_costate=true on user-built PHVF throws PreconditionError" begin
                f = (t, x, p, u, v) -> (p, -x)   # no variable_costate kwarg
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=false, is_variable=true
                )
                t = 0.5;
                x = [1.0];
                p = [0.5];
                u = [0.2];
                v = [0.1]
                Test.@test_throws Exception phvf(t, x, p, u, v; variable_costate=true)
            end

            Test.@testset "IP NonAutonomous NonFixed: variable_costate=true on user-built PHVF throws PreconditionError" begin
                f = (dx, dp, t, x, p, u, v) -> (dx.=p; dp.=(.-x); nothing)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=false, is_variable=true, is_inplace=true
                )
                t = 0.5;
                x = [1.0];
                p = [0.5];
                u = [0.2];
                v = [0.1]
                dx = similar(x);
                dp = similar(p)
                Test.@test_throws Exception phvf(
                    dx, dp, t, x, p, u, v; variable_costate=true
                )
            end

            Test.@testset "OOP NonFixed: variable_costate=false (default) on user-built PHVF works" begin
                f = (x, p, u, v) -> (p, -x)
                phvf = Data.PseudoHamiltonianVectorField(
                    f; is_autonomous=true, is_variable=true
                )
                x = [1.0];
                p = [0.5];
                u = [0.2];
                v = [0.1]
                result = phvf(x, p, u, v)
                Test.@test result == (p, -x)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
function test_pseudo_hamiltonian_vector_field()
    return TestPseudoHamiltonianVectorField.test_pseudo_hamiltonian_vector_field()
end
