# time!

function __time!(
    ocp::OptimalControlModel{<:TimeDependence, NonFixed},
    t0::Time,
    indf::Index,
    name::String = CTBase.__time_name(),
)
    time!(ocp; t0 = t0, indf = indf.val, name = name)
end

function __time!(ocp::OptimalControlModel, t0::Time, indf::Index, name::Symbol)
    time!(ocp; t0 = t0, indf = indf.val, name = name)
end

function __time!(
    ocp::OptimalControlModel{<:TimeDependence, NonFixed},
    ind0::Index,
    tf::Time,
    name::String = CTBase.__time_name(),
)
    time!(ocp; ind0 = ind0.val, tf = tf, name = name)
end

function __time!(ocp::OptimalControlModel, ind0::Index, tf::Time, name::Symbol)
    time!(ocp; ind0 = ind0.val, tf = tf, name = name)
end

function __time!(
    ocp::OptimalControlModel{<:TimeDependence, NonFixed},
    ind0::Index,
    indf::Index,
    name::String = CTBase.__time_name(),
)
    time!(ocp; ind0 = ind0.val, indf = indf.val, name = name)
end

function __time!(ocp::OptimalControlModel, ind0::Index, indf::Index, name::Symbol)
    time!(ocp; ind0 = ind0.val, indf = indf.val, name = name)
end

function __time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::String = CTBase.__time_name())
    time!(ocp; t0 = t0, tf = tf, name = name)
end

function __time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::Symbol)
    time!(ocp; t0 = t0, tf = tf, name = name)
end

# constraint!

function __constraint!(
    ocp::OptimalControlModel{<:TimeDependence, V},
    type::Symbol,
    rg::Index,
    lb::Union{ctVector, Nothing},
    ub::Union{ctVector, Nothing},
    label::Symbol = CTBase.__constraint_label(),
) where {V <: VariableDependence}
    constraint!(ocp, type, rg = rg.val, f = nothing, lb = lb, ub = ub, label = label)
    nothing # to force to return nothing
end

function __constraint!(
    ocp::OptimalControlModel{<:TimeDependence, V},
    type::Symbol,
    rg::OrdinalRange{<:Integer},
    lb::Union{ctVector, Nothing},
    ub::Union{ctVector, Nothing},
    label::Symbol = CTBase.__constraint_label(),
) where {V <: VariableDependence}
    constraint!(ocp, type, rg = rg, f = nothing, lb = lb, ub = ub, label = label)
    nothing # to force to return nothing
end

function __constraint!(
    ocp::OptimalControlModel,
    type::Symbol,
    lb::Union{ctVector, Nothing},
    ub::Union{ctVector, Nothing},
    label::Symbol = CTBase.__constraint_label(),
)
    constraint!(ocp, type, rg = nothing, f = nothing, lb = lb, ub = ub, label = label)
    nothing # to force to return nothing
end

function __constraint!(
    ocp::OptimalControlModel{T, V},
    type::Symbol,
    f::Function,
    lb::Union{ctVector, Nothing},
    ub::Union{ctVector, Nothing},
    label::Symbol = CTBase.__constraint_label(),
) where {T, V}
    constraint!(ocp, type, rg = nothing, f = f, lb = lb, ub = ub, label = label)
    nothing # to force to return nothing
end
