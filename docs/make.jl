using Documenter
using CTBase
using Plots

makedocs(;
    modules=[
        CTBase,
        isdefined(Base, :get_extension) ?
        Base.get_extension(CTBase, :CTBasePlots) :
        CTBase.CTBasePlots,
    ],
    warnonly = [:cross_references, :autodocs_block],
    sitename = "CTBase.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "API" => ["api-ctbase.md", 
        #"api-callbacks.md",
        "api-description.md", 
        "api-diffgeom.md",
        "api-exceptions.md", 
        "api-init.md",
        "api-model.md",
        "api-parser.md",
        "api-plot.md", 
        "api-print.md",
        "api-repl.md",
        "api-types.md", 
        "api-utils.md"],
        "Developers" => "api-developers.md"
    ],
    checkdocs=:none,
)

deploydocs(
    repo = "github.com/control-toolbox/CTBase.jl.git",
    devbranch = "main"
)
