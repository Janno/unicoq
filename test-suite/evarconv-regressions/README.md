# Expected-failing evarconv regression tests for Unicoq

These files document Rocq `pretyping/evarconv.ml` bug fixes whose old behavior is still reproducible with the current Unicoq unifier.

They are intentionally **not** part of the normal Dune build: every `.v` file in this directory is expected to fail until the corresponding Unicoq bug is fixed.  To experiment with them, copy `dune.disabled` to `dune` (or rename it temporarily) and build an individual `.vo` target, expecting a non-zero exit status.

No Unicoq crash/anomaly was found while preparing these tests; the anomaly-oriented Rocq regressions examined either pass under Unicoq or produce ordinary type errors.
