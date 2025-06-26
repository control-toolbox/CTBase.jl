
"""
$(TYPEDEF)

Represents a 2D point with x and y coordinates.

# Fields

- `x::Float64`: The x-coordinate.
- `y::Float64`: The y-coordinate.
"""
struct Point
    x::Float64
    y::Float64
end

"""
$(TYPEDSIGNATURES)

Calculates the distance between two points.

# Arguments

- `p1::Point`: The first point.
- `p2::Point`: The second point.

# Returns

The Euclidean distance between the two points.
"""
function distance(p1::Point, p2::Point)
    return sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2)
end

"""
$(TYPEDEF)

Represents a circle with a center point and a radius.

# Fields

- `center::Point`: The center point of the circle.
- `radius::Float64`: The radius of the circle.
"""
struct Circle
    center::Point
    radius::Float64
end

"""
$(TYPEDSIGNATURES)

Calculates the area of a circle.

# Arguments

- `circle::Circle`: The circle whose area is to be calculated.

# Returns

The area of the circle.
"""
function calculate_area(circle::Circle)
    return MathConstants.π * circle.radius^2
end
