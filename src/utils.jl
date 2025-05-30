"""
$(TYPEDSIGNATURES)

Return `i` ∈ [0, 9] as a subscript.

If `i` is not in the range, an exception is thrown.
"""
function ctindice(i::Int)::Char
    if i < 0 || i > 9
        throw(IncorrectArgument("the indice must be between 0 and 9"))
    end
    return '\u2080' + i
end

"""
$(TYPEDSIGNATURES)

Return `i` > 0 as a subscript.

If `i` is not in the range, an exception is thrown.
"""
function ctindices(i::Int)::String
    if i < 0
        throw(IncorrectArgument("the indice must be positive"))
    end
    s = ""
    for d in digits(i)
        s = ctindice(d) * s
    end
    return s
end

"""
$(TYPEDSIGNATURES)

Return `i` ∈ [0, 9] as an upperscript.

If `i` is not in the range, an exception is thrown.
"""
function ctupperscript(i::Int)::Char
    if i < 0 || i > 9
        throw(IncorrectArgument("the upperscript must be between 0 and 9"))
    end
    if i == 0
        return '\u2070'
    end
    if i == 1
        return '\u00B9'
    end
    if i == 2
        return '\u00B2'
    end
    if i == 3
        return '\u00B3'
    end
    if i ≥ 4
        return '\u2074' + i - 4
    end
end

"""
$(TYPEDSIGNATURES)

Return `i` > 0 as an upperscript.

If `i` is not in the range, an exception is thrown.
"""
function ctupperscripts(i::Int)::String
    if i < 0
        throw(IncorrectArgument("the upperscript must be positive"))
    end
    s = ""
    for d in digits(i)
        s = ctupperscript(d) * s
    end
    return s
end
