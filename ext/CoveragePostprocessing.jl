module CoveragePostprocessing

using CTBase: CTBase
using Coverage: Coverage

const SRC_DIR = "src"
const TEST_DIR = "test"
const EXT_DIR = "ext"
const COVERAGE_DIR = "coverage"
const COV_DIR = joinpath(COVERAGE_DIR, "cov")

function CTBase.postprocess_coverage(::CTBase.CoveragePostprocessingTag; generate_report::Bool=true)
    println("✓ Coverage post-processing start")

    _reset_coverage_dir()

    n_cov = _count_cov_files()
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

    _clean_stale_cov_files!()

    n_cov = _count_cov_files()
    if n_cov == 0
        error("Coverage requested but no usable .cov files were found after cleanup.")
    end

    generate_report && _generate_coverage_reports!()

    moved = _collect_and_move_cov_files!()
    isempty(moved) && error("Coverage requested but no .cov files were found to move.")
    println("✓ Moved $(length(moved)) .cov files to $COV_DIR")

    println("✓ Coverage post-processing completed successfully")
    return nothing
end

function _reset_coverage_dir()
    isdir(COVERAGE_DIR) && rm(COVERAGE_DIR; recursive=true, force=true)
    mkpath(COV_DIR)
    println("✓ Reset coverage/ directory")
    return nothing
end

function _count_cov_files()
    n = 0
    for dir in (SRC_DIR, TEST_DIR, EXT_DIR)
        isdir(dir) || continue
        for f in readdir(dir; join=true)
            endswith(f, ".cov") || continue
            n += 1
        end
    end
    return n
end

function _clean_stale_cov_files!()
    covs = String[]
    for dir in (SRC_DIR, TEST_DIR, EXT_DIR)
        isdir(dir) || continue
        append!(covs, filter(f -> endswith(f, ".cov"), readdir(dir; join=true)))
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

    keep_pid = first(sort(collect(pid_counts); by = kv -> kv[2], rev=true))[1]
    keep_suffix = "." * keep_pid * ".cov"

    removed = 0
    for f in covs
        endswith(f, keep_suffix) && continue
        rm(f; force=true)
        removed += 1
    end
    removed > 0 && println("Cleaned $removed existing .cov files from $(SRC_DIR)/, $(TEST_DIR)/, and $(EXT_DIR)/")

    return nothing
end

function _collect_and_move_cov_files!()
    moved = String[]
    for dir in (SRC_DIR, TEST_DIR, EXT_DIR)
        isdir(dir) || continue
        for f in readdir(dir; join=true)
            endswith(f, ".cov") || continue
            dest = joinpath(COV_DIR, basename(f))
            mv(f, dest; force=true)
            push!(moved, dest)
        end
    end
    return moved
end

function _generate_coverage_reports!()
    println("✓ Generating coverage report")

    # Process both src/ and ext/ directories for coverage
    cov_src = Coverage.process_folder(SRC_DIR)
    cov_ext = isdir(EXT_DIR) ? Coverage.process_folder(EXT_DIR) : []
    cov = vcat(cov_src, cov_ext)
    isempty(cov) && error("No coverage data found in $SRC_DIR or $EXT_DIR")

    lcov_file = joinpath(COVERAGE_DIR, "lcov.info")
    Coverage.LCOV.writefile(lcov_file, cov)

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
    sort!(rows, by = r -> r[4])

    open(joinpath(COVERAGE_DIR, "llm_report.md"), "w") do io
        println(io, "# Coverage (LLM digest)\n")

        println(io, "## Overall\n```")
        show(io, Coverage.get_summary(cov)); println(io)
        println(io, "```\n")

        println(io, "## Lowest-covered files (top 20)")
        println(io, "| file | covered | total | % |")
        println(io, "|---|---:|---:|---:|")
        for (f, h, t, p) in rows[1:min(end, 20)]
            println(io, "| `", f, "` | ", h, " | ", t, " | ", round(p; digits=2), " |")
        end
        println(io)

        println(io, "## Uncovered lines (first 200)\n```")
        n = 0
        for fc in cov
            for i in findall(v -> (v isa Integer) && v == 0, fc.coverage)
                println(io, fc.filename, ":", i)
                n += 1
                n >= 200 && break
            end
            n >= 200 && break
        end
        println(io, "```")
    end

    println("✓ Wrote LCOV report to $lcov_file")
    return nothing
end

end
