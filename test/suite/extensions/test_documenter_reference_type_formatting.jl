module TestDocumenterReferenceTypeFormatting

using Test: Test
using CTBase: CTBase
using Documenter: Documenter

const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const DR = DocumenterReference

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Test module for type formatting
module DRTypeFormatTestMod
    struct Simple end
    struct Parametric{T} end
    struct WithValue{T,N} end
end

module DRUnionAllTestMod
    f(x::T) where {T} = x
end

function test_documenter_reference_type_formatting()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Type formatting helpers" begin
        Test.@test DR._format_datatype_for_docs(UInt) == "::UInt"

        # Parametric types without concrete params are UnionAll, use _format_type_for_docs
        param_result = DR._format_type_for_docs(DRTypeFormatTestMod.Parametric)
        Test.@test occursin("Parametric", param_result)

        # Concrete params => kept (WithValue{Int,2} is a DataType)
        concrete_result = DR._format_datatype_for_docs(DRTypeFormatTestMod.WithValue{Int,2})
        Test.@test occursin("WithValue", concrete_result)
        Test.@test occursin("Int", concrete_result)
        Test.@test occursin("2", concrete_result)

        # Fallback branch for non-type inputs
        Test.@test DR._format_type_for_docs(1) == "::1"

        # TypeVar formatting in _format_type_param - need to unwrap UnionAll first
        unwrapped = Base.unwrap_unionall(DRTypeFormatTestMod.Parametric)
        tv = unwrapped.parameters[1]
        Test.@test tv isa TypeVar
        Test.@test DR._format_type_param(tv) == "T"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_method_signature_string handles UnionAll" begin
        m = first(methods(DRUnionAllTestMod.f))
        s = DR._method_signature_string(m, DRUnionAllTestMod, :f)
        Test.@test occursin("DRUnionAllTestMod.f", s)
        Test.@test occursin("T", s)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_for_docs edge cases" begin
        # Test Union types formatting
        union_result = DR._format_type_for_docs(Union{Int,String})
        Test.@test occursin("Union", union_result)
        Test.@test occursin("Int", union_result)
        Test.@test occursin("String", union_result)

        # Test simple non-DataType fallback
        Test.@test DR._format_type_for_docs(Any) == "::Any"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_datatype_for_docs with TypeVar" begin
        # Test parametric type with concrete parameters
        concrete_result = DR._format_datatype_for_docs(Vector{Int})
        Test.@test occursin("Vector", concrete_result) || occursin("Array", concrete_result)
        Test.@test occursin("Int", concrete_result)

        # Test parametric type - the function strips parameters when TypeVar present
        Test.@test DR._format_datatype_for_docs(Int) == "::Int"
        Test.@test DR._format_datatype_for_docs(String) == "::String"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_param edge cases" begin
        # Test Type parameter
        type_result = DR._format_type_param(Int)
        Test.@test type_result == "Int"  # Should strip leading ::

        # Test value parameter - e.g., for sized arrays
        Test.@test DR._format_type_param(3) == "3"
        Test.@test DR._format_type_param(42) == "42"

        # Test with complex type
        param_fmt = DR._format_type_param(DRTypeFormatTestMod.Simple)
        Test.@test occursin("DRTypeFormatTestMod.Simple", param_fmt)

        value_param_fmt = DR._format_type_param(3)
        Test.@test value_param_fmt == "3"
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_format_type_for_docs and helpers" begin
        simple_str = DR._format_type_for_docs(DRTypeFormatTestMod.Simple)
        Test.@test startswith(simple_str, "::")
        Test.@test occursin("DRTypeFormatTestMod.Simple", simple_str)

        param_type = DRTypeFormatTestMod.Parametric{DRTypeFormatTestMod.Simple}
        param_str = DR._format_type_for_docs(param_type)
        Test.@test occursin("Parametric", param_str)
        Test.@test occursin("Simple", param_str)

        union_str = DR._format_type_for_docs(Union{DRTypeFormatTestMod.Simple,Nothing})
        Test.@test occursin("Union", union_str)
        Test.@test occursin("Simple", union_str)
        Test.@test occursin("Nothing", union_str)

        value_type = DRTypeFormatTestMod.WithValue{Int,3}
        value_str = DR._format_type_for_docs(value_type)
        Test.@test occursin("WithValue", value_str)
        Test.@test occursin("3", value_str)
    end

    return nothing
end

end # module

function test_documenter_reference_type_formatting()
    return TestDocumenterReferenceTypeFormatting.test_documenter_reference_type_formatting()
end
