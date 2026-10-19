"""
$(TYPEDEF)

Abstract supertype for tags used to select a particular implementation of
`test_extensions_quality`.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.DevTools.ExtensionsQualityTag() isa CTBase.DevTools.AbstractExtensionsQualityTag
true
```

See also: [`CTBase.DevTools.ExtensionsQualityTag`](@extref)
"""
abstract type AbstractExtensionsQualityTag end

"""
$(TYPEDEF)

Concrete tag type used to dispatch to the `CTBaseAqua` extension.

# Example

```julia-repl
julia> using CTBase

julia> tag = CTBase.DevTools.ExtensionsQualityTag()
CTBase.DevTools.ExtensionsQualityTag()
```

See also: [`CTBase.DevTools.AbstractExtensionsQualityTag`](@extref)
"""
struct ExtensionsQualityTag <: AbstractExtensionsQualityTag end

"""
$(TYPEDSIGNATURES)

Check every extension of a package for type piracy and method ambiguities
([ct-conventions `TST8`](https://github.com/control-toolbox/ct-conventions)).

`Aqua.test_all` never inspects an extension, because an extension is a separate module
and not a submodule of its package. For each entry of the `[extensions]` table of the
`Project.toml` of `pkg`, this function asserts that the extension is loaded, then checks
that it pirates no method (every function and type of `pkg` being treated as owned) and
introduces no ambiguity. It is an **extension point**: the default implementation throws
an `CTBase.Exceptions.ExtensionError` unless `Aqua` and `Test` are loaded.

# Arguments

- `pkg::Module`: the package whose extensions are checked.

# Keyword Arguments

- `allowed_piracies::AbstractDict{String,<:AbstractDict{String,String}}`: piracy needed by
  design, per extension name. Each entry maps the signature of a pirated method, as
  printed by the failure message, to the reason it is accepted. A method not listed fails,
  and so does a listed signature that is no longer pirated. Default: empty.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the `CTBaseAqua` extension is not loaded.

# Example

```julia
using CTBase, Aqua, Test
CTBase.DevTools.test_extensions_quality(
    MyPkg;
    allowed_piracies=Dict(
        "MyPkgMakie" => Dict("Tuple{typeof(Makie.plot), MyPkg.Solution}" => "ports the plot entry point"),
    ),
)
```
"""
function test_extensions_quality(
    ::AbstractExtensionsQualityTag,
    pkg::Module;
    allowed_piracies::AbstractDict=Dict{String,Dict{String,String}}(),
)
    return throw(
        Exceptions.ExtensionError(
            :Aqua,
            :Test;
            feature="extension quality checks",
            context="test_extensions_quality",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for `test_extensions_quality` using the default backend tag.

# Arguments

- `pkg::Module`: the package whose extensions are checked.

# Keyword Arguments

Forwarded to `test_extensions_quality(ExtensionsQualityTag(), pkg; kwargs...)`.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the `CTBaseAqua` extension is not loaded.
"""
function test_extensions_quality(pkg::Module; kwargs...)
    return test_extensions_quality(ExtensionsQualityTag(), pkg; kwargs...)
end
