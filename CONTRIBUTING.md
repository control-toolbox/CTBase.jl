## Contributing

[issue-url]: https://github.com/control-toolbox/CTBase.jl/issues
[first-good-issue-url]: https://github.com/control-toolbox/CTBase.jl/contribute

If you think you found a bug or if you have a feature request / suggestion, feel free to open an [issue][issue-url].  
Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions). You can find first good issues (if any 🙂) [here][first-good-issue-url]. You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).

>[!NOTE]
> If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).

---

## Developer Resources

The [control-toolbox Handbook](https://github.com/control-toolbox/Handbook) (philosophy, rules, plan template, CI/CD conventions) is a git submodule in `.handbook/`, pinned to a SemVer release tag. Clone with `git clone --recurse-submodules`, or run `git submodule update --init` in an existing clone.

To bump it, run `git -C .handbook fetch --tags && git -C .handbook checkout <tag>`, then commit the updated pointer.
