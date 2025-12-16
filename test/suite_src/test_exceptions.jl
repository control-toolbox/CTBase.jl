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
    end

    # Test IncorrectArgument
    @testset verbose = VERBOSE showtiming = SHOWTIMING "IncorrectArgument" begin
        e = CTBase.IncorrectArgument("invalid argument")
        @test_throws CTBase.IncorrectArgument throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("IncorrectArgument", output)
        @test occursin("invalid argument", output)
    end

    # Test NotImplemented
    @testset verbose = VERBOSE showtiming = SHOWTIMING "NotImplemented" begin
        e = CTBase.NotImplemented("feature not ready")
        @test_throws CTBase.NotImplemented throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("NotImplemented", output)
        @test occursin("feature not ready", output)
    end

    # Test UnauthorizedCall
    @testset verbose = VERBOSE showtiming = SHOWTIMING "UnauthorizedCall" begin
        e = CTBase.UnauthorizedCall("access denied")
        @test_throws CTBase.UnauthorizedCall throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("UnauthorizedCall", output)
        @test occursin("access denied", output)
    end

    # Test ParsingError
    @testset verbose = VERBOSE showtiming = SHOWTIMING "ParsingError" begin
        e = CTBase.ParsingError("syntax error")
        @test_throws CTBase.ParsingError throw(e)
        output = sprint(showerror, e)
        @test typeof(output) == String
        @test occursin("ParsingError", output)
        @test occursin("syntax error", output)
    end

    # Test ExtensionError
    @testset verbose = VERBOSE showtiming = SHOWTIMING "ExtensionError" begin
        # Test constructor throws if no dependencies provided
        @test_throws CTBase.UnauthorizedCall CTBase.ExtensionError()
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
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "CTException supertype catch" begin
        e = CTBase.IncorrectArgument("msg")
        @test_throws CTBase.IncorrectArgument throw(e)
    end

    return nothing
end
