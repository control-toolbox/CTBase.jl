# ═══════════════════════════════════════════════════════════════════════════════
# Documentation helpers: errors without extensions, warnings without paths
# ═══════════════════════════════════════════════════════════════════════════════

"""
Script run by the fresh process of `repl_without_extensions`.

It loads the package named by `ARGS[1]` only, then evaluates the snippets read from
`stdin` (separated by NUL) in order. Every snippet but the last must succeed (an uncaught
error makes the process fail); the last must throw. The error is printed outside the
`catch` block: without a backtrace, CTBase exceptions omit their source locator, exactly
as an `@repl` block shows them. `Core.eval` avoids the `LoadError` wrapper of
`include_string`. Prints `CTBASE_NO_ERROR` when the last snippet does not throw.
"""
const _FRESH_PROCESS_SCRIPT = raw"""
package = Symbol(ARGS[1])
Core.eval(Main, :(using $package: $package))
snippets = split(read(stdin, String), '\0')
for code in snippets[1:(end - 1)]
    Core.eval(Main, Meta.parseall(code))
end
err = try
    Core.eval(Main, Meta.parseall(snippets[end]))
    nothing
catch e
    e
end
if err === nothing
    print("CTBASE_NO_ERROR")
else
    print(IOContext(stdout, :color => true), "ERROR: ")
    showerror(IOContext(stdout, :color => true), err)
end
"""

"""
    $(TYPEDSIGNATURES)

Evaluate `codes` in a fresh Julia process where only `package` is loaded, and return the
error displayed by the last snippet (with ANSI colors).
"""
function _run_without_extensions(
    package::Symbol, codes::Tuple{Vararg{AbstractString}}, project::AbstractString
)
    julia = Base.julia_cmd()
    load_path = join(LOAD_PATH, Sys.iswindows() ? ';' : ':')
    script = _FRESH_PROCESS_SCRIPT
    cmd = `$julia --startup-file=no --color=yes --project=$project -e $script $package`
    cmd = addenv(cmd, "JULIA_LOAD_PATH" => load_path)
    output = read(pipeline(cmd; stdin=IOBuffer(join(codes, '\0'))), String)
    if occursin("CTBASE_NO_ERROR", output)
        throw(
            CTBase.Exceptions.IncorrectArgument(
                "the last snippet did not throw without extensions";
                got="`$(last(codes))` succeeded in a fresh process loading only $package",
                expected="a snippet that throws when the extensions are not loaded",
                suggestion="Fix or remove the example: it no longer shows an error.",
                context="repl_without_extensions",
            ),
        )
    end
    return rstrip(output)
end

function CTBase.DevTools.repl_without_extensions(
    ::CTBase.DevTools.DocumenterReferenceTag,
    package::Symbol,
    codes::AbstractString...;
    project::AbstractString=dirname(Base.active_project()),
)
    isempty(codes) && throw(
        CTBase.Exceptions.IncorrectArgument(
            "no snippet to evaluate";
            expected="at least one snippet, the last one throwing",
            context="repl_without_extensions",
        ),
    )
    output = _run_without_extensions(package, codes, project)
    input = join(("julia> " * c for c in codes), "\n\n")
    n_in = count('\n', input) + 1
    n_out = count('\n', output) + 1
    spec = "julia:$(n_in),ansi:$(n_out)"
    return Markdown.MD(Markdown.Code("ansi julia-repl-runs=$spec", input * "\n" * output))
end

"""
    _WarningRecorder

Logger used by `warnings_without_paths`: records the label (`"Warning"` or `"Error"`),
message and module of every record at level `Warn` or above, and nothing else.

`Base.CoreLogging` is what the `Logging` standard library re-exports; using it directly
keeps `Logging` out of CTBase's dependencies.
"""
struct _WarningRecorder <: Base.CoreLogging.AbstractLogger
    records::Vector{Tuple{String,String,Module}}
end

Base.CoreLogging.min_enabled_level(::_WarningRecorder) = Base.CoreLogging.Warn
Base.CoreLogging.shouldlog(::_WarningRecorder, args...) = true
Base.CoreLogging.catch_exceptions(::_WarningRecorder) = false
function Base.CoreLogging.handle_message(
    logger::_WarningRecorder, level, message, _module, args...; kwargs...
)
    label = level >= Base.CoreLogging.Error ? "Error" : "Warning"
    push!(logger.records, (label, string(message), _module))
    return nothing
end

function CTBase.DevTools.warnings_without_paths(
    f, ::CTBase.DevTools.DocumenterReferenceTag; show::Bool=false
)
    logger = _WarningRecorder(Tuple{String,String,Module}[])
    value = Base.CoreLogging.with_logger(f, logger)
    for (label, message, _module) in logger.records
        lines = split(message, '\n')
        println("┌ ", label, ": ", first(lines))
        foreach(l -> println("│ ", l), lines[2:end])
        println("└ @ ", _module)
    end
    if show
        Base.show(IOContext(stdout, :color => true), MIME"text/plain"(), value)
        println()
        return nothing
    end
    return value
end
