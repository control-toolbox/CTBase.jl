# --------------------------------------------------------------------------------------------------
# Print callback
mutable struct PrintCallback <: CTCallback
    callback::Function
    priority::Integer
    function PrintCallback(cb::Function; priority::Integer=1)
        new(cb, priority)
    end
end
function (cb::PrintCallback)(args...; kwargs...)
    return cb.callback(args...; kwargs...)
end
const PrintCallbacks = Tuple{Vararg{PrintCallback}}

#
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

# Stop callback
mutable struct StopCallback <: CTCallback
    callback::Function
    priority::Integer
    function StopCallback(cb::Function; priority::Integer=1)
        new(cb, priority)
    end
end
function (cb::StopCallback)(args...; kwargs...)
    return cb.callback(args...; kwargs...)
end
const StopCallbacks = Tuple{Vararg{StopCallback}}

#
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
