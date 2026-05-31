# bedtools for Windows: Unofficial Community Build

This repository provides an unofficial Windows build of
[bedtools](https://github.com/arq5x/bedtools2) v2.31.1.

bedtools is a command-line toolkit for genomic interval operations. The
upstream project is primarily built for Unix-like environments. This repository
vendors bedtools v2.31.1 as a patched source tree in
`bedtools-2.31.1-patch/` and applies a small MSYS2-UCRT64 compatibility patch
so that `bedtools.exe` can be built and used on Windows.

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
bedtools-2.31.1-patch/
```

The upstream bedtools README and license are kept inside that directory:

```text
bedtools-2.31.1-patch/README.md
bedtools-2.31.1-patch/LICENSE
```

Build outputs such as `bedtools-2.31.1-patch/bin/bedtools.exe`,
`bedtools-2.31.1-patch/obj/`, and release ZIP files are not meant to be
committed to git.

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
cd /c/path/to/bedtools-windows-build/bedtools-2.31.1-patch
make -j2
```

The executable is created as:

```text
bedtools-2.31.1-patch/bin/bedtools.exe
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
make test
```

The final MSYS2-UCRT64 `make test` run was executed with:

```text
MSYSTEM=UCRT64
make=/usr/bin/make
g++=/ucrt64/bin/g++
g++ -dumpmachine=x86_64-w64-mingw32
_WIN32=1
__MINGW64__=1
```

It reported:

```text
ok lines: 812
canonical ...ok markers: 757
skipped tests: 1 (merge.t44b, missing optional vcfSVtest.2.vcf)
segmentation faults: 0
bad_alloc failures: 0
passing tools: bamtobed bamtofastq bed12tobed6 bedtobam bigchroms closest cluster complement coverage expand fisher flank general genomecov getfasta groupby intersect jaccard makewindows map merge multicov reldist sample shift shuffle slop sort spacing split subtract
failing tools: negativecontrol
```

`negativecontrol` is expected by the upstream harness to fail.

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

## MSYS2-UCRT64 Runtime and Test Fixes

The following fixes were found by running the upstream test data. They are
separate from the compile-only compatibility patch above.

| Area | Change | Reason |
|---|---|---|
| standard streams | Set `stdin`, `stdout`, and `stderr` to binary mode on `_WIN32` at process startup | Native UCRT64 text mode rewrites LF to CRLF and can corrupt BAM data written through stdio |
| generic input streams | Open regular input files with `ios::binary` in `InputStreamMgr` | Text-mode reads can alter bytes before BAM/BGZF detection and caused BAM inputs to be misclassified in `map`, `merge`, and `groupby` |
| `bamtofastq` file outputs | Open FASTQ output files with `ios::binary` | `-fq` and `-fq2` write to files, not stdout, so startup stdio binary mode does not cover them |
| `getfasta -fo` / `maskfasta` / `split` file outputs | Open the named output files in binary mode (`ios::binary`, `fopen "wb"`) | These tools write to named files rather than stdout, so the startup stdio binary mode does not cover them; text mode emitted CRLF (verified: getfasta `-fo` produced `\r\n`, LF after the fix) |
| legacy `GenomeFile` parser | Initialize `_genomeLength` and parse chromosome sizes with `strtoll()` into `CHRPOS` | Win64/UCRT64 uses 32-bit `long`; `atol()` truncated hg19-sized coordinates and made `sample`/`shuffle` fail with `bad_alloc` or wrong seeded output |
| `closest` context flags | Initialize `_forceUpstream` and `_forceDownstream` | Uninitialized bools made plain `closest` invocations behave as if `-fu` or `-fd` had been requested |
| `coverage` context flags | Initialize `_mean` | Uninitialized bools made plain `coverage` invocations behave as if mutually exclusive output modes had been combined |
| sweep flow-control flags | Initialize `_runToQueryEnd` and `_shouldRunToDbEnd` | Uninitialized flags could drain query/DB records before final sorted-input validation, which made `closest.t15` miss the expected error |
| `complement` `-L` flag | Initialize `_onlyChromsWithBedRecords` | Uninitialized, it could behave as if `-L` was set and skip genome chromosomes with no input records |
| base context CRAM state | Initialize `_isCram` | Default output is normal BAM unless input detection marks it as CRAM |
| legacy `BedFile` line counter | Initialize `_lineNum` | Uninitialized line counters can produce random diagnostics when legacy readers report parse/order errors |
| `coverage` buffer cleanup | Use `delete[]` for `_floatValBuf` | Valgrind found a `new[]`/`delete` mismatch in the `coverage` tool |

The modified source locations include comments explaining the Windows/UCRT64
runtime issue:

```text
bedtools-2.31.1-patch/src/bedtools.cpp
bedtools-2.31.1-patch/src/utils/FileRecordTools/FileReaders/InputStreamMgr.cpp
bedtools-2.31.1-patch/src/bamToFastq/bamToFastq.cpp
bedtools-2.31.1-patch/src/fastaFromBed/fastaFromBed.cpp
bedtools-2.31.1-patch/src/maskFastaFromBed/maskFastaFromBed.cpp
bedtools-2.31.1-patch/src/split/splitBed.cpp
bedtools-2.31.1-patch/src/utils/GenomeFile/GenomeFile.cpp
bedtools-2.31.1-patch/src/utils/Contexts/ContextClosest.cpp
bedtools-2.31.1-patch/src/utils/Contexts/ContextCoverage.cpp
bedtools-2.31.1-patch/src/utils/Contexts/ContextBase.cpp
bedtools-2.31.1-patch/src/utils/Contexts/ContextIntersect.cpp
bedtools-2.31.1-patch/src/utils/Contexts/ContextComplement.cpp
bedtools-2.31.1-patch/src/utils/bedFile/bedFile.cpp
bedtools-2.31.1-patch/src/coverageFile/coverageFile.cpp
```

After these fixes, the earlier BAM field-count failures in `groupby`, `map`,
and `merge`, the `jaccard` failure, the `sample`/`shuffle` `bad_alloc`
failures, the `bamtofastq` CRLF file-output diff, and the plain
`closest`/`coverage` false option errors were resolved. The final `closest.t15`
and `complement.t5`/`complement.t10` outputs were also checked against Linux
builds and matched byte-for-byte.

Regular inputs are also opened in binary mode so the UCRT64 build matches Linux
byte handling. CRLF text input is therefore not normalized by the Windows C
runtime; a trailing `\r` can remain in text fields just as it would on Linux.
Normalize CRLF BED/GFF/VCF files before exact byte comparisons when LF output is
required.

Upstream test harness adaptations:

1. `complement`, `getfasta`, `intersect`, and `shuffle.t6` use Bash process
   substitution such as `<(...)`, which becomes `/proc/<pid>/fd/<n>`. Native
   UCRT64 `bedtools.exe` cannot open those MSYS pseudo paths. Use temporary
   files when validating native Windows executables.
2. BAM stdin tests should use bedtools' documented `-` form instead of MSYS
   pseudo paths such as `/dev/stdin`.
3. The sort-and-naming stderr checks were revalidated with the upstream
   `2>&1 > /dev/null | ...` pipeline. No custom stderr retry wrapper is needed.

## Potential Upstream Bugs (Not Windows-Specific)

Some of the fixes above address latent defects in the upstream bedtools source
that are **not** specific to Windows. They are undefined behavior on every
platform and only appear to work on Linux because freshly allocated memory
often reads as zero there, and because the common allocator happens to tolerate
the `new[]`/`delete` mismatch. A different compiler, optimization level, or
allocator could expose them anywhere. They are highlighted here for upstream
awareness:

- **Member variables read before initialization** (UB). Each is declared in its
  class but never set in the constructor, only later via an option handler or
  setter:
  - `ContextIntersect::_shouldRunToDbEnd` — most impactful. When it reads as
    true, DB records are drained before sorted-input validation, suppressing the
    expected sort-order error (seen as `closest.t15`).
  - `ContextBase::_runToQueryEnd`, `ContextBase::_isCram`
  - `ContextClosest::_forceUpstream`, `ContextClosest::_forceDownstream`
  - `ContextCoverage::_mean`
  - `ContextComplement::_onlyChromsWithBedRecords`
  - `BedFile::_lineNum`
- **`GenomeFile::_genomeLength` used uninitialized**: the file constructor
  accumulates into it without first setting it to 0, and the BAM-header
  (`RefVector`) constructor never builds `_startOffsets`, so `projectOnGenome()`
  can index an empty vector.
- **`new[]`/`delete` mismatch in the `coverage` tool**:
  `CoverageFile::_floatValBuf` is allocated with `new char[]` but freed with
  scalar `delete` (found by Valgrind).

These were confirmed by building the same patched source on Linux/WSL: the
relevant outputs match the unmodified upstream build byte-for-byte, so the fixes
do not change correct Linux behavior — they only remove the latent undefined
behavior. (The separate `strtoll`/`CHRPOS` change in `GenomeFile` is a genuine
Win64 LLP64 concern, where `long` is 32-bit, and is not listed here.)

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
bedtools-2.31.1-patch/src/multiIntersectBed/multiIntersectBedMain.cpp
bedtools-2.31.1-patch/src/unionBedGraphs/unionBedGraphsMain.cpp
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
[bedtools-2.31.1-patch/LICENSE](bedtools-2.31.1-patch/LICENSE).

Runtime DLLs included in release ZIP files come from MSYS2 packages and retain
their respective upstream licenses. See
[THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt) and the [LICENSES](LICENSES)
folder for package and license details.
