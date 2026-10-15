module TestDocumentationHelpers

using Test: Test
using CTBase: CTBase
using CTBase: DevTools
# Loading these three activates the DocumenterReference extension
using Documenter: Documenter
using Markdown: Markdown
using MarkdownAST: MarkdownAST

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# A tag no extension implements: reaches the stubs although the extension is loaded
struct FakeDocTag <: DevTools.AbstractDocumenterReferenceTag end

# Run f with stdout captured; return (value, printed text)
function captured(f)
    pipe = Pipe()
    value = redirect_stdout(f, pipe)
    close(pipe.in)
    return value, read(pipe, String)
end

function test_documentation_helpers()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Documentation helpers" begin

        # ==================================================================
        # CONTRACT TESTS — exports and extension dispatch
        # ==================================================================

        Test.@testset "exported by DevTools, not by CTBase" begin
            for name in (:repl_without_extensions, :warnings_without_paths)
                Test.@test name in names(DevTools)
                Test.@test !(name in names(CTBase))
            end
        end

        Test.@testset "the default tag dispatches to the extension" begin
            ext = Base.get_extension(CTBase, :DocumenterReference)
            Test.@test ext isa Module
            m = which(
                DevTools.warnings_without_paths,
                Tuple{Function,DevTools.DocumenterReferenceTag},
            )
            Test.@test m.module === ext
            m = which(
                DevTools.repl_without_extensions,
                Tuple{DevTools.DocumenterReferenceTag,Symbol,String},
            )
            Test.@test m.module === ext
        end

        # ==================================================================
        # UNIT TESTS — warnings_without_paths
        # ==================================================================

        Test.@testset "warnings printed without source path" begin
            value, out = captured() do
                DevTools.warnings_without_paths() do
                    @warn "first line\nsecond line"
                    @info "not shown"
                    42
                end
            end
            Test.@test value == 42
            Test.@test out ==
                "┌ Warning: first line\n│ second line\n└ @ $(@__MODULE__)\n"
            Test.@test !occursin(@__FILE__, out)
        end

        Test.@testset "show = true prints the value and returns nothing" begin
            value, out = captured() do
                DevTools.warnings_without_paths(; show=true) do
                    @error "broken"
                    [1, 2]
                end
            end
            Test.@test value === nothing
            Test.@test startswith(out, "┌ Error: broken\n└ @ $(@__MODULE__)\n")
            Test.@test occursin("2-element Vector{Int64}", out)
        end

        Test.@testset "no warning: nothing printed" begin
            value, out = captured(() -> DevTools.warnings_without_paths(() -> :ok))
            Test.@test value === :ok
            Test.@test out == ""
        end

        # ==================================================================
        # INTEGRATION TESTS — repl_without_extensions (spawns a Julia process)
        # ==================================================================

        Test.@testset "error of a missing extension, rendered like @repl" begin
            # Documenter is loaded here, not in the fresh process: the stub throws there
            md = DevTools.repl_without_extensions(
                :CTBase, "CTBase.DevTools.automatic_reference_documentation()"
            )
            Test.@test md isa Markdown.MD
            code = only(md.content)
            Test.@test code isa Markdown.Code
            Test.@test startswith(code.language, "ansi julia-repl-runs=julia:1,ansi:")
            Test.@test startswith(
                code.code,
                "julia> CTBase.DevTools.automatic_reference_documentation()\nERROR: ",
            )
            Test.@test occursin("ExtensionError", code.code)
            Test.@test occursin("Documenter", code.code)
        end

        Test.@testset "snippets before the last are inputs, run first" begin
            md = DevTools.repl_without_extensions(:CTBase, "x = 1", "error(\"x = \$x\")")
            code = only(md.content)
            Test.@test startswith(code.language, "ansi julia-repl-runs=julia:3,ansi:")
            Test.@test startswith(code.code, "julia> x = 1\n\njulia> error(")
            Test.@test occursin("x = 1", split(code.code, "ERROR: ")[end])
        end

        # ==================================================================
        # ERROR TESTS — stubs and failure paths
        # ==================================================================

        Test.@testset "stubs throw ExtensionError" begin
            Test.@test_throws CTBase.Exceptions.ExtensionError DevTools.repl_without_extensions(
                FakeDocTag(), :CTBase, "1"
            )
            Test.@test_throws CTBase.Exceptions.ExtensionError DevTools.warnings_without_paths(
                () -> 1, FakeDocTag()
            )
        end

        Test.@testset "an example that no longer throws fails" begin
            Test.@test_throws CTBase.Exceptions.IncorrectArgument DevTools.repl_without_extensions(
                :CTBase, "1 + 1"
            )
        end

        Test.@testset "no snippet" begin
            Test.@test_throws CTBase.Exceptions.IncorrectArgument DevTools.repl_without_extensions(
                :CTBase
            )
        end

        Test.@testset "a failing snippet before the last makes the process fail" begin
            Test.@test_throws Base.ProcessFailedException redirect_stderr(devnull) do
                DevTools.repl_without_extensions(
                    :CTBase, "error(\"setup\")", "error(\"last\")"
                )
            end
        end
    end
end

end # module TestDocumentationHelpers

# CRITICAL: redefine in outer scope so the test runner can call it
test_documentation_helpers() = TestDocumentationHelpers.test_documentation_helpers()
