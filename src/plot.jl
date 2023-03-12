# --------------------------------------------------------------------------------------------------
# Plot solution
# print("x", '\u2080'+9) : x₉ 
#

const SymbolPlot = Tuple{Symbol,Integer}

#
abstract type AbstractPlotNode end

# leaf
struct PlotLeaf <: AbstractPlotNode
    element::SymbolPlot
    PlotLeaf(element::SymbolPlot) = new(element) 
end
AbstractTrees.children(::PlotLeaf) = ()

# node
struct PlotNode <: AbstractPlotNode
    element::Union{Symbol, Matrix{Any}}
    children::Vector{<:AbstractPlotNode}
    PlotNode(element::Union{Symbol, Matrix{Any}}, children::Vector{<:AbstractPlotNode}) = new(element, children)
end

AbstractTrees.children(node::PlotNode) = node.children

# tree
struct PlotTree
    root::AbstractPlotNode
end

# internal plot
function _plot_time(sol::OptimalControlSolution, d::Dimension, s::Symbol; 
    labels::Vector{String}, title::String, kwargs...)
    p = Plots.plot(; xlabel="time", title=title, kwargs...)
    for i in range(1, d)
        _plot_time!(p, sol, s, i; label=labels[i], kwargs...)
    end
    return p
end

function _plot_time(sol::OptimalControlSolution, s::Symbol, i::Integer;
    label::String, kwargs...)
    p = CTBase.plot(sol, :time, (s, i); label=label, kwargs...)
    return p
end

function _plot_time!(p, sol::OptimalControlSolution, s::Symbol, i::Integer;
    label::String, kwargs...)
    CTBase.plot!(p, sol, :time, (s, i); label=label, kwargs...)
end

# General plot
function CTBase.plot(sol::OptimalControlSolution; layout::Symbol=:split,
    state_style=(), control_style=(), adjoint_style=(), kwargs...)

    # parameters
    n = state_dimension(sol)
    m = control_dimension(sol)
    x_labels = state_labels(sol)
    u_labels = control_labels(sol)

    if layout==:group
            
        # state
        px = _plot_time(sol, n, :state; labels=x_labels, title="state", state_style...)
        
        # control
        pu = _plot_time(sol, m, :control; labels=u_labels, title="control", control_style...)

        # adjoint
        pp = _plot_time(sol, n, :adjoint; labels="p".*x_labels, title="adjoint", adjoint_style...)

        # layout
        ps = Plots.plot(px, pu, pp, layout=(1, 3); kwargs...)

    elseif layout==:split
    
        # create tree root
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
        function rec_plot(node::PlotLeaf)
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
                label=l, title=t, style...)
            return pc
        end

        function rec_plot(node::PlotNode)
            subplots=()
            for c ∈ node.children
                pc = rec_plot(c)
                subplots = (subplots..., pc)
            end
            if typeof(node.element)==Symbol
                if node.element==:row
                    ps = plot(subplots..., layout=(1, length(subplots)))
                elseif node.element==:column
                    ps = plot(subplots..., layout=(length(subplots), 1))
                else 
                    error("no such choice for layout")
                end
            else
                ps = plot(subplots..., layout=node.element)
            end
            return ps
        end

        # plot
        ps = rec_plot(root)

    end

    return ps

end

# simple plot: use a Plots recipe 
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
            label --> sol.state_labels[i]
        elseif s==:control
            label --> sol.control_labels[i]
        elseif s==:adjoint
            label --> "p"*sol.state_labels[i]
        end
    end
    x, y
end

"""
	get(sol::UncFreeXfSolution, xx::Union{Symbol, Tuple{Symbol, Integer}})
TBW
"""
function get(sol::OptimalControlSolution, xx::Union{Symbol,Tuple{Symbol,Integer}})

    T = time_steps(sol)
    X = state(sol).(T)
    U = control(sol).(T)
    P = adjoint(sol).(T)

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