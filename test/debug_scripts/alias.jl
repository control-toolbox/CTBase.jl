#!/usr/bin/env julia
#
# basic problem using macros
#

# find local CTBase
basename = '/' * joinpath(split(Base.source_path(), '/')[1:end-3])
println(basename)
using Pkg; Pkg.activate(basename)

using CTBase

tf = 1.0

@def verbose_threshold=80 debug=true begin
    t0, variable
    t ∈ [ t0, tf ], time
    x ∈ R^3, state

    v = x₂

    0  ≤ v(t) ≤ 1

    v(tf) -> min

end
