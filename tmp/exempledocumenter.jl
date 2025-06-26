
"""
A struct representing a 2D point in a plane with x and y coordinates.

# Fields

- `x::Float64`: The x coordinate of the point.
- `y::Float64`: The y coordinate of the point.

# Example

```julia-repl
julia> p1 = Point(0.0, 0.0)
Point(0.0, 0.0)

julia> p2 = Point(1.0, 1.0)
Point(1.0, 1.0)

julia> distance(p1, p2)
2.23606797749979
```
"""
struct Point
    x::Float64
    y::Float64
end

"""
Calculates the Euclidean distance between two points.

# Arguments

- `p1::Point`: The first Point.
- `p2::Point`: The second Point.

# Example

```julia-repl
julia> p1 = Point(0.0, 0.0)
Point(0.0, 0.0)

julia> p2 = Point(1.0, 1.0)
Point(1.0, 1.0)

julia> distance(p1, p2)
2.23606797749979
```
"""
function distance(p1::Point, p2::Point)
    return sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2)
end

"""
A struct representing a circle with a radius.

# Fields

- `radius::Float64`: The radius of the circle.

# Example

```julia-repl
julia> circle = Circle(3.0)
Circle(3.0)
```
"""
struct Circle
    radius::Float64
end

"""
Calculates the area of a given circle.

# Arguments

- `circle::Circle`: The circle to calculate the area for.

# Example

```julia-repl
julia> circle = Circle(3.0)
Circle(3.0)

julia> calculate_area(circle)
28.27433388230814
```
"""
function calculate_area(circle::Circle)
    return MathConstants.π * circle.radius^2
end