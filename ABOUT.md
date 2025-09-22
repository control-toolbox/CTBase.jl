## About control-toolbox

The **control-toolbox** ecosystem brings together <a href="https://julialang.org" style="display:inline-flex; align-items:center;">
  <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em" style="margin-right:0.3em;">
  Julia
</a> packages for mathematical control and its applications.  

- The root package, [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl), provides tools to model and solve optimal control problems defined by ordinary differential equations. It supports both direct and indirect methods, and can run on CPU or GPU.  

<p align="right">
  <a href="http://control-toolbox.org/OptimalControl.jl">
    <img src="https://img.shields.io/badge/Documentation-OptimalControl.jl-blue" alt="Documentation OptimalControl.jl">
  </a>
</p>

- Complementing it, [OptimalControlProblems.jl](https://github.com/control-toolbox/OptimalControlProblems.jl) offers a curated collection of benchmark optimal control problems formulated with ODEs in Julia. Each problem is available both in the **OptimalControl** DSL and in **JuMP**, with discretised versions ready to be solved using the solver of your choice. This makes the package particularly useful for benchmarking and comparing different solution strategies.  

<p align="right">
  <a href="http://control-toolbox.org/OptimalControlProblems.jl">
    <img src="https://img.shields.io/badge/Documentation-OptimalControlProblems.jl-blue" alt="Documentation OptimalControlProblems.jl">
  </a>
</p>
