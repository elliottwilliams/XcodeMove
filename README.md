# XcodeMove

**`xcmv`** is a command that works like `mv`, but moves files between Xcode
projects as well as the filesystem. This makes it easy to bulk-move files
between projects.

## Usage

Use xcmv like mv. However, some optional arguments allow for customization of
the file's reference in the destination project.

```sh
$ xcmv -h
Usage: xcmv src_file [...] dst_file
        --git=[true|false]           Use `git mv` (default: true if in a git repo)
    -t, --targets=[TARGETS]          Comma-separated list of targets to add moved files to (default: guess)
    -h, --headers=[HEADERS]          Visibility level of moved header files (default: `public` for frameworks, `project` otherwise)
        --help                       This help message
    -v, --version
```

## Assumptions

* A source file is already in an xcode project
* The `.xcodeproj` file for a source file can be found by traversing up through
  the filesystem
