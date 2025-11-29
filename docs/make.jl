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

# ═══════════════════════════════════════════════════════════════════════════════
# Build documentation
# ═══════════════════════════════════════════════════════════════════════════════
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
        "API Reference" => [
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                modules=[CTBase],
                exclude=Symbol[:include, :eval],
                public=false,
                private=true,
                title="CTBase",
                title_in_menu="CTBase",  # optionnel
                filename="ctbase",
                source_files=[abspath(joinpath(@__DIR__, "..", "src", "CTBase.jl"))],
            ),
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                modules=[CTBase],
                exclude=Symbol[:include, :eval],
                public=false,
                private=true,
                title="Default",
                title_in_menu="Default",  # optionnel
                filename="default",
                source_files=[abspath(joinpath(@__DIR__, "..", "src", "default.jl"))],
            ),
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                modules=[CTBase],
                exclude=Symbol[:include, :eval],
                public=false,
                private=true,
                title="Description",
                title_in_menu="Description",  # optionnel
                filename="description",
                source_files=[abspath(joinpath(@__DIR__, "..", "src", "description.jl"))],
            ),
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                modules=[CTBase],
                doc_modules=[Base],  # pour inclure Base.showerror
                exclude=Symbol[:include, :eval],
                public=false,
                private=true,
                title="Exception",
                title_in_menu="Exception",  # optionnel
                filename="exception",
                source_files=[abspath(joinpath(@__DIR__, "..", "src", "exception.jl"))],
            ),
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                modules=[CTBase],
                exclude=Symbol[:include, :eval],
                public=false,
                private=true,
                title="Utils",
                title_in_menu="Utils",  # optionnel
                filename="utils",
                source_files=[abspath(joinpath(@__DIR__, "..", "src", "utils.jl"))],
            ),
        ],
    ],
    checkdocs=:none,
)

# ═══════════════════════════════════════════════════════════════════════════════
# Deploy documentation to GitHub Pages
# ═══════════════════════════════════════════════════════════════════════════════
deploydocs(; repo=repo_url * ".git", devbranch="main")
