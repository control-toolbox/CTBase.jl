using Documenter
using CTBase

makedocs(
    sitename = "CTBase.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "API" => ["api-ctbase.md", "api-callbacks.md", #"api-parser.md", #"api-default.md", 
        "api-description.md", "api-exceptions.md", "api-functions.md", "api-model.md", "api-plot.md", 
        "api-print.md", 
        "api-solution.md", "api-utils.md"],
        "Developers" => "api-developers.md"
    ]
)

deploydocs(
    repo = "github.com/control-toolbox/CTBase.jl.git",
    devbranch = "main"
)