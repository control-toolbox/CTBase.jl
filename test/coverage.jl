# ==============================================================================
# CTBase Coverage Post-Processing
# ==============================================================================
#
# See test/README.md for details.
#
# Usage:
#   julia --project=@. -e 'using Pkg; Pkg.test("CTBase"; coverage=true); include("test/coverage.jl")'
#
# ==============================================================================
pushfirst!(LOAD_PATH, @__DIR__)
using CTBase # Provides postprocess_coverage
using Coverage

# This function:
# 1. Aggregates coverage data.
# 2. Generates an LCOV file (coverage/lcov.info).
# 3. Generates a markdown summary (coverage/cov_report.md).
# 4. Archives used .cov files to keep the directory clean.
CTBase.postprocess_coverage(;
    root_dir=dirname(@__DIR__), # Point to the package root
)
