"""
$(TYPEDSIGNATURES)

Post-process coverage artifacts produced by `Pkg.test(; coverage=true)`.

This implementation:

- Collects coverage source directories under `root_dir` (`src/`, `test/`, `ext/` when present)
- Resets the `coverage/` directory
- Removes stale `.cov` files (keeping the most complete PID suffix when multiple runs exist)
- Optionally generates reports (LCOV + markdown report)
- Moves `.cov` files into `coverage/cov/` (recursively from source dirs)

# Keyword Arguments

- `generate_report::Bool=true`: If `true`, write `coverage/lcov.info` and `coverage/cov_report.md`.
- `root_dir::String=pwd()`: Root directory of the project.
- `dest_dir::String="coverage"`: Destination directory for coverage artifacts.
- `worst_n_files::Int=20`: Maximum number of lowest-covered files to list in the report.
- `max_uncovered_lines::Int=200`: Maximum number of uncovered lines to display in the report.

# Returns

- `Nothing`

# Notes

This function **creates/removes/moves files and directories** under `root_dir`.

# Example

```julia
using CTBase

# CTBase.postprocess_coverage(; generate_report=true, root_dir=pwd())
```
"""
function CTBase.postprocess_coverage(
    ::CTBase.Extensions.CoveragePostprocessingTag;
    generate_report::Bool=true,
    root_dir::String=pwd(),
    dest_dir::String="coverage",
    worst_n_files::Int=20,
    max_uncovered_lines::Int=200,
)
    # Validate report limits
    worst_n_files > 0 || throw(
        CTBase.Exceptions.IncorrectArgument(
            "worst_n_files must be > 0, got $(worst_n_files)"
        ),
    )
    max_uncovered_lines > 0 || throw(
        CTBase.Exceptions.IncorrectArgument(
            "max_uncovered_lines must be > 0, got $(max_uncovered_lines)"
        ),
    )

    println("✓ Coverage post-processing start")

    # Define paths relative to root_dir
    source_dirs = String[]
    for d in ["src", "test", "ext"]
        path = joinpath(root_dir, d)
        if isdir(path)
            push!(source_dirs, path)
        end
    end

    coverage_dir = joinpath(root_dir, dest_dir)
    cov_storage_dir = joinpath(coverage_dir, "cov")

    _reset_coverage_dir(coverage_dir, cov_storage_dir)

    n_cov = _count_cov_files(source_dirs)
    if n_cov == 0
        throw(
            CTBase.Exceptions.PreconditionError(
                "Coverage requested but no .cov files were produced";
                reason="no .cov files found in src/, test/, or ext/",
                suggestion="run Pkg.test(...; coverage=true) to generate coverage data",
            ),
        )
    end

    _clean_stale_cov_files!(source_dirs)

    n_cov = _count_cov_files(source_dirs)
    n_cov == 0 && throw(
        CTBase.Exceptions.PreconditionError(
            "Coverage requested but no usable .cov files were found after cleanup"
        ),
    )

    generate_report && _generate_coverage_reports!(
        source_dirs, coverage_dir, root_dir, worst_n_files, max_uncovered_lines
    )

    moved = _collect_and_move_cov_files!(source_dirs, cov_storage_dir)
    isempty(moved) && throw(
        CTBase.Exceptions.PreconditionError(
            "Coverage requested but no .cov files were found to move"
        ),
    )
    println("✓ Moved $(length(moved)) .cov files to $cov_storage_dir")

    println("✓ Coverage post-processing completed successfully")
    return nothing
end
