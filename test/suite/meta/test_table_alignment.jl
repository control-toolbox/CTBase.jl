"""
Regression guard for the ct-conventions rule "table delimiter cells state their
alignment" (`SITE19`): flags any tracked `.md` or `.jl` file containing a table
delimiter row whose cells do not all state an alignment. Julia's Markdown
parser reads a bare `---` cell as right-aligned; write `:---` for text, `:-:`
for a centred column, `---:` for numbers.
"""

module TestTableAlignment

using Test: Test

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# A delimiter row is a line made only of pipes, dashes, colons and whitespace,
# with at least one pipe and one dash, preceded by a line containing a pipe
# (the header row). Each of its cells must match `:?-+:?`; a cell without a
# colon leaves its alignment unstated.
const DELIM_ROW_RE = r"^\s*\|?[\s\-:|]+\|?\s*$"
const DELIM_CELL_RE = r"^\s*:?-+:?\s*$"

# Files that legitimately show an unaligned delimiter row as an example.
const DELIM_EXEMPT = ()

function _is_bad_delimiter(line, prev_line)
    (occursin('-', line) && occursin('|', line)) || return false
    occursin(DELIM_ROW_RE, line) || return false
    occursin('|', prev_line) || return false
    cells = split(line, '|')
    !isempty(cells) && isempty(strip(first(cells))) && popfirst!(cells)
    !isempty(cells) && isempty(strip(last(cells))) && pop!(cells)
    isempty(cells) && return false
    all(c -> occursin(DELIM_CELL_RE, c), cells) || return false
    return any(c -> !occursin(':', c), cells)
end

function _report_violations(violations)
    println(stderr, "Found table delimiter cells without explicit alignment (SITE19):")
    for violation in violations
        println(stderr, "  ", violation)
    end
    return false
end

function test_table_alignment()
    Test.@testset "Table delimiter cells state their alignment (SITE19)" verbose = VERBOSE showtiming =
        SHOWTIMING begin
        repo_root = joinpath(@__DIR__, "..", "..", "..")
        tracked = filter(
            f -> endswith(f, ".jl") || endswith(f, ".md"),
            readlines(Cmd(`git ls-files`; dir=repo_root)),
        )
        violations = String[]
        for relpath in tracked
            basename(relpath) in DELIM_EXEMPT && continue
            prev = ""
            for (line_number, line) in enumerate(eachline(joinpath(repo_root, relpath)))
                if _is_bad_delimiter(line, prev)
                    push!(violations, "$relpath:$line_number: $(strip(line))")
                end
                prev = line
            end
        end
        Test.@test isempty(violations) || _report_violations(violations)
    end
end

end # module TestTableAlignment

# CRITICAL: redefine in outer scope so the test runner can call it
test_table_alignment() = TestTableAlignment.test_table_alignment()
