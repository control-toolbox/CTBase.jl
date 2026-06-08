"""
Coverage post-processing backend for CTBase.

This extension implements `CTBase.postprocess_coverage` and provides utilities
to collect `.cov` files, generate reports, and move artifacts into a dedicated
`coverage/` directory.

Most functions in this module have filesystem side effects.
"""
module CoveragePostprocessing

using CTBase: CTBase
using Coverage: Coverage
import DocStringExtensions: TYPEDSIGNATURES

include("helpers.jl")
include("entry_point.jl")

end
