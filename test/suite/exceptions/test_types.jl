module TestExceptionTypes

import Test
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
Tests for exception type definitions (types.jl)
"""
function test_exception_types()
    Test.@testset "Exception Types" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "CTException Hierarchy" begin
            # Test that all exceptions inherit from CTException
            Test.@test Exceptions.IncorrectArgument("test") isa Exceptions.CTException
            Test.@test Exceptions.PreconditionError("test") isa Exceptions.CTException

            Test.@test Exceptions.NotImplemented("test") isa Exceptions.CTException
            Test.@test Exceptions.ParsingError("test") isa Exceptions.CTException
            Test.@test Exceptions.AmbiguousDescription((:f,)) isa Exceptions.CTException
            Test.@test Exceptions.ExtensionError(:MyExt) isa Exceptions.CTException
            Test.@test Exceptions.SolverFailure("test") isa Exceptions.CTException

            # Test that they are also standard Exceptions
            Test.@test Exceptions.IncorrectArgument("test") isa Exception
            Test.@test Exceptions.PreconditionError("test") isa Exception

            Test.@test Exceptions.NotImplemented("test") isa Exception
            Test.@test Exceptions.ParsingError("test") isa Exception
            Test.@test Exceptions.AmbiguousDescription((:f,)) isa Exception
            Test.@test Exceptions.ExtensionError(:MyExt) isa Exception
            Test.@test Exceptions.SolverFailure("test") isa Exception
        end

        Test.@testset "IncorrectArgument - Construction" begin
            # Simple message only
            e = Exceptions.IncorrectArgument("Invalid input")
            Test.@test e.msg == "Invalid input"
            Test.@test isnothing(e.got)
            Test.@test isnothing(e.expected)
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With got and expected
            e = Exceptions.IncorrectArgument("Invalid value", got="x", expected="y")
            Test.@test e.msg == "Invalid value"
            Test.@test e.got == "x"
            Test.@test e.expected == "y"
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With all fields
            e = Exceptions.IncorrectArgument(
                "Invalid criterion",
                got=":invalid",
                expected=":min or :max",
                suggestion="Use objective!(ocp, :min, ...)",
                context="objective! function",
            )
            Test.@test e.msg == "Invalid criterion"
            Test.@test e.got == ":invalid"
            Test.@test e.expected == ":min or :max"
            Test.@test e.suggestion == "Use objective!(ocp, :min, ...)"
            Test.@test e.context == "objective! function"

            # Test that it can be thrown
            Test.@test_throws Exceptions.IncorrectArgument throw(Exceptions.IncorrectArgument("Test error"))
        end

        Test.@testset "PreconditionError - Construction" begin
            # Simple message only
            e = Exceptions.PreconditionError("State must be set before dynamics")
            Test.@test e.msg == "State must be set before dynamics"
            Test.@test isnothing(e.reason)
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With reason
            e = Exceptions.PreconditionError("Cannot call", reason="precondition not met")
            Test.@test e.msg == "Cannot call"
            Test.@test e.reason == "precondition not met"
            Test.@test isnothing(e.suggestion)

            # With all fields
            e = Exceptions.PreconditionError(
                "Cannot call state! twice",
                reason="state has already been defined for this OCP",
                suggestion="Create a new OCP instance",
                context="state! function",
            )
            Test.@test e.msg == "Cannot call state! twice"
            Test.@test e.reason == "state has already been defined for this OCP"
            Test.@test e.suggestion == "Create a new OCP instance"
            Test.@test e.context == "state! function"

            # Test that it can be thrown
            Test.@test_throws Exceptions.PreconditionError throw(Exceptions.PreconditionError("Test error"))
        end

        Test.@testset "NotImplemented - Construction" begin
            # Simple message only
            e = Exceptions.NotImplemented("run! not implemented")
            Test.@test e.msg == "run! not implemented"
            Test.@test isnothing(e.required_method)
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With required method
            e = Exceptions.NotImplemented(
                "run! not implemented", required_method="run!(::MyAlgorithm, state)"
            )
            Test.@test e.msg == "run! not implemented"
            Test.@test e.required_method == "run!(::MyAlgorithm, state)"
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With all fields (NEW)
            e = Exceptions.NotImplemented(
                "Method solve! not implemented",
                required_method="solve!(::MyStrategy, ...)",
                context="solve call",
                suggestion="Import the relevant package (e.g. CTDirect) or implement solve!(::MyStrategy, ...)",
            )
            Test.@test e.msg == "Method solve! not implemented"
            Test.@test e.required_method == "solve!(::MyStrategy, ...)"
            Test.@test e.context == "solve call"
            Test.@test e.suggestion ==
                "Import the relevant package (e.g. CTDirect) or implement solve!(::MyStrategy, ...)"

            # Test that it can be thrown
            Test.@test_throws Exceptions.NotImplemented throw(Exceptions.NotImplemented("Test"))
        end

        Test.@testset "ParsingError - Construction" begin
            # Simple message only
            e = Exceptions.ParsingError("Unexpected token")
            Test.@test e.msg == "Unexpected token"
            Test.@test isnothing(e.location)
            Test.@test isnothing(e.suggestion)

            # With location
            e = Exceptions.ParsingError("Unexpected token", location="line 42")
            Test.@test e.msg == "Unexpected token"
            Test.@test e.location == "line 42"
            Test.@test isnothing(e.suggestion)

            # With all fields (NEW)
            e = Exceptions.ParsingError(
                "Unexpected token 'end'",
                location="line 42, column 15",
                suggestion="Check syntax balance or remove extra 'end'",
            )
            Test.@test e.msg == "Unexpected token 'end'"
            Test.@test e.location == "line 42, column 15"
            Test.@test e.suggestion == "Check syntax balance or remove extra 'end'"

            # Test that it can be thrown
            Test.@test_throws Exceptions.ParsingError throw(Exceptions.ParsingError("Test"))
        end

        Test.@testset "AmbiguousDescription - Construction" begin
            # Simple description only
            e = Exceptions.AmbiguousDescription((:f,))
            Test.@test e.description == (:f,)
            Test.@test contains(e.msg, "cannot find matching description")
            Test.@test isnothing(e.candidates)
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With custom message
            e = Exceptions.AmbiguousDescription((:x, :y); msg="Custom message")
            Test.@test e.description == (:x, :y)
            Test.@test e.msg == "Custom message"
            Test.@test isnothing(e.candidates)
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With all fields
            e = Exceptions.AmbiguousDescription(
                (:f,),
                candidates=["(:a, :b)", "(:c, :d)"],
                suggestion="Use a complete description",
                context="algorithm selection",
            )
            Test.@test e.description == (:f,)
            Test.@test e.candidates == ["(:a, :b)", "(:c, :d)"]
            Test.@test e.suggestion == "Use a complete description"
            Test.@test e.context == "algorithm selection"

            # Test that it can be thrown
            Test.@test_throws Exceptions.AmbiguousDescription throw(Exceptions.AmbiguousDescription((:test,)))
        end

        Test.@testset "ExtensionError - Construction" begin
            # Simple dependency only
            e = Exceptions.ExtensionError(:MyExt)
            Test.@test e.weakdeps == (:MyExt,)
            Test.@test e.msg == "missing dependencies"
            Test.@test isnothing(e.feature)
            Test.@test isnothing(e.context)

            # With message
            e = Exceptions.ExtensionError(:Plots; message="to plot results")
            Test.@test e.weakdeps == (:Plots,)
            Test.@test e.msg == "missing dependencies to plot results"
            Test.@test isnothing(e.feature)
            Test.@test isnothing(e.context)

            # With all fields
            e = Exceptions.ExtensionError(
                :Plots,
                :PlotlyJS,
                message="to plot optimization results",
                feature="plotting functionality",
                context="solve! call",
            )
            Test.@test e.weakdeps == (:Plots, :PlotlyJS)
            Test.@test e.msg == "missing dependencies to plot optimization results"
            Test.@test e.feature == "plotting functionality"
            Test.@test e.context == "solve! call"

            # Test that it can be thrown
            Test.@test_throws Exceptions.ExtensionError throw(Exceptions.ExtensionError(:TestExt))

            # Test error when no dependencies provided
            Test.@test_throws Exceptions.PreconditionError Exceptions.ExtensionError()
        end

        Test.@testset "SolverFailure - Construction" begin
            # Simple message only
            e = Exceptions.SolverFailure("Solver failed")
            Test.@test e.msg == "Solver failed"
            Test.@test isnothing(e.retcode)
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With retcode
            e = Exceptions.SolverFailure("Integration failed", retcode=":Unstable")
            Test.@test e.msg == "Integration failed"
            Test.@test e.retcode == ":Unstable"
            Test.@test isnothing(e.suggestion)
            Test.@test isnothing(e.context)

            # With all fields
            e = Exceptions.SolverFailure(
                "Optimization did not converge",
                retcode=":MaxIterations",
                suggestion="Increase max iterations or adjust tolerance",
                context="IPOPT solver",
            )
            Test.@test e.msg == "Optimization did not converge"
            Test.@test e.retcode == ":MaxIterations"
            Test.@test e.suggestion == "Increase max iterations or adjust tolerance"
            Test.@test e.context == "IPOPT solver"

            # Test that it can be thrown
            Test.@test_throws Exceptions.SolverFailure throw(Exceptions.SolverFailure("Test error"))
        end
    end
end

end # module

test_types() = TestExceptionTypes.test_exception_types()
