<div align="center">

# asdf-lefthook [![Build](https://github.com/jtzero/asdf-lefthook/actions/workflows/build.yml/badge.svg)](https://github.com/jtzero/asdf-lefthook/actions/workflows/build.yml) [![Lint](https://github.com/jtzero/asdf-lefthook/actions/workflows/lint.yml/badge.svg)](https://github.com/jtzero/asdf-lefthook/actions/workflows/lint.yml)

[lefthook](https://github.com/evilmartians/lefthook.git) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies


- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).

# Install

Plugin:

```shell
asdf plugin add lefthook
# or
asdf plugin add lefthook https://github.com/jtzero/asdf-lefthook.git
```

lefthook:

```shell
# Show all installable versions
asdf list-all lefthook

# Install specific version
asdf install lefthook latest

# Set a version globally (on your ~/.tool-versions file)
asdf global lefthook latest

# Now lefthook commands are available
lefthook --help
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/jtzero/asdf-lefthook/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [jtzero <jtzero511@gmail.com>](https://github.com/jtzero/)
