using Documenter
using CTBase
using Markdown
using MarkdownAST: MarkdownAST

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════════
draft = false # Draft mode: if true, @example blocks in markdown are not executed

# ═══════════════════════════════════════════════════════════════════════════════
# Docstrings from external packages
# ═══════════════════════════════════════════════════════════════════════════════
const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)

Modules = [Base]
for Module in Modules
    isnothing(DocMeta.getdocmeta(Module, :DocTestSetup)) &&
        DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive=true)
end

# ═══════════════════════════════════════════════════════════════════════════════
# Repository configuration
# ═══════════════════════════════════════════════════════════════════════════════
repo_url = "github.com/control-toolbox/CTBase.jl"
src_dir = abspath(joinpath(@__DIR__, "..", "src"))
ext_dir = abspath(joinpath(@__DIR__, "..", "ext"))

# Helper to build absolute paths
# Helper to build absolute paths (reused in api_reference.jl, but passed as arg)
# src(...) defined above

# Include the API reference manager
include("api_reference.jl")

# ═══════════════════════════════════════════════════════════════════════════════
# Build documentation
# ═══════════════════════════════════════════════════════════════════════════════

with_api_reference(src_dir) do api_pages
    makedocs(;
        draft=draft,
        remotes=nothing, # Disable remote links. Needed for DocumenterReference
        warnonly=true,
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
        pages=[
            "Introduction" => "index.md",
            "API Reference" => api_pages,
        ],
        checkdocs=:none,
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
# Deploy documentation to GitHub Pages
# ═══════════════════════════════════════════════════════════════════════════════
deploydocs(; repo=repo_url * ".git", devbranch="main")
