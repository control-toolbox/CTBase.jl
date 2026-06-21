# src/

Source code of CTBase.jl. Organised as **one submodule per responsibility**: each
subdirectory contains a manifest file (`SubModule.jl`) and its implementation files.
The package top-level (`CTBase.jl`) exports **nothing** — all symbols are accessed via
qualified paths (`CTBase.SubModule.symbol`).

Conventions: [control-toolbox Handbook](https://github.com/control-toolbox/Handbook).
