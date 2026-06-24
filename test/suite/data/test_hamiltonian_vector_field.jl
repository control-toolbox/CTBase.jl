module TestHamiltonianVectorField

import Test
import CTBase.Data: Data
import CTBase.Traits: Traits
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Fake function with multiple methods for testing
_multi_method_hvf(x::Int, p) = (x, -p)
_multi_method_hvf(x::Float64, p) = (x, -p)
_multi_method_hvf(x::AbstractVector, p) = (x, -p)

# TOP-LEVEL: Fake function with invalid arity for testing error branches
_bad_arity_hvf(x) = (x, -x)

function test_hamiltonian_vector_field()
    Test.@testset "Hamiltonian Vector Field Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Construction
        # ====================================================================
        
        Test.@testset "Construction" begin
            # Autonomous, Fixed
            hvf_autonomous_fixed = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
            Test.@test hvf_autonomous_fixed isa Data.HamiltonianVectorField
            Test.@test Traits.time_dependence(hvf_autonomous_fixed) == Traits.Autonomous
            Test.@test Traits.variable_dependence(hvf_autonomous_fixed) == Traits.Fixed
            
            # NonAutonomous, Fixed
            hvf_nonautonomous_fixed = Data.HamiltonianVectorField((t, x, p) -> (x, -p); is_autonomous=false, is_variable=false)
            Test.@test hvf_nonautonomous_fixed isa Data.HamiltonianVectorField
            Test.@test Traits.time_dependence(hvf_nonautonomous_fixed) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(hvf_nonautonomous_fixed) == Traits.Fixed
            
            # Autonomous, NonFixed
            hvf_autonomous_nonfixed = Data.HamiltonianVectorField((x, p, v) -> (x .* v, -p); is_autonomous=true, is_variable=true)
            Test.@test hvf_autonomous_nonfixed isa Data.HamiltonianVectorField
            Test.@test Traits.time_dependence(hvf_autonomous_nonfixed) == Traits.Autonomous
            Test.@test Traits.variable_dependence(hvf_autonomous_nonfixed) == Traits.NonFixed
            
            # NonAutonomous, NonFixed
            hvf_nonautonomous_nonfixed = Data.HamiltonianVectorField((t, x, p, v) -> (x .* v, -p); is_autonomous=false, is_variable=true)
            Test.@test hvf_nonautonomous_nonfixed isa Data.HamiltonianVectorField
            Test.@test Traits.time_dependence(hvf_nonautonomous_nonfixed) == Traits.NonAutonomous
            Test.@test Traits.variable_dependence(hvf_nonautonomous_nonfixed) == Traits.NonFixed
        end
        
        # ====================================================================
        # UNIT TESTS - Natural signatures
        # ====================================================================
        
        Test.@testset "Natural Signatures" begin
            # (x, p) for Autonomous, Fixed
            hvf1 = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
            dx, dp = hvf1([1.0, 2.0], [3.0, 4.0])
            Test.@test dx == [1.0, 2.0]
            Test.@test dp == [-3.0, -4.0]
            
            # (t, x, p) for NonAutonomous, Fixed
            hvf2 = Data.HamiltonianVectorField((t, x, p) -> (t .* x, -p); is_autonomous=false, is_variable=false)
            dx, dp = hvf2(2.0, [1.0, 2.0], [3.0, 4.0])
            Test.@test dx == [2.0, 4.0]
            Test.@test dp == [-3.0, -4.0]
            
            # (x, p, v) for Autonomous, NonFixed
            hvf3 = Data.HamiltonianVectorField((x, p, v) -> (x .* v, -p); is_autonomous=true, is_variable=true)
            dx, dp = hvf3([1.0, 2.0], [3.0, 4.0], 2.0)
            Test.@test dx == [2.0, 4.0]
            Test.@test dp == [-3.0, -4.0]
            
            # (t, x, p, v) for NonAutonomous, NonFixed
            hvf4 = Data.HamiltonianVectorField((t, x, p, v) -> (t .* x .* v, -p); is_autonomous=false, is_variable=true)
            dx, dp = hvf4(2.0, [1.0, 2.0], [3.0, 4.0], 2.0)
            Test.@test dx == [4.0, 8.0]
            Test.@test dp == [-3.0, -4.0]
        end
        
        # ====================================================================
        # UNIT TESTS - Uniform signature
        # ====================================================================
        
        Test.@testset "Uniform Signature" begin
            # All combinations should work with (t, x, p, v)
            hvf_autonomous_fixed = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
            dx, dp = hvf_autonomous_fixed(0.0, [1.0, 2.0], [3.0, 4.0], nothing)
            Test.@test dx == [1.0, 2.0]
            Test.@test dp == [-3.0, -4.0]
            
            hvf_nonautonomous_fixed = Data.HamiltonianVectorField((t, x, p) -> (t .* x, -p); is_autonomous=false, is_variable=false)
            dx, dp = hvf_nonautonomous_fixed(2.0, [1.0, 2.0], [3.0, 4.0], nothing)
            Test.@test dx == [2.0, 4.0]
            Test.@test dp == [-3.0, -4.0]
            
            hvf_autonomous_nonfixed = Data.HamiltonianVectorField((x, p, v) -> (x .* v, -p); is_autonomous=true, is_variable=true)
            dx, dp = hvf_autonomous_nonfixed(0.0, [1.0, 2.0], [3.0, 4.0], 2.0)
            Test.@test dx == [2.0, 4.0]
            Test.@test dp == [-3.0, -4.0]
            
            # Test variable_costate kwarg for NonFixed
            dx, dp = hvf_autonomous_nonfixed(0.0, [1.0, 2.0], [3.0, 4.0], 2.0; variable_costate=false)
            Test.@test dx == [2.0, 4.0]
            Test.@test dp == [-3.0, -4.0]
        end
        
        # ====================================================================
        # UNIT TESTS - Trait accessors
        # ====================================================================
        
        Test.@testset "Trait Accessors" begin
            hvf = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
            Test.@test Traits.has_time_dependence_trait(hvf) == true
            Test.@test Traits.has_variable_dependence_trait(hvf) == true
            Test.@test Traits.time_dependence(hvf) == Traits.Autonomous
            Test.@test Traits.variable_dependence(hvf) == Traits.Fixed
        end
        
        # ====================================================================
        # UNIT TESTS - Typed constructor (trait types passed positionally)
        # ====================================================================

        Test.@testset "Typed constructor" begin
            hvf = Data.HamiltonianVectorField(
                (x, p) -> (x, -p), Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace
            )
            Test.@test hvf isa Data.HamiltonianVectorField
            Test.@test Traits.time_dependence(hvf) === Traits.Autonomous
            Test.@test Traits.variable_dependence(hvf) === Traits.Fixed
            Test.@test Traits.mutability(hvf) === Traits.OutOfPlace
            dx, dp = hvf([1.0, 2.0], [3.0, 4.0])
            Test.@test dx == [1.0, 2.0]
            Test.@test dp == [-3.0, -4.0]
        end

        # ====================================================================
        # UNIT TESTS - Subtyping
        # ====================================================================

        Test.@testset "Subtyping" begin
            Test.@testset "HamiltonianVectorField is an AbstractVectorField" begin
                hvf = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
                Test.@test hvf isa Data.AbstractVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Base.show
        # ====================================================================

        Test.@testset "Base.show" begin
            hvf = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)
            # Just check that show doesn't throw
            Test.@test_nowarn sprint(show, hvf)
        end

        # ====================================================================
        # UNIT TESTS - Explicit is_inplace parameter
        # ====================================================================

        Test.@testset "Explicit is_inplace parameter" begin
            Test.@testset "is_inplace=true creates InPlace HamiltonianVectorField" begin
                # Define an out-of-place function but force InPlace
                f(x, p) = (x, -p)
                hvf = Data.HamiltonianVectorField(f; is_inplace=true)
                Test.@test Traits.mutability(hvf) === Traits.InPlace
            end

            Test.@testset "is_inplace=false creates OutOfPlace HamiltonianVectorField" begin
                # Define an in-place function but force OutOfPlace
                f(x, p) = (x, -p)
                hvf = Data.HamiltonianVectorField(f; is_inplace=false)
                Test.@test Traits.mutability(hvf) === Traits.OutOfPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - PreconditionError for multiple methods
        # ====================================================================

        Test.@testset "PreconditionError for multiple methods" begin
            Test.@testset "Throws PreconditionError when is_inplace is not specified" begin
                Test.@test_throws Exceptions.PreconditionError Data.HamiltonianVectorField(_multi_method_hvf)
            end

            Test.@testset "No error when is_inplace is explicitly specified" begin
                hvf = Data.HamiltonianVectorField(_multi_method_hvf; is_inplace=false)
                Test.@test Traits.mutability(hvf) === Traits.OutOfPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - Internal Helpers
        # ====================================================================

        Test.@testset "Internal Helpers" begin
            Test.@testset "_oop_arity_hvf" begin
                Test.@test Data._oop_arity_hvf(Traits.Autonomous, Traits.Fixed) == 2
                Test.@test Data._oop_arity_hvf(Traits.NonAutonomous, Traits.Fixed) == 3
                Test.@test Data._oop_arity_hvf(Traits.Autonomous, Traits.NonFixed) == 3
                Test.@test Data._oop_arity_hvf(Traits.NonAutonomous, Traits.NonFixed) == 4
            end

            Test.@testset "_natural_sig_hvf helpers" begin
                Test.@test Data._natural_sig_hvf(Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace) == "f(x, p)"
                Test.@test Data._natural_sig_hvf(Traits.NonAutonomous, Traits.Fixed, Traits.OutOfPlace) == "f(t, x, p)"
                Test.@test Data._natural_sig_hvf(Traits.Autonomous, Traits.Fixed, Traits.InPlace) == "f(dx, dp, x, p)"
                Test.@test Data._uniform_sig_hvf(Traits.OutOfPlace) == "f(t, x, p, v)"
                Test.@test Data._uniform_sig_hvf(Traits.InPlace) == "f(dx, dp, t, x, p, v)"
            end

            Test.@testset "_detect_mutability_hvf invalid arity" begin
                Test.@test_throws Exceptions.IncorrectArgument Data._detect_mutability_hvf(_bad_arity_hvf, Traits.Autonomous, Traits.Fixed)
            end
        end

        # ====================================================================
        # UNIT TESTS - InPlace Call Signatures
        # ====================================================================

        Test.@testset "InPlace Call Signatures" begin
            Test.@testset "Autonomous Fixed - (dx, dp, x, p)" begin
                f(dx, dp, x, p) = (dx .= -x; dp .= -p)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=true, is_variable=false, is_inplace=true)
                
                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    hvf(dx, dp, 3.0, 1.0)
                    Test.@test dx[1] == -3.0
                    Test.@test dp[1] == -1.0
                end
                
                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    hvf(dx, dp, [1.0, 2.0], [0.5, 1.0])
                    Test.@test dx == [-1.0, -2.0]
                    Test.@test dp == [-0.5, -1.0]
                end
            end

            Test.@testset "NonAutonomous Fixed - (dx, dp, t, x, p)" begin
                f(dx, dp, t, x, p) = (dx .= t .* x; dp .= t .* p)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=false, is_variable=false, is_inplace=true)
                
                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    hvf(dx, dp, 2.0, 3.0, 1.0)
                    Test.@test dx[1] == 6.0
                    Test.@test dp[1] == 2.0
                end
                
                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    hvf(dx, dp, 2.0, [1.0, 2.0], [0.5, 1.0])
                    Test.@test dx == [2.0, 4.0]
                    Test.@test dp == [1.0, 2.0]
                end
            end

            Test.@testset "Autonomous NonFixed - (dx, dp, x, p, v)" begin
                f(dx, dp, x, p, v) = (dx .= x .+ v; dp .= p .+ v)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=true, is_variable=true, is_inplace=true)
                
                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    hvf(dx, dp, 3.0, 1.0, 0.5)
                    Test.@test dx[1] == 3.5
                    Test.@test dp[1] == 1.5
                end
                
                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    hvf(dx, dp, [1.0, 2.0], [0.5, 1.0], 0.5)
                    Test.@test dx == [1.5, 2.5]
                    Test.@test dp == [1.0, 1.5]
                end
            end

            Test.@testset "NonAutonomous NonFixed - (dx, dp, t, x, p, v)" begin
                f(dx, dp, t, x, p, v) = (dx .= t .* x .+ v; dp .= t .* p .+ v)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=false, is_variable=true, is_inplace=true)
                
                Test.@testset "scalar" begin
                    dx = [0.0]
                    dp = [0.0]
                    hvf(dx, dp, 2.0, 3.0, 1.0, 0.5)
                    Test.@test dx[1] == 6.5
                    Test.@test dp[1] == 2.5
                end
                
                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    dp = [0.0, 0.0]
                    hvf(dx, dp, 2.0, [1.0, 2.0], [0.5, 1.0], 0.5)
                    Test.@test dx == [2.5, 4.5]
                    Test.@test dp == [1.5, 2.5]
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Uniform InPlace Call Signature
        # ====================================================================

        Test.@testset "Uniform InPlace Signature" begin
            Test.@testset "Autonomous Fixed InPlace uniform" begin
                f(dx, dp, x, p) = (dx .= -x; dp .= -p)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=true, is_variable=false, is_inplace=true)
                
                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                hvf(dx, dp, 0.0, [1.0, 2.0], [0.5, 1.0], 0.0)
                Test.@test dx == [-1.0, -2.0]
                Test.@test dp == [-0.5, -1.0]
            end

            Test.@testset "NonAutonomous Fixed InPlace uniform" begin
                f(dx, dp, t, x, p) = (dx .= t .* x; dp .= t .* p)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=false, is_variable=false, is_inplace=true)
                
                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                hvf(dx, dp, 2.0, [1.0, 2.0], [0.5, 1.0], 0.0)
                Test.@test dx == [2.0, 4.0]
                Test.@test dp == [1.0, 2.0]
            end

            Test.@testset "Autonomous NonFixed InPlace uniform" begin
                f(dx, dp, x, p, v) = (dx .= x .+ v; dp .= p .+ v)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=true, is_variable=true, is_inplace=true)
                
                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                hvf(dx, dp, 0.0, [1.0, 2.0], [0.5, 1.0], 0.5)
                Test.@test dx == [1.5, 2.5]
                Test.@test dp == [1.0, 1.5]
                
                # Test variable_costate kwarg
                dx = [0.0, 0.0]
                dp = [0.0, 0.0]
                hvf(dx, dp, 0.0, [1.0, 2.0], [0.5, 1.0], 0.5; variable_costate=false)
                Test.@test dx == [1.5, 2.5]
                Test.@test dp == [1.0, 1.5]
            end
        end

        Test.@testset "Show Methods" begin
            hvf = Data.HamiltonianVectorField((x, p) -> (x, -p); is_autonomous=true, is_variable=false)

            Test.@testset "Base.show (compact)" begin
                io = IOBuffer()
                show(io, hvf)
                str = String(take!(io))
                Test.@test occursin("HamiltonianVectorField", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
                Test.@test occursin("out-of-place", str)
                Test.@test occursin("natural call", str)
                Test.@test occursin("uniform call", str)
            end

            Test.@testset "Base.show (text/plain)" begin
                io = IOBuffer()
                show(io, MIME("text/plain"), hvf)
                str = String(take!(io))
                Test.@test occursin("HamiltonianVectorField", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
            end
        end

        # ====================================================================
        # UNIT TESTS - variable_costate kwarg on user-built HVF
        # ====================================================================

        Test.@testset "variable_costate kwarg on user-built HVF" begin
            Test.@testset "OOP NonFixed: variable_costate=true on user-built HVF throws PreconditionError" begin
                f = (x, p, v) -> (p, -x)   # no variable_costate kwarg
                hvf = Data.HamiltonianVectorField(f; is_autonomous=true, is_variable=true)
                x = [1.0]; p = [0.5]; v = [0.1]
                Test.@test_throws Exception hvf(x, p, v; variable_costate=true)
            end

            Test.@testset "IP NonFixed: variable_costate=true on user-built HVF throws PreconditionError" begin
                f = (dx, dp, x, p, v) -> (dx .= p; dp .= .-x; nothing)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=true, is_variable=true, is_inplace=true)
                x = [1.0]; p = [0.5]; v = [0.1]
                dx = similar(x); dp = similar(p)
                Test.@test_throws Exception hvf(dx, dp, x, p, v; variable_costate=true)
            end

            Test.@testset "OOP NonAutonomous NonFixed: variable_costate=true on user-built HVF throws PreconditionError" begin
                f = (t, x, p, v) -> (p, -x)   # no variable_costate kwarg
                hvf = Data.HamiltonianVectorField(f; is_autonomous=false, is_variable=true)
                t = 0.5; x = [1.0]; p = [0.5]; v = [0.1]
                Test.@test_throws Exception hvf(t, x, p, v; variable_costate=true)
            end

            Test.@testset "IP NonAutonomous NonFixed: variable_costate=true on user-built HVF throws PreconditionError" begin
                f = (dx, dp, t, x, p, v) -> (dx .= p; dp .= .-x; nothing)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=false, is_variable=true, is_inplace=true)
                t = 0.5; x = [1.0]; p = [0.5]; v = [0.1]
                dx = similar(x); dp = similar(p)
                Test.@test_throws Exception hvf(dx, dp, t, x, p, v; variable_costate=true)
            end

            Test.@testset "OOP NonFixed: variable_costate=false (default) on user-built HVF works" begin
                f = (x, p, v) -> (p, -x)
                hvf = Data.HamiltonianVectorField(f; is_autonomous=true, is_variable=true)
                x = [1.0]; p = [0.5]; v = [0.1]
                result = hvf(x, p, v)
                Test.@test result == (p, -x)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_hamiltonian_vector_field() = TestHamiltonianVectorField.test_hamiltonian_vector_field()
