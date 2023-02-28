using CTBase
using AbstractTrees
using Plots

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
    element::Symbol
    children::Vector{<:AbstractPlotNode}
    PlotNode(element::Symbol, children::Vector{<:AbstractPlotNode}) = new(element, children)
end

AbstractTrees.children(node::PlotNode) = node.children

# tree
struct PlotTree
    root::AbstractPlotNode
end

# example
leaf1 = PlotLeaf((:state, 1))
leaf2 = PlotLeaf((:state, 2))
leaf3 = PlotLeaf((:control, 1))
node1 = PlotNode(:row, [leaf1, leaf2])
root = PlotNode(:column, [node1, leaf3])
tree = PlotTree(root)


println(tree)

println("")
println("## Node1:")
println("children: ", AbstractTrees.children(node1))
println("nodevalue: ", AbstractTrees.nodevalue(node1))
#println("parent: ", AbstractTrees.parent(node1))
#println("nextsibling: ", AbstractTrees.nextsibling(node1))
#println("prevsibling: ", AbstractTrees.prevsibling(node1))

println("")
println("## Tree leaves: from root")
leaves = collect(Leaves(root))
for leaf ∈ leaves
    println("Leaf: ", leaf)
end

println("")
println("## Iterator")
#for node in AbstractTrees.PostOrderDFS(root)
#    print(typeof(node), " -- ")
#    println(node.element)
#end

function myplot()

    x(t) = t
    u(t) = t^2

    subplots=()
    for node in AbstractTrees.PostOrderDFS(root)
        print(typeof(node), " -- ")
        println(node.element)
        if typeof(node)==PlotLeaf
            (s, i) = node.element
            if s==:state
                y = x
                l = "x" * ctindices(i)
            elseif s==:control
                y = u
                l = "u" * ctindices(i)
            else
                y = nothing
            end
            t = range(0, 1, 100)
            pc = plot(t, y, label=l)
            subplots = (subplots..., pc)
        else
            if node.element == :row
                pc = plot(subplots..., layout=(1, length(subplots)))
            elseif node.element == :column
                pc = plot(subplots..., layout=(length(subplots), 1))
            else 
                error("no such choice for layout")
            end
            subplots = (pc, )
        end
    end
    println(subplots)
    pg = plot(subplots[1])
    return pg
end

myplot()

# iterator
#Base.IteratorEltype(::Type{<:TreeIterator{AbstractPlotNode}}) = Base.HasEltype()
#Base.eltype(::Type{<:TreeIterator{AbstractPlotNode}}) = AbstractPlotNode
#= 

macro layout(expr::Expr)
    dump(expr)
    for node in AbstractTrees.PreOrderDFS(expr)
        if hasproperty(node, :head)
            println("Head: ", node.head)
            #println(" -- Args: ", node.args)
        else
            println("Node: type=", typeof(node), " -- value=", node)
        end
    end
end

function layout(expr::Expr)
    @eval @layout $expr
end

#println("")
#println("## Cas 1")
#@layout (:x, 1) * (:x, 2) / :u
# equivlent to @layout ((:x, 1) * (:x, 2)) / :u

println("")
println("## Cas 2")
@layout (:x, 1) * (:x, 2) * (:x, 3) / :u
#layout(:((:x, 1) * (:x, 2) * (:x, 3) / :u))

#println("")
#println("## Cas 3")
#@layout (:x, 1) * ((:x, 2) * (:x, 3)) / :u
 =#