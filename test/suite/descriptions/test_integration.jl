module TestIntegration

using Test: Test
import CTBase.Descriptions: Descriptions
import CTBase.Extensions: Extensions
import CTBase.Exceptions: Exceptions
import CTBase.Unicode: Unicode

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: Fake type for extension testing
struct DummyDocRefTag <: Extensions.AbstractDocumenterReferenceTag end

function test_integration()
    # Integration test: description workflow combining add, complete, remove, and exceptions
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Integration: description workflow" begin
        algorithms = ()
        algorithms = Descriptions.add(algorithms, (:descent, :bfgs, :bisection))
        algorithms = Descriptions.add(algorithms, (:descent, :gradient, :fixedstep))

        # Successful completion from partial descriptions
        Test.@test Descriptions.complete((:descent,); descriptions=algorithms) ==
            (:descent, :bfgs, :bisection)
        Test.@test Descriptions.complete(
            (:gradient, :fixedstep); descriptions=algorithms
        ) == (:descent, :gradient, :fixedstep)

        # Removing known prefix from completed description
        full = Descriptions.complete((:descent,); descriptions=algorithms)
        prefix = (:descent, :bfgs)
        diff = Descriptions.remove(full, prefix)
        Test.@test diff == (:bisection,)

        # Ambiguous / invalid descriptions should raise AmbiguousDescription
        Test.@test_throws Exceptions.AmbiguousDescription Descriptions.complete(
            (:unknown,); descriptions=algorithms
        )
        Test.@test_throws Exceptions.AmbiguousDescription Descriptions.complete(
            (:descent, :unknown); descriptions=algorithms
        )
    end

    # Integration test: formatting labels using Unicode (subscripts/superscripts) with descriptions
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Integration: label formatting with Unicode" begin
        base = :x

        # Single index / power labels
        label1 = string(base, Unicode.ctindice(1))      # x₁
        label2 = string(base, Unicode.ctupperscript(2)) # x²
        Test.@test label1 == "x₁"
        Test.@test label2 == "x²"

        # Multi-digit index and power combined
        label3 = string(base, Unicode.ctindices(10), Unicode.ctupperscripts(3))
        Test.@test label3 == "x₁₀³"

        # Negative inputs should still throw via the public API
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctindices(-5)
        Test.@test_throws Exceptions.IncorrectArgument Unicode.ctupperscripts(-2)
    end

    # Integration test: descriptions and exceptions consistency
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Integration: descriptions and exceptions" begin
        descs = ()
        descs = Descriptions.add(descs, (:a, :b))

        # Duplicate description via add should raise IncorrectArgument
        Test.@test_throws Exceptions.IncorrectArgument Descriptions.add(descs, (:a, :b))

        # Build a small description set and complete from a prefix
        full = (:a, :b, :c)
        all_descs = ()
        all_descs = Descriptions.add(all_descs, full)
        completed = Descriptions.complete((:a,); descriptions=all_descs)
        Test.@test completed == full

        # Removing a subset should leave the remaining tail
        tail = Descriptions.remove(completed, (:a,))
        Test.@test tail == (:b, :c)
    end

    # Integration test: automatic_reference_documentation fallback when extension is not used
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Integration: automatic_reference_documentation fallback" begin
        err = try
            Extensions.automatic_reference_documentation(DummyDocRefTag();)
            nothing
        catch e
            e
        end

        Test.@test err isa Exceptions.ExtensionError
        Test.@test err.weakdeps == (:Documenter, :Markdown, :MarkdownAST)
    end

    return nothing
end

end # module TestIntegration

# CRITICAL: redefine in outer scope so the test runner can call it
test_integration() = TestIntegration.test_integration()
