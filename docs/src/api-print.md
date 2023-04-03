# Print

```@meta
CurrentModule =  CTBase
```

```@autodocs
Modules = [CTBase]
Order = [:module, :constant, :type, :function, :macro]
Pages = ["print.jl"]
Private = false
```

An optimal control problem can be described as minimising the cost functional

```math
g(t_0, x(t_0), t_f, x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))~\mathrm{d}t
```

where the state $x$ and the control $u$ are functions subject, for $t \in [t_0, t_f]$,
to the differential constraint

```math
   \dot{x}(t) = f(t, x(t), u(t))
```

and other constraints such as

```math
\begin{array}{llcll}
~\xi_l  &\le& \xi(t, u(t))        &\le& \xi_u, \\
\eta_l &\le& \eta(t, x(t))       &\le& \eta_u, \\
\psi_l &\le& \psi(t, x(t), u(t)) &\le& \psi_u, \\
\phi_l &\le& \phi(t_0, x(t_0), t_f, x(t_f)) &\le& \phi_u.
\end{array}
```

Let us define the following optimal control problem.

```@example main
using CTBase

ocp = Model()

state!(ocp, 2, ["r", "v"]) # dimension of the state with the names of the components
control!(ocp, 1)           # dimension of the control
time!(ocp, [0, 1], "s")    # initial and final time, with the name of the variable time

constraint!(ocp, :initial, [-1, 0])
constraint!(ocp, :final  , [ 0, 0])
A = [ 0 1
      0 0 ]
B = [ 0
      1 ]
constraint!(ocp, :dynamics, (x, u) -> A*x + B*u)

objective!(ocp, :lagrange, (x, u) -> 0.5u^2)
nothing # hide
```

Then, we can print the form of this optimal control problem:

```@example main
ocp
```
