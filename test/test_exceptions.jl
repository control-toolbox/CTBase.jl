function test_exceptions()

    # Test suite for CTException subtypes and their error printing

    # Test AmbiguousDescription
    @testset "AmbiguousDescription" begin
        e = CTBase.AmbiguousDescription((:e,))
        # Check that throwing error(e) produces an ErrorException
        @test_throws ErrorException error(e)
        # Check that showerror produces a string output
        output = sprint(showerror, e)
        @test typeof(output) == String
        # Check that the output contains the type name styled (red, bold)
        @test occursin("AmbiguousDescription", output)
        @test occursin("(:e,)", output)
    end

    # Test IncorrectArgument
    @testset "IncorrectArgument" begin
        e = CTBase.IncorrectArgument("invalid argument")
        @test_throws ErrorException error(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("IncorrectArgument", output)
        @test occursin("invalid argument", output)
    end

    # Test IncorrectMethod
    @testset "IncorrectMethod" begin
        e = CTBase.IncorrectMethod(:foo)
        @test_throws ErrorException error(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("IncorrectMethod", output)
        @test occursin("foo", output)
    end

    # Test IncorrectOutput
    @testset "IncorrectOutput" begin
        e = CTBase.IncorrectOutput("unexpected result")
        @test_throws ErrorException error(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("IncorrectOutput", output)
        @test occursin("unexpected result", output)
    end

    # Test NotImplemented
    @testset "NotImplemented" begin
        e = CTBase.NotImplemented("feature not ready")
        @test_throws ErrorException error(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("NotImplemented", output)
        @test occursin("feature not ready", output)
    end

    # Test UnauthorizedCall
    @testset "UnauthorizedCall" begin
        e = CTBase.UnauthorizedCall("access denied")
        @test_throws ErrorException error(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("UnauthorizedCall", output)
        @test occursin("access denied", output)
    end

    # Test ParsingError
    @testset "ParsingError" begin
        e = CTBase.ParsingError("syntax error")
        @test_throws ErrorException error(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("ParsingError", output)
        @test occursin("syntax error", output)
    end

    # Test ExtensionError
    @testset "ExtensionError" begin
        # Test constructor throws if no dependencies provided
        @test_throws CTBase.UnauthorizedCall CTBase.ExtensionError()
        # Create with one weak dependency
        e = CTBase.ExtensionError(:MyExt)
        @test_throws ErrorException error(e)
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
    end

    return nothing
    
end
