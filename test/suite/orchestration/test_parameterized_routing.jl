module TestParameterizedRouting

using Test: Test
using CTBase: Exceptions
using CTBase: Orchestration
using CTBase: Strategies
using CTBase: Options

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

abstract type ParameterizedRoutingModeler <: Strategies.AbstractStrategy end
abstract type ParameterizedRoutingSolverFamily <: Strategies.AbstractStrategy end

struct ParameterizedRoutingModel <: ParameterizedRoutingModeler end
Strategies.id(::Type{ParameterizedRoutingModel}) = :routing_model
Strategies.parameter(::Type{<:ParameterizedRoutingModel}) = nothing
function Strategies.metadata(::Type{ParameterizedRoutingModel})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:shared_option,
            type=Int,
            default=1,
            description="Modeler option",
            aliases=(:modeler_alias,),
        ),
    )
end

struct ParameterizedRoutingSolver{P<:Strategies.AbstractStrategyParameter} <:
       ParameterizedRoutingSolverFamily end
Strategies.id(::Type{<:ParameterizedRoutingSolver}) = :routing_solver
function Strategies.parameter(
    ::Type{<:ParameterizedRoutingSolver{P}}
) where {P<:Strategies.AbstractStrategyParameter}
    return P
end

function Strategies.metadata(::Type{ParameterizedRoutingSolver{Strategies.CPU}})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:cpu_option,
            type=Int,
            default=1,
            description="CPU-only option",
            aliases=(:cpu_alias,),
        ),
        Options.OptionDefinition(;
            name=:shared_option,
            type=Int,
            default=2,
            description="CPU shared option",
            aliases=(:cpu_shared_alias,),
        ),
    )
end

function Strategies.metadata(::Type{ParameterizedRoutingSolver{Strategies.GPU}})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:gpu_option,
            type=Int,
            default=1,
            description="GPU-only option",
            aliases=(:gpu_alias,),
        ),
        Options.OptionDefinition(;
            name=:shared_option,
            type=Int,
            default=2,
            description="GPU shared option",
            aliases=(:gpu_shared_alias,),
        ),
    )
end

const PARAMETERIZED_ROUTING_REGISTRY = Strategies.create_registry(
    ParameterizedRoutingModeler => (ParameterizedRoutingModel,),
    ParameterizedRoutingSolverFamily =>
        ((ParameterizedRoutingSolver, [Strategies.CPU, Strategies.GPU]),),
)

const PARAMETERIZED_ROUTING_FAMILIES = (
    modeler=ParameterizedRoutingModeler, solver=ParameterizedRoutingSolverFamily
)
const PARAMETERIZED_ROUTING_ACTION_DEFS = Options.OptionDefinition[]
const CPU_METHOD = (:routing_model, :routing_solver, :cpu)
const GPU_METHOD = (:routing_model, :routing_solver, :gpu)

function test_parameterized_routing()
    Test.@testset "Parameterized option routing" verbose=VERBOSE showtiming=SHOWTIMING begin
        resolved_cpu = Orchestration.resolve_method(
            CPU_METHOD, PARAMETERIZED_ROUTING_FAMILIES, PARAMETERIZED_ROUTING_REGISTRY
        )
        resolved_gpu = Orchestration.resolve_method(
            GPU_METHOD, PARAMETERIZED_ROUTING_FAMILIES, PARAMETERIZED_ROUTING_REGISTRY
        )

        Test.@testset "Parameter resolution" begin
            Test.@test resolved_cpu.parameter === Strategies.CPU
            Test.@test resolved_gpu.parameter === Strategies.GPU
        end

        Test.@testset "Ownership map uses the active parameter" begin
            cpu_owners = Orchestration.build_option_ownership_map(
                resolved_cpu, PARAMETERIZED_ROUTING_FAMILIES, PARAMETERIZED_ROUTING_REGISTRY
            )
            gpu_owners = Orchestration.build_option_ownership_map(
                resolved_gpu, PARAMETERIZED_ROUTING_FAMILIES, PARAMETERIZED_ROUTING_REGISTRY
            )

            Test.@test cpu_owners[:cpu_option] == Set([:solver])
            Test.@test !haskey(cpu_owners, :gpu_option)
            Test.@test gpu_owners[:gpu_option] == Set([:solver])
            Test.@test !haskey(gpu_owners, :cpu_option)
            Test.@test gpu_owners[:shared_option] == Set([:modeler, :solver])
        end

        Test.@testset "Alias map uses the active parameter" begin
            cpu_aliases = Orchestration.build_alias_to_primary_map(
                resolved_cpu, PARAMETERIZED_ROUTING_FAMILIES, PARAMETERIZED_ROUTING_REGISTRY
            )
            gpu_aliases = Orchestration.build_alias_to_primary_map(
                resolved_gpu, PARAMETERIZED_ROUTING_FAMILIES, PARAMETERIZED_ROUTING_REGISTRY
            )

            Test.@test cpu_aliases[:cpu_alias] === :cpu_option
            Test.@test !haskey(cpu_aliases, :gpu_alias)
            Test.@test gpu_aliases[:gpu_alias] === :gpu_option
            Test.@test !haskey(gpu_aliases, :cpu_alias)
            Test.@test gpu_aliases[:gpu_shared_alias] === :shared_option
        end

        Test.@testset "End-to-end routing uses the active parameter" begin
            cpu_routed = Orchestration.route_all_options(
                CPU_METHOD,
                PARAMETERIZED_ROUTING_FAMILIES,
                PARAMETERIZED_ROUTING_ACTION_DEFS,
                (cpu_option=10,),
                PARAMETERIZED_ROUTING_REGISTRY,
            )
            gpu_routed = Orchestration.route_all_options(
                GPU_METHOD,
                PARAMETERIZED_ROUTING_FAMILIES,
                PARAMETERIZED_ROUTING_ACTION_DEFS,
                (gpu_option=20,),
                PARAMETERIZED_ROUTING_REGISTRY,
            )

            Test.@test cpu_routed.strategies.solver[:cpu_option] == 10
            Test.@test gpu_routed.strategies.solver[:gpu_option] == 20
        end

        Test.@testset "Unknown-option suggestions use the active parameter" begin
            err = try
                Orchestration.route_all_options(
                    GPU_METHOD,
                    PARAMETERIZED_ROUTING_FAMILIES,
                    PARAMETERIZED_ROUTING_ACTION_DEFS,
                    (gpu_optio=20,),
                    PARAMETERIZED_ROUTING_REGISTRY,
                )
                nothing
            catch e
                e
            end

            Test.@test err isa Exceptions.IncorrectArgument
            msg = sprint(showerror, err)
            Test.@test occursin("gpu_option", msg)
            Test.@test !occursin("cpu_option", msg)
        end

        Test.@testset "Ambiguous-option errors use the active parameter" begin
            err = try
                Orchestration.route_all_options(
                    GPU_METHOD,
                    PARAMETERIZED_ROUTING_FAMILIES,
                    PARAMETERIZED_ROUTING_ACTION_DEFS,
                    (shared_option=20,),
                    PARAMETERIZED_ROUTING_REGISTRY,
                )
                nothing
            catch e
                e
            end

            Test.@test err isa Exceptions.IncorrectArgument
            msg = sprint(showerror, err)
            Test.@test occursin("gpu_shared_alias", msg)
            Test.@test occursin("modeler_alias", msg)
            Test.@test !occursin("cpu_shared_alias", msg)
        end
    end
end

end # module

test_parameterized_routing() = TestParameterizedRouting.test_parameterized_routing()
