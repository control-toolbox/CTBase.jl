# Color System

```@meta
CurrentModule = CTBase
```

CTBase uses ANSI colors to make the output of `show`, `describe`, and error
messages easier to read in a color-capable terminal. This guide explains the
semantic color roles, the built-in themes, and how to customize the color scheme
at runtime.

```@example color
using CTBase
nothing # hide
```

## Overview

Every color emitted by CTBase comes from a single *active palette* — a
[`Core.Palette`](@ref) struct that maps **semantic roles** to ANSI codes.
All display paths (Strategies, Options, Exceptions, TestRunner) read from the
same palette, so changing it in one place re-skins everything.

```text
CTBase.Core.set_palette!(theme)
         │
         ▼
   _ACTIVE_PALETTE (Ref{Palette})
         │
         ├─► Core.get_format_codes(io)  ─► Base.show / describe
         └─► Core._red/_yellow/…        ─► Exceptions display
```

Color is only emitted when the IO object reports `get(io, :color, false) == true`
(the standard Julia terminal check). In a plain `IOBuffer` or a redirected file,
no escape codes are written — regardless of the palette.

## Semantic Roles

Each role has a distinct name and meaning. Two roles can share the same default
color, but they are independently configurable:

| Role | `fmt` key | Default | Meaning |
| --- | --- | --- | --- |
| `name` | `fmt.name` | bold blue | identifiers, type names, option keys |
| `type` | `fmt.type` | cyan | type annotations, hierarchy entries |
| `value` | `fmt.value` | green | data / option values |
| `keyword` | `fmt.keyword` | yellow | Julia symbols (`:gradient`), aliases, IDs |
| `count` | `fmt.count` | magenta | numeric counts, lengths |
| `label` | `fmt.label` | gray | secondary labels, `[default]` / `[user]` tags |
| `emphasis` | `fmt.emphasis` | bold | message text, function names |
| `muted` | `fmt.muted` | dim | structural chars (`│ └─ →`), time suffix |
| `error` | `fmt.error` | red | failures, missing extension messages |
| `warning` | `fmt.warning` | yellow | notable values: `Got`, `Retcode`, skipped test |
| `success` | `fmt.success` | green | positive info: `Hint`, `Expected`, passing test |

> **Note** `fmt.bold` and `fmt.dim` are legacy aliases for `fmt.emphasis` and
> `fmt.muted` kept for backward compatibility.

## Built-in Themes

Three palettes are provided out of the box. Use [`Core.show_palette`](@ref) to
preview any of them in your terminal:

```julia
using CTBase

# Preview the default palette
CTBase.Core.show_palette()

# Compare with high-contrast
CTBase.Core.set_palette!(CTBase.Core.HIGH_CONTRAST_PALETTE)
CTBase.Core.show_palette()
CTBase.Core.reset_palette!()
```

`show_palette` prints three sections: the role swatches, a mock `describe`/`show`
block, and a mock exception block — so you see exactly what each role looks like
before committing to a theme.

### `DEFAULT_PALETTE`

The standard theme. Colors match Julia's REPL conventions.

```@example color
CTBase.Core.current_palette() === CTBase.Core.DEFAULT_PALETTE
```

```@example color
CTBase.Core.show_palette()
```

### `MONOCHROME_PALETTE`

All roles use an empty code — no color or formatting is ever emitted. Useful
for CI logs, plain-text output, or accessibility contexts.

```@example color
CTBase.Core.set_palette!(CTBase.Core.MONOCHROME_PALETTE)
CTBase.Core.current_palette() === CTBase.Core.MONOCHROME_PALETTE
```

```@example color
CTBase.Core.show_palette()
```

```@example color
CTBase.Core.reset_palette!()  # back to default
nothing # hide
```

### `HIGH_CONTRAST_PALETTE`

Bright bold variants for better readability on low-contrast terminals or for
users who prefer stronger visual cues.

```@example color
CTBase.Core.set_palette!(CTBase.Core.HIGH_CONTRAST_PALETTE)
```

```@example color
CTBase.Core.show_palette()
```

```@example color
CTBase.Core.reset_palette!()
nothing # hide
```

## Switching Themes at Runtime

Use [`Core.set_palette!`](@ref) to swap the active palette, and
[`Core.reset_palette!`](@ref) to restore the default:

```julia
using CTBase

# Switch to monochrome (e.g. for automated output)
CTBase.Core.set_palette!(CTBase.Core.MONOCHROME_PALETTE)

# … all show / describe calls are now plain text …

# Restore the default
CTBase.Core.reset_palette!()
```

The change is **global and immediate** — the next `show` or `describe` call
picks up the new palette. There is no scoped override in the current
implementation.

## Fine-Grained Overrides

[`Core.set_color!`](@ref) changes a single role without touching the rest:

```julia
using CTBase

# Make errors magenta instead of red
CTBase.Core.set_color!(:error, "35")

# Suppress the muted dim effect
CTBase.Core.set_color!(:muted, "")

# Restore everything
CTBase.Core.reset_palette!()
```

Valid role symbols are `:name`, `:type`, `:value`, `:keyword`, `:count`,
`:label`, `:emphasis`, `:muted`, `:error`, `:warning`, `:success`.

The `code` string is the numeric part of the ANSI escape sequence (e.g. `"32"`
for green, `"1;34"` for bold blue, `""` to suppress styling for that role). See
[ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters)
for a reference table.

## Custom Palettes

Build a [`Core.Palette`](@ref) from scratch using [`Core.Style`](@ref) values:

```julia
using CTBase

my_palette = CTBase.Core.Palette(
    CTBase.Core.Style("1;35"),  # name     — bold magenta
    CTBase.Core.Style("33"),    # type     — yellow
    CTBase.Core.Style("32"),    # value    — green
    CTBase.Core.Style("36"),    # keyword  — cyan
    CTBase.Core.Style("34"),    # count    — blue
    CTBase.Core.Style("90"),    # label    — gray
    CTBase.Core.Style("1"),     # emphasis — bold
    CTBase.Core.Style("2"),     # muted    — dim
    CTBase.Core.Style("31"),    # error    — red
    CTBase.Core.Style("33"),    # warning  — yellow
    CTBase.Core.Style("32"),    # success  — green
)

CTBase.Core.set_palette!(my_palette)

# … use CTBase …

CTBase.Core.reset_palette!()
```

Fields must be provided in the order shown in [`Core.Palette`](@ref).

## Using `get_format_codes` in Custom Display Code

If you implement `Base.show` for a type that extends CTBase, use
[`Core.get_format_codes`](@ref) to derive styled codes rather than
hardcoding ANSI sequences:

```julia
function Base.show(io::IO, ::MIME"text/plain", x::MyType)
    fmt = CTBase.Core.get_format_codes(io)
    print(io, fmt.name, "MyType", fmt.reset, " with value ")
    print(io, fmt.value, x.value, fmt.reset)
    println(io)
end
```

This ensures your display code:

- respects the active palette (user-selected theme),
- is automatically silenced when the IO does not support color,
- stays consistent with every other CTBase display.

## See Also

- [`Core.Style`](@ref), [`Core.Palette`](@ref) — type definitions
- [`Core.DEFAULT_PALETTE`](@ref), [`Core.MONOCHROME_PALETTE`](@ref),
  [`Core.HIGH_CONTRAST_PALETTE`](@ref) — built-in themes
- [`Core.current_palette`](@ref), [`Core.set_palette!`](@ref),
  [`Core.reset_palette!`](@ref) — palette switching
- [`Core.set_color!`](@ref) — single-role override
- [`Core.get_format_codes`](@ref) — derive styled codes for
  custom `show` methods
- [`Core.show_palette`](@ref) — interactive preview of the active palette
