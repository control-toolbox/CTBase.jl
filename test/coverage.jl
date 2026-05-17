# ==============================================================================
# CTBase Coverage Post-Processing
# ==============================================================================
#
# See test/README.md for details.
#
# ⚠️ Prerequisites:
# The Coverage package must be installed in your base Julia environment:
#   julia --project=@v1.12 -e 'using Pkg; Pkg.add("Coverage")'
#
# Usage:
#   julia --project=@. -e 'using Pkg; Pkg.test("CTBase"; coverage=true); include("test/coverage.jl")'
#
# ==============================================================================

# Report configuration
const WORST_N_FILES = 20
const MAX_UNCOVERED_LINES = 200

using Coverage
using CTBase
CTBase.postprocess_coverage(;
    root_dir=dirname(@__DIR__),
    dest_dir=".coverage",
    worst_n_files=WORST_N_FILES,
    max_uncovered_lines=MAX_UNCOVERED_LINES,
)
