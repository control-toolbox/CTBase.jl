module TestCoreMacros

using Test: Test
import CTBase.Core
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_macros()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "@ensure" begin
        Test.@testset "@ensure - condition true" begin
            x = 5
            Test.@test_nowarn Core.@ensure x > 0 Exceptions.IncorrectArgument(
                "x must be positive"
            )
            Test.@test_nowarn Core.@ensure x == 5 Exceptions.IncorrectArgument(
                "x must be 5"
            )
        end

        Test.@testset "@ensure - condition false" begin
            x = -5
            Test.@test_throws Exceptions.IncorrectArgument Core.@ensure x > 0 Exceptions.IncorrectArgument(
                "x must be positive"
            )
            y = 10
            Test.@test_throws Exceptions.IncorrectArgument Core.@ensure y < 0 Exceptions.IncorrectArgument(
                "y must be negative"
            )
        end

        Test.@testset "@ensure - with different exception types" begin
            x = 0
            Test.@test_throws ArgumentError Core.@ensure x != 0 ArgumentError(
                "x cannot be zero"
            )
            Test.@test_throws DomainError Core.@ensure x > 0 DomainError(
                x, "x must be positive"
            )
        end

        Test.@testset "@ensure - complex conditions" begin
            x = 5
            y = 10
            Test.@test_nowarn Core.@ensure x < y Exceptions.IncorrectArgument(
                "x must be less than y"
            )
            Test.@test_throws Exceptions.IncorrectArgument Core.@ensure x > y Exceptions.IncorrectArgument(
                "x must be greater than y"
            )
            Test.@test_nowarn Core.@ensure (x > 0 && y > 0) Exceptions.IncorrectArgument(
                "both must be positive"
            )
            Test.@test_throws Exceptions.IncorrectArgument Core.@ensure (x < 0 || y < 0) Exceptions.IncorrectArgument(
                "at least one must be negative"
            )
        end

        Test.@testset "@ensure - exception message verification" begin
            x = -5
            try
                Core.@ensure x > 0 Exceptions.IncorrectArgument("x must be positive")
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                Test.@test e.msg == "x must be positive"
            end
        end

        Test.@testset "@ensure - with type checks" begin
            x = 5
            Test.@test_nowarn Core.@ensure x isa Int Exceptions.IncorrectArgument(
                "x must be an Int"
            )
            Test.@test_throws Exceptions.IncorrectArgument Core.@ensure x isa String Exceptions.IncorrectArgument(
                "x must be a String"
            )
        end
    end
    return nothing
end

end # module TestCoreMacros

test_macros() = TestCoreMacros.test_macros()
