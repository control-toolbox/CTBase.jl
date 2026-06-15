# to run the documentation generation:
# julia --project=. docs/make.jl
pushfirst!(LOAD_PATH, joinpath(@__DIR__))
pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))

using Documenter
using DocumenterVitepress
using CTBase
using Markdown
using MarkdownAST: MarkdownAST
using Test
using Coverage

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════════
draft = false # Draft mode: if true, @example blocks in markdown are not executed

# ═══════════════════════════════════════════════════════════════════════════════
# Docstrings from external packages
# ═══════════════════════════════════════════════════════════════════════════════
const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const CoveragePostprocessing = Base.get_extension(CTBase, :CoveragePostprocessing)
const TestRunner = Base.get_extension(CTBase, :TestRunner)

if !isnothing(DocumenterReference)
    DocumenterReference.reset_config!()
end

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
#ext_dir = abspath(joinpath(@__DIR__, "..", "ext"))

# Helper to build absolute paths
# Helper to build absolute paths (reused in api_reference.jl, but passed as arg)
# src(...) defined above

# Include the API reference manager
include("api_reference.jl")

# ═══════════════════════════════════════════════════════════════════════════════
# Build documentation
# ═══════════════════════════════════════════════════════════════════════════════

with_api_reference(src_dir) do api_pages
    return makedocs(;
        draft=draft,
        remotes=nothing, # Disable remote links. Needed for DocumenterReference
        warnonly=[:cross_references],
        sitename="CTBase.jl",
        format=DocumenterVitepress.MarkdownVitepress(;
            repo="https://" * repo_url,
            devbranch="main",
            devurl="dev",
            sidebar_drawer=true,
        ),
        pages=[
            "Introduction" => "index.md",
            "Getting Started" => "getting-started.md",
            "User Guides" => [
                "Descriptions" => joinpath("guide", "descriptions.md"),
                "Exceptions" => joinpath("guide", "exceptions.md"),
                "Test Runner" => joinpath("guide", "test-runner.md"),
                "Coverage" => joinpath("guide", "coverage.md"),
                "API Documentation" => joinpath("guide", "api-documentation.md"),
            ],
            "API Reference" => api_pages,
        ],
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
# Deploy documentation to GitHub Pages
# ═══════════════════════════════════════════════════════════════════════════════
DocumenterVitepress.deploydocs(;
    repo=repo_url * ".git",
    devbranch="main",
    push_preview=true,
)
