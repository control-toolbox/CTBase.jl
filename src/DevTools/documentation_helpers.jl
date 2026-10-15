"""
$(TYPEDSIGNATURES)

REPL transcript of `codes` evaluated in a **fresh Julia process** where only `package` is
loaded, rendered like an `@repl` block. The last snippet must throw; its error is the
output. Use it from an `@eval` block to show an error that only exists when an extension
is not loaded:

````markdown
```@eval
CTBase.DevTools.repl_without_extensions(:MyPackage, "MyPackage.Solver()")
```
````

`make.jl` loads every weak dependency so that the API reference documents the extensions,
and extension methods are global to the process: an `@repl` block would show a working
instance instead of the error.

This method is an **extension point**: it throws an `CTBase.Exceptions.ExtensionError`
unless the `DocumenterReference` extension is loaded.

# Arguments

- `package::Symbol`: the package loaded in the fresh process (`using package: package`).
- `codes::AbstractString...`: snippets evaluated in order in `Main`. All but the last are
  shown as inputs and must succeed (e.g. `using` statements); the last one must throw.

# Keyword Arguments

- `project::AbstractString`: the environment of the fresh process. Default: the active
  project (the docs environment when `make.jl` runs with `--project=docs`).

# Returns

- `Markdown.MD`: an `ansi` code block with a `julia-repl-runs` spec, rendered by
  DocumenterVitepress with Julia-highlighted inputs and ANSI-colored output.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the `DocumenterReference` extension is not loaded.
- `CTBase.Exceptions.IncorrectArgument`: If the last snippet does not throw, so that an
  example that no longer shows an error fails the build.
- `Base.ProcessFailedException`: If a snippet before the last one throws.

See also: [`CTBase.DevTools.warnings_without_paths`](@ref).
"""
function repl_without_extensions(
    ::AbstractDocumenterReferenceTag,
    package::Symbol,
    codes::AbstractString...;
    kwargs...,
)
    return throw(
        Exceptions.ExtensionError(
            :Documenter,
            :Markdown,
            :MarkdownAST;
            feature="REPL transcripts without extensions",
            context="documentation build",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for `repl_without_extensions` using the default backend tag.

# Example

````markdown
```@eval
CTBase.DevTools.repl_without_extensions(:MyPackage, "MyPackage.Solver()")
```
````
"""
function repl_without_extensions(package::Symbol, codes::AbstractString...; kwargs...)
    return repl_without_extensions(DocumenterReferenceTag(), package, codes...; kwargs...)
end

"""
$(TYPEDSIGNATURES)

Evaluate `f()` with its warnings captured, print them without source location, and
return the value of `f()`. Use it on hidden lines around the visible lines of an
`@example` block:

````markdown
```@example page
CTBase.DevTools.warnings_without_paths(; show = true) do # hide
MyPackage.Solver(unknown_option = 1; mode = :permissive)
end # hide
```
````

In an `@example` block, Documenter prints a log record with its source location
(`└ @ Module /path/on/the/build/machine/file.jl:line`), which publishes local or CI paths.
Here each warning is printed as `┌ Warning: …` / `│ …` / `└ @ Module`.

Documenter does not show what a block printed when the block returns a value. With
`show = true`, the value is printed after the warnings and `nothing` is returned, so both
appear. Variables assigned inside the block must be declared `global` on a hidden line.

This method is an **extension point**: it throws an `CTBase.Exceptions.ExtensionError`
unless the `DocumenterReference` extension is loaded.

# Keyword Arguments

- `show::Bool`: print the value of `f()` (as the REPL would) and return `nothing`.
  Default: `false`.

# Returns

- The value of `f()`, or `nothing` when `show = true`.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the `DocumenterReference` extension is not loaded.

See also: [`CTBase.DevTools.repl_without_extensions`](@ref).
"""
function warnings_without_paths(f, ::AbstractDocumenterReferenceTag; kwargs...)
    return throw(
        Exceptions.ExtensionError(
            :Documenter,
            :Markdown,
            :MarkdownAST;
            feature="warnings without source paths in documentation examples",
            context="documentation build",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for `warnings_without_paths` using the default backend tag.

# Example

````markdown
```@example page
CTBase.DevTools.warnings_without_paths() do # hide
MyPackage.Solver(unknown_option = 1; mode = :permissive)
end # hide
```
````
"""
function warnings_without_paths(f; kwargs...)
    return warnings_without_paths(f, DocumenterReferenceTag(); kwargs...)
end
