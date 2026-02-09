"""
Test runner backend for CTBase.

This extension implements [`CTBase.run_tests`](@ref), allowing test selection
via command-line arguments (globs) and configurable filename/function-name builders.

Most functions in this module have side effects (including file inclusion and
running testsets).
"""
module TestRunner

using CTBase: CTBase
using DocStringExtensions
using Test: Test, @testset

"""
$(TYPEDEF)

Union type representing a test specification.

A test spec can be either:
- `Symbol`: A logical test name (e.g., `:utils`, `:core`)
- `String`: A relative file path or glob pattern (e.g., `"suite/test_utils.jl"`, `"suite/core/*"`)

This type is used throughout TestRunner to represent both user-provided selections
and internal test identifiers.

# Notes
- Symbol specs are resolved via `filename_builder` and `funcname_builder`
- String specs are treated as relative paths from `test_dir`
- Glob patterns are supported for String specs

See also: [`CTBase.run_tests`](@ref), [`TestRunner._select_tests`](@ref)
"""
const TestSpec = Union{Symbol,String}

"""
$(TYPEDEF)

Context information passed to test callbacks (`on_test_start`, `on_test_done`).

Provides details about the current test being executed, including progress
information (`index`, `total`) and execution results (`status`, `error`, `elapsed`).

# Fields
- `spec::TestSpec`: test identifier (Symbol or relative path String)
- `filename::String`: absolute path of the included test file
- `func_symbol::Union{Symbol,Nothing}`: function to call (`nothing` if `eval_mode=false`)
- `index::Int`: 1-based index of the current test in the selected list
- `total::Int`: total number of selected tests
- `status::Symbol`: one of `:pre_eval`, `:post_eval`, `:skipped`, `:error`, `:test_failed`
- `error::Union{Exception,Nothing}`: captured exception when `status == :error`
- `elapsed::Union{Float64,Nothing}`: wall-clock seconds for the eval phase (only in `on_test_done`)

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> info = TestRunner.TestRunInfo(
           :utils, 
           "/path/to/test_utils.jl", 
           :test_utils, 
           3, 10, 
           :post_eval, 
           nothing, 
           1.23
       )
TestRunner.TestRunInfo(:utils, "/path/to/test_utils.jl", :test_utils, 3, 10, :post_eval, nothing, 1.23)

julia> info.status
:post_eval

julia> info.elapsed
1.23
```
"""
struct TestRunInfo
    spec::TestSpec
    filename::String
    func_symbol::Union{Symbol,Nothing}
    index::Int
    total::Int
    status::Symbol
    error::Union{Exception,Nothing}
    elapsed::Union{Float64,Nothing}
end

"""
$(TYPEDSIGNATURES)

Run tests with configurable file/function name builders and optional available tests filter.

# Arguments
- `::CTBase.Extensions.TestRunnerTag`: Dispatch tag for the TestRunner extension
- `args::AbstractVector{<:AbstractString}`: Command-line arguments (typically `String.(ARGS)`)
- `testset_name::String`: Name of the main testset (default: `"Tests"`)
- `available_tests`: Allowed tests (Symbols, Strings, or glob patterns). Empty = auto-discovery
- `filename_builder::Function`: `name → filename` mapping (default: `identity`)
- `funcname_builder::Function`: `name → function_name` mapping (default: `identity`)
- `eval_mode::Bool`: Whether to call the function after include (default: `true`)
- `verbose::Bool`: Verbose `@testset` output (default: `true`)
- `showtiming::Bool`: Show timing in `@testset` output (default: `true`)
- `test_dir::String`: Root directory for test files (default: `joinpath(pwd(), "test")`)
- `on_test_start::Union{Function,Nothing}`: Callback before eval (default: `nothing`)
- `on_test_done::Union{Function,Nothing}`: Callback after eval (default: `nothing`)
- `progress::Bool`: Show built-in progress bar (default: `true`)

# Returns
- `Nothing`: Tests are executed via side effects

# Notes
- Test selection is driven by `args` (coverage flags are automatically filtered out)
- Selection arguments are interpreted as glob patterns and matched against both test names and filenames
- Arguments starting with `test/` are automatically stripped for convenience
- When `on_test_done` is provided, the built-in progress bar is disabled unless `progress=true`

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> # Run all tests with default settings
julia> CTBase.run_tests()

julia> # Run specific tests with custom callbacks
julia> CTBase.run_tests(;
           args=["utils", "core"],
           on_test_start = info -> (println("Running: ", info.spec); true),
           on_test_done = info -> println("Done: ", info.status)
       )
```

See also: [`TestRunner.TestRunInfo`](@ref), [`TestRunner._parse_test_args`](@ref), [`TestRunner._select_tests`](@ref)
"""
function CTBase.run_tests(
    ::CTBase.Extensions.TestRunnerTag;
    args::AbstractVector{<:AbstractString}=String[],
    testset_name::String="Tests",
    available_tests=Symbol[],
    filename_builder::Function=identity,
    funcname_builder::Function=identity,
    eval_mode::Bool=true,
    verbose::Bool=true,
    showtiming::Bool=true,
    test_dir::String=joinpath(pwd(), "test"),
    on_test_start::Union{Function,Nothing}=nothing,
    on_test_done::Union{Function,Nothing}=nothing,
    progress::Bool=true,
)
    # Guard: a subdirectory named "test" inside test_dir would conflict with
    # the automatic `test/` prefix stripping in _parse_test_args.
    if isdir(joinpath(test_dir, "test"))
        error(
            "A subdirectory \"test\" exists inside the test directory " *
            "\"$(test_dir)\". This is not supported because selection " *
            "arguments starting with \"test/\" are automatically stripped " *
            "(e.g. \"test/suite\" → \"suite\"). Please rename the subdirectory."
        )
    end

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

    total = length(selected)

    # Wire up default progress callback when no custom on_test_done is provided
    effective_on_test_done = if on_test_done !== nothing
        on_test_done
    elseif progress
        _default_on_test_done
    else
        nothing
    end

    @testset verbose = verbose showtiming = showtiming "$testset_name" begin
        for (idx, spec) in enumerate(selected)
            @testset "$(spec)" begin
                _run_single_test(
                    spec;
                    available_tests=available_tests_vec,
                    filename_builder,
                    funcname_builder,
                    eval_mode,
                    test_dir,
                    index=idx,
                    total,
                    on_test_start,
                    on_test_done=effective_on_test_done,
                )
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)

Parse command-line test arguments, filtering out coverage-related flags.

# Arguments
- `args::Vector{String}`: Raw command-line arguments

# Returns
- `Tuple{Vector{String}, Bool, Bool}`: `(selections, run_all, dry_run)` where:
  - `selections`: selection patterns provided by the user (as strings)
  - `run_all`: whether `-a` / `--all` was present
  - `dry_run`: whether `-n` / `--dryrun` was present

# Notes
- Coverage flags (`coverage=true`, `--coverage`, etc.) are automatically filtered out
- Selection patterns starting with `test/` or `test\\` are automatically stripped
  so that users can write `test/suite/foo` or `suite/foo` interchangeably

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._parse_test_args(["utils", "-a", "--dryrun"])
(["utils"], true, true)

julia> TestRunner._parse_test_args(["test/suite", "coverage=true"])
(["suite"], false, false)
```
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
            push!(selections, _strip_test_prefix(arg))
        end
    end
    return (selections, run_all, dry_run)
end

"""
$(TYPEDSIGNATURES)

Strip a leading `test/` or `test\\` prefix from a selection pattern.

This allows users to type `test/suite/foo` instead of `suite/foo` since
the test directory is already the root for pattern matching.

# Arguments
- `s::AbstractString`: Selection pattern to process

# Returns
- `String`: Pattern with `test/` or `test\\` prefix stripped (if present)

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._strip_test_prefix("test/suite/foo")
"suite/foo"

julia> TestRunner._strip_test_prefix("suite/foo")
"suite/foo"

julia> TestRunner._strip_test_prefix("test\\windows\\path")
"windows\\path"
```
"""
function _strip_test_prefix(s::AbstractString)
    for prefix in ("test/", "test\\")
        if startswith(s, prefix)
            return String(s[length(prefix)+1:end])
        end
    end
    return String(s)
end

"""
$(TYPEDSIGNATURES)

Normalize user-provided selection patterns before glob matching.

Applied transformations:
- Strip trailing `/` (e.g. `"suite/exceptions/"` → `"suite/exceptions"`)
- If a selection contains no glob wildcard (`*` or `?`) and matches a directory
  prefix of at least one candidate, expand it to `"selection/*"` so that all
  files under that directory are selected.

The original selection is always kept so that exact-name matches still work.

# Arguments
- `selections::Vector{String}`: User-provided selection patterns
- `candidates::Vector{<:TestSpec}`: Available test candidates

# Returns
- `Vector{String}`: Normalized selection patterns

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._normalize_selections(
           ["suite/"], 
           ["suite/test_a.jl", "suite/test_b.jl"]
       )
2-element Vector{String}:
 "suite"
 "suite/*"
```
"""
function _normalize_selections(selections::Vector{String}, candidates::Vector{<:TestSpec})
    candidate_strs = [c isa Symbol ? String(c) : String(c) for c in candidates]
    normalized = String[]
    for sel in selections
        # Strip trailing slash(es)
        s = rstrip(sel, '/')
        push!(normalized, s)
        # If no glob wildcard, check if it looks like a directory prefix
        if !occursin('*', s) && !occursin('?', s)
            prefix = s * "/"
            is_dir_prefix = any(c -> startswith(c, prefix), candidate_strs)
            if is_dir_prefix
                push!(normalized, s * "/*")
            end
        end
    end
    return unique(normalized)
end

"""
$(TYPEDSIGNATURES)

Convert a glob pattern (using `*` and `?`) into a regular expression.

The returned regex is anchored (matches the full string).

# Arguments
- `pattern::AbstractString`: Glob pattern to convert

# Returns
- `Regex`: Anchored regular expression equivalent to the glob pattern

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._glob_to_regex("test_*.jl")
r"^test_.*\\.jl\$"

julia> TestRunner._glob_to_regex("suite/test_?.jl")
r"^suite/test.\\.jl\$"
```
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

"""
    _ensure_jl(filename::AbstractString) -> String

Ensure that a filename ends with `.jl` extension.

If the filename already ends with `.jl`, returns it unchanged.
Otherwise, appends `.jl` to the filename.

# Arguments
- `filename::AbstractString`: Base filename with or without `.jl` extension

# Returns
- `String`: Filename guaranteed to end with `.jl`

# Example
```julia
julia> TestRunner._ensure_jl("test_utils")
"test_utils.jl"

julia> TestRunner._ensure_jl("test_utils.jl")
"test_utils.jl"
```
"""
function _ensure_jl(filename::AbstractString)
    endswith(filename, ".jl") ? filename : filename * ".jl"
end

"""
    _builder_to_string(x) -> String

Convert a Symbol or String to String.

This helper function ensures that builder function outputs are always
converted to strings for consistent handling.

# Arguments
- `x`: Symbol or String to convert

# Returns
- `String`: The string representation of `x`

# Example
```julia
julia> TestRunner._builder_to_string(:utils)
"utils"

julia> TestRunner._builder_to_string("utils")
"utils"
```
"""
function _builder_to_string(x)
    x isa Symbol ? String(x) : String(x)
end

"""
    _normalize_available_tests(available_tests) -> Vector{TestSpec}

Normalize and validate the `available_tests` argument.

Converts the input to a `Vector{TestSpec}` and validates that all entries
are either `Symbol` or `String`. Returns an empty vector if `available_tests`
is `nothing`.

# Arguments
- `available_tests`: `nothing`, `Vector`, or `Tuple` containing `Symbol` or `String` entries

# Returns
- `Vector{TestSpec}`: Normalized vector of test specifications

# Throws
- `ArgumentError`: If `available_tests` is not a Vector/Tuple or contains invalid entries

# Example
```julia
julia> TestRunner._normalize_available_tests([:utils, "suite/*"])
2-element Vector{Union{Symbol, String}}:
 :utils
 "suite/*"

julia> TestRunner._normalize_available_tests(nothing)
Union{Symbol, String}[]
```
"""
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

"""
    _collect_test_files_recursive(test_dir::AbstractString) -> Vector{String}

Recursively collect all `.jl` files in `test_dir` (excluding `runtests.jl`).

Returns relative paths from `test_dir`, sorted alphabetically.

# Arguments
- `test_dir::AbstractString`: Root directory to search

# Returns
- `Vector{String}`: Relative paths to all `.jl` files (excluding `runtests.jl`)

# Example
```julia
# Assuming test_dir contains:
# - test/utils.jl
# - test/core/test_core.jl
# - test/runtests.jl

julia> TestRunner._collect_test_files_recursive("test")
2-element Vector{String}:
 "test/core/test_core.jl"
 "test/utils.jl"
```
"""
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

"""
    _find_symbol_test_file_rel(name::Symbol, filename_builder::Function; test_dir::AbstractString) -> Union{String,Nothing}

Find the relative path to a test file for a given symbol name.

Uses the `filename_builder` to construct the expected filename, then searches
for files matching that basename. If multiple matches exist (e.g., files in
different subdirectories), prefers the shallowest path.

# Arguments
- `name::Symbol`: Test name to resolve
- `filename_builder::Function`: Function that maps test names to filenames
- `test_dir::AbstractString`: Root directory containing test files

# Returns
- `String`: Relative path to the matching test file
- `nothing`: If no matching file is found

# Notes
- Searches recursively in `test_dir`
- Excludes `runtests.jl` from consideration
- Prefers shallower paths when multiple matches exist
- Returns the exact relative path if found

See also: [`TestRunner._collect_test_files_recursive`](@ref), [`TestRunner._ensure_jl`](@ref)
"""
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
$(TYPEDSIGNATURES)

Determine which tests to run based on selections, available_tests filter, and file globbing.

1. Identify potential test files in `test_dir` (default: `test/`).
2. Filter by `available_tests` if provided.
3. Filter by `selections` (interpreted as globs) if present.

# Arguments
- `selections::Vector{String}`: User-provided selection patterns
- `available_tests::AbstractVector{<:TestSpec}`: Allowed tests (empty = auto-discovery)
- `run_all::Bool`: Whether to run all available tests
- `filename_builder::Function`: Function to map test names to filenames
- `test_dir::String`: Root directory containing test files

# Returns
- `Vector{TestSpec}`: Selected test specifications

# Notes
- If `available_tests` is empty, this function falls back to an auto-discovery
  heuristic using the filename stem as the candidate test name
- Selection arguments are matched against multiple representations of each candidate
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

    # 3. Normalize selections: expand bare directory paths to dir/*
    selections = _normalize_selections(selections, candidates)

    # 4. Filter candidates by selections (Patterns)
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
            if startswith(candidate_basename_no_ext, "test_")
                candidate_basename_no_ext[6:end]
            else
                candidate_basename_no_ext
            end

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
$(TYPEDSIGNATURES)

Run a single selected test.

This helper:
- Resolves a test filename via `filename_builder`
- Includes the file into `Main`
- Calls `on_test_start` (if provided) after include, before eval
- Optionally evaluates a function (via `funcname_builder`) when `eval_mode=true`
- Calls `on_test_done` (if provided) after eval, skip, or error

# Arguments
- `spec::TestSpec`: Test specification to run
- `available_tests::AbstractVector{<:TestSpec}`: Available tests for validation
- `filename_builder::Function`: Function to map test names to filenames
- `funcname_builder::Function`: Function to map test names to function names
- `eval_mode::Bool`: Whether to evaluate the function after include
- `test_dir::String`: Root directory containing test files
- `index::Int`: 1-based index in the selected list (default: `1`)
- `total::Int`: Total number of selected tests (default: `1`)
- `on_test_start::Union{Function,Nothing}`: Callback before eval (default: `nothing`)
- `on_test_done::Union{Function,Nothing}`: Callback after eval (default: `nothing`)

# Notes
- This function is not part of the public API
- Use `run_tests` for running multiple tests with proper orchestration
"""
function _run_single_test(
    spec::TestSpec;
    available_tests::AbstractVector{<:TestSpec},
    filename_builder::Function,
    funcname_builder::Function,
    eval_mode::Bool,
    test_dir::String,
    index::Int=1,
    total::Int=1,
    on_test_start::Union{Function,Nothing}=nothing,
    on_test_done::Union{Function,Nothing}=nothing,
)
    # --- Resolve filename and func_symbol ---
    filename, func_symbol = _resolve_test(
        spec; available_tests, filename_builder, funcname_builder, eval_mode, test_dir
    )

    # --- Include the file ---
    Base.include(Main, filename)

    # --- Check function exists after include ---
    if eval_mode && func_symbol !== nothing && !isdefined(Main, func_symbol)
        error("""
        Function "$(func_symbol)" not found after including "$(filename)".
        Make sure the file defines a function with this name.
        """)
    end

    # --- on_test_start callback ---
    if on_test_start !== nothing
        info = TestRunInfo(spec, filename, func_symbol, index, total, :pre_eval, nothing, nothing)
        should_continue = on_test_start(info)
        if should_continue === false
            if on_test_done !== nothing
                done_info = TestRunInfo(spec, filename, func_symbol, index, total, :skipped, nothing, nothing)
                on_test_done(done_info)
            end
            return nothing
        end
    end

    # --- Skip eval if not in eval mode ---
    if !eval_mode || func_symbol === nothing
        if on_test_done !== nothing
            done_info = TestRunInfo(spec, filename, func_symbol, index, total, :skipped, nothing, nothing)
            on_test_done(done_info)
        end
        return nothing
    end

    # --- Snapshot testset results before eval ---
    ts = Test.get_testset()
    n_before = (ts isa Test.DefaultTestSet) ? length(ts.results) : nothing

    # --- Eval the function ---
    t0 = time()
    try
        Main.eval(Expr(:call, func_symbol))
        elapsed = time() - t0
        if on_test_done !== nothing
            # Detect @test failures by scanning only the new results added during eval
            status = if n_before !== nothing
                _has_failures_in_results(ts, n_before + 1) ? :test_failed : :post_eval
            else
                :post_eval
            end
            done_info = TestRunInfo(spec, filename, func_symbol, index, total, status, nothing, elapsed)
            on_test_done(done_info)
        end
    catch ex
        elapsed = time() - t0
        if on_test_done !== nothing
            done_info = TestRunInfo(spec, filename, func_symbol, index, total, :error, ex, elapsed)
            on_test_done(done_info)
        end
        rethrow()
    end

    return nothing
end

"""
$(TYPEDSIGNATURES)

Resolve a test spec into an absolute filename and function symbol.

Handles both `String` specs (relative paths) and `Symbol` specs (logical names).
Raises errors if the file is not found or if `eval_mode=true` but no function can be determined.

# Arguments
- `spec::TestSpec`: Test specification to resolve
- `available_tests::AbstractVector{<:TestSpec}`: Available tests for validation
- `filename_builder::Function`: Function to map test names to filenames
- `funcname_builder::Function`: Function to map test names to function names
- `eval_mode::Bool`: Whether to resolve a function name
- `test_dir::String`: Root directory containing test files

# Returns
- `Tuple{String, Union{Symbol,Nothing}}`: `(filename, func_symbol)` where:
  - `filename`: Absolute path to the test file
  - `func_symbol`: Function symbol to call (or `nothing` if `eval_mode=false`)

# Throws
- `ErrorException`: If the test file is not found
- `ErrorException`: If `eval_mode=true` but no function can be determined

# Notes
- This function is not part of the public API
- Use `run_tests` for running tests with proper error handling
"""
function _resolve_test(
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

        func_symbol = if eval_mode
            Symbol(replace(basename(rel), ".jl" => ""))
        else
            nothing
        end

        return (filename, func_symbol)
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
    !isfile(filename) && error("""
        Test file "$(filename)" not found for test "$(name)".
        Current directory: $(pwd())
        """)

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

    if !eval_mode || func_symbol === nothing
        return (filename, nothing)
    end

    func_symbol = func_symbol isa Symbol ? func_symbol : Symbol(String(func_symbol))

    return (filename, func_symbol)
end

# ============================================================================
# Progress display
# ============================================================================

"""
$(TYPEDSIGNATURES)

Recursively scan a `DefaultTestSet` results for `Test.Fail` or `Test.Error` entries,
starting at index `from`.

This is used to detect `@test` failures that occurred during a specific eval by
comparing the results count before and after the eval. The `anynonpass` field is
unreliable because it is only updated when a testset *finishes* (in `Test.finish`).

# Arguments
- `ts::Test.DefaultTestSet`: TestSet to scan
- `from::Int`: Starting index for scanning (default: `1`)

# Returns
- `Bool`: `true` if any failures are found, `false` otherwise

# Example
```julia-repl
julia> using CTBase.TestRunner, Test

julia> ts = Test.DefaultTestSet("test", [])
julia> Test.@testset "example" begin
           Test.@test 1 == 1
           Test.@test 2 == 0  # This will fail
       end
Test.DefaultTestSet("example", Any[Test.Pass(1), Test.Fail("false")])

julia> TestRunner._has_failures_in_results(ts)
true
```
"""
function _has_failures_in_results(ts::Test.DefaultTestSet, from::Int=1)
    for i in from:length(ts.results)
        r = ts.results[i]
        if r isa Test.DefaultTestSet
            _has_failures_in_results(r) && return true
        elseif r isa Test.Fail || r isa Test.Error
            return true
        end
    end
    return false
end

"""
$(TYPEDSIGNATURES)

Compute the progress bar character width based on the number of tests.

- `total ≤ 20`: width equals `total` (one block per test).
- `total > 20`: fixed width of 20 (some tests skip a block advance).

# Arguments
- `total::Int`: Total number of tests

# Returns
- `Int`: Character width for the progress bar (0 if `total ≤ 0`)

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._bar_width(10)
10

julia> TestRunner._bar_width(25)
20

julia> TestRunner._bar_width(0)
0
```
"""
function _bar_width(total::Int)
    total <= 0 && return 0
    return min(total, 20)
end

"""
$(TYPEDSIGNATURES)

Render a progress bar string like `[████████░░░░░░░░░░░]`.

When `width` is `nothing` (default), the width is computed automatically
via `_bar_width(total)`. Returns an empty string when the bar is hidden.

# Arguments
- `index::Int`: current progress (1-based)
- `total::Int`: total number of items
- `width::Union{Int,Nothing}`: character width of the bar (default: auto)

# Returns
- `String`: Progress bar string, or empty string if hidden

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._progress_bar(5, 10)
"[█████░░░░░]"

julia> TestRunner._progress_bar(5, 10; width=20)
"[████████████████████░░░░░░]"

julia> TestRunner._progress_bar(0, 10; width=5)
"[░░░░░]"
```
"""
function _progress_bar(index::Int, total::Int; width::Union{Int,Nothing}=nothing)
    w = width === nothing ? _bar_width(total) : width
    w <= 0 && return ""
    total <= 0 && return "[" * repeat("░", w) * "]"
    filled = round(Int, index / total * w)
    filled = clamp(filled, 0, w)
    return "[" * repeat("█", filled) * repeat("░", w - filled) * "]"
end

"""
$(TYPEDSIGNATURES)

Write a styled progress line for a completed test to `io`.

Uses ANSI colors: green for success, red for errors, yellow for skipped.

# Arguments
- `io::IO`: Output stream to write to
- `info::TestRunInfo`: Test execution information

# Notes
- Format: `[progress_bar] symbol [index/total] spec (time) status`
- Colors: green for success, red for errors, yellow for skipped
- Time is displayed with one decimal place when available

# Example
```julia-repl
julia> using CTBase.TestRunner, IOBuffer

julia> info = TestRunner.TestRunInfo(
           :test_example, 
           "/path/to/test.jl", 
           :test_example, 
           5, 10, 
           :post_eval, 
           nothing, 
           1.23
       );

julia> buf = IOBuffer();
julia> TestRunner._format_progress_line(buf, info);
julia> String(take!(buf))
"[█████░░░░░░░░░░░] ✓ [05/10] test_example (1.2s)"
```
"""
function _format_progress_line(io::IO, info::TestRunInfo)
    # ANSI codes
    reset   = "\e[0m"
    bold    = "\e[1m"
    dim     = "\e[2m"
    green   = "\e[32m"
    red     = "\e[31m"
    yellow  = "\e[33m"
    cyan    = "\e[36m"

    bar = _progress_bar(info.index, info.total)

    if info.status == :error || info.status == :test_failed
        color = red
        symbol = "✗"
    elseif info.status == :skipped
        color = yellow
        symbol = "○"
    else
        color = green
        symbol = "✓"
    end

    w = ndigits(info.total)
    idx_str = "[$(lpad(info.index, w, '0'))/$(info.total)]"
    time_str = if info.elapsed !== nothing
        " $(dim)($(round(info.elapsed; digits=1))s)$(reset)"
    else
        ""
    end
    status_str = (info.status == :error || info.status == :test_failed) ? " $(bold)$(red)FAILED$(reset)$(dim)," : ""

    if !isempty(bar)
        print(io, "$(color)$(bar)$(reset) ")
    end
    print(io, "$(bold)$(color)$(symbol)$(reset) ")
    print(io, "$(cyan)$(idx_str)$(reset) ")
    print(io, "$(bold)$(info.spec)$(reset)")
    println(io, "$(status_str)$(time_str)")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Default progress callback for `on_test_done`. Prints to `stdout`.

# Arguments
- `info::TestRunInfo`: Test execution information to display

# Notes
- This is the default callback used when `progress=true` and no custom `on_test_done` is provided
- Outputs a formatted progress line to `stdout` with colors and timing information

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> info = TestRunner.TestRunInfo(
           :test_example, 
           "/path/to/test.jl", 
           :test_example, 
           5, 10, 
           :post_eval, 
           nothing, 
           1.23
       );

julia> TestRunner._default_on_test_done(info)
[█████░░░░░░░░░░░] ✓ [05/10] test_example (1.2s)
```
"""
function _default_on_test_done(info::TestRunInfo)
    _format_progress_line(stdout, info)
    return nothing
end

end
