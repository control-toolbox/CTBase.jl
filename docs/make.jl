using Documenter
using CTBase
using DocumenterMermaid

makedocs(;
    warnonly = [:cross_references, :autodocs_block],
    sitename = "CTBase.jl",
    format = Documenter.HTML(
        prettyurls = false,
        size_threshold_ignore = [
            "api.md",
            "dev.md",
        ],
        assets=[
            asset("https://control-toolbox.org/assets/css/documentation.css"),
            asset("https://control-toolbox.org/assets/js/documentation.js"),
        ],
    ),
    pages = [
        "Introduction"  => "index.md",
        "API"           => "api.md",
        "Developers"    => "dev.md",
    ],
    checkdocs=:none,
)

deploydocs(
    repo = "github.com/control-toolbox/CTBase.jl.git",
    devbranch = "main"
)
