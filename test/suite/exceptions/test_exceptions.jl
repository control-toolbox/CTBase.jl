module TestExceptions

using Test: Test
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_exceptions()

    # Test suite for CTException subtypes and their error printing

    # Test AmbiguousDescription
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "AmbiguousDescription" begin
        e = Exceptions.AmbiguousDescription((:e,))
        # Check that throwing error(e) produces an ErrorException
        Test.@test_throws Exceptions.AmbiguousDescription throw(e)
        # Check that showerror produces a string output
        output = sprint(showerror, e)
        Test.@test typeof(output) == String
        # Check that the output contains the type name styled (red, bold)
        Test.@test occursin("AmbiguousDescription", output)
        Test.@test occursin("(:e,)", output)

        # Test enriched version with candidates and suggestions
        e_enriched = Exceptions.AmbiguousDescription(
            (:x,),
            candidates=["(:a, :b)", "(:c, :d)"],
            suggestion="Try one of the available descriptions",
            context="test context",
        )
        output_enriched = sprint(showerror, e_enriched)
        Test.@test occursin("Available", output_enriched)
        Test.@test occursin("(:a, :b)", output_enriched)
        Test.@test occursin("(:c, :d)", output_enriched)
        Test.@test occursin("Hint", output_enriched)
        Test.@test occursin("Try one of the available descriptions", output_enriched)
        Test.@test occursin("Context", output_enriched)
        Test.@test occursin("test context", output_enriched)
    end

    # Test IncorrectArgument
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "IncorrectArgument" begin
        e = Exceptions.IncorrectArgument("invalid argument")
        Test.@test_throws Exceptions.IncorrectArgument throw(e)
        output = sprint(showerror, e)
        Test.@test typeof(output) == String
        Test.@test occursin("IncorrectArgument", output)
        Test.@test occursin("invalid argument", output)

        # Test enriched version with all fields
        e_enriched = Exceptions.IncorrectArgument(
            "dimension mismatch",
            got="vector of length 3",
            expected="vector of length 2",
            suggestion="Resize your vector to match the expected dimension",
            context="initialization",
        )
        output_enriched = sprint(showerror, e_enriched)
        Test.@test occursin("Got", output_enriched)
        Test.@test occursin("vector of length 3", output_enriched)
        Test.@test occursin("Expected", output_enriched)
        Test.@test occursin("vector of length 2", output_enriched)
        Test.@test occursin("Hint", output_enriched)
        Test.@test occursin("Resize your vector", output_enriched)
        Test.@test occursin("Context", output_enriched)
        Test.@test occursin("initialization", output_enriched)
    end

    # Test NotImplemented
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "NotImplemented" begin
        e = Exceptions.NotImplemented("feature not ready")
        Test.@test_throws Exceptions.NotImplemented throw(e)
        output = sprint(showerror, e)
        Test.@test typeof(output) == String
        Test.@test occursin("NotImplemented", output)
        Test.@test occursin("feature not ready", output)

        # Test enriched version
        e_enriched = Exceptions.NotImplemented(
            "method not implemented",
            required_method="MyAbstractType",
            suggestion="Implement this method for your concrete type",
            context="algorithm execution",
        )
        output_enriched = sprint(showerror, e_enriched)
        Test.@test occursin("Type", output_enriched)
        Test.@test occursin("MyAbstractType", output_enriched)
        Test.@test occursin("Hint", output_enriched)
        Test.@test occursin("Implement this method", output_enriched)
        Test.@test occursin("Context", output_enriched)
        Test.@test occursin("algorithm execution", output_enriched)
    end

    # Test PreconditionError
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "PreconditionError" begin
        e = Exceptions.PreconditionError("state must be set before dynamics")
        Test.@test_throws Exceptions.PreconditionError throw(e)
        output = sprint(showerror, e)
        Test.@test typeof(output) == String
        Test.@test occursin("PreconditionError", output)
        Test.@test occursin("state must be set before dynamics", output)

        # Test enriched version
        e_enriched = Exceptions.PreconditionError(
            "Cannot call state! twice",
            reason="state has already been defined for this OCP",
            suggestion="Create a new OCP instance",
            context="state definition",
        )
        output_enriched = sprint(showerror, e_enriched)
        Test.@test occursin("Reason", output_enriched)
        Test.@test occursin("state has already been defined", output_enriched)
        Test.@test occursin("Hint", output_enriched)
        Test.@test occursin("Create a new OCP instance", output_enriched)
        Test.@test occursin("Context", output_enriched)
        Test.@test occursin("state definition", output_enriched)
    end

    # Test ParsingError
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ParsingError" begin
        e = Exceptions.ParsingError("syntax error")
        Test.@test_throws Exceptions.ParsingError throw(e)
        output = sprint(showerror, e)
        Test.@test typeof(output) == String
        Test.@test occursin("ParsingError", output)
        Test.@test occursin("syntax error", output)

        # Test enriched version
        e_enriched = Exceptions.ParsingError(
            "unexpected token",
            location="line 42, column 15",
            suggestion="Check syntax balance",
        )
        output_enriched = sprint(showerror, e_enriched)
        Test.@test occursin("Location", output_enriched)
        Test.@test occursin("line 42, column 15", output_enriched)
        Test.@test occursin("Hint", output_enriched)
        Test.@test occursin("Check syntax balance", output_enriched)
    end

    # Test ExtensionError
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "ExtensionError" begin
        # Test constructor throws if no dependencies provided
        Test.@test_throws Exceptions.PreconditionError Exceptions.ExtensionError()
        # Create with one weak dependency
        e = Exceptions.ExtensionError(:MyExt)
        Test.@test_throws Exceptions.ExtensionError throw(e)
        output = sprint(showerror, e)
        Test.@test typeof(output) == String
        Test.@test occursin("ExtensionError", output)
        Test.@test occursin("MyExt", output)
        Test.@test occursin("using", output)
        # Create with multiple weak dependencies
        e2 = Exceptions.ExtensionError(:Ext1, :Ext2)
        output2 = sprint(showerror, e2)
        Test.@test occursin("Ext1", output2)
        Test.@test occursin("Ext2", output2)

        # Test with optional message
        e_msg = Exceptions.ExtensionError(:MyExt; message="to enable feature X")
        output_msg = sprint(showerror, e_msg)
        Test.@test occursin("ExtensionError", output_msg)
        Test.@test occursin("MyExt", output_msg)
        Test.@test occursin("to enable feature X", output_msg)

        # Test enriched version with feature and context
        e_enriched = Exceptions.ExtensionError(
            :Documenter,
            :Markdown;
            message="to generate documentation",
            feature="automatic documentation",
            context="reference generation",
        )
        output_enriched = sprint(showerror, e_enriched)
        Test.@test occursin("Missing", output_enriched)
        Test.@test occursin("Documenter", output_enriched)
        Test.@test occursin("Markdown", output_enriched)
        Test.@test occursin("to generate documentation", output_enriched)
    end

    # Test SolverFailure
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "SolverFailure" begin
        e = Exceptions.SolverFailure("solver failed")
        Test.@test_throws Exceptions.SolverFailure throw(e)
        output = sprint(showerror, e)
        Test.@test typeof(output) == String
        Test.@test occursin("SolverFailure", output)
        Test.@test occursin("solver failed", output)

        # Test enriched version with retcode
        e_enriched = Exceptions.SolverFailure(
            "ODE integration failed",
            retcode=":Unstable",
            suggestion="Reduce time step",
            context="SciML integrator",
        )
        output_enriched = sprint(showerror, e_enriched)
        Test.@test occursin("Retcode", output_enriched)
        Test.@test occursin(":Unstable", output_enriched)
        Test.@test occursin("Hint", output_enriched)
        Test.@test occursin("Reduce time step", output_enriched)
        Test.@test occursin("Context", output_enriched)
        Test.@test occursin("SciML integrator", output_enriched)
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "CTException supertype catch" begin
        e = Exceptions.IncorrectArgument("msg")
        Test.@test_throws Exceptions.IncorrectArgument throw(e)
    end

    return nothing
end

end # module

test_exceptions() = TestExceptions.test_exceptions()
