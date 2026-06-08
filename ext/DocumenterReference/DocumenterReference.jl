#  Copyright 2023, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
#  Modified November 2025 for CTBenchmarks.jl:
#  - Separated public and private API documentation into distinct pages
#  - Added robust handling for missing docstrings (warnings instead of errors)
#  - Included non-exported symbols in API reference
#  - Filtered internal compiler-generated symbols (starting with '#')
#
#  Refactored December 2025:
#  - Extracted helper functions to reduce code duplication
#  - Improved documentation and code organization
#  - Added Dict-based DocType to string conversion

module DocumenterReference

using CTBase: CTBase
using Documenter: Documenter
using Markdown: Markdown
using MarkdownAST: MarkdownAST

include("types.jl")
include("config_helpers.jl")
include("symbol_classification.jl")
include("source_file_detection.jl")
include("symbol_iteration.jl")
include("type_formatting.jl")
include("page_building.jl")
include("entry_point.jl")

# ═══════════════════════════════════════════════════════════════════════════════
# Documenter Pipeline Integration
# ═══════════════════════════════════════════════════════════════════════════════

"""
    APIBuilder <: Documenter.Builder.DocumentPipeline

Custom Documenter pipeline stage for automatic API reference generation.

This builder is inserted into the Documenter pipeline at order `0.0` (before
most other stages) to generate API reference pages from the configurations
stored in `CONFIG`.
"""
abstract type APIBuilder <: Documenter.Builder.DocumentPipeline end

"""
    Documenter.Selectors.order(::Type{APIBuilder}) -> Float64

Return the pipeline order for `APIBuilder`.
# Run before SetupBuildDirectory (1.0) so that generated files exist when Documenter checks pages.
"""
Documenter.Selectors.order(::Type{APIBuilder}) = 0.5

function Documenter.Selectors.runner(::Type{APIBuilder}, document::Documenter.Document)
    @info "APIBuilder: creating API reference"
    for config in CONFIG
        _build_api_page(document, config)
    end
    _finalize_api_pages(document)
    return nothing
end

end
