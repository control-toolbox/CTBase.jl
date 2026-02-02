"""
Coverage post-processing backend for CTBase.

This extension implements [`CTBase.postprocess_coverage`](@ref) and provides utilities
to collect `.cov` files, generate reports, and move artifacts into a dedicated
`coverage/` directory.

Most functions in this module have filesystem side effects.
"""
module CoveragePostprocessing

using CTBase: CTBase
using Coverage

# Main entry point for coverage post-processing
"""
    CTBase.postprocess_coverage(::CTBase.Extensions.CoveragePostprocessingTag; generate_report::Bool=true, root_dir::String=pwd())

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

# Returns

- `Nothing`

# Notes

This function **creates/removes/moves files and directories** under `root_dir`.

# Usage sketch (non-executed)

```julia
using CTBase

# CTBase.postprocess_coverage(; generate_report=true, root_dir=pwd())
```
"""
function CTBase.postprocess_coverage(
    ::CTBase.Extensions.CoveragePostprocessingTag; generate_report::Bool=true, root_dir::String=pwd()
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

    coverage_dir = joinpath(root_dir, "coverage")
    cov_storage_dir = joinpath(coverage_dir, "cov")

    _reset_coverage_dir(coverage_dir, cov_storage_dir)

    n_cov = _count_cov_files(source_dirs)
    if n_cov == 0
        error("""
        Coverage requested but no .cov files were produced.

        Expected locations:
          - src/*.cov
          - test/*.cov
          - ext/*.cov

        Did you run:
          Pkg.test(...; coverage=true) ?
        """)
    end

    _clean_stale_cov_files!(source_dirs)

    n_cov = _count_cov_files(source_dirs)
    if n_cov == 0
        error("Coverage requested but no usable .cov files were found after cleanup.")
    end

    generate_report && _generate_coverage_reports!(source_dirs, coverage_dir, root_dir)

    moved = _collect_and_move_cov_files!(source_dirs, cov_storage_dir)
    isempty(moved) && error("Coverage requested but no .cov files were found to move.")
    println("✓ Moved $(length(moved)) .cov files to $cov_storage_dir")

    println("✓ Coverage post-processing completed successfully")
    return nothing
end

"""
    _reset_coverage_dir(coverage_dir, cov_storage_dir)

Internal helper that recreates the `coverage/` directory structure.

This function removes `coverage_dir` (recursively) if it already exists, then
creates `cov_storage_dir`.
"""
function _reset_coverage_dir(coverage_dir, cov_storage_dir)
    isdir(coverage_dir) && rm(coverage_dir; recursive=true, force=true)
    mkpath(cov_storage_dir)
    println("✓ Reset coverage/ directory")
    return nothing
end

"""
    _count_cov_files(source_dirs) -> Int

Internal helper that counts the number of `.cov` files in the provided directories.
"""
function _count_cov_files(source_dirs)
    n = 0
    for dir in source_dirs
        for (root, dirs, files) in walkdir(dir)
            for f in files
                endswith(f, ".cov") || continue
                n += 1
            end
        end
    end
    return n
end

"""
    _clean_stale_cov_files!(source_dirs)

Internal helper that removes stale `.cov` files from `source_dirs`.

If multiple runs are detected (PID suffix in filenames), this function keeps the
PID with the largest number of `.cov` files and removes the others.
"""
function _clean_stale_cov_files!(source_dirs)
    covs = String[]
    for dir in source_dirs
        for (root, dirs, files) in walkdir(dir)
            for f in files
                if endswith(f, ".cov")
                    push!(covs, joinpath(root, f))
                end
            end
        end
    end
    isempty(covs) && return nothing

    pid_counts = Dict{String,Int}()
    pid_re = r"\.(\d+)\.cov$"
    for f in covs
        m = match(pid_re, f)
        m === nothing && continue
        pid = m.captures[1]
        pid_counts[pid] = get(pid_counts, pid, 0) + 1
    end
    isempty(pid_counts) && return nothing

    keep_pid = first(sort(collect(pid_counts); by=kv -> kv[2], rev=true))[1]
    keep_suffix = "." * keep_pid * ".cov"

    removed = 0
    for f in covs
        endswith(f, keep_suffix) && continue
        rm(f; force=true)
        removed += 1
    end
    removed > 0 && println("Cleaned $removed existing .cov files from source directories")

    return nothing
end

"""
    _collect_and_move_cov_files!(source_dirs, dest_dir) -> Vector{String}

Internal helper that moves all `.cov` files from `source_dirs` into `dest_dir`.

Returns a vector of destination paths for the moved files.
"""
function _collect_and_move_cov_files!(source_dirs, dest_dir)
    moved = String[]
    for dir in source_dirs
        for (root, dirs, files) in walkdir(dir)
            for f in files
                endswith(f, ".cov") || continue
                # We flatten the structure in coverage/cov
                # If there are name collisions (e.g. src/foo.jl.cov and src/subdir/foo.jl.cov),
                # the last one wins or we should perhaps preserve structure?
                # The current implementation was flattening, so we keep flattening but maybe warn?
                # Actually, Coverage.jl handles files by absolute path usually, but here we just move .cov files.
                # Let's keep simple flattening for now as requested, but beware of collisions.

                # Note: to avoid collisions we could use replace(relpath(joinpath(root, f), root_dir), "/" => "_")
                # But let's stick to the plan: just recursive collection.

                src = joinpath(root, f)
                dest = joinpath(dest_dir, f) # Wait, this might fail if f is just filename.

                # The issue with joinpath(dest_dir, f) if f is just a filename is that it puts everything in root of dest_dir.
                # If f comes from walkdir's `files`, it is just the filename.
                # So `src` is correct. `dest` puts it in `coverage/cov/filename.cov`. 
                # This matches previous behavior, just expanded to subdirs.

                dest = joinpath(dest_dir, f)
                mv(src, dest; force=true)
                push!(moved, dest)
            end
        end
    end
    return moved
end

"""
    _generate_coverage_reports!(source_dirs, coverage_dir, root_dir)

Internal helper that generates coverage reports from `.cov` files.

Writes:

- `coverage/lcov.info`
- `coverage/cov_report.md`
"""
function _generate_coverage_reports!(source_dirs, coverage_dir, root_dir)
    println("✓ Generating coverage report")

    # Process source directories for coverage
    cov_all = Coverage.FileCoverage[]
    for dir in source_dirs
        # Coverage.process_folder looks for .jl files in dir and checks for .cov files
        # It handles the matching.
        append!(cov_all, Coverage.process_folder(dir))
    end

    isempty(cov_all) && error("No coverage data found in source directories")

    lcov_file = joinpath(coverage_dir, "lcov.info")
    Coverage.LCOV.writefile(lcov_file, cov_all)

    sep = Base.Filesystem.path_separator
    report_prefixes_abs = (joinpath(root_dir, "src"), joinpath(root_dir, "ext"))
    cov = filter(cov_all) do fc
        f = fc.filename
        if any(p -> startswith(f, p), report_prefixes_abs)
            return true
        end
        startswith(f, "src" * string(sep)) && return true
        startswith(f, "ext" * string(sep)) && return true
        return false
    end
    isempty(cov) && (cov = cov_all)

    function line_stats(fc)
        hits = 0
        total = 0
        for v in fc.coverage
            (v === nothing || v == -1) && continue
            v isa Integer || continue
            total += 1
            hits += (v > 0)
        end
        pct = total == 0 ? 100.0 : 100 * hits / total
        return hits, total, pct
    end

    rows = [(fc.filename, line_stats(fc)...) for fc in cov]
    sort!(rows; by=r -> r[4])

    # Helper to make paths relative to root_dir
    function relative_path(path, root)
        if startswith(path, root)
            relpath = path[(length(root) + 1):end]
            # Remove leading slash if present
            return startswith(relpath, "/") ? relpath[2:end] : relpath
        end
        return path
    end

    function write_report(io)
        println(io, "# Coverage report\n")

        println(io, "## Overall\n\n```shell")
        show(io, Coverage.get_summary(cov));
        println(io)
        println(io, "```\n")

        println(io, "## Lowest-covered files (top 20)\n")
        println(io, "| file | covered | total | % |")
        println(io, "|---|---:|---:|---:|")
        for (f, h, t, p) in rows[1:min(end, 20)]
            rel_f = relative_path(f, root_dir)
            println(io, "| `", rel_f, "` | ", h, " | ", t, " | ", round(p; digits=2), " |")
        end
        println(io)

        println(io, "## Uncovered lines (first 200)\n\n```shell")
        n = 0
        for fc in cov
            rel_filename = relative_path(fc.filename, root_dir)
            for i in findall(v -> (v isa Integer) && v == 0, fc.coverage)
                println(io, rel_filename, ":", i)
                n += 1
                n >= 200 && break
            end
            n >= 200 && break
        end
        println(io, "```")
        return nothing
    end

    open(joinpath(coverage_dir, "cov_report.md"), "w") do io
        write_report(io)
    end

    println("✓ Wrote coverage report to $lcov_file")
    return nothing
end

end
