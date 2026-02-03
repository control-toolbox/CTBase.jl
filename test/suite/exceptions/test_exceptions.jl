function test_exceptions()

    # Test suite for CTException subtypes and their error printing

    # Test AmbiguousDescription
    @testset verbose = VERBOSE showtiming = SHOWTIMING "AmbiguousDescription" begin
        e = CTBase.AmbiguousDescription((:e,))
        # Check that throwing error(e) produces an ErrorException
        @test_throws CTBase.AmbiguousDescription throw(e)
        # Check that showerror produces a string output
        output = sprint(showerror, e)
        @test typeof(output) == String
        # Check that the output contains the type name styled (red, bold)
        @test occursin("AmbiguousDescription", output)
        @test occursin("(:e,)", output)
        
        # Test enriched version with candidates and suggestions
        e_enriched = CTBase.AmbiguousDescription(
            (:x,),
            candidates=["(:a, :b)", "(:c, :d)"],
            suggestion="Try one of the available descriptions",
            context="test context"
        )
        output_enriched = sprint(showerror, e_enriched)
        @test occursin("Available descriptions", output_enriched)
        @test occursin("(:a, :b)", output_enriched)
        @test occursin("(:c, :d)", output_enriched)
        @test occursin("Suggestion", output_enriched)
        @test occursin("Try one of the available descriptions", output_enriched)
        @test occursin("Context", output_enriched)
        @test occursin("test context", output_enriched)
    end

    # Test IncorrectArgument
    @testset verbose = VERBOSE showtiming = SHOWTIMING "IncorrectArgument" begin
        e = CTBase.IncorrectArgument("invalid argument")
        @test_throws CTBase.IncorrectArgument throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("IncorrectArgument", output)
        @test occursin("invalid argument", output)
        
        # Test enriched version with all fields
        e_enriched = CTBase.IncorrectArgument(
            "dimension mismatch",
            got="vector of length 3",
            expected="vector of length 2",
            suggestion="Resize your vector to match the expected dimension",
            context="initialization"
        )
        output_enriched = sprint(showerror, e_enriched)
        @test occursin("Got", output_enriched)
        @test occursin("vector of length 3", output_enriched)
        @test occursin("Expected", output_enriched)
        @test occursin("vector of length 2", output_enriched)
        @test occursin("Suggestion", output_enriched)
        @test occursin("Resize your vector", output_enriched)
        @test occursin("Context", output_enriched)
        @test occursin("initialization", output_enriched)
    end

    # Test NotImplemented
    @testset verbose = VERBOSE showtiming = SHOWTIMING "NotImplemented" begin
        e = CTBase.NotImplemented("feature not ready")
        @test_throws CTBase.NotImplemented throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("NotImplemented", output)
        @test occursin("feature not ready", output)
        
        # Test enriched version
        e_enriched = CTBase.NotImplemented(
            "method not implemented",
            required_method="MyAbstractType",
            suggestion="Implement this method for your concrete type",
            context="algorithm execution"
        )
        output_enriched = sprint(showerror, e_enriched)
        @test occursin("Type", output_enriched)
        @test occursin("MyAbstractType", output_enriched)
        @test occursin("Suggestion", output_enriched)
        @test occursin("Implement this method", output_enriched)
        @test occursin("Context", output_enriched)
        @test occursin("algorithm execution", output_enriched)
    end

    # Test PreconditionError
    @testset verbose = VERBOSE showtiming = SHOWTIMING "PreconditionError" begin
        e = CTBase.PreconditionError("state must be set before dynamics")
        @test_throws CTBase.PreconditionError throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("PreconditionError", output)
        @test occursin("state must be set before dynamics", output)
        
        # Test enriched version
        e_enriched = CTBase.PreconditionError(
            "Cannot call state! twice",
            reason="state has already been defined for this OCP",
            suggestion="Create a new OCP instance",
            context="state definition"
        )
        output_enriched = sprint(showerror, e_enriched)
        @test occursin("Reason", output_enriched)
        @test occursin("state has already been defined", output_enriched)
        @test occursin("Suggestion", output_enriched)
        @test occursin("Create a new OCP instance", output_enriched)
        @test occursin("Context", output_enriched)
        @test occursin("state definition", output_enriched)
    end

    # Test ParsingError
    @testset verbose = VERBOSE showtiming = SHOWTIMING "ParsingError" begin
        e = CTBase.ParsingError("syntax error")
        @test_throws CTBase.ParsingError throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("ParsingError", output)
        @test occursin("syntax error", output)
        
        # Test enriched version
        e_enriched = CTBase.ParsingError(
            "unexpected token",
            location="line 42, column 15",
            suggestion="Check syntax balance"
        )
        output_enriched = sprint(showerror, e_enriched)
        @test occursin("Location", output_enriched)
        @test occursin("line 42, column 15", output_enriched)
        @test occursin("Suggestion", output_enriched)
        @test occursin("Check syntax balance", output_enriched)
    end

    # Test ExtensionError
    @testset verbose = VERBOSE showtiming = SHOWTIMING "ExtensionError" begin
        # Test constructor throws if no dependencies provided
        @test_throws CTBase.PreconditionError CTBase.ExtensionError()
        # Create with one weak dependency
        e = CTBase.ExtensionError(:MyExt)
        @test_throws CTBase.ExtensionError throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("ExtensionError", output)
        @test occursin("MyExt", output)
        @test occursin("using", output)
        # Create with multiple weak dependencies
        e2 = CTBase.ExtensionError(:Ext1, :Ext2)
        output2 = sprint(showerror, e2)
        @test occursin("Ext1", output2)
        @test occursin("Ext2", output2)

        # Test with optional message
        e_msg = CTBase.ExtensionError(:MyExt; message="to enable feature X")
        output_msg = sprint(showerror, e_msg)
        @test occursin("ExtensionError", output_msg)
        @test occursin("MyExt", output_msg)
        @test occursin("to enable feature X", output_msg)
        
        # Test enriched version with feature and context
        e_enriched = CTBase.ExtensionError(
            :Documenter, :Markdown;
            message="to generate documentation",
            feature="automatic documentation",
            context="reference generation"
        )
        output_enriched = sprint(showerror, e_enriched)
        @test occursin("Missing dependencies", output_enriched)
        @test occursin("Documenter", output_enriched)
        @test occursin("Markdown", output_enriched)
        @test occursin("to generate documentation", output_enriched)
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "CTException supertype catch" begin
        e = CTBase.IncorrectArgument("msg")
        @test_throws CTBase.IncorrectArgument throw(e)
    end

    return nothing
end
