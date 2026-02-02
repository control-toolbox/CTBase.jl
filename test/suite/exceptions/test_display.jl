module TestExceptionDisplay

using Test
using CTBase
using CTBase.Exceptions
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
Tests for exception display functions (display.jl)
"""
function test_exception_display()
    @testset "Exception Display" verbose = VERBOSE showtiming = SHOWTIMING begin
        
        @testset "IncorrectArgument - User-Friendly Display" begin
            io = IOBuffer()
            e = IncorrectArgument(
                "Test error",
                got="value1",
                expected="value2",
                suggestion="Fix it like this",
                context="test function"
            )
            
            # User-friendly display (default)
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            # Check for key sections in user-friendly display
            @test contains(output, "Control Toolbox Error")
            @test contains(output, "Problem:")
            @test contains(output, "Test error")
            @test contains(output, "Details:")
            @test contains(output, "Got:")
            @test contains(output, "value1")
            @test contains(output, "Expected:")
            @test contains(output, "value2")
            @test contains(output, "Context:")
            @test contains(output, "test function")
            @test contains(output, "Suggestion:")
            @test contains(output, "Fix it like this")
        end
        
        @testset "IncorrectArgument - Full Stacktrace Display" begin
            io = IOBuffer()
            e = IncorrectArgument(
                "Test error",
                got="value1",
                expected="value2"
            )
            
            # Full stacktrace display
            CTBase.set_show_full_stacktrace!(true)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            # Check for standard Julia error format
            @test contains(output, "IncorrectArgument")
            @test contains(output, "Test error")
            @test contains(output, "got: value1")
            @test contains(output, "expected: value2")
            
            # Reset to default
            CTBase.set_show_full_stacktrace!(false)
        end
        
        @testset "IncorrectArgument - Minimal Display" begin
            io = IOBuffer()
            e = IncorrectArgument("Simple error")
            
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            @test contains(output, "Simple error")
            @test contains(output, "Problem:")
        end
        
        @testset "UnauthorizedCall - User-Friendly Display" begin
            io = IOBuffer()
            e = UnauthorizedCall(
                "Cannot call function",
                reason="already called",
                suggestion="Create new instance",
                context="state! function"
            )
            
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            @test contains(output, "Control Toolbox Error")
            @test contains(output, "Cannot call function")
            @test contains(output, "Reason:")
            @test contains(output, "already called")
            @test contains(output, "Suggestion:")
            @test contains(output, "Create new instance")
        end
        
        @testset "UnauthorizedCall - Full Stacktrace Display" begin
            io = IOBuffer()
            e = UnauthorizedCall("Test", reason="test reason")
            
            CTBase.set_show_full_stacktrace!(true)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            @test contains(output, "UnauthorizedCall")
            @test contains(output, "Test")
            @test contains(output, "reason: test reason")
            
            CTBase.set_show_full_stacktrace!(false)
        end
        
        @testset "NotImplemented - Display" begin
            io = IOBuffer()
            e = NotImplemented("Feature not implemented", type_info="MyType")
            
            # User-friendly
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "Feature not implemented")
            @test contains(output, "Type:")
            @test contains(output, "MyType")
            
            # Full stacktrace
            CTBase.set_show_full_stacktrace!(true)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "NotImplemented")
            
            CTBase.set_show_full_stacktrace!(false)
        end
        
        @testset "ParsingError - Display" begin
            io = IOBuffer()
            e = ParsingError("Syntax error", location="line 42")
            
            # User-friendly
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "Syntax error")
            @test contains(output, "Location:")
            @test contains(output, "line 42")
            
            # Full stacktrace
            CTBase.set_show_full_stacktrace!(true)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "ParsingError")
            @test contains(output, "at: line 42")
            
            CTBase.set_show_full_stacktrace!(false)
        end
        
        @testset "Display - No Crash on Edge Cases" begin
            io = IOBuffer()
            
            # Empty optional fields
            e1 = IncorrectArgument("Error")
            @test_nowarn showerror(io, e1)
            
            e2 = UnauthorizedCall("Error")
            @test_nowarn showerror(io, e2)
            
            e3 = NotImplemented("Error")
            @test_nowarn showerror(io, e3)
            
            e4 = ParsingError("Error")
            @test_nowarn showerror(io, e4)
            
            e5 = AmbiguousDescription((:test,))
            @test_nowarn showerror(io, e5)
            
            e6 = ExtensionError(:TestExt)
            @test_nowarn showerror(io, e6)
        end
        
        @testset "AmbiguousDescription - Display" begin
            io = IOBuffer()
            e = AmbiguousDescription(
                (:f,),
                candidates=["(:a, :b)", "(:c, :d)"],
                suggestion="Use complete description",
                context="algorithm selection"
            )
            
            # User-friendly
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "AmbiguousDescription")
            @test contains(output, "(:f,)")
            @test contains(output, "Valid candidates:")
            @test contains(output, "(:a, :b)")
            @test contains(output, "algorithm selection")
            
            # Full stacktrace
            CTBase.set_show_full_stacktrace!(true)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "AmbiguousDescription")
            @test contains(output, "(:f,) is ambiguous / incorrect")
            
            CTBase.set_show_full_stacktrace!(false)
        end
        
        @testset "ExtensionError - Display" begin
            io = IOBuffer()
            e = ExtensionError(
                :Plots, :PlotlyJS,
                message="to plot results",
                feature="plotting functionality",
                context="solve! call"
            )
            
            # User-friendly
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "ExtensionError")
            @test contains(output, "Missing dependencies:")
            @test contains(output, "Plots")
            @test contains(output, "PlotlyJS")
            @test contains(output, "plotting functionality")
            @test contains(output, "julia> using")
            
            # Full stacktrace
            CTBase.set_show_full_stacktrace!(true)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            @test contains(output, "ExtensionError")
            @test contains(output, "Please make:")
            @test contains(output, "using Plots, PlotlyJS")
            
            CTBase.set_show_full_stacktrace!(false)
        end
        
        @testset "extract_user_frames function" begin
            # Test with a mock stacktrace that includes various frame types
            # This tests the filtering logic in extract_user_frames
            try
                # Create an error to generate a real stacktrace
                error("test error")
            catch e
                st = stacktrace(catch_backtrace())
                filtered = CTBase.Exceptions.extract_user_frames(st)
                
                # Should return some frames (non-empty in normal test environment)
                @test filtered isa Vector
                # The filtering should work without errors
                @test_nowarn CTBase.Exceptions.extract_user_frames(st)
            end
        end
        
        @testset "NotImplemented - Missing optional fields" begin
            io = IOBuffer()
            # Test with only required field (msg)
            e = NotImplemented("Not implemented feature")
            
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            @test contains(output, "NotImplemented")
            @test contains(output, "Not implemented feature")
            # Should not contain optional sections that are not provided
            @test !contains(output, "Type:")
            @test !contains(output, "Context:")
            @test !contains(output, "Suggestion:")
        end

        @testset "NotImplemented - All optional fields" begin
            io = IOBuffer()
            e = NotImplemented(
                "Not implemented feature";
                type_info="MyType",
                context="testing context",
                suggestion="use this instead",
            )

            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))

            @test contains(output, "NotImplemented")
            @test contains(output, "Not implemented feature")
            @test contains(output, "Type:")
            @test contains(output, "MyType")
            @test contains(output, "Context:")
            @test contains(output, "testing context")
            @test contains(output, "Suggestion:")
            @test contains(output, "use this instead")
        end

        @testset "ParsingError - Missing optional fields" begin
            io = IOBuffer()
            # Test with only required field (msg)
            e = ParsingError("Parse error")
            
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            @test contains(output, "ParsingError")
            @test contains(output, "Parse error")
            # Should not contain optional sections that are not provided
            @test !contains(output, "Location:")
            @test !contains(output, "Suggestion:")
        end

        @testset "ParsingError - All optional fields" begin
            io = IOBuffer()
            e = ParsingError("Parse error"; location="line 10", suggestion="check syntax")

            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))

            @test contains(output, "ParsingError")
            @test contains(output, "Parse error")
            @test contains(output, "Location:")
            @test contains(output, "line 10")
            @test contains(output, "Suggestion:")
            @test contains(output, "check syntax")
        end

        @testset "ExtensionError - Minimal fields" begin
            io = IOBuffer()
            # Test with only required fields
            e = ExtensionError(:TestDep)
            
            CTBase.set_show_full_stacktrace!(false)
            @test_nowarn showerror(io, e)
            output = String(take!(io))
            
            @test contains(output, "ExtensionError")
            @test contains(output, "Missing dependencies:")
            @test contains(output, "TestDep")
            # Should not contain optional sections that are not provided
            @test !contains(output, "Feature:")
            @test !contains(output, "Context:")
            @test !contains(output, "Purpose:")
        end
        
        @testset "User code location display" begin
            io = IOBuffer()
            e = IncorrectArgument("Test error for location")
            
            CTBase.set_show_full_stacktrace!(false)

            # We must throw and catch the error to have a valid backtrace
            try
                throw(e)
            catch e_caught
                @test_nowarn showerror(io, e_caught)
            end

            output = String(take!(io))
            
            # The output should contain the user code location section
            # (this tests the lines 173-187 that were uncovered)
            @test contains(output, "Control Toolbox Error")
            @test contains(output, "In your code:")
            # In a real test environment, this should show user frames
            # The exact content depends on the test environment
        end
    end
end

end # module

test_display() = TestExceptionDisplay.test_exception_display()
