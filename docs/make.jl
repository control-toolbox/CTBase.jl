using Documenter
using CTBase
using DocumenterMermaid

# to add docstrings from external packages
Modules = [Base]
for Module in Modules
    isnothing(DocMeta.getdocmeta(Module, :DocTestSetup)) &&
        DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive=true)
end

repo_url = "github.com/control-toolbox/CTBase.jl"

makedocs(;
    warnonly=[:cross_references, :autodocs_block],
    sitename="CTBase.jl",
    format=Documenter.HTML(;
        repolink="https://" * repo_url,
        prettyurls=false,
        size_threshold_ignore=["api.md", "dev.md"],
        assets=[
            asset("https://control-toolbox.org/assets/css/documentation.css"),
            asset("https://control-toolbox.org/assets/js/documentation.js"),
        ],
    ),
    pages=["Introduction" => "index.md", "Developers" => "dev.md"],
    checkdocs=:none,
)

deploydocs(; repo=repo_url * ".git", devbranch="main")
