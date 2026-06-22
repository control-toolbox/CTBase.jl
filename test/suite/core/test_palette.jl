module TestPalette

using Test: Test
import CTBase.Core

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_palette()
    io_plain = IOContext(devnull, :color => false)
    io_color = IOContext(devnull, :color => true)

    # Always restore the default palette after this test suite so other tests
    # are not affected by palette mutations.
    try
        _run_palette_tests(io_plain, io_color)
    finally
        Core.reset_palette!()
    end

    return nothing
end

function _run_palette_tests(io_plain, io_color)
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Style" begin
        Test.@testset "construction" begin
            s = Core.Style("32")
            Test.@test s.code == "32"
            s_empty = Core.Style("")
            Test.@test s_empty.code == ""
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Palette" begin
        Test.@testset "DEFAULT_PALETTE fields" begin
            p = Core.DEFAULT_PALETTE
            Test.@test p isa Core.Palette
            Test.@test p.name.code == "1;34"
            Test.@test p.type.code == "36"
            Test.@test p.value.code == "32"
            Test.@test p.keyword.code == "33"
            Test.@test p.count.code == "35"
            Test.@test p.label.code == "90"
            Test.@test p.emphasis.code == "1"
            Test.@test p.muted.code == "2"
            Test.@test p.error.code == "31"
            Test.@test p.warning.code == "33"
            Test.@test p.success.code == "32"
        end

        Test.@testset "MONOCHROME_PALETTE — all codes empty" begin
            p = Core.MONOCHROME_PALETTE
            for field in fieldnames(Core.Palette)
                Test.@test getfield(p, field).code == ""
            end
        end

        Test.@testset "HIGH_CONTRAST_PALETTE — all codes non-empty" begin
            p = Core.HIGH_CONTRAST_PALETTE
            for field in fieldnames(Core.Palette)
                Test.@test !isempty(getfield(p, field).code)
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "current_palette / set_palette!" begin
        Test.@testset "default is DEFAULT_PALETTE" begin
            Test.@test Core.current_palette() === Core.DEFAULT_PALETTE
        end

        Test.@testset "set_palette! changes active palette" begin
            Core.set_palette!(Core.MONOCHROME_PALETTE)
            Test.@test Core.current_palette() === Core.MONOCHROME_PALETTE
        end

        Test.@testset "reset_palette! restores default" begin
            Core.set_palette!(Core.HIGH_CONTRAST_PALETTE)
            Core.reset_palette!()
            Test.@test Core.current_palette() === Core.DEFAULT_PALETTE
        end

        Test.@testset "set_palette! returns the new palette" begin
            result = Core.set_palette!(Core.MONOCHROME_PALETTE)
            Test.@test result === Core.MONOCHROME_PALETTE
            Core.reset_palette!()
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "set_color!" begin
        Test.@testset "overrides a single role" begin
            Core.reset_palette!()
            Core.set_color!(:error, "35")
            p = Core.current_palette()
            Test.@test p.error.code == "35"
            # other roles unchanged
            Test.@test p.name.code == "1;34"
            Test.@test p.success.code == "32"
            Core.reset_palette!()
        end

        Test.@testset "all roles are settable" begin
            roles = (:name, :type, :value, :keyword, :count, :label,
                     :emphasis, :muted, :error, :warning, :success)
            Core.reset_palette!()
            for role in roles
                Core.set_color!(role, "99")
                p = Core.current_palette()
                Test.@test getfield(p, role).code == "99"
                Core.reset_palette!()
            end
        end

        Test.@testset "empty code suppresses styling for that role" begin
            Core.set_color!(:error, "")
            Test.@test Core._red("x", io_color) == "x"
            Core.reset_palette!()
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_style helper" begin
        Test.@testset "no color IO — returns plain string" begin
            st = Core.Style("32")
            Test.@test Core._style(st, "hello", io_plain) == "hello"
        end

        Test.@testset "color IO + non-empty code — wraps with escape" begin
            st = Core.Style("32")
            result = Core._style(st, "hello", io_color)
            Test.@test startswith(result, "\033[32m")
            Test.@test endswith(result, "\033[0m")
            Test.@test contains(result, "hello")
        end

        Test.@testset "color IO + empty code — returns plain string" begin
            st = Core.Style("")
            Test.@test Core._style(st, "hello", io_color) == "hello"
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "MONOCHROME_PALETTE silences all output" begin
        Core.set_palette!(Core.MONOCHROME_PALETTE)

        Test.@testset "get_format_codes — all style fields empty" begin
            fmt = Core.get_format_codes(io_color)
            # :reset is palette-independent (it's "\033[0m" whenever color is on)
            # so we only check the style-bearing fields here
            for field in (
                :name, :type, :value, :keyword, :count, :label,
                :emphasis, :muted, :error, :warning, :success,
                :bold, :dim,
            )
                Test.@test fmt[field] == ""
            end
        end

        Test.@testset "named helpers — return plain text" begin
            for f in (Core._dim, Core._bold, Core._red, Core._yellow, Core._green)
                Test.@test f("x", io_color) == "x"
            end
        end

        Core.reset_palette!()
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "HIGH_CONTRAST_PALETTE changes codes" begin
        Core.set_palette!(Core.HIGH_CONTRAST_PALETTE)
        fmt_hc = Core.get_format_codes(io_color)
        Core.reset_palette!()
        fmt_def = Core.get_format_codes(io_color)

        Test.@testset "error code differs from default" begin
            Test.@test fmt_hc.error != fmt_def.error
        end
        Test.@testset "success code differs from default" begin
            Test.@test fmt_hc.success != fmt_def.success
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "get_format_codes — new semantic keys present" begin
        fmt = Core.get_format_codes(io_color)
        for key in (:emphasis, :muted, :error, :warning, :success)
            Test.@test haskey(fmt, key)
            Test.@test fmt[key] != ""
        end
        # Legacy aliases still present
        Test.@test haskey(fmt, :bold)
        Test.@test haskey(fmt, :dim)
        Test.@test fmt.bold == fmt.emphasis
        Test.@test fmt.dim == fmt.muted
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "show_palette" begin
        Test.@testset "runs without error — default palette" begin
            buf = IOBuffer()
            io = IOContext(buf, :color => true)
            Core.show_palette(io)
            output = String(take!(buf))
            Test.@test contains(output, "DEFAULT_PALETTE")
            Test.@test contains(output, "Semantic roles")
            Test.@test contains(output, "Mock describe")
            Test.@test contains(output, "Mock exception")
            # All 11 role names appear in the role swatches
            for role in ("name", "type", "value", "keyword", "count",
                         "label", "emphasis", "muted", "error", "warning", "success")
                Test.@test contains(output, role)
            end
        end

        Test.@testset "names active palette — MONOCHROME" begin
            Core.set_palette!(Core.MONOCHROME_PALETTE)
            buf = IOBuffer()
            Core.show_palette(IOContext(buf, :color => true))
            output = String(take!(buf))
            Test.@test contains(output, "MONOCHROME_PALETTE")
            Core.reset_palette!()
        end

        Test.@testset "names active palette — HIGH_CONTRAST" begin
            Core.set_palette!(Core.HIGH_CONTRAST_PALETTE)
            buf = IOBuffer()
            Core.show_palette(IOContext(buf, :color => true))
            output = String(take!(buf))
            Test.@test contains(output, "HIGH_CONTRAST_PALETTE")
            Core.reset_palette!()
        end

        Test.@testset "names custom palette as 'custom'" begin
            my = Core.Palette(
                Core.Style("35"), Core.Style("35"), Core.Style("35"), Core.Style("35"),
                Core.Style("35"), Core.Style("35"), Core.Style("35"), Core.Style("35"),
                Core.Style("35"), Core.Style("35"), Core.Style("35"),
            )
            Core.set_palette!(my)
            buf = IOBuffer()
            Core.show_palette(IOContext(buf, :color => true))
            output = String(take!(buf))
            Test.@test contains(output, "custom")
            Core.reset_palette!()
        end

        Test.@testset "plain IO — no ANSI codes in role content" begin
            buf = IOBuffer()
            io_plain = IOContext(buf, :color => false)
            Core.show_palette(io_plain)
            output = String(take!(buf))
            # With color disabled the role descriptions must still appear
            Test.@test contains(output, "Semantic roles")
            # No ANSI escape in content produced by the palette (bold headers may still use IO color)
            # The role swatch open() calls return "" when color=false
            Test.@test !occursin("\033[1;34m", output)  # name role code absent
            Test.@test !occursin("\033[31m", output)     # error role code absent
        end
    end

end

end # module

test_palette() = TestPalette.test_palette()
