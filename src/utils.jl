"""
$(TYPEDSIGNATURES)

Return the integer `i` ∈ [0, 9] as a Unicode **subscript character**.

Throws an `IncorrectArgument` exception if `i` is outside this range.

The Unicode subscript digits start at codepoint U+2080 for '0' and continue sequentially.
"""
function ctindice(i::Int)::Char
    if i < 0 || i > 9
        throw(IncorrectArgument("the subscript must be between 0 and 9"))
    end
    # Unicode subscript digits 0-9 are contiguous from U+2080 to U+2089
    return Char(Int('\u2080') + i)
end

"""
$(TYPEDSIGNATURES)

Return the integer `i` ≥ 0 as a string of Unicode **subscript characters**.

Throws an `IncorrectArgument` if `i` is negative.

Example:

```julia-repl
julia> ctindices(123)
"₁₂₃"
```
"""
function ctindices(i::Int)::String
    if i < 0
        throw(IncorrectArgument("the subscript must be positive"))
    end
    s = ""
    # digits returns digits from least significant to most significant,
    # so build string from right to left by prepending
    for d in digits(i)
        s = ctindice(d) * s
    end
    return s
end

"""
$(TYPEDSIGNATURES)

Return the integer `i` ∈ [0, 9] as a Unicode **superscript (upper) character**.

Throws an `IncorrectArgument` exception if `i` is outside this range.

Note: Unicode superscripts ¹ (U+00B9), ² (U+00B2), and ³ (U+00B3) are special cases.
The other digits ⁰ (U+2070) and ⁴ to ⁹ (U+2074 to U+2079) are mostly contiguous.
"""
function ctupperscript(i::Int)::Char
    if i < 0 || i > 9
        throw(IncorrectArgument("the superscript must be between 0 and 9"))
    elseif i == 0
        return '\u2070'   # superscript zero
    elseif i == 1
        return '\u00B9'   # superscript one
    elseif i == 2
        return '\u00B2'   # superscript two
    elseif i == 3
        return '\u00B3'   # superscript three
    elseif 4 <= i <= 9
        # Unicode superscript digits 4-9 contiguous starting at U+2074
        return Char(Int('\u2074') + (i - 4))
    else
        # Defensive fallback (should never occur due to prior checks)
        throw(IncorrectArgument("Invalid input for ctupperscript"))
    end
end

"""
$(TYPEDSIGNATURES)

Return the integer `i` ≥ 0 as a string of Unicode **superscript characters**.

Throws an `IncorrectArgument` exception if `i` is negative.

Example:

```julia-repl
julia> ctupperscripts(123)
"¹²³"
```
"""
function ctupperscripts(i::Int)::String
    if i < 0
        throw(IncorrectArgument("the superscript must be positive"))
    end
    s = ""
    for d in digits(i)
        s = ctupperscript(d) * s
    end
    return s
end
