# API Documentation Guide

This guide explains how to set up automated API reference documentation generation using the **DocumenterReference** extension of `CTBase.jl`. This is particularly useful for maintaining comprehensive and up-to-date API documentation as your codebase evolves.

## Overview

The `DocumenterReference` extension provides the `CTBase.automatic_reference_documentation()` function, which automatically generates API reference pages from your Julia source code. It:

- Extracts docstrings from your modules
- Separates public and private APIs
- Generates markdown files suitable for `Documenter.jl`
- Handles extensions and optional dependencies gracefully
- Supports filtering and customization

## Architecture

### Directory Structure

```text
docs/
├── make.jl                 # Main documentation build script
├── api_reference.jl        # API reference generation logic
└── src/
    ├── index.md           # Documentation homepage
    └── ...
```

### How It Works

The documentation generation happens in two stages:

1. **`api_reference.jl`**: Defines `generate_api_reference()` which calls `CTBase.automatic_reference_documentation()` for each module.
2. **`make.jl`**: Calls `with_api_reference()` which executes the generation and passes the pages to `Documenter.makedocs()`.

## Setting Up API Documentation

### Basic Configuration

The core function is `CTBase.automatic_reference_documentation()`. Here's a minimal example:

```julia
using CTBase
using Documenter

CTBase.automatic_reference_documentation(;
    subdirectory=".",
    primary_modules=[MyModule => ["src/MyModule.jl"]],
    title="MyModule API",
    title_in_menu="API",
    filename="api",
)
```

### Key Parameters

- **`subdirectory`**: Where to write generated markdown files (relative to `docs/src`).
- **`primary_modules`**: Vector of modules to document, optionally with source files.
  - Format: `Module` or `Module => ["path/to/file.jl"]`.
  - When source files are provided, only symbols from those files are documented.
- **`title`**: Title displayed at the top of the generated page.
- **`title_in_menu`**: Title in the navigation menu (defaults to `title`).
- **`filename`**: Base filename for the markdown file (without `.md` extension).
- **`exclude`**: Vector of symbol names to skip from documentation.
- **`public`**: Generate public API page (default: `true`).
- **`private`**: Generate private API page (default: `true`).
- **`external_modules_to_document`**: Additional modules to search for docstrings (e.g., `[Base]`).
- **`public_title`**: Custom title for public API page (empty string uses default).
- **`private_title`**: Custom title for private API page (empty string uses default).
- **`public_description`**: Custom description for public API page (empty string uses default).
- **`private_description`**: Custom description for private API page (empty string uses default).

### Public vs. Private API

The `public` and `private` flags control which symbols are documented:

#### Option 1: Public API Only (`public=true, private=false`)

```julia
CTBase.automatic_reference_documentation(;
    # ...
    public=true,
    private=false,
    title="MyModule API",
    filename="api",
)
```

**Result**: Only exported symbols are documented. This is ideal for end-user documentation.

#### Option 2: Private API Only (`public=false, private=true`)

```julia
CTBase.automatic_reference_documentation(;
    # ...
    public=false,
    private=true,
    title="MyModule Internals",
    filename="internals",
)
```

**Result**: Only non-exported (private) symbols are documented. Useful for developer documentation.

#### Option 3: Both Public and Private (`public=true, private=true`)

```julia
CTBase.automatic_reference_documentation(;
    # ...
    public=true,
    private=true,
    title="MyModule Complete Reference",
    filename="complete_api",
)
```

**Result**: If `public` and `private` are both true, the function returns a structure with two sub-pages (Public and Private).

## Customizing Page Titles and Descriptions

You can customize the titles and descriptions of generated API pages using the `public_title`, `private_title`, `public_description`, and `private_description` parameters.

### Default Behavior

By default, the system automatically generates appropriate titles based on the page type:

- **Single public page** (`public=true, private=false`): Title is "Public API"
- **Single private page** (`public=false, private=true`): Title is "Private API"
- **Split pages** (`public=true, private=true`): Titles are "Public API" and "Private API"
- **Combined page** (both public and private on same page): Title is "API reference"

### Custom Titles

Override the default titles with custom text:

```julia
CTBase.automatic_reference_documentation(;
    # ...
    public=false,
    private=true,
    private_title="Internal Implementation",
    filename="internals",
)
```

**Result**: The private page will display "Internal Implementation" instead of "Private API".

### Custom Descriptions

Customize the introductory text that appears below the title:

```julia
CTBase.automatic_reference_documentation(;
    # ...
    public=true,
    private=false,
    public_title="User API",
    public_description="This page documents the public interface for end users. All functions listed here are stable and safe to use in your applications.",
    filename="api",
)
```

**Result**: The page will show your custom title and description instead of the defaults.

### Split Pages with Custom Titles

When generating split pages, you can customize both public and private titles:

```julia
CTBase.automatic_reference_documentation(;
    # ...
    public=true,
    private=true,
    public_title="Exported Functions",
    public_description="Stable API for end users.",
    private_title="Internal Functions",
    private_description="Implementation details for contributors.",
    filename="api",
)
```

**Result**: Two pages are created with your custom titles and descriptions.

### Empty String Behavior

If you pass empty strings (the default), the system uses the standard titles and descriptions:

```julia
CTBase.automatic_reference_documentation(;
    # ...
    public_title="",        # Uses default: "Public API"
    private_title="",       # Uses default: "Private API"
    public_description="",  # Uses default description
    private_description="", # Uses default description
    # ...
)
```

This allows you to selectively customize only the titles or descriptions you want to change.

## Handling Extensions

When your package uses extensions (weak dependencies), you should check if they're loaded before documenting them in `api_reference.jl`:

```julia
# Check if the extension is loaded
MyExtension = Base.get_extension(MyPackage, :MyExtension)
if !isnothing(MyExtension)
    push!(
        pages,
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[MyExtension => ["ext/MyExtension.jl"]],
            external_modules_to_document=[MyPackage],
            # ...
            title="MyExtension",
            filename="my_extension",
        ),
    )
end
```

## Integration with Documenter.jl

In `docs/make.jl`, use `with_api_reference()` to integrate the generated pages:

```julia
using Documenter
using CTBase

include("api_reference.jl")

with_api_reference(dirname(@__DIR__)) do api_pages
    makedocs(;
        # ...
        pages=[
            "Introduction" => "index.md",
            "API Reference" => api_pages,
            # ...
        ],
    )
end
```

The `with_api_reference()` function:

1. Generates the API reference pages.
2. Passes them to your `makedocs()` call.
3. Cleans up temporary generated files after the build.

## DocType System

The `DocumenterReference` extension recognizes several documentation element types:

- **`DOCTYPE_ABSTRACT_TYPE`**: Abstract type declarations
- **`DOCTYPE_STRUCT`**: Concrete struct types
- **`DOCTYPE_FUNCTION`**: Functions and callables
- **`DOCTYPE_MACRO`**: Macros (names starting with `@`)
- **`DOCTYPE_MODULE`**: Submodules
- **`DOCTYPE_CONSTANT`**: Constants and non-function values

These types are automatically detected and organized in the generated documentation.

## Common Patterns

### Pattern 1: Main Module with Extensions

```julia
# In api_reference.jl
function generate_api_reference(src_dir)
    pages = []
    
    # Main module
    push!(pages, CTBase.automatic_reference_documentation(;
        subdirectory=".",
        primary_modules=[MyPackage => [joinpath(src_dir, "MyPackage.jl")]],
        title="MyPackage API",
        filename="api",
    ))
    
    # Check and document extensions
    for (ext_name, ext_files) in [
        (:PlotExt, ["ext/PlotExt.jl"]),
        (:OptimExt, ["ext/OptimExt.jl"])
    ]
        ext = Base.get_extension(MyPackage, ext_name)
        if !isnothing(ext)
            push!(pages, CTBase.automatic_reference_documentation(;
                subdirectory=".",
                primary_modules=[ext => ext_files],
                external_modules_to_document=[MyPackage],
                title="$ext_name Extension",
                filename=lowercase(string(ext_name)),
            ))
        end
    end
    
    return pages
end
```

### Pattern 2: Separate Public and Private Documentation

```julia
# Public API for users
push!(pages, CTBase.automatic_reference_documentation(;
    subdirectory=".",
    primary_modules=[MyPackage],
    public=true,
    private=false,
    title="Public API",
    filename="api_public",
))

# Private API for developers
push!(pages, CTBase.automatic_reference_documentation(;
    subdirectory=".",
    primary_modules=[MyPackage],
    public=false,
    private=true,
    title="Internal API",
    filename="api_private",
))
```

### Pattern 3: Filtering Unwanted Symbols

```julia
CTBase.automatic_reference_documentation(;
    subdirectory=".",
    primary_modules=[MyPackage],
    exclude=[
        "eval",           # Compiler-generated
        "include",        # Compiler-generated
        "__init__",       # Internal initialization
        "PRIVATE_CONST",  # Internal constant
    ],
    title="MyPackage API",
    filename="api",
)
```

## Troubleshooting

### Issue: Extension not documented

**Problem**: Extension exists but doesn't appear in documentation

**Solution**: Ensure the extension is loaded before generating docs:

```julia
# In docs/make.jl
using MyPackage
using OptionalDependency  # Load the extension

# Now the extension will be available
const MyExt = Base.get_extension(MyPackage, :MyExt)
```

### Issue: Docstrings not found

**Problem**: Functions are listed but have no documentation

**Solution**: Check that:
1. Docstrings are properly formatted with `"""`
2. Source files are correctly specified in `primary_modules`
3. The module is properly loaded

### Issue: Too many symbols documented

**Problem**: Documentation includes internal/generated symbols

**Solution**: Use the `exclude` parameter:

```julia
exclude=["eval", "include", "#.*"]  # Exclude compiler-generated symbols
```

### Issue: Methods from Base not showing

**Problem**: Extended Base methods don't appear

**Solution**: Add Base to `external_modules_to_document`:

```julia
external_modules_to_document=[Base, Core]
```

### Issue: ExtensionError when generating docs

**Error**: `ExtensionError: missing dependencies`

**Solution**: The DocumenterReference extension requires Documenter, Markdown, and MarkdownAST. Ensure they're in your docs environment:

```julia
# In docs/Project.toml
[deps]
Documenter = "..."
Markdown = "..."
MarkdownAST = "..."
```

## Best Practices

1. **Exclude internal symbols**: Use the `exclude` parameter to hide implementation details or compiler-generated symbols
2. **Separate public and private**: Create separate pages for public and private APIs to keep the end-user documentation focused
3. **Document external modules**: Use `external_modules_to_document` to include methods from other packages that your package extends (e.g., `Base` or `Plots`)
4. **Check extensions before documenting**: Always use `Base.get_extension()` to safely check for optional dependencies before calling `automatic_reference_documentation` on them
5. **Use meaningful titles**: Choose clear, descriptive titles for each documentation page
6. **Organize by module**: Group related functionality together
7. **Keep it up-to-date**: Regenerate documentation with each release
8. **Test documentation builds**: Include documentation building in your CI pipeline

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Documentation
on:
  push:
    branches: [main]
    tags: ['*']
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@v1
      - name: Install dependencies
        run: julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
      - name: Build documentation
        run: julia --project=docs docs/make.jl
      - name: Deploy to GitHub Pages
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/build
```

## Summary

The `DocumenterReference` extension provides a powerful, flexible system for automatically generating API documentation. By following the patterns shown in this guide, you can maintain comprehensive, up-to-date documentation with minimal manual effort.

## See Also

- [Exception Handling](exceptions.md): Documenting exception types
- [Test Runner Guide](test-runner.md): Testing documentation examples
- [Coverage Guide](coverage.md): Ensuring documentation coverage
