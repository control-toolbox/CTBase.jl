module TestVectorField

using Test: Test
import CTBase.Data
import CTBase.Traits
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Fake function with multiple methods for testing
_multi_method_f(x::Int) = -x
_multi_method_f(x::Float64) = -x
_multi_method_f(x::AbstractVector) = -x

# TOP-LEVEL: Fake function with invalid arity for testing error branches
_bad_arity_f(x, y, z) = x + y + z

# ==============================================================================
# Test function
# ==============================================================================

function test_vector_field()
    Test.@testset "VectorField Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Abstract Types
        # ====================================================================

        Test.@testset "Abstract Types" begin
            vf = Data.VectorField(x -> x; is_autonomous=true, is_variable=false)
            Test.@test vf isa Data.VectorField
        end

        # ====================================================================
        # UNIT TESTS - Construction
        # ====================================================================

        Test.@testset "Construction" begin
            Test.@testset "keyword constructor with defaults" begin
                vf = Data.VectorField(x -> x)
                Test.@test vf isa Data.VectorField
                Test.@test Traits.time_dependence(vf) === Traits.Autonomous
                Test.@test Traits.variable_dependence(vf) === Traits.Fixed
            end

            Test.@testset "keyword constructor with explicit flags" begin
                vf_autonomous = Data.VectorField(
                    x -> x; is_autonomous=true, is_variable=false
                )
                Test.@test Traits.time_dependence(vf_autonomous) === Traits.Autonomous
                Test.@test Traits.variable_dependence(vf_autonomous) === Traits.Fixed

                vf_nonautonomous = Data.VectorField(
                    (t, x) -> t .* x; is_autonomous=false, is_variable=false
                )
                Test.@test Traits.time_dependence(vf_nonautonomous) === Traits.NonAutonomous
                Test.@test Traits.variable_dependence(vf_nonautonomous) === Traits.Fixed

                vf_nonfixed = Data.VectorField(
                    (x, v) -> x .+ v; is_autonomous=true, is_variable=true
                )
                Test.@test Traits.time_dependence(vf_nonfixed) === Traits.Autonomous
                Test.@test Traits.variable_dependence(vf_nonfixed) === Traits.NonFixed

                vf_full = Data.VectorField(
                    (t, x, v) -> t .* x .+ v; is_autonomous=false, is_variable=true
                )
                Test.@test Traits.time_dependence(vf_full) === Traits.NonAutonomous
                Test.@test Traits.variable_dependence(vf_full) === Traits.NonFixed
            end
        end

        # ====================================================================
        # UNIT TESTS - Trait Methods
        # ====================================================================

        Test.@testset "Trait Methods" begin
            vf_aut = Data.VectorField(x -> x; is_autonomous=true, is_variable=false)
            vf_nonaut = Data.VectorField(
                (t, x) -> t .* x; is_autonomous=false, is_variable=false
            )
            vf_fixed = Data.VectorField(x -> x; is_autonomous=true, is_variable=false)
            vf_nonfixed = Data.VectorField(
                (x, v) -> x .+ v; is_autonomous=true, is_variable=true
            )

            Test.@testset "has_time_dependence_trait returns true" begin
                Test.@test Traits.has_time_dependence_trait(vf_aut) === true
                Test.@test Traits.has_time_dependence_trait(vf_nonaut) === true
            end

            Test.@testset "has_variable_dependence_trait returns true" begin
                Test.@test Traits.has_variable_dependence_trait(vf_fixed) === true
                Test.@test Traits.has_variable_dependence_trait(vf_nonfixed) === true
            end

            Test.@testset "time_dependence returns correct trait" begin
                Test.@test Traits.time_dependence(vf_aut) === Traits.Autonomous
                Test.@test Traits.time_dependence(vf_nonaut) === Traits.NonAutonomous
            end

            Test.@testset "variable_dependence returns correct trait" begin
                Test.@test Traits.variable_dependence(vf_fixed) === Traits.Fixed
                Test.@test Traits.variable_dependence(vf_nonfixed) === Traits.NonFixed
            end
        end

        # ====================================================================
        # UNIT TESTS - Natural Call Signatures
        # ====================================================================

        Test.@testset "Natural Call Signatures" begin
            Test.@testset "Autonomous Fixed - (x)" begin
                vf = Data.VectorField(x -> -x; is_autonomous=true, is_variable=false)

                Test.@testset "scalar" begin
                    Test.@test vf(3.0) == -3.0
                end

                Test.@testset "vector" begin
                    Test.@test vf([1.0, 2.0]) == [-1.0, -2.0]
                end

                Test.@testset "matrix" begin
                    x0 = [1.0 2.0; 3.0 4.0]
                    result = vf(x0)
                    Test.@test result == -x0
                end
            end

            Test.@testset "NonAutonomous Fixed - (t, x)" begin
                vf = Data.VectorField(
                    (t, x) -> t .* x; is_autonomous=false, is_variable=false
                )

                Test.@testset "scalar" begin
                    Test.@test vf(2.0, 3.0) == 6.0
                end

                Test.@testset "vector" begin
                    Test.@test vf(2.0, [1.0, 2.0]) == [2.0, 4.0]
                end

                Test.@testset "matrix" begin
                    x0 = [1.0 2.0; 3.0 4.0]
                    result = vf(2.0, x0)
                    Test.@test result == 2 .* x0
                end
            end

            Test.@testset "Autonomous NonFixed - (x, v)" begin
                vf = Data.VectorField(
                    (x, v) -> x .+ v; is_autonomous=true, is_variable=true
                )

                Test.@testset "scalar" begin
                    Test.@test vf(3.0, 0.5) == 3.5
                end

                Test.@testset "vector" begin
                    Test.@test vf([1.0, 2.0], 0.5) == [1.5, 2.5]
                end

                Test.@testset "matrix" begin
                    x0 = [1.0 2.0; 3.0 4.0]
                    result = vf(x0, 0.5)
                    Test.@test result == x0 .+ 0.5
                end
            end

            Test.@testset "NonAutonomous NonFixed - (t, x, v)" begin
                vf = Data.VectorField(
                    (t, x, v) -> t .* x .+ v; is_autonomous=false, is_variable=true
                )

                Test.@testset "scalar" begin
                    Test.@test vf(2.0, 3.0, 0.5) == 6.5
                end

                Test.@testset "vector" begin
                    Test.@test vf(2.0, [1.0, 2.0], 0.5) == [2.5, 4.5]
                end

                Test.@testset "matrix" begin
                    x0 = [1.0 2.0; 3.0 4.0]
                    result = vf(2.0, x0, 0.5)
                    Test.@test result == 2 .* x0 .+ 0.5
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Uniform Call Signature (t, x, v)
        # ====================================================================

        Test.@testset "Uniform Call Signature" begin
            Test.@testset "Autonomous Fixed ignores t and v" begin
                vf = Data.VectorField(x -> -x; is_autonomous=true, is_variable=false)

                Test.@testset "scalar" begin
                    Test.@test vf(0.0, 3.0, 0.0) == -3.0
                end

                Test.@testset "vector" begin
                    Test.@test vf(0.0, [1.0, 2.0], 0.0) == [-1.0, -2.0]
                end

                Test.@testset "matrix" begin
                    x0 = [1.0 2.0; 3.0 4.0]
                    result = vf(0.0, x0, 0.0)
                    Test.@test result == -x0
                end
            end

            Test.@testset "NonAutonomous Fixed uses t, ignores v" begin
                vf = Data.VectorField(
                    (t, x) -> t .* x; is_autonomous=false, is_variable=false
                )

                Test.@testset "scalar" begin
                    Test.@test vf(2.0, 3.0, 0.0) == 6.0
                end

                Test.@testset "vector" begin
                    Test.@test vf(2.0, [1.0, 2.0], 0.0) == [2.0, 4.0]
                end

                Test.@testset "matrix" begin
                    x0 = [1.0 2.0; 3.0 4.0]
                    result = vf(2.0, x0, 0.0)
                    Test.@test result == 2 .* x0
                end
            end

            Test.@testset "Autonomous NonFixed ignores t, uses v" begin
                vf = Data.VectorField(
                    (x, v) -> x .+ v; is_autonomous=true, is_variable=true
                )

                Test.@testset "scalar" begin
                    Test.@test vf(0.0, 3.0, 0.5) == 3.5
                end

                Test.@testset "vector" begin
                    Test.@test vf(0.0, [1.0, 2.0], 0.5) == [1.5, 2.5]
                end

                Test.@testset "matrix" begin
                    x0 = [1.0 2.0; 3.0 4.0]
                    result = vf(0.0, x0, 0.5)
                    Test.@test result == x0 .+ 0.5
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - InPlace Call Signatures
        # ====================================================================

        Test.@testset "InPlace Call Signatures" begin
            Test.@testset "Autonomous Fixed - (dx, x)" begin
                f(dx, x) = dx .= -x
                vf = Data.VectorField(
                    f; is_autonomous=true, is_variable=false, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    x = 3.0
                    vf(dx, x)
                    Test.@test dx[1] == -3.0
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    x = [1.0, 2.0]
                    vf(dx, x)
                    Test.@test dx == [-1.0, -2.0]
                end
            end

            Test.@testset "NonAutonomous Fixed - (dx, t, x)" begin
                f(dx, t, x) = dx .= t .* x
                vf = Data.VectorField(
                    f; is_autonomous=false, is_variable=false, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    vf(dx, 2.0, 3.0)
                    Test.@test dx[1] == 6.0
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    vf(dx, 2.0, [1.0, 2.0])
                    Test.@test dx == [2.0, 4.0]
                end
            end

            Test.@testset "Autonomous NonFixed - (dx, x, v)" begin
                f(dx, x, v) = dx .= x .+ v
                vf = Data.VectorField(
                    f; is_autonomous=true, is_variable=true, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    vf(dx, 3.0, 0.5)
                    Test.@test dx[1] == 3.5
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    vf(dx, [1.0, 2.0], 0.5)
                    Test.@test dx == [1.5, 2.5]
                end
            end

            Test.@testset "NonAutonomous NonFixed - (dx, t, x, v)" begin
                f(dx, t, x, v) = dx .= t .* x .+ v
                vf = Data.VectorField(
                    f; is_autonomous=false, is_variable=true, is_inplace=true
                )

                Test.@testset "scalar" begin
                    dx = [0.0]
                    vf(dx, 2.0, 3.0, 0.5)
                    Test.@test dx[1] == 6.5
                end

                Test.@testset "vector" begin
                    dx = [0.0, 0.0]
                    vf(dx, 2.0, [1.0, 2.0], 0.5)
                    Test.@test dx == [2.5, 4.5]
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Uniform InPlace Call Signature
        # ====================================================================

        Test.@testset "Uniform InPlace Signature" begin
            Test.@testset "Autonomous Fixed InPlace uniform" begin
                f(dx, x) = dx .= -x
                vf = Data.VectorField(
                    f; is_autonomous=true, is_variable=false, is_inplace=true
                )

                dx = [0.0, 0.0]
                vf(dx, 0.0, [1.0, 2.0], 0.0)
                Test.@test dx == [-1.0, -2.0]
            end

            Test.@testset "NonAutonomous Fixed InPlace uniform" begin
                f(dx, t, x) = dx .= t .* x
                vf = Data.VectorField(
                    f; is_autonomous=false, is_variable=false, is_inplace=true
                )

                dx = [0.0, 0.0]
                vf(dx, 2.0, [1.0, 2.0], 0.0)
                Test.@test dx == [2.0, 4.0]
            end

            Test.@testset "Autonomous NonFixed InPlace uniform" begin
                f(dx, x, v) = dx .= x .+ v
                vf = Data.VectorField(
                    f; is_autonomous=true, is_variable=true, is_inplace=true
                )

                dx = [0.0, 0.0]
                vf(dx, 0.0, [1.0, 2.0], 0.5)
                Test.@test dx == [1.5, 2.5]
            end

            Test.@testset "NonAutonomous NonFixed InPlace uniform" begin
                # natural signature (dx, t, x, v) coincides with the uniform one
                f(dx, t, x, v) = dx .= t .* x .+ v
                vf = Data.VectorField(
                    f; is_autonomous=false, is_variable=true, is_inplace=true
                )

                dx = [0.0, 0.0]
                vf(dx, 2.0, [1.0, 2.0], 0.5)
                Test.@test dx == [2.5, 4.5]
            end
        end

        # ====================================================================
        # UNIT TESTS - Typed constructor (trait types passed positionally)
        # ====================================================================

        Test.@testset "Typed constructor" begin
            vf = Data.VectorField(
                x -> -x, Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace
            )
            Test.@test vf isa Data.VectorField
            Test.@test Traits.time_dependence(vf) === Traits.Autonomous
            Test.@test Traits.variable_dependence(vf) === Traits.Fixed
            Test.@test Traits.mutability(vf) === Traits.OutOfPlace
            Test.@test vf(3.0) == -3.0

            vf_ip = Data.VectorField(
                (dx, x) -> (dx .= -x), Traits.Autonomous, Traits.Fixed, Traits.InPlace
            )
            Test.@test Traits.mutability(vf_ip) === Traits.InPlace
        end

        Test.@testset "Common Trait Predicates" begin
            vf_aut = Data.VectorField(x -> x; is_autonomous=true, is_variable=false)
            vf_nonaut = Data.VectorField(
                (t, x) -> t .* x; is_autonomous=false, is_variable=false
            )
            vf_fixed = Data.VectorField(x -> x; is_autonomous=true, is_variable=false)
            vf_nonfixed = Data.VectorField(
                (x, v) -> x .+ v; is_autonomous=true, is_variable=true
            )

            Test.@testset "is_autonomous / is_nonautonomous" begin
                Test.@test Traits.is_autonomous(vf_aut) === true
                Test.@test Traits.is_nonautonomous(vf_aut) === false
                Test.@test Traits.is_autonomous(vf_nonaut) === false
                Test.@test Traits.is_nonautonomous(vf_nonaut) === true
            end

            Test.@testset "is_variable / is_nonvariable" begin
                Test.@test Traits.is_variable(vf_fixed) === false
                Test.@test Traits.is_nonvariable(vf_fixed) === true
                Test.@test Traits.is_variable(vf_nonfixed) === true
                Test.@test Traits.is_nonvariable(vf_nonfixed) === false
            end
        end

        # ====================================================================
        # UNIT TESTS - Show Methods
        # ====================================================================

        Test.@testset "Show Methods" begin
            vf = Data.VectorField(x -> x; is_autonomous=true, is_variable=false)

            Test.@testset "Base.show (compact)" begin
                io = IOBuffer()
                show(io, vf)
                str = String(take!(io))
                Test.@test occursin("VectorField", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
                Test.@test occursin("out-of-place", str)
                Test.@test occursin("natural call", str)
                Test.@test occursin("uniform call", str)
            end

            Test.@testset "Base.show (text/plain)" begin
                io = IOBuffer()
                show(io, MIME("text/plain"), vf)
                str = String(take!(io))
                Test.@test occursin("VectorField", str)
                Test.@test occursin("autonomous", str)
                Test.@test occursin("fixed (no variable)", str)
            end
        end

        # ====================================================================
        # UNIT TESTS - Subtyping
        # ====================================================================

        Test.@testset "Subtyping" begin
            Test.@testset "VectorField is an AbstractVectorField" begin
                vf = Data.VectorField(x -> -x; is_autonomous=true, is_variable=false)
                Test.@test vf isa Data.AbstractVectorField
            end
        end

        # ====================================================================
        # UNIT TESTS - Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported types" begin
                Test.@test isdefined(Data, :VectorField)
            end
        end

        # ====================================================================
        # UNIT TESTS - Explicit is_inplace parameter
        # ====================================================================

        Test.@testset "Explicit is_inplace parameter" begin
            Test.@testset "is_inplace=true creates InPlace VectorField" begin
                # Define an out-of-place function but force InPlace
                f(x) = -x
                vf = Data.VectorField(f; is_inplace=true)
                Test.@test Traits.mutability(vf) === Traits.InPlace
            end

            Test.@testset "is_inplace=false creates OutOfPlace VectorField" begin
                # Define an in-place function but force OutOfPlace
                f(x) = -x
                vf = Data.VectorField(f; is_inplace=false)
                Test.@test Traits.mutability(vf) === Traits.OutOfPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - PreconditionError for multiple methods
        # ====================================================================

        Test.@testset "PreconditionError for multiple methods" begin
            Test.@testset "Throws PreconditionError when is_inplace is not specified" begin
                Test.@test_throws Exceptions.PreconditionError Data.VectorField(
                    _multi_method_f
                )
            end

            Test.@testset "No error when is_inplace is explicitly specified" begin
                vf = Data.VectorField(_multi_method_f; is_inplace=false)
                Test.@test Traits.mutability(vf) === Traits.OutOfPlace
            end
        end

        # ====================================================================
        # UNIT TESTS - Internal Helpers
        # ====================================================================

        Test.@testset "Internal Helpers" begin
            Test.@testset "_oop_arity_vf" begin
                Test.@test Data._oop_arity_vf(Traits.Autonomous, Traits.Fixed) == 1
                Test.@test Data._oop_arity_vf(Traits.NonAutonomous, Traits.Fixed) == 2
                Test.@test Data._oop_arity_vf(Traits.Autonomous, Traits.NonFixed) == 2
                Test.@test Data._oop_arity_vf(Traits.NonAutonomous, Traits.NonFixed) == 3
            end

            Test.@testset "_natural_sig_vf helpers" begin
                Test.@test Data._natural_sig_vf(
                    Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace
                ) == "f(x)"
                Test.@test Data._natural_sig_vf(
                    Traits.NonAutonomous, Traits.Fixed, Traits.OutOfPlace
                ) == "f(t, x)"
                Test.@test Data._natural_sig_vf(
                    Traits.Autonomous, Traits.Fixed, Traits.InPlace
                ) == "f(dx, x)"
                Test.@test Data._uniform_sig_vf(Traits.OutOfPlace) == "f(t, x, v)"
                Test.@test Data._uniform_sig_vf(Traits.InPlace) == "f(dx, t, x, v)"
            end

            Test.@testset "_detect_mutability_vf invalid arity" begin
                Test.@test_throws Exceptions.IncorrectArgument Data._detect_mutability_vf(
                    _bad_arity_f, Traits.Autonomous, Traits.Fixed
                )
            end
        end
    end
end

end # module

test_vector_field() = TestVectorField.test_vector_field()
