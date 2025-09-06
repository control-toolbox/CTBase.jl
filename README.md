# CTBase.jl

[ci-img]: https://github.com/control-toolbox/CTBase.jl/actions/workflows/CI.yml/badge.svg?branch=main
[ci-url]: https://github.com/control-toolbox/CTBase.jl/actions/workflows/CI.yml?query=branch%3Amain

[co-img]: https://codecov.io/gh/control-toolbox/CTBase.jl/branch/main/graph/badge.svg?token=YM5YQQUSO3
[co-url]: https://codecov.io/gh/control-toolbox/CTBase.jl

[doc-dev-img]: https://img.shields.io/badge/docs-dev-8A2BE2.svg
[doc-dev-url]: https://control-toolbox.org/CTBase.jl/dev/

[doc-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[doc-stable-url]: https://control-toolbox.org/CTBase.jl/stable/

[release-img]: https://juliahub.com/docs/General/CTBase/stable/version.svg
[release-url]: https://github.com/control-toolbox/CTBase.jl/releases

[pkg-eval-img]: https://img.shields.io/badge/Julia-package-purple
[pkg-eval-url]: https://juliahub.com/ui/Packages/General/CTBase

[deps-img]: https://juliahub.com/docs/General/CTBase/stable/deps.svg
[deps-url]: https://juliahub.com/ui/Packages/General/CTBase?t=2

[licence-img]: https://img.shields.io/badge/License-MIT-yellow.svg
[licence-url]: https://github.com/control-toolbox/CTBase.jl/blob/master/LICENSE

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl

[blue-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[blue-url]: https://github.com/JuliaDiff/BlueStyle

The CTBase.jl package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox). 

| **Name**          | **Badge**         |
:-------------------|:------------------|
| Documentation     | [![Documentation][doc-stable-img]][doc-stable-url] [![Documentation][doc-dev-img]][doc-dev-url]                   | 
| Code Status       | [![Build Status][ci-img]][ci-url] [![Covering Status][co-img]][co-url] [![Aqua.jl][aqua-img]][aqua-url] [![Code Style: Blue][blue-img]][blue-url] [![pkgeval][pkg-eval-img]][pkg-eval-url] |
| Dependencies      | [![deps][deps-img]][deps-url] |
| Licence           | [![License: MIT][licence-img]][licence-url]   |
| Release           | [![Release][release-img]][release-url]        |

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

## Installation

To install CTBase please 
<a href="https://docs.julialang.org/en/v1/manual/getting-started/">open Julia's interactive session (known as REPL)</a> 
and press <kbd>]</kbd> key in the REPL to use the package mode, then add the package:

```julia
julia> ]
pkg> add CTBase
```

> [!TIP]
> If you are new to Julia, please follow this [guidelines](https://github.com/orgs/control-toolbox/discussions/64).

## Contributing

[issue-url]: https://github.com/control-toolbox/CTBase.jl/issues
[first-good-issue-url]: https://github.com/control-toolbox/CTBase.jl/contribute

If you think you found a bug or if you have a feature request / suggestion, feel free to open an [issue][issue-url].
Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). 
If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions).
You can find first good issues (if any 🙂) [here][first-good-issue-url]. You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).

>[!NOTE]
> If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).
