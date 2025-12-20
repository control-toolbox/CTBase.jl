# Add the test directory to the load path so Julia can find dependencies from 
# test/Project.toml. This is necessary because this script is included from the 
# main project context, not from the test project context. Without this, Julia 
# won't find Coverage and other test-only dependencies.
pushfirst!(LOAD_PATH, @__DIR__)

using Pkg
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
