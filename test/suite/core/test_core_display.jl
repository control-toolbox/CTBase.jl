module TestCoreDisplay

using Test: Test
import CTBase.Core

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_core_display()
    io_plain = IOContext(devnull, :color => false)
    io_color = IOContext(devnull, :color => true)

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_apply_ansi" begin
        Test.@testset "no color — returns plain string" begin
            Test.@test Core._apply_ansi("hello", "1", io_plain) == "hello"
            Test.@test Core._apply_ansi("hello", "2", io_plain) == "hello"
            Test.@test Core._apply_ansi("hello", "1;31", io_plain) == "hello"
        end

        Test.@testset "with color — wraps with escape codes" begin
            result = Core._apply_ansi("hello", "42", io_color)
            Test.@test startswith(result, "\033[42m")
            Test.@test endswith(result, "\033[0m")
            Test.@test contains(result, "hello")
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "semantic wrappers" begin
        Test.@testset "no color — all return plain string" begin
            Test.@test Core._dim("x", io_plain) == "x"
            Test.@test Core._bold("x", io_plain) == "x"
            Test.@test Core._red("x", io_plain) == "x"
            Test.@test Core._yellow("x", io_plain) == "x"
            Test.@test Core._green("x", io_plain) == "x"
        end

        Test.@testset "with color — all wrap string" begin
            for f in (Core._dim, Core._bold, Core._red, Core._yellow, Core._green)
                result = f("x", io_color)
                Test.@test startswith(result, "\033[")
                Test.@test endswith(result, "\033[0m")
                Test.@test contains(result, "x")
            end
        end

        Test.@testset "each wrapper uses distinct ANSI code" begin
            results = map(
                f -> f("x", io_color),
                (Core._dim, Core._bold, Core._red, Core._yellow, Core._green),
            )
            Test.@test allunique(results)
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "get_format_codes" begin
        all_fields = (
            :bold, :dim, :reset,
            :name, :type, :value, :keyword, :count, :label,
            :emphasis, :muted, :error, :warning, :success,
        )

        Test.@testset "no color — all fields are empty strings" begin
            fmt = Core.get_format_codes(io_plain)
            for field in all_fields
                Test.@test fmt[field] == ""
            end
        end

        Test.@testset "with color — all fields are non-empty" begin
            fmt = Core.get_format_codes(io_color)
            for field in all_fields
                Test.@test fmt[field] != ""
            end
        end

        Test.@testset "returns a NamedTuple with expected fields" begin
            fmt = Core.get_format_codes(io_plain)
            Test.@test fmt isa NamedTuple
            for field in all_fields
                Test.@test haskey(fmt, field)
            end
        end

        Test.@testset "legacy aliases match semantic fields" begin
            fmt = Core.get_format_codes(io_color)
            Test.@test fmt.bold == fmt.emphasis
            Test.@test fmt.dim  == fmt.muted
        end
    end

    return nothing
end

end # module

test_core_display() = TestCoreDisplay.test_core_display()
