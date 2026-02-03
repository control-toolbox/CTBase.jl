# Error Handling and CTBase Exceptions

CTBase defines a small hierarchy of domain-specific exceptions to make error
handling explicit and consistent across the control-toolbox ecosystem.

All custom exceptions inherit from `CTBase.CTException`:

```julia
abstract type CTBase.CTException <: Exception end
```

## Exception Hierarchy

```
CTException (abstract)
├── IncorrectArgument      # Input validation errors
├── PreconditionError      # Order of operations, state validation
├── NotImplemented         # Unimplemented interface methods
├── ParsingError           # Parsing errors
├── AmbiguousDescription   # Ambiguous or incorrect descriptions
└── ExtensionError         # Missing optional dependencies
```
