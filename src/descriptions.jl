# -------------------------------------------------------------------------------------------------- 
# the description may be given as a tuple or a list of symbols (Vararg{Symbol})
makeDescription(desc::DescVarArg) = Tuple(desc) # create a description from Vararg{Symbol}
makeDescription(desc::Description) = desc

# -------------------------------------------------------------------------------------------------- 
# Possible algorithms
add(x::Tuple{}, y::Description) = (y,)
add(x::Tuple{Vararg{Description}}, y::Description) = (x..., y)

# this function transform an incomplete description to a complete one
function getFullDescription(desc::Description, desc_list)::Description
    n = length(desc_list)
    table = zeros(Int8, n, 2)
    for i in range(1, n)
        table[i, 1] = length(desc ∩ desc_list[i])
        table[i, 2] = desc ⊆ desc_list[i] ? 1 : 0
    end
    if maximum(table[:, 2]) == 0
        throw(AmbiguousDescription(desc))
    end
    # argmax : Return the index or key of the maximal element in a collection.
    # If there are multiple maximal elements, then the first one will be returned.
    # This means that the first has the priority
    return desc_list[argmax(table[:, 1])]
end

diff(x::Description, y::Description) = Tuple(setdiff(x, y))
\(x::Description, y::Description) = diff(x, y)