# bedtools for Windows: Unofficial Community Build

This repository provides an unofficial Windows build of
[bedtools](https://github.com/arq5x/bedtools2) v2.31.1.

bedtools is a command-line toolkit for genomic interval operations. The
upstream project is primarily built for Unix-like environments. This repository
vendors the bedtools2 source tree and applies a small MSYS2-UCRT64
compatibility patch so that `bedtools.exe` can be built and used on Windows.

These builds are not produced, endorsed, or supported by the upstream bedtools
project. For bedtools itself, see the upstream repository:

https://github.com/arq5x/bedtools2

## Downloading bedtools for Windows

Prebuilt Windows binaries are available from the
[Releases](https://github.com/win-ngs/bedtools-windows-build/releases) page of
this repository.

Download the latest release archive, for example:

```text
bedtools-2.31.1-windows-ucrt64.zip
```

After extracting the archive, you should see:

```text
bedtools-2.31.1-windows-ucrt64/
  bedtools.exe
  libbz2-1.dll
  libgcc_s_seh-1.dll
  liblzma-5.dll
  libstdc++-6.dll
  libwinpthread-1.dll
  zlib1.dll
  README.md
  LICENSE.md
  THIRD_PARTY_NOTICES.txt
  LICENSES/
```

Keep the DLL files in the same folder as `bedtools.exe`.

## How to Use

This Windows build uses the same command-line options as upstream bedtools. For
detailed usage, options, and examples, refer to the upstream bedtools
documentation:

https://bedtools.readthedocs.io/

Example:

```powershell
cd C:\Users\you\Downloads\bedtools-2.31.1-windows-ucrt64
.\bedtools.exe --version
.\bedtools.exe --help
```

Sort a BED file from standard input:

```powershell
"chr1`t5`t10`nchr1`t1`t3" | .\bedtools.exe sort -i -
```

Keep the extracted files together. Do not move only `bedtools.exe` to another
folder, because the `.dll` files in the ZIP are needed for the program to
start.

## Source Tree

The patched source tree is included in this repository:

```text
bedtools2/
```

The upstream bedtools README and license are kept inside that directory:

```text
bedtools2/README.md
bedtools2/LICENSE
```

Build outputs such as `bedtools2/bin/bedtools.exe`, `bedtools2/obj/`, and
release ZIP files are not meant to be committed to git.

## Building from Source

You do not need to build bedtools yourself if you only want to use the released
Windows binary. This section is for maintainers or users who want to recreate
the build.

Install [MSYS2](https://www.msys2.org/) first. Open an MSYS2-UCRT64 shell and
install the build tools and runtime dependencies:

```sh
pacman -S --needed \
  base-devel \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-bzip2 \
  mingw-w64-ucrt-x86_64-xz \
  mingw-w64-ucrt-x86_64-zlib
```

Build bedtools:

```sh
cd /c/path/to/bedtools-windows-build/bedtools2
make -j2
```

The executable is created as:

```text
bedtools2/bin/bedtools.exe
```

## Validation Performed

This patched build was checked with MSYS2-UCRT64 using:

```text
g++ 16.1.0
bedtools v2.31.1
```

The following checks were run:

```text
make clean
make -j2
bedtools.exe --version
bedtools sort smoke test
```

## MSYS2-UCRT64 Compatibility Patch

The upstream bedtools v2.31.1 source did not compile unchanged in MSYS2-UCRT64
with GCC 16.1.0. The patch is limited to Windows/MSYS2 compatibility fixes:

| Area | Change | Reason |
|---|---|---|
| C/C++ fixed-width integer headers | Added direct `<stdint.h>` includes where public fixed-width integer types are used | GCC 16/UCRT64 no longer provides these typedefs reliably through unrelated indirect includes |
| `coverageFile` formatting | Replaced GNU `asprintf()` formatting with C++ stream formatting | MinGW/UCRT64 does not provide GNU `asprintf()` |
| large-file offset support | Replaced `__int64_t` with `int64_t` for Windows `off_type` | `__int64_t` is not a portable MinGW/UCRT64 type name |
| Fisher exact support | Added a local `M_SQRT2` fallback | MinGW/UCRT64 does not expose this POSIX math constant by default |
| regression test helper | Used `_mkdir()` on Windows | MinGW's `mkdir()` takes only a path argument |
| vendored htslib | Kept Windows builds on htslib's bundled `drand48` fallback | MinGW/UCRT64 lacks `drand48()` |
| linking | Added `-lws2_32` for MinGW builds | htslib's socket helpers reference Winsock APIs |

The modified source locations include comments explaining the Windows/UCRT64
change.

## MSYS2-UCRT64 Runtime Path Review

The following review is separate from the compile-fix patch above. MSYS2-UCRT64
produces native Windows executables, so code that compiles successfully can
still have runtime problems if it assumes POSIX path or process behavior.

The source tree was searched for patterns that commonly cause UCRT64 runtime
issues, including external command dispatch, manual `PATH` parsing, executable
permission checks, POSIX-only process APIs, and helpers that only treat `/` as a
path separator.

One Windows path handling fix was made as part of this review:

| Area | Change | Reason |
|---|---|---|
| `multiinter` filename helper | Replaced POSIX `basename()` use with string handling that accepts both `/` and `\` | Native Windows paths such as `C:\data\a.bed` must not be treated as a single basename |
| `unionbedg` filename helper | Replaced POSIX `basename()` use with string handling that accepts both `/` and `\` | Same UCRT64 path separator issue |

The modified source locations include comments explaining that the change is
for native Windows/UCRT64 path behavior:

```text
bedtools2/src/multiIntersectBed/multiIntersectBedMain.cpp
bedtools2/src/unionBedGraphs/unionBedGraphsMain.cpp
```

The normal bedtools command path does not use a dispatcher executable that
searches for related binaries such as `tool.avx2.exe`. The main `bedtools.exe`
dispatches subcommands in-process. The supported modern subcommands pass
`argv + 1` into the command context, so the stored program name is the
subcommand name rather than a Windows executable path.

No normal runtime use of the following high-risk patterns was found:

```text
execv / execvp / fork
manual PATH scanning with ':' separators
S_IXUSR executable-permission checks
dispatcher construction from argv[0]
```

`stat()` is used for ordinary file existence and metadata checks. No `S_IXUSR`
or POSIX executable-bit test is used for deciding whether another program can be
run.

There are two remaining caveats:

1. `bedtools regresstest` is a developer/regression-test command and still uses
   POSIX shell assumptions such as `system()`, `/dev/null`, `ps`, `kill`, and
   fixed Unix-style paths. It should not be treated as a supported UCRT64 user
   workflow.
2. Vendored htslib contains CRAM reference/cache code with some POSIX-style
   path construction. Basic Windows absolute paths are recognized in htslib's
   CRAM path handling, but CRAM reference-cache edge cases are less well covered
   by this build validation than the common BED/BAM workflows.

The htslib plugin path iterator contains `HTS_PATH` parsing with `:`
separators, but the static `libhts.a` linked into this build did not include
`plugin.o`, so that code is not part of the released `bedtools.exe`.

Runtime validation included passing native Windows absolute paths directly to
the packaged executable:

```powershell
.\bedtools.exe intersect -a C:\...\a.bed -b C:\...\b.bed
.\bedtools.exe multiinter -header -i C:\...\d1.bed C:\...\d2.bed
```

## License

bedtools is distributed under the MIT License. See [LICENSE.md](LICENSE.md) and
[bedtools2/LICENSE](bedtools2/LICENSE).

Runtime DLLs included in release ZIP files come from MSYS2 packages and retain
their respective upstream licenses. See
[THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt) and the [LICENSES](LICENSES)
folder for package and license details.
