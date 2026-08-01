"""
Regression guard for the Handbook rule "using, never import" (tenet 2,
`philosophy/modules.md#using-never-import`): flags any tracked `.jl` or `.md`
file that still uses the `import` keyword, or the forbidden dotted
`using Pkg.Sub` form (the canonical spelling is `using Pkg: Sub`).
"""

module TestNoImport

using Test: Test

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

const IMPORT_RE = r"^\s*import\b"
const DOTTED_USING_RE = r"^\s*using\s+[A-Za-z_]\w*\.[A-Za-z_]"

# BREAKING.md quotes historical "before" API verbatim (e.g. the pre-0.18.0-beta
# `CTBase.Extensions.*` names) — that's a historical fact, not a current-convention
# violation, so it's exempt from the dotted-using check.
const DOTTED_USING_EXEMPT = ("BREAKING.md",)

function test_no_import()
    Test.@testset "No `import` / no dotted `using Pkg.Sub` (Handbook tenet 2)" verbose =
        VERBOSE showtiming = SHOWTIMING begin
        repo_root = joinpath(@__DIR__, "..", "..", "..")
        tracked = filter(
            f -> endswith(f, ".jl") || endswith(f, ".md"),
            readlines(Cmd(`git ls-files`; dir=repo_root)),
        )
        for relpath in tracked
            path = joinpath(repo_root, relpath)
            check_dotted = !(basename(relpath) in DOTTED_USING_EXEMPT)
            for line in eachline(path)
                Test.@test !occursin(IMPORT_RE, line)
                if check_dotted
                    Test.@test !occursin(DOTTED_USING_RE, line)
                end
            end
        end
    end
end

end # module TestNoImport

# CRITICAL: redefine in outer scope so the test runner can call it
test_no_import() = TestNoImport.test_no_import()
