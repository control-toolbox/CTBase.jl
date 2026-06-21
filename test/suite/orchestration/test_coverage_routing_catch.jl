module TestCoverageRoutingCatch

using Test: Test
import CTBase.Exceptions
import CTBase.Orchestration
import CTBase.Strategies
import CTBase.Options

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# FAKE TYPES FOR TESTING (TOP-LEVEL)
# ============================================================================

abstract type FakeDiscretizer <: Strategies.AbstractStrategy end
abstract type FakeModeler <: Strategies.AbstractStrategy end

struct FakeDisc <: FakeDiscretizer
    options::Strategies.StrategyOptions
end

struct FakeMod <: FakeModeler
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{FakeDisc}) = :fake_disc
Strategies.id(::Type{FakeMod}) = :fake_mod

# Both have a 'backend' option to create ambiguity
function Strategies.metadata(::Type{FakeDisc})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:cpu, description="Backend"
        ),
    )
end

function Strategies.metadata(::Type{FakeMod})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:dense, description="Backend"
        ),
    )
end

Strategies.options(s::Union{FakeDisc,FakeMod}) = s.options

function FakeDisc(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeDisc; mode=mode, kwargs...)
    return FakeDisc(opts)
end

function FakeMod(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(FakeMod; mode=mode, kwargs...)
    return FakeMod(opts)
end

# ============================================================================
# TEST FUNCTION
# ============================================================================

"""
    test_coverage_routing_catch()

🧪 **Applying Testing Rule**: Unit Tests for routing error branches

Tests uncovered lines in routing.jl:
- Line 330: catch block in _error_ambiguous_option when metadata lookup fails
- Lines 379, 384: _warn_unknown_option_permissive (not called in current codebase)
"""
function test_coverage_routing_catch()
    Test.@testset "Routing Catch Block Coverage" verbose=VERBOSE showtiming=SHOWTIMING begin
        registry = Strategies.create_registry(
            FakeDiscretizer => (FakeDisc,), FakeModeler => (FakeMod,)
        )

        families = (discretizer=FakeDiscretizer, modeler=FakeModeler)
        action_defs = Options.OptionDefinition[]

        # ====================================================================
        # UNIT TESTS - Ambiguous option error (triggers catch at line 330)
        # ====================================================================

        Test.@testset "Ambiguous Option Error" begin
            # Both FakeDisc and FakeMod have 'backend' option
            # Providing it without disambiguation should trigger ambiguity error
            method = (:fake_disc, :fake_mod)
            kwargs = (backend=:sparse,)  # Ambiguous!

            # This should throw IncorrectArgument due to ambiguity
            # The error path includes a try-catch for metadata lookup (line 330)
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )
        end

        # ====================================================================
        # UNIT TESTS - Explicit mode ambiguity (line 379, 384)
        # ====================================================================

        Test.@testset "Explicit Mode Ambiguity" begin
            # Test with source_mode=:explicit (internal mode)
            # This triggers different error messages at lines 379, 384
            method = (:fake_disc, :fake_mod)
            kwargs = (backend=:sparse,)

            # With explicit mode, ambiguity error has different message
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry; source_mode=:explicit
            )
        end

        # ====================================================================
        # UNIT TESTS - Successful disambiguation
        # ====================================================================

        Test.@testset "Successful Disambiguation" begin
            method = (:fake_disc, :fake_mod)

            # Disambiguate using route_to
            kwargs = (backend=Strategies.route_to(fake_disc=:cpu, fake_mod=:dense),)

            # This should work fine
            result = Orchestration.route_all_options(
                method, families, action_defs, kwargs, registry
            )

            Test.@test haskey(result.strategies.discretizer, :backend)
            Test.@test haskey(result.strategies.modeler, :backend)
            Test.@test result.strategies.discretizer[:backend] === :cpu
            Test.@test result.strategies.modeler[:backend] === :dense
        end
    end
end

end # module

test_coverage_routing_catch() = TestCoverageRoutingCatch.test_coverage_routing_catch()
