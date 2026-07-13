module TestCodeQuality

using Test: Test
using Aqua: Aqua
using JET: JET
using CTBase: CTBase
using Logging: Logging

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Filter LoweredCodeUtils' benign "skipping callee ... UndefRefError()" warnings
# ==============================================================================
#
# JET.test_package collects method signatures via Revise/LoweredCodeUtils without
# calling anything. For keyword-argument functor methods (a callable struct with a
# `; kwarg=default` in its call signature), Julia compiles a hidden body function
# named `var"#_#N"`; LoweredCodeUtils cannot statically attribute that hidden body
# to its parent method and emits a `@warn "skipping callee ..." ` before moving on.
# It is a collector limitation, not a JET finding — the flagged body is simply
# excluded from the static scan; everything else (including its runtime behavior,
# covered by the normal test suite) is unaffected.
#
# Filtered precisely by message prefix + emitting module, so any other, unrelated
# warning from LoweredCodeUtils still surfaces normally.
struct _SkipBenignLoweredCodeUtilsWarnings <: Logging.AbstractLogger
    logger::Logging.AbstractLogger
end

function Logging.min_enabled_level(l::_SkipBenignLoweredCodeUtilsWarnings)
    return Logging.min_enabled_level(l.logger)
end

function Logging.shouldlog(
    l::_SkipBenignLoweredCodeUtilsWarnings, level, _module, group, id
)
    return Logging.shouldlog(l.logger, level, _module, group, id)
end

function Logging.handle_message(
    l::_SkipBenignLoweredCodeUtilsWarnings,
    level,
    message,
    _module,
    group,
    id,
    file,
    line;
    kwargs...,
)
    if level == Logging.Warn &&
        nameof(_module) === :LoweredCodeUtils &&
        startswith(string(message), "skipping callee")
        return nothing
    end
    return Logging.handle_message(
        l.logger, level, message, _module, group, id, file, line; kwargs...
    )
end

function test_code_quality()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Code quality" begin
        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Aqua" begin
            Aqua.test_all(
                CTBase;
                ambiguities=false,
                #stale_deps=(; ignore=[:SomePackage],),
                deps_compat=(; ignore=[:LinearAlgebra, :Unicode],),
                piracies=true,
            )
            # do not warn about ambiguities in dependencies
            Aqua.test_ambiguities(CTBase)
        end

        Test.@testset "JET" begin
            Logging.with_logger(
                _SkipBenignLoweredCodeUtilsWarnings(Logging.current_logger())
            ) do
                JET.test_package(CTBase; target_modules=(CTBase,))
            end
        end

        # Test.@testset "JuliaFormatter" begin
        #     Test.@test JuliaFormatter.format(CTBase; verbose=true, overwrite=false)
        # end

        # Test.@testset "Doctests" begin
        #     Documenter.doctest(CTBase)
        # end
    end

    return nothing
end

end # module TestCodeQuality

# CRITICAL: redefine in outer scope so the test runner can call it
test_code_quality() = TestCodeQuality.test_code_quality()
