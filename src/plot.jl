"""
$(TYPEDEF)

Abstract node for plot.
"""
abstract type AbstractPlotNode end

"""
$(TYPEDEF)

Type alias for a plot element.
"""
const SymbolPlot = Tuple{Symbol,Integer}

"""
$(TYPEDEF)

A leaf of a plot tree.
"""
struct PlotLeaf <: AbstractPlotNode
    element::SymbolPlot
    PlotLeaf(element::SymbolPlot) = new(element) 
end

"""
$(TYPEDEF)

A node of a plot tree.
"""
struct PlotNode <: AbstractPlotNode
    element::Union{Symbol, Matrix{Any}}
    children::Vector{<:AbstractPlotNode}
    PlotNode(element::Union{Symbol, Matrix{Any}}, children::Vector{<:AbstractPlotNode}) = new(element, children)
end

# --------------------------------------------------------------------------------------------------
# internal plots
"""
$(TYPEDSIGNATURES)

Plot a vectorial function of time `f(t) ∈ Rᵈ` where `f` is given by the symbol `s`.
The argument `s` can be `:state`, `:control` or `:adjoint`.
"""
function _plot_time(sol::OptimalControlSolution, d::Dimension, s::Symbol; 
    t_label, labels::Vector{String}, title::String, kwargs...)
    p = Plots.plot(; xlabel="time", title=title, kwargs...)
    for i in range(1, d)
        _plot_time!(p, sol, s, i; t_label=t_label, label=labels[i], kwargs...)
    end
    return p
end

"""
$(TYPEDSIGNATURES)

Plot the i-th component of a vectorial function of time `f(t) ∈ Rᵈ` where `f` is given by the symbol `s`.
The argument `s` can be `:state`, `:control` or `:adjoint`.
"""
function _plot_time(sol::OptimalControlSolution, s::Symbol, i::Integer;
    t_label, label::String, kwargs...)
    p = CTBase.plot(sol, :time, (s, i); xlabel=t_label, label=label, kwargs...) # use simple plot
    return p
end

"""
$(TYPEDSIGNATURES)

Update the plot `p` with the i-th component of a vectorial function of time `f(t) ∈ Rᵈ` where
`f` is given by the symbol `s`.
The argument `s` can be `:state`, `:control` or `:adjoint`.
"""
function _plot_time!(p, sol::OptimalControlSolution, s::Symbol, i::Integer;
    t_label, label::String, kwargs...)
    CTBase.plot!(p, sol, :time, (s, i); xlabel=t_label, label=label, kwargs...) # use simple plot
end

"""
$(TYPEDSIGNATURES)

Plot the optimal control solution `sol` using the layout `layout`.
The argument `layout` can be `:group` or `:split` (default).

!!! note

    The keyword arguments `state_style`, `control_style` and `adjoint_style` are passed to the `plot` function of the `Plots` package. The `state_style` is passed to the plot of the state, the `control_style` is passed to the plot of the control and the `adjoint_style` is passed to the plot of the adjoint.
"""
function CTBase.plot(sol::OptimalControlSolution; layout::Symbol=:split,
    state_style=(), control_style=(), adjoint_style=(), kwargs...)

    # parameters
    n = sol.state_dimension
    m = sol.control_dimension
    x_labels = sol.state_names
    u_labels = sol.control_names
    t_label = sol.time_name

    if layout==:group
            
        # state
        px = _plot_time(sol, n, :state; t_label=t_label, labels=x_labels, title="state", state_style...)
        
        # control
        pu = _plot_time(sol, m, :control; t_label=t_label, labels=u_labels, title="control", control_style...)

        # adjoint
        pp = _plot_time(sol, n, :adjoint; t_label=t_label, labels="p".*x_labels, title="adjoint", adjoint_style...)

        # layout
        ps = Plots.plot(px, pu, pp, layout=(1, 3); kwargs...)

    elseif layout==:split
    
        # create tree plot
        state_plots = Vector{PlotLeaf}()
        adjoint_plots = Vector{PlotLeaf}()
        control_plots = Vector{PlotLeaf}()

        for i ∈ 1:n
            push!(state_plots, PlotLeaf((:state, i)))
            push!(adjoint_plots, PlotLeaf((:adjoint, i)))
        end
        for i ∈ 1:m
            push!(control_plots, PlotLeaf((:control, i)))
        end

        #
        node_x = PlotNode(:column, state_plots)
        node_p = PlotNode(:column, adjoint_plots)
        node_u = PlotNode(:column, control_plots)
        node_xp = PlotNode(:row, [node_x, node_p])

        function _width(r) # generate a{0.2h}, if r=0.2
            i = Expr(:call, :*, r, :h)
            a = Expr(:curly, :a, i)
            return a
        end
        r = round(n/(n+m), digits=2)
        a = _width(r)
        @eval l = @layout [$a
                            b]
        root = PlotNode(l, [node_xp, node_u])

        #
        function rec_plot(node::PlotLeaf, depth::Integer)
            (s, i) = node.element
            if s==:state
                l = x_labels[i]
                t = i==1 ? "state" : ""
                style = state_style
            elseif s==:adjoint
                l = "p"*x_labels[i]
                t = i==1 ? "adjoint" : ""
                style = adjoint_style
            elseif s==:control
                l = u_labels[i]
                t = i==1 ? "control" : ""
                style = control_style
            end
            pc = _plot_time(sol, s, i; 
                tickfontsize=8, titlefontsize=8, labelfontsize=8,
                t_label=t_label, label=l, title=t, style...)
            return pc
        end

        function rec_plot(node::PlotNode, depth::Integer=0)
            subplots=()
            for c ∈ node.children
                pc = rec_plot(c, depth+1)
                subplots = (subplots..., pc)
            end
            kwargs_plot = depth==0 ? kwargs : ()
            if typeof(node.element)==Symbol
                if node.element==:row
                    ps = plot(subplots...; layout=(1, length(subplots)), kwargs_plot...)
                elseif node.element==:column
                    ps = plot(subplots...; layout=(length(subplots), 1), kwargs_plot...)
                else 
                    error("no such choice for layout")
                end
            else
                ps = plot(subplots...; layout=node.element, kwargs_plot...)
            end
            return ps
        end

        # plot
        ps = rec_plot(root)

    end

    return ps

end

"""
$(TYPEDSIGNATURES)

Returns `x` and `y` for the plot of the optimal control solution `sol` 
corresponding respectively to the argument `xx` and the argument `yy`.

**Notes.**

- The argument `xx` can be `:time`, `:state`, `:control` or `:adjoint`.
- If `xx` is `:time`, then, a label is added to the plot.
- The argument `yy` can be `:state`, `:control` or `:adjoint`.
"""
@recipe function f(sol::OptimalControlSolution,
    xx::Union{Symbol,Tuple{Symbol,Integer}}, yy::Union{Symbol,Tuple{Symbol,Integer}})
    x = get(sol, xx)
    y = get(sol, yy)
    if xx isa Symbol && xx==:time
        if yy isa Symbol
            s = yy
            i = 1
        else
            s = yy[1]
            i = yy[2]
        end
        if s==:state
            label --> sol.state_names[i]
        elseif s==:control
            label --> sol.control_names[i]
        elseif s==:adjoint
            label --> "p"*sol.state_names[i]
        end
        # change ylims if the gap between min and max is less than a tol
        tol = 1e-3
        ymin = minimum(y)
        ymax = maximum(y)
        if abs(ymax-ymin)≤abs(ymin)*tol
            ymiddle = (ymin+ymax)/2.0
            ylims --> (0.9*ymiddle, 1.1*ymiddle)
        end
    end
    x, y
end

"""
$(TYPEDSIGNATURES)

Get the data for plotting.
"""
function get(sol::OptimalControlSolution, xx::Union{Symbol,Tuple{Symbol,Integer}})

    T = sol.times
    X = sol.state.(T)
    U = sol.control.(T)
    P = sol.adjoint.(T)

    m = length(T)

    if typeof(xx) == Symbol
        vv = xx
        if vv == :time
            x = T
        elseif vv == :state
            x = [X[i][1] for i in 1:m]
        elseif vv == :adjoint || vv == :costate
            x = [P[i][1] for i in 1:m]
        else
            #x = vcat([U[i][1] for i in 1:m-1], U[m-1][1])
            x = [U[i][1] for i in 1:m]
        end
    else
        vv = xx[1]
        ii = xx[2]
        if vv == :time
            x = T
        elseif vv == :state
            x = [X[i][ii] for i in 1:m]
        elseif vv == :adjoint || vv == :costate
            x = [P[i][ii] for i in 1:m]
        else
            #x = vcat([U[i][ii] for i in 1:m-1], U[m-1][ii])
            x = [U[i][ii] for i in 1:m]
        end
    end

    return x

end