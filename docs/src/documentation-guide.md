# Documentation Guide

This guide explains how to set up automated API reference documentation generation using the `DocumenterReference` extension. This is particularly useful for maintaining comprehensive and up-to-date API documentation as your codebase evolves.

## Overview

The `DocumenterReference` extension provides the `CTBase.automatic_reference_documentation()` function, which automatically generates API reference pages from your Julia source code. It:

- Extracts docstrings from your modules
- Separates public and private APIs
- Generates markdown files suitable for Documenter.jl
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
    ├── developers-guide.md # Testing and coverage guide
    └── documentation-guide.md  # This file
```

### How It Works

The documentation generation happens in two stages:

1. **`api_reference.jl`**: Defines `generate_api_reference()` which calls `CTBase.automatic_reference_documentation()` for each module
2. **`make.jl`**: Calls `with_api_reference()` which executes the generation and passes the pages to `Documenter.makedocs()`

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

- **`subdirectory`**: Where to write generated markdown files (relative to `docs/src`)
- **`primary_modules`**: Vector of modules to document, optionally with source files
  - Format: `Module` or `Module => ["path/to/file.jl"]`
  - When source files are provided, only symbols from those files are documented
- **`title`**: Title displayed at the top of the generated page
- **`title_in_menu`**: Title in the navigation menu (defaults to `title`)
- **`filename`**: Base filename for the markdown file (without `.md` extension)
- **`exclude`**: Vector of symbol names to skip from documentation
- **`public`**: Generate public API page (default: `true`)
- **`private`**: Generate private API page (default: `true`)
- **`external_modules_to_document`**: Additional modules to search for docstrings (e.g., `[Base]`)

### Public vs. Private API

The `public` and `private` flags control which symbols are documented:

#### Option 1: Public API Only (`public=true, private=false`)

```julia
CTBase.automatic_reference_documentation(;
    subdirectory=".",
    primary_modules=[MyModule => src("MyModule.jl")],
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
    subdirectory=".",
    primary_modules=[MyModule => src("MyModule.jl")],
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
    subdirectory=".",
    primary_modules=[MyModule => src("MyModule.jl")],
    public=true,
    private=true,
    title="MyModule Complete Reference",
    filename="complete_api",
)
```

**Result**: All symbols are documented in a single page. This provides a comprehensive reference.

### Example: CTBase Configuration

Here's how CTBase configures its API documentation in `docs/api_reference.jl`:

```julia
function generate_api_reference(src_dir::String)
    # Helper functions to build absolute paths
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    ext_dir = abspath(joinpath(src_dir, "..", "ext"))
    ext(files...) = [abspath(joinpath(ext_dir, f)) for f in files]

    # Symbols to exclude from all API pages
    EXCLUDE_SYMBOLS = Symbol[:include, :eval]

    pages = [
        # Main CTBase module - private API only
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[CTBase => src("CTBase.jl")],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="CTBase",
            title_in_menu="CTBase",
            filename="ctbase",
        ),
        # Other modules...
    ]

    # Extensions are checked with Base.get_extension
    DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
    if !isnothing(DocumenterReference)
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory=".",
                primary_modules=[DocumenterReference => ext("DocumenterReference.jl")],
                external_modules_to_document=[CTBase],
                exclude=EXCLUDE_SYMBOLS,
                public=false,
                private=true,
                title="DocumenterReference",
                title_in_menu="DocumenterReference",
                filename="documenter_reference",
            ),
        )
    end

    return pages
end
```

## Handling Extensions

When your package uses extensions (weak dependencies), you need to check if they're loaded before documenting them:

```julia
# Check if the extension is loaded
MyExtension = Base.get_extension(MyPackage, :MyExtension)
if !isnothing(MyExtension)
    push!(
        pages,
        CTBase.automatic_reference_documentation(;
            subdirectory=".",
            primary_modules=[MyExtension => ext("MyExtension.jl")],
            external_modules_to_document=[MyPackage],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="MyExtension",
            title_in_menu="MyExtension",
            filename="my_extension",
        ),
    )
end
```

This ensures that:

- Documentation is only generated if the extension is actually loaded
- The extension can reference types and functions from the main package via `external_modules_to_document`

## Integration with Documenter.jl

In `docs/make.jl`, use `with_api_reference()` to integrate the generated pages:

```julia
using Documenter
using CTBase

include("api_reference.jl")

with_api_reference(dirname(@__DIR__)) do api_pages
    makedocs(;
        modules=[CTBase],
        authors="Your Name",
        repo="https://github.com/yourname/yourpackage.jl",
        sitename="YourPackage.jl",
        format=Documenter.HTML(;
            assets=String[],
        ),
        pages=[
            "Introduction" => "index.md",
            "Developers Guide" => "developers-guide.md",
            "Documentation Guide" => "documentation-guide.md",
            "API Reference" => api_pages,
        ],
        checkdocs=:none,
    )
end
```

The `with_api_reference()` function:

1. Generates the API reference pages
2. Passes them to your `makedocs()` call
3. Cleans up temporary generated files after the build

## DocType System

The `DocumenterReference` extension recognizes several documentation element types:

- **`DOCTYPE_ABSTRACT_TYPE`**: Abstract type declarations
- **`DOCTYPE_STRUCT`**: Concrete struct types
- **`DOCTYPE_FUNCTION`**: Functions and callables
- **`DOCTYPE_MACRO`**: Macros (names starting with `@`)
- **`DOCTYPE_MODULE`**: Submodules
- **`DOCTYPE_CONSTANT`**: Constants and non-function values

These types are automatically detected and organized in the generated documentation.

## Best Practices

1. **Exclude internal symbols**: Use the `exclude` parameter to hide implementation details

   ```julia
   exclude=Symbol[:_internal_helper, :_private_constant]
   ```

2. **Separate public and private**: Create separate pages for public and private APIs

   ```julia
   # Public API
   CTBase.automatic_reference_documentation(;
       ...,
       public=true,
       private=false,
       filename="api_public",
   )
   # Private API
   CTBase.automatic_reference_documentation(;
       ...,
       public=false,
       private=true,
       filename="api_private",
   )
   ```

3. **Document external modules**: Use `external_modules_to_document` to include methods from other packages

   ```julia
   CTBase.automatic_reference_documentation(;
       ...,
       external_modules_to_document=[Base, Documenter],
   )
   ```

4. **Check extensions before documenting**: Always use `Base.get_extension()` to safely check for optional dependencies

   ```julia
   MyExt = Base.get_extension(MyPackage, :MyExtension)
   if !isnothing(MyExt)
       # Document the extension
   end
   ```

## Troubleshooting

### Missing Docstrings

If symbols appear without docstrings in the generated documentation, ensure:

- The docstring is defined immediately before the symbol
- The docstring uses the correct Julia docstring syntax (triple quotes)
- The symbol is actually exported or included in your module

### Symbols Not Appearing

If expected symbols don't appear in the documentation:

- Check if they're in the `exclude` list
- Verify the source file path is correct
- Ensure the symbol is defined in the specified source file (not imported)

### Extension Not Documented

If an extension's documentation isn't generated:

- Verify the extension is loaded with `Base.get_extension()`
- Check that the extension file path is correct
- Ensure the extension module is properly defined

## Summary

The `DocumenterReference` extension provides a powerful, flexible system for automatically generating API documentation. By following the patterns shown in this guide, you can maintain comprehensive, up-to-date documentation with minimal manual effort.
