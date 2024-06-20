module CTBasePlots

    #
    using DocStringExtensions
    using MLStyle # pattern matching

    #
    using CTBase
    using Plots
    using LinearAlgebra
    import Plots: plot, plot!

    # --------------------------------------------------------------------------------------------------
    include("plot.jl")

end