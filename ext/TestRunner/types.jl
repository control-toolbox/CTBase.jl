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

See also: [`CTBase.Extensions.run_tests`](@ref)
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
