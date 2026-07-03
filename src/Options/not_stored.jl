"""
$(TYPEDEF)

Internal sentinel type used by the option extraction system to signal that an option
should not be stored in the instance.

This is returned by `extract_option` when an option has `CTBase.Core.NotProvided`
as its default and was not provided by the user.

# Note
This type is internal to the Options module and should not be used directly by users.
Use `CTBase.Core.NotProvided` instead.

See also: `CTBase.Core.NotProvided`, [`extract_option`](@ref).
"""
struct NotStoredType end

"""
    NotStored

Internal singleton instance of [`NotStoredType`](@ref).

Used internally by the option extraction system to signal that an option should not
be stored. This is distinct from `nothing` which is a valid option value.

See also: `CTBase.Core.NotProvided`, [`extract_option`](@ref).
"""
const NotStored = NotStoredType()

Base.show(io::IO, ::NotStoredType) = print(io, "NotStored")
