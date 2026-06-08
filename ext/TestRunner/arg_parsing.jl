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
            return String(s[(length(prefix) + 1):end])
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
    candidate_strs = [String(c) for c in candidates]
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
$(TYPEDSIGNATURES)

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
    return endswith(filename, ".jl") ? filename : filename * ".jl"
end

"""
$(TYPEDSIGNATURES)

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
    return String(x)
end

"""
$(TYPEDSIGNATURES)

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
        throw(
            CTBase.Exceptions.IncorrectArgument(
                "available_tests must be a Vector or Tuple of Symbol/String";
                got=string(typeof(available_tests)),
            ),
        )
    end

    out = TestSpec[]
    for entry in available_tests
        if entry isa Symbol || entry isa String
            push!(out, entry)
        else
            throw(
                CTBase.Exceptions.IncorrectArgument(
                    "available_tests entries must be Symbol or String";
                    got=string(typeof(entry)),
                ),
            )
        end
    end
    return out
end
