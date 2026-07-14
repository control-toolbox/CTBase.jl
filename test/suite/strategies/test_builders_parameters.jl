module TestBuildersParameters

using Test: Test
import CTBase.Strategies
import CTBase.Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
abstract type TestFamily <: Strategies.AbstractStrategy end

struct TestStratA <: TestFamily
    options::Strategies.StrategyOptions
end

struct TestStratB{P<:Strategies.AbstractStrategyParameter} <: TestFamily
    options::Strategies.StrategyOptions
end

# Implement contracts
Strategies.id(::Type{<:TestStratA}) = :teststrata
Strategies.id(::Type{<:TestStratB}) = :teststratb
Strategies.parameter(::Type{<:TestStratA}) = nothing
function Strategies.parameter(
    ::Type{<:TestStratB{P}}
) where {P<:Strategies.AbstractStrategyParameter}
    return P
end

# Simple metadata for testing
function Strategies.metadata(::Type{T}) where {T<:TestStratA}
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:opt1, type=Int, default=10, description="Test option 1"
        ),
    )
end

function Strategies.metadata(::Type{T}) where {T<:TestStratB}
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:opt1, type=Int, default=20, description="Test option 1"
        ),
        Strategies.OptionDefinition(;
            name=:backend,
            type=Union{Nothing,String},
            default=nothing,
            description="Test backend",
        ),
    )
end

# Helper metadata for parameter-specific defaults
function __teststratb_backend(::Type{Strategies.CPU})
    return nothing
end

function __teststratb_backend(::Type{Strategies.GPU})
    return "cuda_backend"
end

# Parameter-specific metadata
function Strategies.metadata(
    ::Type{TestStratB{P}}
) where {P<:Strategies.AbstractStrategyParameter}
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:opt1, type=Int, default=20, description="Test option 1"
        ),
        Strategies.OptionDefinition(;
            name=:backend,
            type=Union{Nothing,String},
            default=__teststratb_backend(P),
            description="Test backend",
        ),
    )
end

# Simple constructors
function TestStratA(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(TestStratA; mode=mode, kwargs...)
    return TestStratA(opts)
end

function TestStratB{P}(;
    mode::Symbol=:strict, kwargs...
) where {P<:Strategies.AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(TestStratB{P}; mode=mode, kwargs...)
    return TestStratB{P}(opts)
end

function test_builders_parameters()
    Test.@testset "Builders with Parameters" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - extract_global_parameter_from_method
        # ====================================================================

        Test.@testset "extract_global_parameter_from_method" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )

            Test.@test Strategies.extract_global_parameter_from_method(
                (:teststratb, :cpu), r
            ) == Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method(
                (:teststratb, :gpu), r
            ) == Strategies.GPU
            Test.@test_throws Exceptions.IncorrectArgument Strategies.extract_global_parameter_from_method(
                (:teststratb,), r
            )
            Test.@test_throws Exceptions.IncorrectArgument Strategies.extract_global_parameter_from_method(
                (:teststrata, :cpu), r
            )

            Test.@test Strategies.extract_global_parameter_from_method(
                (:teststratb, :cpu, :teststrata), r
            ) == Strategies.CPU
            Test.@test Strategies.extract_global_parameter_from_method(
                (:cpu, :teststrata, :teststratb), r
            ) == Strategies.CPU
        end

        Test.@testset "registry.parameters empty when no parameterized strategies" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA,),  # No parameterized strategies
            )

            # Registry parameters should be empty (no parameterized strategies registered)
            Test.@test isempty(r.parameters)

            # :cpu/:gpu are not recognized as parameter tokens (registry.parameters is empty)
            # So they are treated as unknown tokens and extract returns nothing
            Test.@test Strategies.extract_global_parameter_from_method(
                (:teststrata, :cpu), r
            ) === nothing
            Test.@test Strategies.extract_global_parameter_from_method(
                (:teststrata, :gpu), r
            ) === nothing
        end

        Test.@testset "registry.parameters contains discovered parameters" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )

            # Registry parameters should contain CPU and GPU (discovered from TestStratB)
            Test.@test !isempty(r.parameters)
            Test.@test haskey(r.parameters, :cpu)
            Test.@test haskey(r.parameters, :gpu)
            Test.@test r.parameters[:cpu] === Strategies.CPU
            Test.@test r.parameters[:gpu] === Strategies.GPU
            Test.@test length(r.parameters) == 2
        end

        # ====================================================================
        # UNIT TESTS - build_strategy with parameter (id-direct)
        # ====================================================================

        Test.@testset "build_strategy parameterized (id-direct)" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )

            p_cpu = Strategies.extract_global_parameter_from_method((:teststratb, :cpu), r)
            p_gpu = Strategies.extract_global_parameter_from_method((:teststratb, :gpu), r)
            s_cpu = Strategies.build_strategy(:teststratb, p_cpu, TestFamily, r)
            s_gpu = Strategies.build_strategy(:teststratb, p_gpu, TestFamily, r)

            Test.@test s_cpu isa TestStratB{Strategies.CPU}
            Test.@test s_gpu isa TestStratB{Strategies.GPU}
        end

        Test.@testset "build_strategy non-parameterized (id-direct)" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )

            s = Strategies.build_strategy(:teststrata, TestFamily, r)
            Test.@test s isa TestStratA
        end

        Test.@testset "build_strategy parameterized with options (id-direct)" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )

            p = Strategies.extract_global_parameter_from_method((:teststratb, :cpu), r)
            s = Strategies.build_strategy(:teststratb, p, TestFamily, r; opt1=100)
            Test.@test s isa TestStratB{Strategies.CPU}
            Test.@test Strategies.option_value(s, :opt1) == 100
        end

        # ====================================================================
        # UNIT TESTS - build_strategy with parameter
        # ====================================================================

        Test.@testset "build_strategy parameterized" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )

            s_cpu = Strategies.build_strategy(:teststratb, Strategies.CPU, TestFamily, r)
            s_gpu = Strategies.build_strategy(:teststratb, Strategies.GPU, TestFamily, r)

            Test.@test s_cpu isa TestStratB{Strategies.CPU}
            Test.@test s_gpu isa TestStratB{Strategies.GPU}
        end

        Test.@testset "build_strategy parameterized with options" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )

            s = Strategies.build_strategy(
                :teststratb, Strategies.GPU, TestFamily, r; opt1=50
            )
            Test.@test s isa TestStratB{Strategies.GPU}
            Test.@test Strategies.option_value(s, :opt1) == 50
        end

        Test.@testset "build_strategy unsupported parameter error" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU]),),  # Only CPU
            )

            Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy(
                :teststratb, Strategies.GPU, TestFamily, r
            )
        end

        # ====================================================================
        # UNIT TESTS - option_names with parameter (id-direct)
        # ====================================================================

        Test.@testset "option_names parameterized (id-direct)" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )

            p_cpu = Strategies.extract_global_parameter_from_method((:teststratb, :cpu), r)
            p_gpu = Strategies.extract_global_parameter_from_method((:teststratb, :gpu), r)
            Tcpu = Strategies.type_from_id(:teststratb, TestFamily, r; parameter=p_cpu)
            Tgpu = Strategies.type_from_id(:teststratb, TestFamily, r; parameter=p_gpu)
            names_cpu = Strategies.option_names(Tcpu)
            names_gpu = Strategies.option_names(Tgpu)

            Test.@test :opt1 in names_cpu
            Test.@test :backend in names_cpu
            Test.@test :opt1 in names_gpu
            Test.@test :backend in names_gpu
        end

        Test.@testset "option_names non-parameterized (id-direct)" begin
            r = Strategies.create_registry(
                TestFamily => (TestStratA, (TestStratB, [Strategies.CPU, Strategies.GPU]))
            )

            T = Strategies.type_from_id(:teststrata, TestFamily, r)
            names = Strategies.option_names(T)
            Test.@test names == (:opt1,)
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================

        Test.@testset "Parameter-specific default options" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )

            p_cpu = Strategies.extract_global_parameter_from_method((:teststratb, :cpu), r)
            p_gpu = Strategies.extract_global_parameter_from_method((:teststratb, :gpu), r)
            s_cpu = Strategies.build_strategy(:teststratb, p_cpu, TestFamily, r)
            s_gpu = Strategies.build_strategy(:teststratb, p_gpu, TestFamily, r)

            # Check that defaults are different based on parameter
            Test.@test Strategies.option_value(s_cpu, :backend) === nothing
            Test.@test Strategies.option_value(s_gpu, :backend) == "cuda_backend"
        end

        Test.@testset "Correctness verification" begin
            r = Strategies.create_registry(
                TestFamily => ((TestStratB, [Strategies.CPU, Strategies.GPU]),)
            )

            # Verify extract_global_parameter_from_method returns correct types
            result = Strategies.extract_global_parameter_from_method((:teststratb, :cpu), r)
            Test.@test result === Strategies.CPU

            # Verify builder functions return correct types
            s1 = Strategies.build_strategy(:teststratb, result, TestFamily, r)
            Test.@test s1 isa TestStratB{Strategies.CPU}

            s2 = Strategies.build_strategy(:teststratb, Strategies.CPU, TestFamily, r)
            Test.@test s2 isa TestStratB{Strategies.CPU}
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_builders_parameters() = TestBuildersParameters.test_builders_parameters()
