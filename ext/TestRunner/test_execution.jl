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
        spec; filename_builder, funcname_builder, eval_mode, test_dir
    )

    # --- Include the file ---
    Base.include(Main, filename)

    # --- Check function exists after include ---
    if eval_mode && func_symbol !== nothing && !isdefined(Main, func_symbol)
        throw(
            CTBase.Exceptions.PreconditionError(
                "Function \"$(func_symbol)\" not found after including \"$(filename)\"";
                reason="the file does not define a function with this name",
                suggestion="make sure the file defines a top-level function named $(func_symbol)",
            ),
        )
    end

    # --- on_test_start callback ---
    if on_test_start !== nothing
        info = TestRunInfo(
            spec, filename, func_symbol, index, total, :pre_eval, nothing, nothing
        )
        should_continue = on_test_start(info)
        if should_continue === false
            if on_test_done !== nothing
                done_info = TestRunInfo(
                    spec, filename, func_symbol, index, total, :skipped, nothing, nothing
                )
                on_test_done(done_info)
            end
            return nothing
        end
    end

    # --- Skip eval if not in eval mode ---
    if !eval_mode || func_symbol === nothing
        if on_test_done !== nothing
            done_info = TestRunInfo(
                spec, filename, func_symbol, index, total, :skipped, nothing, nothing
            )
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
            done_info = TestRunInfo(
                spec, filename, func_symbol, index, total, status, nothing, elapsed
            )
            on_test_done(done_info)
        end
    catch ex
        elapsed = time() - t0
        if on_test_done !== nothing
            done_info = TestRunInfo(
                spec, filename, func_symbol, index, total, :error, ex, elapsed
            )
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
    filename_builder::Function,
    funcname_builder::Function,
    eval_mode::Bool,
    test_dir::String,
)
    if spec isa String
        rel = _ensure_jl(spec)
        filename = joinpath(test_dir, rel)
        if !isfile(filename)
            throw(
                CTBase.Exceptions.IncorrectArgument(
                    "Test file \"$(filename)\" not found";
                    context="current directory: $(pwd())",
                ),
            )
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
    rel === nothing && throw(
        CTBase.Exceptions.IncorrectArgument(
            "Test file not found for test \"$(name)\"";
            context="current directory: $(pwd())",
        ),
    )

    filename = joinpath(test_dir, rel)

    # Check file exists
    !isfile(filename) && throw(
        CTBase.Exceptions.IncorrectArgument(
            "Test file \"$(filename)\" not found for test \"$(name)\"";
            context="current directory: $(pwd())",
        ),
    )

    # Determine function name
    func_symbol = funcname_builder(name)

    # Check consistency: eval_mode=true but funcname_builder returns nothing
    if eval_mode && func_symbol === nothing
        throw(
            CTBase.Exceptions.PreconditionError(
                "eval_mode=true but funcname_builder returned nothing for test \"$(name)\"";
                reason="funcname_builder must return a Symbol when eval_mode=true",
                suggestion="set eval_mode=false, or make funcname_builder return a Symbol",
            ),
        )
    end

    if !eval_mode || func_symbol === nothing
        return (filename, nothing)
    end

    func_symbol = func_symbol isa Symbol ? func_symbol : Symbol(String(func_symbol))

    return (filename, func_symbol)
end

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
