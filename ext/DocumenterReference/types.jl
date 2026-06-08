"""
    DocType

Enumeration of documentation element types recognized by the API reference generator.

# Values

- `DOCTYPE_ABSTRACT_TYPE`: An abstract type declaration
- `DOCTYPE_CONSTANT`: A constant binding (including non-function, non-type values)
- `DOCTYPE_FUNCTION`: A function or callable
- `DOCTYPE_MACRO`: A macro (name starts with `@`)
- `DOCTYPE_MODULE`: A submodule
- `DOCTYPE_STRUCT`: A concrete struct type
"""
@enum(
    DocType,
    DOCTYPE_ABSTRACT_TYPE,
    DOCTYPE_CONSTANT,
    DOCTYPE_FUNCTION,
    DOCTYPE_MACRO,
    DOCTYPE_MODULE,
    DOCTYPE_STRUCT,
)

"""
    DOCTYPE_NAMES::Dict{DocType, String}

Mapping from DocType enum values to their human-readable string representations.
"""
const DOCTYPE_NAMES = Dict{DocType,String}(
    DOCTYPE_ABSTRACT_TYPE => "abstract type",
    DOCTYPE_CONSTANT => "constant",
    DOCTYPE_FUNCTION => "function",
    DOCTYPE_MACRO => "macro",
    DOCTYPE_MODULE => "module",
    DOCTYPE_STRUCT => "struct",
)

"""
    DOCTYPE_ORDER::Dict{DocType, Int}

Ordering for DocType values used when sorting symbols for display.
Lower values appear first.
"""
const DOCTYPE_ORDER = Dict{DocType,Int}(
    DOCTYPE_MODULE => 0,
    DOCTYPE_MACRO => 1,
    DOCTYPE_FUNCTION => 2,
    DOCTYPE_ABSTRACT_TYPE => 3,
    DOCTYPE_STRUCT => 4,
    DOCTYPE_CONSTANT => 5,
)

"""
    _Config

Internal configuration for API reference generation.

# Fields

- `current_module::Module`: The module being documented.
- `subdirectory::String`: Output directory for generated API pages.
- `modules::Dict{Module,Vector{String}}`: Mapping of modules to their source files.
  When a module is specified as `Module => files`, the files are stored here.
- `sort_by::Function`: Custom sort function for symbols.
- `exclude::Set{Symbol}`: Symbol names to exclude from documentation.
- `public::Bool`: Flag to generate public API page.
- `private::Bool`: Flag to generate private API page.
- `title::String`: Title displayed at the top of the generated page.
- `title_in_menu::String`: Title displayed in the navigation menu.
- `source_files::Vector{String}`: Global source file paths (fallback if no module-specific files).
- `filename::String`: Base filename (without extension) for the markdown file.
- `include_without_source::Bool`: If `true`, include symbols whose source file cannot be determined.
- `external_modules_to_document::Vector{Module}`: Additional modules to search for docstrings.
- `public_title::String`: Custom title for public API page (empty string uses default).
- `private_title::String`: Custom title for private API page (empty string uses default).
- `public_description::String`: Custom description for public API page (empty string uses default).
- `private_description::String`: Custom description for private API page (empty string uses default).
"""
struct _Config
    current_module::Module
    subdirectory::String
    modules::Dict{Module,Vector{String}}
    sort_by::Function
    exclude::Set{Symbol}
    public::Bool
    private::Bool
    title::String
    title_in_menu::String
    source_files::Vector{String}
    filename::String
    include_without_source::Bool
    external_modules_to_document::Vector{Module}
    public_title::String
    private_title::String
    public_description::String
    private_description::String
end

"""
    CONFIG::Vector{_Config}

Global configuration storage for API reference generation.

Each call to `CTBase.automatic_reference_documentation` appends a new `_Config`
entry to this vector. Use `reset_config!` to clear it between builds.
"""
const CONFIG = _Config[]

"""
    PAGE_CONTENT_ACCUMULATOR::Dict{String, Vector{Tuple{Module, Vector{String}, Vector{String}}}}

Global accumulator for multi-module combined pages.
Maps output filename to a list of (module, public_docstrings, private_docstrings) tuples.
"""
const PAGE_CONTENT_ACCUMULATOR = Dict{
    String,Vector{Tuple{Module,Vector{String},Vector{String}}}
}()
