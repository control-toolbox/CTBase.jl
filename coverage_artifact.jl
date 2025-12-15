module CoverageArtifact

import Pkg

Pkg.activate(joinpath(@__DIR__, "test"))

using Coverage
using Printf

const SRC_DIR = "src"
const TEST_DIR = "test"
const EXT_DIR = "ext"
const COVERAGE_DIR = "coverage"
const COV_DIR = joinpath(COVERAGE_DIR, "cov")

"""
    run(; generate_report=true)

Workflow coverage complet et correct :

1. Nettoie coverage/
2. Nettoie les anciens .cov dans src/ et test/
3. (Les tests doivent être lancés AVANT avec coverage=true)
4. Déplace tous les .cov vers coverage/cov
5. Génère le rapport coverage dans coverage/
"""
function run(; generate_report::Bool = true)
    println("✓ Coverage artifact start")

    reset_coverage_dir()

    n_cov = count_cov_files()
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

    clean_existing_cov_files()

    n_cov = count_cov_files()
    if n_cov == 0
        error("Coverage requested but no usable .cov files were found after cleanup.")
    end

    generate_report && generate_coverage_report()

    moved = collect_and_move_cov_files()
    isempty(moved) && error("Coverage requested but no .cov files were found to move.")
    println("✓ Moved $(length(moved)) .cov files to $COV_DIR")

    println("✓ Coverage artifact completed successfully")
end

# -------------------------------------------------------------------
# Internals
# -------------------------------------------------------------------

function reset_coverage_dir()
    isdir(COVERAGE_DIR) && rm(COVERAGE_DIR; recursive=true, force=true)
    mkpath(COV_DIR)
    println("✓ Reset coverage/ directory")
end

function clean_existing_cov_files()
    covs = String[]
    for dir in (SRC_DIR, TEST_DIR, EXT_DIR)
        isdir(dir) || continue
        append!(covs, filter(f -> endswith(f, ".cov"), readdir(dir; join=true)))
    end

    isempty(covs) && return

    pid_counts = Dict{String,Int}()
    pid_re = r"\.(\d+)\.cov$"
    for f in covs
        m = match(pid_re, f)
        m === nothing && continue
        pid = m.captures[1]
        pid_counts[pid] = get(pid_counts, pid, 0) + 1
    end

    isempty(pid_counts) && return

    keep_pid = first(sort(collect(pid_counts); by = kv -> kv[2], rev=true))[1]
    keep_suffix = "." * keep_pid * ".cov"

    removed = 0
    for f in covs
        endswith(f, keep_suffix) && continue
        rm(f; force=true)
        removed += 1
    end

    removed > 0 && println("Cleaned $removed existing .cov files from $(SRC_DIR)/, $(TEST_DIR)/, and $(EXT_DIR)/")
end

function count_cov_files()
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

function collect_and_move_cov_files()
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

function generate_coverage_report()
    println("✓ Generating coverage report")

    cov = process_folder(SRC_DIR)

    isempty(cov) && error("No coverage data found in $SRC_DIR")

    lcov_file = joinpath(COVERAGE_DIR, "lcov.info")
    LCOV.writefile(lcov_file, cov)

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
end

end # module
