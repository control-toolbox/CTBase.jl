"""
Test runner backend for CTBase.

This extension implements [`CTBase.run_tests`](@ref), allowing test selection
via command-line arguments (globs) and configurable filename/function-name builders.

Most functions in this module have side effects (including file inclusion and
running testsets).
"""
module TestRunner

using CTBase: CTBase
using Test: Test, @testset

const TestSpec = Union{Symbol,String}

"""
    run_tests(::CTBase.TestRunnerTag; kwargs...)

Run tests with configurable file/function name builders and optional available tests filter.

# Keyword Arguments
- `testset_name::String = "Tests"` — name of the main testset
- `available_tests::Vector{Symbol} = Symbol[]` — if non-empty, only these tests are allowed
- `filename_builder::Function = identity` — `Symbol → Symbol`, builds the filename from the test name
- `funcname_builder::Function = identity` — `Symbol → Symbol|Nothing`, builds the function name (or nothing to skip eval)
- `eval_mode::Bool = true` — whether to eval the function after include
- `verbose::Bool = true` — verbose testset output
- `showtiming::Bool = true` — show timing in testset output

# Notes

- Test selection is driven by `Main.ARGS` (coverage flags are ignored).
- Selection arguments are interpreted as glob patterns and matched against both
  the test name and the corresponding filename.

# Usage sketch (non-executed)

```julia
using CTBase

# CTBase.run_tests(; testset_name="Tests")
```
"""
function CTBase.run_tests(
    ::CTBase.TestRunnerTag;
    args::AbstractVector{<:AbstractString}=String[],
    testset_name::String="Tests",
    available_tests=Symbol[],
    filename_builder::Function=identity,
    funcname_builder::Function=identity,
    eval_mode::Bool=true,
    verbose::Bool=true,
    showtiming::Bool=true,
    test_dir::String=joinpath(pwd(), "test"),
)
    # Parse command-line arguments
    (selections, run_all, dry_run) = _parse_test_args(String.(args))

    available_tests_vec = _normalize_available_tests(available_tests)

    # Get selected tests
    selected = _select_tests(
        selections, available_tests_vec, run_all, filename_builder; test_dir=test_dir
    )

    if dry_run
        println("Dry run: the following tests would be executed:")
        println(join(selected, "\n"))
        return nothing
    end

    @testset verbose = verbose showtiming = showtiming "$testset_name" begin
        for spec in selected
            @testset "$(spec)" begin
                _run_single_test(
                    spec;
                    available_tests=available_tests_vec,
                    filename_builder,
                    funcname_builder,
                    eval_mode,
                    test_dir,
                )
            end
        end
    end
end

"""
    _parse_test_args(args::Vector{String}) -> Tuple{Vector{Symbol}, Bool, Bool}

Parse command-line test arguments, filtering out coverage-related flags.

Returns `(selections, run_all, dry_run)` where:

- `selections`: selection patterns provided by the user (as symbols)
- `run_all`: whether `-a` / `--all` was present
- `dry_run`: whether `-n` / `--dryrun` was present
"""
function _parse_test_args(args::Vector{String})
    selections = String[]
    run_all = false
    dry_run = false

    for arg in args
        if arg in ("coverage=true", "coverage", "--coverage", "coverage=false")
            continue
        elseif arg == "-a" || arg == "--all"
            run_all = true
        elseif arg == "-n" || arg == "--dryrun"
            dry_run = true
        else
            push!(selections, arg)
        end
    end
    return (selections, run_all, dry_run)
end

"""
    _glob_to_regex(pattern::AbstractString) -> Regex

Convert a glob pattern (using `*` and `?`) into a regular expression.

The returned regex is anchored (matches the full string).
"""
function _glob_to_regex(pattern::AbstractString)
    # Escape special regex characters except * and ?
    regex_str = replace(
        pattern,
        "." => "\\.",
        "+" => "\\+",
        "(" => "\\(",
        ")" => "\\)",
        "[" => "\\[",
        "]" => "\\]",
        "{" => "\\{",
        "}" => "\\}",
        "^" => "\\^",
        "\u0024" => "\\\u0024",
        "\\" => "\\\\",
    )
    # Convert glob wildcards to regex wildcards
    regex_str = replace(regex_str, "*" => ".*", "?" => ".")
    # Anchor to full string
    return Regex("^" * regex_str * "\u0024")
end

function _ensure_jl(filename::AbstractString)
    endswith(filename, ".jl") ? filename : filename * ".jl"
end

function _builder_to_string(x)
    x isa Symbol ? String(x) : String(x)
end

function _normalize_available_tests(available_tests)
    available_tests === nothing && return TestSpec[]

    if !(available_tests isa AbstractVector || available_tests isa Tuple)
        throw(ArgumentError("available_tests must be a Vector or Tuple of Symbol/String"))
    end

    out = TestSpec[]
    for entry in available_tests
        if entry isa Symbol || entry isa String
            push!(out, entry)
        else
            throw(ArgumentError("available_tests entries must be Symbol or String"))
        end
    end
    return out
end

function _collect_test_files_recursive(test_dir::AbstractString)
    files = String[]
    for (root, _, fs) in walkdir(test_dir)
        for f in fs
            if endswith(f, ".jl") && f != "runtests.jl"
                full = joinpath(root, f)
                push!(files, relpath(full, test_dir))
            end
        end
    end
    sort!(files)
    return files
end

function _find_symbol_test_file_rel(
    name::Symbol, filename_builder::Function; test_dir::AbstractString
)
    wanted = _ensure_jl(_builder_to_string(filename_builder(name)))
    all = _collect_test_files_recursive(test_dir)
    matches = filter(f -> basename(f) == wanted, all)

    if isempty(matches)
        return nothing
    end
    if wanted in matches
        return wanted
    end

    sort!(matches; by=f -> (count(==('/'), f), ncodeunits(f), f))
    return first(matches)
end

"""
Determine which tests to run based on selections, available_tests filter, and file globbing.
1. Identify potential test files in `test_dir` (default: `test/`).
2. Filter by `available_tests` if provided.
3. Filter by `selections` (interpreted as globs) if present.

# Notes

If `available_tests` is empty, this function falls back to an auto-discovery
heuristic using the filename stem as the candidate test name.
"""
function _select_tests(
    selections::Vector{String},
    available_tests::AbstractVector{<:TestSpec},
    run_all::Bool,
    filename_builder::Function;
    test_dir::String=joinpath(pwd(), "test"), # Default assumption
)
    # 1. Identify all potential test files
    # We look for .jl files in test_dir, excluding runtests.jl
    all_files = filter(f -> endswith(f, ".jl") && f != "runtests.jl", readdir(test_dir))

    # Map filenames back to "test names" is tricky without reverse builder.
    # Strategy:
    # We assume `available_tests` defines the canonical list of "names".
    # If `available_tests` is empty, we derive names from files? 
    #   -> User said: "list all .jl files... but only keep available if provided"

    candidates = TestSpec[]

    if isempty(available_tests)
        # If no available_tests provided, every .jl file is a candidate!
        # This effectively AUTO-DISCOVERS tests.
        # We need to guess the "name" from the filename.
        # This is hard because filename_builder is name -> filename.
        #   utils -> test_utils.jl
        #   test_utils.jl -> utils ??
        # For now, let's keep the user's current behavior:
        # If available_tests is empty, the logic relies on what the user passes.
        # BUT the new logic says "if args empty -> run all".
        # So we MUST perform auto-discovery if we want "run all" to work without explicit available_tests.

        # Heuristic: if file starts with "test_", strip it?
        # Or just use the basename as the symbol?
        # Let's assume the "name" is the filename without extension for auto-discovery?
        # Or better: don't guess names yet. Just work with filenames?
        # But `run_tests` iterates over `names`.

        # Let's look at existing files: test_utils.jl -> name=:utils (via filename_builder)
        # We cannot invert `filename_builder` (F -> S).
        # So we are stuck if we want to infer names from files.

        # COMPROMISE: If available_tests is empty, we cannot guarantee auto-discovery compatibility with arbitrary filename_builders.
        # We will assume a default mapping for auto-discovery: name = file_basename_without_extension.
        for f in all_files
            name_str = replace(f, ".jl" => "")
            # If name starts with "test_", removing it is common convention, but maybe risky?
            # Let's keep the full basename as the name if we are auto-discovering.
            push!(candidates, Symbol(name_str))
        end
    else
        # If available_tests IS provided, we only consider these.
        # We verify if their files exist.
        recursive_files = _collect_test_files_recursive(test_dir)
        for entry in available_tests
            if entry isa Symbol
                rel = _find_symbol_test_file_rel(entry, filename_builder; test_dir=test_dir)
                if rel !== nothing
                    push!(candidates, entry)
                end
            else
                full = joinpath(test_dir, entry)
                if isdir(full)
                    prefix = entry * "/"
                    for f in recursive_files
                        if startswith(f, prefix)
                            push!(candidates, f)
                        end
                    end
                else
                    regex = _glob_to_regex(entry)
                    for f in recursive_files
                        f_no_ext = replace(f, ".jl" => "")
                        if !isnothing(match(regex, f)) || !isnothing(match(regex, f_no_ext))
                            push!(candidates, f)
                        end
                    end
                end
            end
        end
    end

    # If run_all is requested or no selections, return all candidates
    if run_all || isempty(selections)
        return candidates
    end

    # 3. Filter candidates by selections (Patterns)
    # selections are now patterns! e.g. [:utils, :test_u*]
    filtered = TestSpec[]

    for candidate in candidates
        candidate_str = candidate isa Symbol ? String(candidate) : String(candidate)
        # Also check the associated filename?
        # If I have candidate :utils -> test_utils.jl
        # And user passes "test_u*", it should match "test_utils.jl" OR "utils"?
        # User said "Scan test/ directory... ARGS are globs".
        # So matching against the FILENAME seems primary.

        # Resolve filename for candidate
        if candidate isa String
            candidate_filename = _ensure_jl(candidate)
        elseif isempty(available_tests)
            candidate_filename = "$(candidate).jl"
        else
            candidate_filename = _ensure_jl(_builder_to_string(filename_builder(candidate)))
        end

        # Also match strictly against filename without extension?
        candidate_filename_no_ext = replace(candidate_filename, ".jl" => "")

        candidate_basename = basename(candidate_filename)
        candidate_basename_no_ext = replace(candidate_basename, ".jl" => "")
        candidate_basename_no_test_prefix =
            startswith(candidate_basename_no_ext, "test_") ? candidate_basename_no_ext[6:end] :
            candidate_basename_no_ext

        matched = false
        for sel in selections
            regex = _glob_to_regex(sel)

            # Match against:
            # 1. Candidate name (e.g. :utils)
            # 2. Filename (e.g. test_utils.jl)
            # 3. Filename without extension (e.g. test_utils)
            if !isnothing(match(regex, candidate_str)) ||
                !isnothing(match(regex, candidate_filename)) ||
                !isnothing(match(regex, candidate_filename_no_ext)) ||
                !isnothing(match(regex, candidate_basename)) ||
                !isnothing(match(regex, candidate_basename_no_ext)) ||
                !isnothing(match(regex, candidate_basename_no_test_prefix))
                matched = true
                break
            end
        end

        if matched
            push!(filtered, candidate)
        end
    end

    return filtered
end

"""
    _run_single_test(name::Symbol; kwargs...)

Run a single selected test.

This helper:

- Resolves a test filename via `filename_builder`
- Includes the file into `Main`
- Optionally evaluates a function (via `funcname_builder`) when `eval_mode=true`

This function is not part of the public API.
"""
function _run_single_test(
    spec::TestSpec;
    available_tests::AbstractVector{<:TestSpec},
    filename_builder::Function,
    funcname_builder::Function,
    eval_mode::Bool,
    test_dir::String,
)
    if spec isa String
        rel = _ensure_jl(spec)
        filename = joinpath(test_dir, rel)
        if !isfile(filename)
            error("""
            Test file "$(filename)" not found.
            Current directory: $(pwd())
            """)
        end
        Base.include(Main, filename)

        if !eval_mode
            return nothing
        end

        func_symbol = Symbol(replace(basename(rel), ".jl" => ""))
        if !isdefined(Main, func_symbol)
            error("""
            Function "$(func_symbol)" not found after including "$(filename)".
            Make sure the file defines a function with this name.
            """)
        end

        Main.eval(Expr(:call, func_symbol))
        return nothing
    end

    name = spec

    # Build filename
    rel = _find_symbol_test_file_rel(name, filename_builder; test_dir=test_dir)
    rel === nothing && error("""
    Test file not found for test "$(name)".
    Current directory: $(pwd())
    """)

    filename = joinpath(test_dir, rel)

    # Check file exists
    if !isfile(filename)
        error("""
        Test file "$(filename)" not found for test "$(name)".
        Current directory: $(pwd())
        """)
    end

    # Include the file
    Base.include(Main, filename)

    # Determine function name
    func_symbol = funcname_builder(name)

    # Check consistency: eval_mode=true but funcname_builder returns nothing
    if eval_mode && func_symbol === nothing
        error(
            """
      Inconsistency: eval_mode=true but funcname_builder returned nothing for test "$(name)".
      Either set eval_mode=false, or make funcname_builder return a Symbol.
      """,
        )
    end

    # Skip eval if not in eval mode or funcname_builder returned nothing
    if !eval_mode || func_symbol === nothing
        return nothing
    end

    func_symbol = func_symbol isa Symbol ? func_symbol : Symbol(String(func_symbol))

    # Check function exists before eval
    if !isdefined(Main, func_symbol)
        error("""
        Function "$(func_symbol)" not found after including "$(filename)".
        Make sure the file defines a function with this name.
        """)
    end

    # Eval the function
    Main.eval(Expr(:call, func_symbol))

    return nothing
end

end
