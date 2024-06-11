using CTBase
using Test
using Plots

# functions and types that are not exported
const vec2vec  = CTBase.vec2vec
const subs = CTBase.subs
const has = CTBase.has
const replace_call = CTBase.replace_call
const constraint_type = CTBase.constraint_type

# 
include("utils.jl")
function __constraint!(
    ocp::OptimalControlModel{<: TimeDependence, V}, 
    type::Symbol, 
    rg::Index, 
    lb::Union{ctVector,Nothing}, 
    ub::Union{ctVector,Nothing}, 
    label::Symbol=CTBase.__constraint_label()) where {V <: VariableDependence} 

    constraint!(ocp, type, rg=rg.val, f=nothing, lb=lb, ub=ub, label=label)
    nothing # to force to return nothing

end

function __constraint!(
    ocp::OptimalControlModel{<: TimeDependence, V}, 
    type::Symbol, 
    rg::OrdinalRange{<:Integer}, 
    lb::Union{ctVector,Nothing}, 
    ub::Union{ctVector,Nothing}, 
    label::Symbol=CTBase.__constraint_label()) where {V <: VariableDependence} 

    constraint!(ocp, type, rg=rg, f=nothing, lb=lb, ub=ub, label=label)
    nothing # to force to return nothing

end

function __constraint!(
    ocp::OptimalControlModel, 
    type::Symbol, 
    lb::Union{ctVector,Nothing}, 
    ub::Union{ctVector,Nothing}, 
    label::Symbol=CTBase.__constraint_label())

    constraint!(ocp, type, rg=nothing, f=nothing, lb=lb, ub=ub, label=label)
    nothing # to force to return nothing

end

function __constraint!(
    ocp::OptimalControlModel{T, V}, 
    type::Symbol, 
    f::Function, 
    lb::Union{ctVector,Nothing}, 
    ub::Union{ctVector,Nothing}, 
    label::Symbol=CTBase.__constraint_label()) where {T, V}

    constraint!(ocp, type, rg=nothing, f=f, lb=lb, ub=ub, label=label)
    nothing # to force to return nothing
end

#
@testset verbose = true showtiming = true "Base" begin
    for name ∈ (
        :callback,
        :ctparser_utils,
        :default,
        :description,
        :differential_geometry,
        :exception,
        :function,
	    :goddard,
        :model,
        :plot,
        :print,
        :utils,
        :onepass,
        )
        @testset "$(name)" begin
            test_name = Symbol(:test_, name)
            include("$(test_name).jl")
            @eval $test_name()
        end
    end
end
