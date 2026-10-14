# test/

Test suite for CTBase.jl. Tests live under `suite/` and are organised by
**functionality**, not by `src/` layout. Each test file follows the pattern
`test_<name>.jl`: a module wrapper, a `test_<name>()` entry function, and a
redefinition of that function in the outer scope so the runner can discover it.

Testing conventions and execution rules:
[ct-conventions](https://github.com/control-toolbox/ct-conventions) (rules `TST1`–`TST7`, `method.md`).
