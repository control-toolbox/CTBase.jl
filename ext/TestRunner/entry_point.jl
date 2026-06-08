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
- `show_progress_line::Bool`: Show progress line with symbol, index, spec, and time (default: `true`)
- `show_progress_bar::Bool`: Show graphical progress bar `[█░░░...]` within the line (default: `true`)
- `progress_bar_threshold::Int`: Maximum tests for full-resolution progress bar (default: `100`)

# Returns
- `Nothing`: Tests are executed via side effects

# Notes
- Test selection is driven by `args` (coverage flags are automatically filtered out)
- Selection arguments are interpreted as glob patterns and matched against both test names and filenames
- Arguments starting with `test/` are automatically stripped for convenience
- When `on_test_done` is provided, the built-in progress line is disabled unless `show_progress_line=true`
- When `show_progress_line=true` but `show_progress_bar=false`, displays minimal output: `✓ [01/76] suite/test.jl (0.2s)` without the graphical bar

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> # Run all tests with default settings
julia> CTBase.Extensions.run_tests()

julia> # Run specific tests with custom callbacks
julia> CTBase.Extensions.run_tests(;
           args=["utils", "core"],
           on_test_start = info -> (println("Running: ", info.spec); true),
           on_test_done = info -> println("Done: ", info.status)
       )
```

See also: [`CTBase.Extensions.run_tests`](@ref), [`CTBase.TestRunner.TestRunInfo`](@ref)
"""
function Extensions.run_tests(
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
    show_progress_line::Bool=true,
    show_progress_bar::Bool=true,
    progress_bar_threshold::Int=_PROGRESS_BAR_THRESHOLD,
)
    # Guard: a subdirectory named "test" inside test_dir would conflict with
    # the automatic `test/` prefix stripping in _parse_test_args.
    if isdir(joinpath(test_dir, "test"))
        throw(
            CTBase.Exceptions.PreconditionError(
                "A subdirectory \"test\" exists inside the test directory \"$(test_dir)\"";
                reason="selection arguments starting with \"test/\" are automatically stripped (e.g. \"test/suite\" → \"suite\")",
                suggestion="rename the subdirectory to avoid the conflict",
            ),
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
    elseif show_progress_line
        _make_default_on_test_done(stdout, total, progress_bar_threshold, show_progress_bar)
    else
        nothing
    end

    Test.@testset verbose = verbose showtiming = showtiming "$testset_name" begin
        for (idx, spec) in enumerate(selected)
            Test.@testset "$(spec)" begin
                _run_single_test(
                    spec;
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
