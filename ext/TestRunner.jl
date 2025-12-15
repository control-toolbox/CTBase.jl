module TestRunner

using CTBase: CTBase
using Test: Test, @testset

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
"""
function CTBase.run_tests(
    ::CTBase.TestRunnerTag;
    testset_name::String = "Tests",
    available_tests::Vector{Symbol} = Symbol[],
    filename_builder::Function = identity,
    funcname_builder::Function = identity,
    eval_mode::Bool = true,
    verbose::Bool = true,
    showtiming::Bool = true,
)
    # Parse command-line arguments
    selections = _parse_test_args(String.(Main.ARGS))

    # Get selected tests
    selected = _select_tests(selections, available_tests)

    @testset verbose = verbose showtiming = showtiming "$testset_name" begin
        for name in selected
            @testset "$(name)" begin
                _run_single_test(
                    name;
                    available_tests,
                    filename_builder,
                    funcname_builder,
                    eval_mode,
                )
            end
        end
    end
end

"""
Parse test arguments from ARGS, filtering out coverage-related flags.
"""
function _parse_test_args(args::Vector{String})
    selections = Symbol[]
    for arg in args
        arg in ("coverage=true", "coverage", "--coverage", "coverage=false") && continue
        push!(selections, Symbol(arg))
    end
    return selections
end

"""
Determine which tests to run based on selections and available_tests filter.
"""
function _select_tests(selections::Vector{Symbol}, available_tests::Vector{Symbol})
    # If :all is requested, return all available tests (or selections if no filter)
    if :all in selections
        return isempty(available_tests) ? selections : available_tests
    end

    # If no selections, return all available tests
    if isempty(selections)
        return available_tests
    end

    # Filter selections against available_tests if specified
    if !isempty(available_tests)
        for sel in selections
            if sel ∉ available_tests
                # Check if file might exist (for helpful message)
                error("""
                Test "$(sel)" is not in the available tests list.
                Available tests: $(join(available_tests, ", "))

                If you want to add this test, include it in the `available_tests` argument:
                    available_tests = [..., :$(sel)]
                """)
            end
        end
    end

    return selections
end

"""
Run a single test: include the file and optionally eval the function.
"""
function _run_single_test(
    name::Symbol;
    available_tests::Vector{Symbol},
    filename_builder::Function,
    funcname_builder::Function,
    eval_mode::Bool,
)
    # Build filename
    file_symbol = filename_builder(name)
    filename = "$(file_symbol).jl"

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
        error("""
        Inconsistency: eval_mode=true but funcname_builder returned nothing for test "$(name)".
        Either set eval_mode=false, or make funcname_builder return a Symbol.
        """)
    end

    # Skip eval if not in eval mode or funcname_builder returned nothing
    if !eval_mode || func_symbol === nothing
        return nothing
    end

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
