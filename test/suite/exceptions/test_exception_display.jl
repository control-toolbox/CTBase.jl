module TestExceptionDisplay

using Test: Test
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
Tests for exception display functions (display.jl)
"""
function test_exception_display()
    Test.@testset "Exception Display" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "IncorrectArgument - User-Friendly Display" begin
            io = IOBuffer()
            e = Exceptions.IncorrectArgument(
                "Test error",
                got="value1",
                expected="value2",
                suggestion="Fix it like this",
                context="test function",
            )

            # User-friendly display (default)
            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            # Check for key sections in user-friendly display
            Test.@test contains(output, "IncorrectArgument")
            Test.@test contains(output, "Test error")
            Test.@test contains(output, "Got")
            Test.@test contains(output, "value1")
            Test.@test contains(output, "Expected")
            Test.@test contains(output, "value2")
            Test.@test contains(output, "Context")
            Test.@test contains(output, "test function")
            Test.@test contains(output, "Hint")
            Test.@test contains(output, "Fix it like this")
        end

        Test.@testset "IncorrectArgument - Full Stacktrace Display" begin
            io = IOBuffer()
            e = Exceptions.IncorrectArgument("Test error", got="value1", expected="value2")

            # Full stacktrace display
            # CTBase.set_show_full_stacktrace!(true)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            # Check for compact format
            Test.@test contains(output, "IncorrectArgument")
            Test.@test contains(output, "Test error")
            Test.@test contains(output, "Got")
            Test.@test contains(output, "value1")
            Test.@test contains(output, "Expected")
            Test.@test contains(output, "value2")

            # Reset to default
            # CTBase.set_show_full_stacktrace!(false)
        end

        Test.@testset "IncorrectArgument - Minimal Display" begin
            io = IOBuffer()
            e = Exceptions.IncorrectArgument("Simple error")

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "Simple error")
            Test.@test !contains(output, "Got  ")
            Test.@test !contains(output, "Expected  ")
            Test.@test !contains(output, "Context  ")
            Test.@test !contains(output, "Hint  ")
        end

        Test.@testset "PreconditionError - User-Friendly Display" begin
            io = IOBuffer()
            e = Exceptions.PreconditionError(
                "State must be set before dynamics",
                reason="state has not been defined yet",
                suggestion="Call state!(ocp, dimension) before dynamics!",
                context="dynamics! function",
            )

            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "PreconditionError")
            Test.@test contains(output, "State must be set before dynamics")
            Test.@test contains(output, "Reason")
            Test.@test contains(output, "state has not been defined yet")
            Test.@test contains(output, "Hint")
            Test.@test contains(output, "Call state!(ocp, dimension)")
        end

        Test.@testset "NotImplemented - Display" begin
            io = IOBuffer()
            e = Exceptions.NotImplemented(
                "Feature not implemented", required_method="MyType"
            )

            # User-friendly
            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "Feature not implemented")
            Test.@test contains(output, "Method")
            Test.@test contains(output, "MyType")

            # CTBase.set_show_full_stacktrace!(false)
        end

        Test.@testset "ParsingError - Display" begin
            io = IOBuffer()
            e = Exceptions.ParsingError("Syntax error", location="line 42")

            # User-friendly
            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "Syntax error")
            Test.@test contains(output, "Location")
            Test.@test contains(output, "line 42")

            # CTBase.set_show_full_stacktrace!(false)
        end

        Test.@testset "Display - No Crash on Edge Cases" begin
            io = IOBuffer()

            # Empty optional fields
            e1 = Exceptions.IncorrectArgument("Error")
            Test.@test_nowarn showerror(io, e1)

            e3 = Exceptions.NotImplemented("Error")
            Test.@test_nowarn showerror(io, e3)

            e4 = Exceptions.ParsingError("Error")
            Test.@test_nowarn showerror(io, e4)

            e5 = Exceptions.AmbiguousDescription((:test,))
            Test.@test_nowarn showerror(io, e5)

            e6 = Exceptions.ExtensionError(:TestExt)
            Test.@test_nowarn showerror(io, e6)

            e7 = Exceptions.SolverFailure("Error")
            Test.@test_nowarn showerror(io, e7)
        end

        Test.@testset "AmbiguousDescription - Display" begin
            io = IOBuffer()
            e = Exceptions.AmbiguousDescription(
                (:f,),
                candidates=["(:a, :b)", "(:c, :d)"],
                suggestion="Use complete description",
                context="algorithm selection",
            )

            # User-friendly
            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "AmbiguousDescription")
            Test.@test contains(output, "(:f,)")
            Test.@test contains(output, "Available")
            Test.@test contains(output, "(:a, :b)")
            Test.@test contains(output, "algorithm selection")

            # CTBase.set_show_full_stacktrace!(false)
        end

        Test.@testset "ExtensionError - Display" begin
            io = IOBuffer()
            e = Exceptions.ExtensionError(
                :Plots,
                :PlotlyJS,
                message="to plot results",
                feature="plotting functionality",
                context="solve! call",
            )

            # User-friendly
            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "ExtensionError")
            Test.@test contains(output, "Missing")
            Test.@test contains(output, "Plots")
            Test.@test contains(output, "PlotlyJS")
            # Check for generated Hint
            Test.@test contains(output, "Run: using")

            # CTBase.set_show_full_stacktrace!(false)
        end

        Test.@testset "extract_user_frames function" begin
            # Test with a mock stacktrace that includes various frame types
            # This tests the filtering logic in extract_user_frames
            try
                # Create an error to generate a real stacktrace
                error("test error")
            catch e
                st = stacktrace(catch_backtrace())
                filtered = Exceptions._extract_user_frames(st)

                # Should return some frames (non-empty in normal test environment)
                Test.@test filtered isa Vector
                # The filtering should work without errors
                Test.@test_nowarn Exceptions._extract_user_frames(st)
            end
        end

        Test.@testset "NotImplemented - Missing optional fields" begin
            io = IOBuffer()
            # Test with only required field (msg)
            e = Exceptions.NotImplemented("Not implemented feature")

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "NotImplemented")
            Test.@test contains(output, "Not implemented feature")
            # Should not contain optional sections that are not provided
            Test.@test !contains(output, "Type:")
            Test.@test !contains(output, "Context:")
            Test.@test !contains(output, "Suggestion:")
        end

        Test.@testset "NotImplemented - All optional fields" begin
            io = IOBuffer()
            e = Exceptions.NotImplemented(
                "Not implemented feature";
                required_method="MyType",
                context="testing context",
                suggestion="use this instead",
            )

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "NotImplemented")
            Test.@test contains(output, "Not implemented feature")
            Test.@test contains(output, "Method")
            Test.@test contains(output, "MyType")
            Test.@test contains(output, "Context")
            Test.@test contains(output, "testing context")
            Test.@test contains(output, "Hint")
            Test.@test contains(output, "use this instead")
        end

        Test.@testset "ParsingError - Missing optional fields" begin
            io = IOBuffer()
            # Test with only required field (msg)
            e = Exceptions.ParsingError("Parse error")

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "ParsingError")
            Test.@test contains(output, "Parse error")
            # Should not contain optional sections that are not provided
            Test.@test !contains(output, "Location  ")
            Test.@test !contains(output, "Hint  ")
        end

        Test.@testset "ParsingError - All optional fields" begin
            io = IOBuffer()
            e = Exceptions.ParsingError(
                "Parse error"; location="line 10", suggestion="check syntax"
            )

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "ParsingError")
            Test.@test contains(output, "Parse error")
            Test.@test contains(output, "Location")
            Test.@test contains(output, "line 10")
            Test.@test contains(output, "Hint")
            Test.@test contains(output, "check syntax")
        end

        Test.@testset "ExtensionError - Minimal fields" begin
            io = IOBuffer()
            # Test with only required fields
            e = Exceptions.ExtensionError(:TestDep)

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "ExtensionError")
            Test.@test contains(output, "Missing")
            Test.@test contains(output, "TestDep")
            # Should not contain optional sections that are not provided
            Test.@test !contains(output, "Feature  ")
            Test.@test !contains(output, "Context  ")
            Test.@test !contains(output, "Purpose  ")
        end

        Test.@testset "PreconditionError - Missing optional fields" begin
            io = IOBuffer()
            e = Exceptions.PreconditionError("Simple error")
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "Simple error")
            Test.@test !contains(output, "Reason  ")
            Test.@test !contains(output, "Context  ")
            Test.@test !contains(output, "Hint  ")
        end

        Test.@testset "AmbiguousDescription - Missing optional fields" begin
            io = IOBuffer()
            e = Exceptions.AmbiguousDescription((:f,))
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "AmbiguousDescription")
            Test.@test contains(output, "(:f,)")
            Test.@test !contains(output, "Available  ")
            Test.@test !contains(output, "Context  ")
            Test.@test !contains(output, "Hint  ")
        end

        Test.@testset "User code location display" begin
            io = IOBuffer()
            e = Exceptions.IncorrectArgument("Test error for location")

            # CTBase.set_show_full_stacktrace!(false)

            # We must throw and catch the error to have a valid backtrace
            try
                throw(e)
            catch e_caught
                Test.@test_nowarn showerror(io, e_caught)
            end

            output = String(take!(io))

            # The output should contain the type name and closing marker
            # (this tests the location-aware formatting path)
            Test.@test contains(output, "IncorrectArgument")
            Test.@test contains(output, "└─")
            # In a real test environment, this should show user frames
            # The exact content depends on the test environment
        end

        Test.@testset "SolverFailure - Display" begin
            io = IOBuffer()
            e = Exceptions.SolverFailure(
                "ODE integration failed",
                retcode=":Unstable",
                suggestion="Reduce time step or check initial conditions",
                context="SciML integrator",
            )

            # User-friendly
            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "SolverFailure")
            Test.@test contains(output, "ODE integration failed")
            Test.@test contains(output, "Retcode")
            Test.@test contains(output, ":Unstable")
            Test.@test contains(output, "Hint")
            Test.@test contains(output, "Reduce time step")
            Test.@test contains(output, "Context")
            Test.@test contains(output, "SciML integrator")

            # CTBase.set_show_full_stacktrace!(false)
        end

        Test.@testset "SolverFailure - Missing optional fields" begin
            io = IOBuffer()
            # Test with only required field (msg)
            e = Exceptions.SolverFailure("Solver failed")

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "SolverFailure")
            Test.@test contains(output, "Solver failed")
            # Should not contain optional sections that are not provided
            Test.@test !contains(output, "Retcode  ")
            Test.@test !contains(output, "Context  ")
            Test.@test !contains(output, "Hint  ")
        end

        Test.@testset "SolverFailure - All optional fields" begin
            io = IOBuffer()
            e = Exceptions.SolverFailure(
                "Optimization did not converge";
                retcode=":MaxIterations",
                context="IPOPT solver",
                suggestion="Increase max iterations",
            )

            # CTBase.set_show_full_stacktrace!(false)
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "SolverFailure")
            Test.@test contains(output, "Optimization did not converge")
            Test.@test contains(output, "Retcode")
            Test.@test contains(output, ":MaxIterations")
            Test.@test contains(output, "Context")
            Test.@test contains(output, "IPOPT solver")
            Test.@test contains(output, "Hint")
            Test.@test contains(output, "Increase max iterations")
        end

        Test.@testset "IncorrectArgument - got without expected" begin
            io = IOBuffer()
            e = Exceptions.IncorrectArgument("wrong value", got="bad_value")
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "Got")
            Test.@test contains(output, "bad_value")
            Test.@test !contains(output, "Expected  ")
        end

        Test.@testset "AmbiguousDescription - diagnostic rendering" begin
            # "empty catalog" branch
            io = IOBuffer()
            e = Exceptions.AmbiguousDescription((:a,); diagnostic="empty catalog")
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "Diagnostic")
            Test.@test contains(output, "Empty catalog")

            # "unknown symbols" branch
            io = IOBuffer()
            e = Exceptions.AmbiguousDescription((:z,); diagnostic="unknown symbols")
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "Diagnostic")
            Test.@test contains(output, "Unknown symbols")

            # "no complete match" branch
            io = IOBuffer()
            e = Exceptions.AmbiguousDescription((:a, :z); diagnostic="no complete match")
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "Diagnostic")
            Test.@test contains(output, "No complete match")

            # else branch — arbitrary diagnostic value
            io = IOBuffer()
            e = Exceptions.AmbiguousDescription((:a,); diagnostic="custom diagnostic")
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))
            Test.@test contains(output, "Diagnostic")
            Test.@test contains(output, "custom diagnostic")
        end

        Test.@testset "AmbiguousDescription - closest-matches inline suggestion" begin
            io = IOBuffer()
            e = Exceptions.AmbiguousDescription(
                (:b, :f);
                candidates=["(:a, :b, :c)", "(:a, :d, :e)", "(:x, :y, :z)"],
                suggestion="Try one of the closest matches:",
            )
            Test.@test_nowarn showerror(io, e)
            output = String(take!(io))

            Test.@test contains(output, "closest matches")
            Test.@test contains(output, "(:a, :b, :c)")
        end
    end
end

end # module

test_exception_display() = TestExceptionDisplay.test_exception_display()
