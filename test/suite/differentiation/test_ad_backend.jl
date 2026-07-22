"""
Unit and error tests for the AD backend contract and DifferentiationInterface strategy.
"""

module TestADBackend

using Test: Test
import CTBase.Differentiation
import CTBase.Data
import CTBase.Traits
import CTBase.Exceptions
import CTBase.Strategies
using ADTypes: ADTypes

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fake AD Backend for Testing (at module top-level)
# ==============================================================================

struct FakeADBackend <: Differentiation.AbstractADBackend
    options::Strategies.StrategyOptions
end

FakeADBackend() = FakeADBackend(Strategies.StrategyOptions())

# ==============================================================================
# Fake Hamiltonian for Testing (at module top-level)
# ==============================================================================

struct FakeHamiltonian <: Data.AbstractHamiltonian{Traits.Autonomous,Traits.Fixed}
    f::Function
end

FakeHamiltonian() = FakeHamiltonian((x, p) -> 0.0)

function test_ad_backend()
    Test.@testset "AD Backend Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ==============================================================================
        # Unit Tests
        # ==============================================================================

        Test.@testset "Unit: AbstractADBackend abstract type" begin
            backend = FakeADBackend()
            Test.@test backend isa Differentiation.AbstractADBackend
            Test.@test backend isa Strategies.AbstractStrategy
        end

        Test.@testset "Unit: DifferentiationInterface construction" begin
            # Default construction
            di = Differentiation.DifferentiationInterface()
            Test.@test di isa Differentiation.DifferentiationInterface
            Test.@test di isa Differentiation.AbstractADBackend

            # Default backend is AutoForwardDiff
            metadata = Strategies.metadata(Differentiation.DifferentiationInterface)
            Test.@test metadata[:ad_backend].default === ADTypes.AutoForwardDiff()

            # Custom backend
            di_custom = Differentiation.DifferentiationInterface(
                backend=ADTypes.AutoZygote()
            )
            Test.@test di_custom isa Differentiation.DifferentiationInterface
        end

        Test.@testset "Unit: CTBase.Strategies contract" begin
            # id
            Test.@test Strategies.id(Differentiation.DifferentiationInterface) === :di

            # description
            desc = Strategies.description(Differentiation.DifferentiationInterface)
            Test.@test desc isa String
            Test.@test !isempty(desc)

            # metadata
            metadata = Strategies.metadata(Differentiation.DifferentiationInterface)
            Test.@test metadata isa Strategies.StrategyMetadata
            Test.@test length(metadata) > 0
            Test.@test :ad_backend in keys(metadata)
        end

        # ==============================================================================
        # Error Tests
        # ==============================================================================

        Test.@testset "Error: hamiltonian_gradient stub throws NotImplemented" begin
            backend = FakeADBackend()
            h = FakeHamiltonian()
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            v = 5.0

            try
                Differentiation.hamiltonian_gradient(backend, h, t, x, p, v)
                Test.@test false  # Should not reach here
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("hamiltonian_gradient", err.required_method)
            end
        end

        Test.@testset "Error: variable_gradient stub throws NotImplemented" begin
            backend = FakeADBackend()
            h = FakeHamiltonian()
            t = 0.0
            x = [1.0, 2.0]
            p = [3.0, 4.0]
            v = 5.0

            try
                Differentiation.variable_gradient(backend, h, t, x, p, v)
                Test.@test false  # Should not reach here
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("variable_gradient", err.required_method)
            end
        end

        Test.@testset "Error: gradient stub throws NotImplemented" begin
            backend = FakeADBackend()
            try
                Differentiation.gradient(backend, x -> sum(x), [1.0, 2.0])
                Test.@test false  # Should not reach here
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("gradient", err.required_method)
            end
        end

        Test.@testset "Error: derivative stub throws NotImplemented" begin
            backend = FakeADBackend()
            try
                Differentiation.derivative(backend, t -> t^2, 1.0)
                Test.@test false  # Should not reach here
            catch err
                Test.@test err isa Exceptions.NotImplemented
                Test.@test occursin("derivative", err.required_method)
            end
        end

        Test.@testset "Type stability" begin
            # Hot path: reading the resolved AD backend from an already-built
            # strategy (as done once per gradient evaluation), not the
            # one-time construction of the strategy itself.
            di = Differentiation.DifferentiationInterface()
            Test.@inferred Differentiation.ad_backend(di)
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_ad_backend() = TestADBackend.test_ad_backend()
