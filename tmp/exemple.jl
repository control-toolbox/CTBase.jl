
struct Point
    x::Float64
    y::Float64
end

function distance(p1::Point, p2::Point)
    return sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2)
end

struct Circle
    center::Point
    radius::Float64
end

function calculate_area(circle::Circle)
    return MathConstants.π * circle.radius^2
end