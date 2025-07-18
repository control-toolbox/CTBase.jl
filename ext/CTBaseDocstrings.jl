module CTBaseDocstrings

using HTTP
using JSON
using CTBase
using DocStringExtensions

include("prompt.jl")
include("prompt_app.jl")
include("docstrings.jl")
include("docstrings_app.jl")

end