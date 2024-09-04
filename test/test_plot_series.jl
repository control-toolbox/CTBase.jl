using Plots

function keep_series_attributes(; kwargs...)
    series_attributes = Plots.attributes(:Series)

    out = []
    for kw in kwargs
        kw[1] ∈ series_attributes && push!(out, kw)
    end

    return out
end

function print_kwargs(; kwargs...)
    for kw in kwargs
        println(kw)
    end
end

attributes = (size=(900, 600), linewidth=2, flip=true, colorbar=:best, bins=:auto)
println("\nBefore keeping series attributes\n")
print_kwargs(; attributes...)

series_attributes = keep_series_attributes(; attributes...)

println("\nAfter keeping series attributes\n")
print_kwargs(; series_attributes...)
