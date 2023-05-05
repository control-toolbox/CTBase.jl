# General abstract type for callbacks
"""
$(TYPEDEF)

Abstract type for callbacks.
"""
abstract type CTCallback end

"""
Tuple of callbacks
"""
const CTCallbacks = Tuple{Vararg{CTCallback}}

# --------------------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Callback for printing.
"""
mutable struct PrintCallback <: CTCallback
    callback::Function
    priority::Integer
    function PrintCallback(cb::Function; priority::Integer=1)
        new(cb, priority)
    end
end

"""
$(TYPEDSIGNATURES)

Call the callback.
"""
function (cb::PrintCallback)(args...; kwargs...)
    return cb.callback(args...; kwargs...)
end

"""
Tuple of print callbacks.
"""
const PrintCallbacks = Tuple{Vararg{PrintCallback}}

"""
$(TYPEDSIGNATURES)

Get the highest priority print callbacks.
"""
function get_priority_print_callbacks(cbs::CTCallbacks)
    callbacks_print = ()
    priority = -Inf

    # search highest priority
    for cb in cbs
        if typeof(cb) === PrintCallback && cb.priority ≥ priority
            priority = cb.priority
        end
    end

    # add callbacks
    for cb in cbs
        if typeof(cb) === PrintCallback && cb.priority == priority
            callbacks_print = (callbacks_print..., cb)
        end
    end
    return callbacks_print
end

"""
$(TYPEDSIGNATURES)

Stopping callback.
"""
mutable struct StopCallback <: CTCallback
    callback::Function
    priority::Integer
    function StopCallback(cb::Function; priority::Integer=1)
        new(cb, priority)
    end
end

"""
$(TYPEDSIGNATURES)

Call the callback.
"""
function (cb::StopCallback)(args...; kwargs...)
    return cb.callback(args...; kwargs...)
end

"""
Tuple of stop callbacks.
"""
const StopCallbacks = Tuple{Vararg{StopCallback}}

"""
$(TYPEDSIGNATURES)

Get the highest priority stop callbacks.
"""
function get_priority_stop_callbacks(cbs::CTCallbacks)
    callbacks_stop = ()
    priority = -Inf

    # search highest priority
    for cb in cbs
        if typeof(cb) === StopCallback && cb.priority ≥ priority
            priority = cb.priority
        end
    end

    # add callbacks
    for cb in cbs
        if typeof(cb) === StopCallback && cb.priority == priority
            callbacks_stop = (callbacks_stop..., cb)
        end
    end
    return callbacks_stop
end
