"""
$(TYPEDSIGNATURES)

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
$(TYPEDSIGNATURES)

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
    candidates = TestSpec[]

    if isempty(available_tests)
        for f in _collect_test_files_recursive(test_dir)
            push!(candidates, f)
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
