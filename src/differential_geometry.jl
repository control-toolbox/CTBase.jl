"""
$(TYPEDSIGNATURES)

Lie derivative of `f` along `X`.
"""
function Ad(X, f)
    return x -> ctgradient(f, x)'*X(x)
end

"""
$(TYPEDSIGNATURES)

Returns the Poisson bracket of `f` and `g`.
"""
function Poisson(f, g)
    function fg(x, p)
        n = size(x, 1)
        ff = z -> f(z[1:n], z[n+1:2n])
        gg = z -> g(z[1:n], z[n+1:2n])
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return fg
end

