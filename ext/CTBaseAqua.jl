module CTBaseAqua

# =============================================================================
# CTBaseAqua — extension quality checks (ct-conventions TST8).
#
# `Aqua.test_all(Pkg)` never inspects an extension: it is a separate module, not a
# submodule. This extension implements `CTBase.DevTools.test_extensions_quality`, which
# runs Aqua's piracy hunt and Test's ambiguity detection on every extension of a
# package, with the functions and types of the package treated as owned.
# =============================================================================

using Aqua: Aqua
using Test: Test
using DocStringExtensions: TYPEDSIGNATURES

using CTBase: DevTools

"""
$(TYPEDSIGNATURES)

Return the names of the extensions declared in the `[extensions]` table of the
`Project.toml` of `pkg`.
"""
function _extension_names(pkg::Module)
    project = Base.parsed_toml(joinpath(pkgdir(pkg), "Project.toml"))
    return sort!(collect(String, keys(get(project, "extensions", Dict{String,Any}()))))
end

"""
$(TYPEDSIGNATURES)

Return every function and type defined in `pkg` and its submodules, to be treated as
owned by an extension of `pkg`.
"""
function _owned_symbols(pkg::Module)
    owned = Union{Function,Type}[]
    work = Module[pkg]
    while !isempty(work)
        mod = pop!(work)
        for name in names(mod; all=true)
            (Base.isdeprecated(mod, name) || !isdefined(mod, name)) && continue
            value = getfield(mod, name)
            if value isa Module
                value !== mod && parentmodule(value) === mod && push!(work, value)
            elseif value isa Union{Function,Type} && parentmodule(Base.unwrap_unionall(value)) === mod
                push!(owned, value)
            end
        end
    end
    return owned
end

"""
$(TYPEDSIGNATURES)

Return the key under which a pirated method is listed in `allowed_piracies`.
"""
_piracy_key(method::Method) = sprint(show, method.sig)

"""
$(TYPEDSIGNATURES)

Return the methods of the extension `ext` that pirate a function and types not owned by
`pkg` or `ext`, every function and type of `pkg` being treated as owned.
"""
_piracies(pkg::Module, ext::Module) = Aqua.Piracy.hunt(ext; treat_as_own=_owned_symbols(pkg))

"""
$(TYPEDSIGNATURES)

Return the ambiguous method pairs involving a method of the extension `ext`.
"""
_ambiguities(ext::Module) = Test.detect_ambiguities(ext; recursive=true)

"""
$(TYPEDSIGNATURES)

Check one loaded extension `ext` of `pkg`: no pirated method outside `allowed`
(a `signature => reason` dictionary), no stale entry in `allowed`, no ambiguity.
"""
function _test_extension(pkg::Module, ext::Module, allowed::AbstractDict{String,String})
    Test.@test all(!isempty, values(allowed))

    pirates = _piracies(pkg, ext)
    unlisted = [m for m in pirates if !haskey(allowed, _piracy_key(m))]
    Test.@test isempty(unlisted) || begin
        @error "Unlisted piracy in $(nameof(ext)); add it to `allowed_piracies` with a reason" methods =
            [_piracy_key(m) => string(m) for m in unlisted]
        false
    end

    stale = setdiff(keys(allowed), Set(_piracy_key.(pirates)))
    Test.@test isempty(stale) || begin
        @error "Stale `allowed_piracies` entries for $(nameof(ext)): no longer pirated" entries =
            collect(stale)
        false
    end

    ambiguities = _ambiguities(ext)
    Test.@test isempty(ambiguities) || begin
        @error "Ambiguities introduced by $(nameof(ext))" pairs =
            [(string(a), string(b)) for (a, b) in ambiguities]
        false
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Implementation of `CTBase.DevTools.test_extensions_quality`: run the piracy and ambiguity
checks on every extension of `pkg`, after asserting that each one is loaded.
"""
function DevTools.test_extensions_quality(
    ::DevTools.ExtensionsQualityTag,
    pkg::Module;
    allowed_piracies::AbstractDict=Dict{String,Dict{String,String}}(),
)
    names_ = _extension_names(pkg)
    Test.@testset "Extensions quality of $(nameof(pkg))" begin
        Test.@test issubset(keys(allowed_piracies), names_)
        for name in names_
            Test.@testset "$name" begin
                ext = Base.get_extension(pkg, Symbol(name))
                Test.@test ext isa Module
                ext isa Module || continue
                _test_extension(pkg, ext, Dict{String,String}(get(allowed_piracies, name, Dict{String,String}())))
            end
        end
    end
    return nothing
end

end
