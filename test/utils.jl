function __time!(ocp::OptimalControlModel{<: TimeDependence, NonFixed}, t0::Time, indf::Index, name::String=CTBase.__time_name())
    time!(ocp; t0=t0, indf=indf.val, name=name)
end

function __time!(ocp::OptimalControlModel, t0::Time, indf::Index, name::Symbol)
    time!(ocp; t0=t0, indf=indf.val, name=name)
end

function __time!(ocp::OptimalControlModel{<: TimeDependence, NonFixed}, ind0::Index, tf::Time, name::String=CTBase.__time_name())
    time!(ocp; ind0=ind0.val, tf=tf, name=name)
end

function __time!(ocp::OptimalControlModel, ind0::Index, tf::Time, name::Symbol)
    time!(ocp; ind0=ind0.val, tf=tf, name=name)
end

function __time!(ocp::OptimalControlModel{<: TimeDependence, NonFixed}, ind0::Index, indf::Index, name::String=CTBase.__time_name())
    time!(ocp; ind0=ind0.val, indf=indf.val, name=name)
end

function __time!(ocp::OptimalControlModel, ind0::Index, indf::Index, name::Symbol)
    time!(ocp; ind0=ind0.val, indf=indf.val, name=name)
end

function __time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::String=CTBase.__time_name())
    time!(ocp; t0=t0, tf=tf, name=name)
end

function __time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::Symbol)
    time!(ocp; t0=t0, tf=tf, name=name)
end