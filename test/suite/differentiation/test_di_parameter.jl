"""
Contract tests for the device-parameterized `DifferentiationInterface{P}` strategy.
"""

module TestDIParameter

using Test: Test
import CTBase.Differentiation
import CTBase.Strategies
using ADTypes: ADTypes

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_di_parameter()
    DI = Differentiation.DifferentiationInterface
    Test.@testset "DifferentiationInterface{P} parameterization" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # CONTRACT - parameter / default_parameter / id
        # ====================================================================

        Test.@testset "parameter contract" begin
            # Bare (device-unspecified) DI resolves to `nothing` via the AbstractADBackend
            # family default — required by consumers that register DI without a parameter
            # (e.g. CTFlows' flow registry) and query `parameter` on the bare type.
            Test.@test Strategies.parameter(DI) === nothing

            Test.@test Strategies.parameter(DI{Strategies.CPU}) == Strategies.CPU
            Test.@test Strategies.parameter(DI{Strategies.GPU}) == Strategies.GPU
            Test.@test Strategies.default_parameter(DI) == Strategies.CPU

            Test.@test Strategies.id(DI) === :di
            Test.@test Strategies.id(DI{Strategies.CPU}) === :di
            Test.@test Strategies.id(DI{Strategies.GPU}) === :di
        end

        # ====================================================================
        # CONTRACT - per-parameter metadata + back-compat bare delegation
        # ====================================================================

        Test.@testset "per-parameter metadata defaults" begin
            md_bare = Strategies.metadata(DI)
            md_cpu = Strategies.metadata(DI{Strategies.CPU})
            md_gpu = Strategies.metadata(DI{Strategies.GPU})

            Test.@test md_cpu[:ad_backend].default === ADTypes.AutoForwardDiff()
            Test.@test md_gpu[:ad_backend].default === ADTypes.AutoZygote()

            # The default is computed from P, so it is flagged `computed` (for `describe`/provenance).
            Test.@test md_cpu[:ad_backend].computed == true
            Test.@test md_gpu[:ad_backend].computed == true

            # Bare `metadata(DI)` delegates to `metadata(DI{CPU})` (back-compat).
            Test.@test md_bare[:ad_backend].default === ADTypes.AutoForwardDiff()
        end

        # ====================================================================
        # CONTRACT - construction per parameter (DI() ≡ DI{CPU})
        # ====================================================================

        Test.@testset "construction per parameter" begin
            di_default = DI()
            Test.@test di_default isa DI{Strategies.CPU}
            Test.@test Strategies.parameter(typeof(di_default)) == Strategies.CPU
            Test.@test Differentiation.ad_backend(di_default) === ADTypes.AutoForwardDiff()

            di_cpu = DI{Strategies.CPU}()
            Test.@test di_cpu isa DI{Strategies.CPU}

            di_gpu = DI{Strategies.GPU}()
            Test.@test di_gpu isa DI{Strategies.GPU}
            Test.@test Strategies.parameter(typeof(di_gpu)) == Strategies.GPU
            # GPU default backend is AutoZygote (resolved from the per-device metadata).
            Test.@test Differentiation.ad_backend(di_gpu) === ADTypes.AutoZygote()

            # Explicit override still wins on either device.
            di_gpu_fd = DI{Strategies.GPU}(; backend=ADTypes.AutoForwardDiff())
            Test.@test Differentiation.ad_backend(di_gpu_fd) === ADTypes.AutoForwardDiff()
        end

        # ====================================================================
        # INTEGRATION - registry with [CPU, GPU] + global parameter extraction
        # ====================================================================

        Test.@testset "registry with device parameters" begin
            r = Strategies.create_registry(
                Differentiation.AbstractADBackend =>
                    ((DI, [Strategies.CPU, Strategies.GPU]),),
            )

            Test.@test :di in Strategies.strategy_ids(Differentiation.AbstractADBackend, r)

            Test.@test Strategies.extract_global_parameter_from_method((:di, :cpu), r) ==
                Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method((:di, :gpu), r) ==
                Strategies.GPU
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_di_parameter() = TestDIParameter.test_di_parameter()
