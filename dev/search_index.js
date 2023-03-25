var documenterSearchIndex = {"docs":
[{"location":"api.html","page":"API","title":"API","text":"CurrentModule = CTBase ","category":"page"},{"location":"api.html","page":"API","title":"API","text":"Pages = [\"api.md\"]","category":"page"},{"location":"api.html#API","page":"API","title":"API","text":"","category":"section"},{"location":"api.html","page":"API","title":"API","text":"This page is a dump of all the docstrings found in the code. ","category":"page"},{"location":"api.html","page":"API","title":"API","text":"Modules = [CTBase]\nOrder = [:module, :type, :function, :macro]","category":"page"},{"location":"api.html#CTBase.constraint!","page":"API","title":"CTBase.constraint!","text":"constraint!(ocp, type, val)\nconstraint!(ocp, type, val, label)\n\n\nAdd an :initial or :final value constraint on the state.\n\nExamples\n\njulia> constraint!(ocp, :initial, [ 0, 0, 0 ])\njulia> constraint!(ocp, :final, [ 0, 0, 0 ])\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.constraint!-2","page":"API","title":"CTBase.constraint!","text":"constraint!(ocp, type, f, val)\nconstraint!(ocp, type, f, val, label)\n\n\nAdd a :boundary, :control, :state or :mixed value functional constraint.\n\nExamples\n\njulia> constraint!(ocp, :boundary, f, [ 0, 0 ])\njulia> constraint!(ocp, :control, f, [ 0, 0 ])\njulia> constraint!(ocp, :state, f, [ 0, 0 ])\njulia> constraint!(ocp, :mixed, f, [ 0, 0 ])\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.constraint!-3","page":"API","title":"CTBase.constraint!","text":"constraint!(ocp, type, rg, lb, ub)\nconstraint!(ocp, type, rg, lb, ub, label)\n\n\nAdd an :initial, :final, :control or :state box constraint on a range.\n\nExamples\n\njulia> constraint!(ocp, :initial, 2:3, [ 0, 0 ], [1, 2])\njulia> constraint!(ocp, :final, Index(1), 0, 2)\njulia> constraint!(ocp, :control, Index(1), 0, 2)\njulia> constraint!(ocp, :state, 2:3, [ 0, 0 ], [1, 2])\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.constraint!-4","page":"API","title":"CTBase.constraint!","text":"constraint!(ocp, type, f, lb, ub)\nconstraint!(ocp, type, f, lb, ub, label)\n\n\nAdd a :boundary, :control, :state or :mixed box functional constraint.\n\nExamples\n\njulia> constraint!(ocp, :boundary, f, [ 0, 0 ], [ 1, 2 ])\njulia> constraint!(ocp, :control, f, [ 0, 0 ], [ 1, 2 ])\njulia> constraint!(ocp, :state, f, [ 0, 0 ], [ 1, 2 ])\njulia> constraint!(ocp, :mixed, f, [ 0, 0 ], [ 1, 2 ])\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.constraint!-5","page":"API","title":"CTBase.constraint!","text":"constraint!(ocp, type, rg, val)\nconstraint!(ocp, type, rg, val, label)\n\n\nAdd an :initial or :final value constraint on a range of the state.\n\nExamples\n\njulia> constraint!(ocp, :initial, 2:3, [ 0, 0 ])\njulia> constraint!(ocp, :final, Index(1), 0)\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.constraint!-6","page":"API","title":"CTBase.constraint!","text":"constraint!(ocp, type, lb, ub)\nconstraint!(ocp, type, lb, ub, label)\n\n\nAdd an :initial, :final, :control or :state box constraint (whole range).\n\nExamples\n\njulia> constraint!(ocp, :initial, [ 0, 0, 0 ], [ 1, 2, 1 ])\njulia> constraint!(ocp, :final, [ 0, 0, 0 ], [ 1, 2, 1 ])\njulia> constraint!(ocp, :control, [ 0, 0 ], [ 2, 3 ])\njulia> constraint!(ocp, :state, [ 0, 0, 0 ], [ 1, 2, 1 ])\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.constraint!-Union{Tuple{dimension_usage}, Tuple{time_dependence}, Tuple{OptimalControlModel{time_dependence, dimension_usage}, Symbol, Function}} where {time_dependence, dimension_usage}","page":"API","title":"CTBase.constraint!","text":"constraint!(ocp, type, f)\n\n\nProvide dynamics (possibly in place).\n\nExamples\n\njulia> constraint!(ocp, :dynamics, f)\njulia> constraint!(ocp, :dynamics!, f!)\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.constraint-Tuple{OptimalControlModel, Symbol}","page":"API","title":"CTBase.constraint","text":"constraint(ocp, label)\n\n\nRetrieve a labeled constraint. The result is a function associated with the constraint computation (not taking into account provided value / bounds).\n\nExamples\n\njulia> constraint(ocp, :con)\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.constraint_type-NTuple{6, Any}","page":"API","title":"CTBase.constraint_type","text":"constraint_type(e, t, t0, tf, x, u)\n\n\nReturn the type constraint among  :initial, :final, :boundary, :control_range, :control_fun, :state_range, :state_fun, :mixed (:other otherwise), together with the appropriate value (range or updated expression).\n\nExample\n\njulia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;\n\njulia> constraint_type(:( x[1:2](0) ), t, t0, tf, x, u)\n(:initial, 1:2)\n\njulia> constraint_type(:( x[1](0) ), t, t0, tf, x, u)\n(:initial, Index(1))\n\njulia> constraint_type(:( 2x[1](0)^2 ), t, t0, tf, x, u)\n(:boundary, :(2 * var\"x#0\"[1] ^ 2))\n\njulia> constraint_type(:( x[1:2](tf) ), t, t0, tf, x, u)\n(:final, 1:2)\n\njulia> constraint_type(:( x[1](tf) ), t, t0, tf, x, u)\n(:final, Index(1))\n\njulia> constraint_type(:( 2x[1](tf)^2 ), t, t0, tf, x, u)\n(:boundary, :(2 * var\"x#f\"[1] ^ 2))\n\njulia> constraint_type(:( x[1](tf) - x[2](0) ), t, t0, tf, x, u)\n(:boundary, :(var\"x#f\"[1] - var\"x#0\"[2]))\n\njulia> constraint_type(:( u[1:2](t) ), t, t0, tf, x, u)\n(:control_range, 1:2)\n\njulia> constraint_type(:( u[1](t) ), t, t0, tf, x, u)\n(:control_range, Index(1))\n\njulia> constraint_type(:( 2u[1](t)^2 ), t, t0, tf, x, u)\n(:control_fun, :(2 * u[1] ^ 2))\n\njulia> constraint_type(:( x[1:2](t) ), t, t0, tf, x, u)\n(:state_range, 1:2)\n\njulia> constraint_type(:( x[1](t) ), t, t0, tf, x, u)\n(:state_range, Index(1))\n\njulia> constraint_type(:( 2x[1](t)^2 ), t, t0, tf, x, u)\n(:state_fun, :(2 * x[1] ^ 2))\n\njulia> constraint_type(:( 2u[1](t)^2 * x(t) ), t, t0, tf, x, u)\n(:mixed, :((2 * u[1] ^ 2) * x))\n\njulia> constraint_type(:( 2u[1](0)^2 * x(t) ), t, t0, tf, x, u)\n:other\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.control!","page":"API","title":"CTBase.control!","text":"control!(ocp, m)\ncontrol!(ocp, m, labels)\n\n\nDefine the control dimension and possibly the names of each coordinate.\n\nExamples\n\njulia> control!(ocp, 2, [ \"u₁\", \"u₂\" ])\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.expr_it-Tuple{Any, Any, Any}","page":"API","title":"CTBase.expr_it","text":"expr_it(e, _Expr, f)\n\n\nExpr iterator: apply _Expr to nodes and f to leaves of the AST.\n\nExample\n\njulia> id(e) = expr_it(e, Expr, x -> x)\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.get-Tuple{OptimalControlSolution, Union{Symbol, Tuple{Symbol, Integer}}}","page":"API","title":"CTBase.get","text":"get(sol::UncFreeXfSolution, xx::Union{Symbol, Tuple{Symbol, Integer}})\n\nTBW\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.has-Tuple{Any, Any, Any}","page":"API","title":"CTBase.has","text":"has(e, x, t)\n\n\nReturn true if e contains an x(t), x[i](t) or x[i:j](t) call.\n\nExample\n\njulia> e = :( ∫( x[1](t)^2 + 2*u(t) ) → min )\n:(∫((x[1])(t) ^ 2 + 2 * u(t)) → min)\n\njulia> has(e, :x, :t)\ntrue\n\njulia> has(e, :u, :t)\ntrue\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.nlp_constraints-Union{Tuple{OptimalControlModel{time_dependence, dimension_usage}}, Tuple{dimension_usage}, Tuple{time_dependence}} where {time_dependence, dimension_usage}","page":"API","title":"CTBase.nlp_constraints","text":"nlp_constraints(ocp)\n\n\nReturn a 6-tuple of tuples:\n\n(ξl, ξ, ξu) are control constraints\n(ηl, η, ηu) are state constraints\n(ψl, ψ, ψu) are mixed constraints\n(ϕl, ϕ, ϕu) are boundary constraints\n(ulb, uind, uub) are control linear constraints of a subset of indices\n(xlb, xind, xub) are state linear constraints of a subset of indices\n\nExamples\n\njulia> (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.objective!-Union{Tuple{dimension_usage}, Tuple{time_dependence}, Tuple{OptimalControlModel{time_dependence, dimension_usage}, Symbol, Function}, Tuple{OptimalControlModel{time_dependence, dimension_usage}, Symbol, Function, Symbol}} where {time_dependence, dimension_usage}","page":"API","title":"CTBase.objective!","text":"objective!(ocp, type, f)\nobjective!(ocp, type, f, criterion)\n\n\nSet the criterion to the function f. Type can be :mayer or :lagrange. Criterion is :min or :max.\n\nExamples\n\njulia> objective!(ocp, (t0, x0, tf, xf) -> tf, :mayer) \n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.remove_constraint!-Tuple{OptimalControlModel, Symbol}","page":"API","title":"CTBase.remove_constraint!","text":"remove_constraint!(ocp, label)\n\n\nRemove a labeled constraint.\n\nExamples\n\njulia> remove_constraint!(ocp, :con)\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.replace_call-NTuple{4, Any}","page":"API","title":"CTBase.replace_call","text":"replace_call(e, x, t, y)\n\n\nReplace calls in e such as x(t), x[i](t) or x[i:j](t) by y, y[i](t) or y[i:j](t), resp.\n\nExample\n\n\njulia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;\n\njulia> e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )\n:((x[1])(0) * (2 * x(tf)) - (x[2])(tf) * (2 * x(0)))\n\njulia> x0 = Symbol(x, 0); e = replace_call(e, x, t0, x0)\n:(x0[1] * (2 * x(tf)) - (x[2])(tf) * (2x0))\n\njulia> xf = Symbol(x, \"f\"); replace_call(ans, x, tf, xf)\n:(x0[1] * (2xf) - xf[2] * (2x0))\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.state!","page":"API","title":"CTBase.state!","text":"state!(ocp, n)\nstate!(ocp, n, labels)\n\n\nDefine the state dimension and possibly the names of each coordinate.\n\nExamples\n\njulia> state!(ocp, 2, [ \"x₁\", \"x₂\" ])\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.subs-Tuple{Any, Union{Real, Symbol}, Any}","page":"API","title":"CTBase.subs","text":"subs(e, e1, e2)\n\n\nSubstitute expression e1 by expression e2 in expression e.\n\nExamples\n\njulia> e = :( ∫( r(t)^2 + 2u₁(t)) → min )\n:(∫(r(t) ^ 2 + 2 * u₁(t)) → min)\n\njulia> subs(e, :r, :( x[1] ))\n:(∫((x[1])(t) ^ 2 + 2 * u₁(t)) → min)\n\njulia> e = :( ∫( u₁(t)^2 + 2u₂(t)) → min )\n:(∫(u₁(t) ^ 2 + 2 * u₂(t)) → min)\n\njulia> for i ∈ 1:2\n       e = subs(e, Symbol(:u, Char(8320+i)), :( u[$i] ))\n       end; e\n:(∫((u[1])(t) ^ 2 + 2 * (u[2])(t)) → min)\n\njulia> t = :t; t0 = 0; tf = :tf; x = :x; u = :u;\n\njulia> e = :( x[1](0) * 2x(tf) - x[2](tf) * 2x(0) )\n:((x[1])(0) * (2 * x(tf)) - (x[2])(tf) * (2 * x(0)))\n\njulia> x0 = Symbol(x, 0); subs(e, :( $x[1]($(t0)) ), :( $x0[1] ))\n\n\n\n\n\n","category":"method"},{"location":"api.html#CTBase.time!","page":"API","title":"CTBase.time!","text":"time!(ocp, times)\ntime!(ocp, times, label)\n\n\nFix initial and final times to t[1] and t[2], respectively.\n\nExamples\n\n```jldoctest julia> time!(ocp, [ 0, 1 ], \"t\")\n\n\n\n\n\n","category":"function"},{"location":"api.html#CTBase.time!-2","page":"API","title":"CTBase.time!","text":"time!(ocp, type, time)\ntime!(ocp, type, time, label)\n\n\nFix initial (resp. final) time, the final (resp. initial) time being variable (free), when type is :initial. And conversely when type is :final. \n\nExamples\n\n```jldoctest julia> time!(ocp, :initial, 0, \"t\") julia> time!(ocp, :final, 1, \"t\")\n\n\n\n\n\n","category":"function"},{"location":"index.html#CTBase.jl","page":"Introduction","title":"CTBase.jl","text":"","category":"section"},{"location":"index.html#Overview","page":"Introduction","title":"Overview","text":"","category":"section"},{"location":"index.html","page":"Introduction","title":"Introduction","text":"This package implements the basic operations on a control problem, most notably the definition of an optimal control problem.","category":"page"}]
}
