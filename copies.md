# UniCoq code derived from Rocq's `evarconv`

## Scope

This report inventories code in UniCoq that is an exact or close adaptation of
Rocq's `pretyping/evarconv.ml`.  It includes code which no longer looks alike at
HEAD but whose history shows that it started as a copy.  It also records copied
code that was later removed.

The snapshots used for current line numbers are:

- UniCoq: `88029c86aca88fa6a62b62f9bfc94e998950eb35`
- Rocq: `01255f8f83d55f847e5f3031cf88039ce7c5ce0f`

"Exact" below means verbatim or mechanically adjusted at the point of copying.
"Near copy" means that names, result plumbing, or representation were changed,
but the source structure, rule order, comments, and history establish the
lineage.  Similar code implementing an ordinary unification rule is not counted
without textual or historical evidence.

## Executive summary

There are seven current copy families in `src/munify.ml`:

1. `ise_list2` and `ise_array2`;
2. the ground-conversion fast path;
3. the rigid/same-head structural comparison scaffold;
4. canonical-structure recognition in `check_conv_record`;
5. canonical-structure dispatch/execution in `try_canonical_structures` and
   `conv_record`;
6. `evar_apprec`;
7. the `is_unnamed` heuristic, now wrapped by `is_stuck`.

There is also one important historical-only family in the UniCoq repository:
the cumulative-inductive/universe head comparison copied in 2018 and removed
again two months later.  Rocq subsequently exposed `compare_heads`, and UniCoq
now calls that API.  A short-lived `apprec_nohdbeta` copy existed in the
pre-UniCoq `beta-ziliani/coq` precursor, but had already been removed before the
standalone UniCoq repository imported the file.

No large block remains byte-for-byte identical at the two current HEADs.  That
is principally the result of ten years of changes to `EConstr`, universe
handling, primitive projections, canonical structures, abstract reduction
stacks, and UniCoq's logging/result monad; it does not erase the provenance.

## Current inventory and API verdicts

| # | UniCoq code | Current Rocq counterpart | Origin classification | Can `evarconv.mli` expose/reuse it? |
|---|---|---|---|---|
| 1a | `ise_list2`, `src/munify.ml:269-277` | `evarconv.ml:422-433` | Near-exact copy at origin; diverged result plumbing | **Mechanically yes, usefully no.** A `val` could be added, but Rocq's helper returns `Evarsolve.unification_result` while UniCoq threads a logger too. |
| 1b | `ise_array2`, `src/munify.ml:278-291` | `evarconv.ml:435-446` | Adapted copy at origin | **Mechanically yes, usefully no.** The semantics now differ: Rocq requires equal lengths and walks backwards; UniCoq aligns a shorter first array with the suffix of the second and walks forwards. |
| 2 | `ground_spine` / `try_conv`, `src/munify.ml:952-969` | `infer_conv_noticing_evars`, `evarconv.ml:659-678`, and the `ground_test` in `evar_conv_x`, lines 720-735 | Near copy at origin and still the same optimization | **Yes.** `infer_conv_noticing_evars` is top-level and its inferred signature uses only public types, so a declaration in `evarconv.mli` would suffice. An adapter would still be needed for UniCoq's logger and spine representation. |
| 3 | `try_app_fo` and the structural arms of `compare_heads`, principally `src/munify.ml:1090-1105` and `1181-1273` | Stack comparison and the rigid/rigid part of `evar_eqappr_x`, principally `evarconv.ml:497-641` and `1235-1424` | Near-copy scaffold at origin; substantially diverged | **Partly already exposed.** `compare_heads` is public and UniCoq already uses it for constants, inductives, and constructors. `evar_eqappr_x` is also exported in the debugging section, but only as the whole Rocq algorithm. Sharing the remaining structural walker would require a callback-oriented refactor, not merely another `val`. |
| 4 | `check_conv_record`, `src/munify.ml:681-718`, including the inherited explanatory comment | `decompose_proj` and `check_conv_record`, `evarconv.ml:300-398` | Exact copy in the precursor; repeatedly ported and now diverged | **Already exposed and plausibly reusable.** UniCoq would need an adapter between application lists and `Reductionops.Stack.t`, and for the newer result shape. |
| 5 | `try_canonical_structures` / `conv_record`, `src/munify.ml:1059-1088` | canonical-structure dispatch in `evar_eqappr_x` and `conv_record`, principally `evarconv.ml:1165-1195,1426-1485` | Exact/adapted copy at origin; repeatedly ported | **Not usefully as-is.** `conv_record` could mechanically be declared in the interface, but it recursively invokes Rocq's unifier. To preserve UniCoq semantics it must first be generalized over the recursive unifier/result plumbing, or reduced to a shared canonical-structure plan constructor. |
| 6 | `evar_apprec`, `src/munify.ml:720-731` | Historical `evar_apprec`; current Rocq directly uses abstract-stack reduction, while `apprec_nohdbeta` remains at `evarconv.ml:189-195` | Near-exact copy at origin | **No current function exists to expose.** The underlying state reducers and stack operations are already public in `Reductionops`; exposing `apprec_nohdbeta` would not be a semantic replacement. |
| 7 | `is_stuck` and its local `is_unnamed`, `src/munify.ml:1438-1451` | local `is_unnamed` in `evar_eqappr_x`, `evarconv.ml:1196-1213` | Exact copy at origin; both sides later evolved | **Only after refactoring.** Rocq's predicate is a local closure over flags, environment, evar map, and stack. It could be hoisted and exposed, but the two predicates no longer agree on all `Proj`, `Case`, evar, and non-applicative-stack cases. |
| 8 | Removed 2018 universe/cumulative-inductive helper block | current public `compare_heads`, implemented at `evarconv.ml:484-531`, adapted at lines 642-643, and specialized for the public API at line 2163 | Explicitly copied (`Stolen from evarconv`) and later removed | **Already solved.** Rocq exported `compare_heads` in 2020 and current UniCoq calls it at `src/munify.ml:912-913,1232-1240`. |
| 9 | Precursor-only `apprec_nohdbeta` (never imported into standalone UniCoq) | `evarconv.ml:189-195` | Short-lived exact/adapted copy | **Easy mechanically, irrelevant currently.** Its public-type signature could be added to the interface, but no current UniCoq duplicate would be removed. |

The detailed evidence and qualifications for each row follow.

## Provenance timeline

### Rocq / Coq

- `6e9f19b7dc30eb451dc4cb67be0dd202eab22718` (1999-11-24),
  “Versions initiales”: early `evarconv`, structural matching, and
  `conv_record` lineage.
- `6fcd224c128ae5e81f4cce9d5de1ac45883cfebf` (2000-09-12): introduction
  of `evar_apprec` under that name.
- `790243ed041f0626cd2d1613473b8f393ecccd56` (2001-07-06): introduction of
  the policy that general conversion is tested only in the absence of evars;
  `c580f69cc36cc4cc908febb900a55ae751039a0c` (2009-02-09) later factored the
  check as `ground_test`.
- `34ea25487315da07264f273aae1018ec20eb99ae` (2001-10-16),
  “Nettoyage Recordobj et conséquences”: introduction of
  `check_conv_record` under that name.
- `43cd2858eb9f5e88382131015d1bce94d98ef1fb` (2003-01-22): introduction
  of `apprec_nohdbeta` to preserve first-order beta redexes.
- `d331f7f1ac0ec2ed12d458597d558a1988db1ba6` (2004-09-07):
  introduction of `ise_list2` and `ise_array2` under those names.
- `df73f477fd496168bf448d2bfef8cec3cb0643ee` (2009-05-16):
  `check_conv_record` was put in `evarconv.mli` so another unifier could reuse
  canonical-structure recognition.  The commit message explicitly says it
  shares the recognition and unification steps with `evar_conv`.
- `4a0fc5c294cf0f6db842bab26df80a3ce7cdf07b` (2012-03-22):
  introduction of the `is_unnamed` canonical-structure/reduction heuristic.
- `ec3bff58d151ff804866175e907664d1fba3c600` (2012-08-09):
  conversion of `evarconv` to abstract-machine states.  On the main lineage,
  this removed the standalone `evar_apprec` wrapper and used state reduction
  directly.
- `4385872b2d82fbad2be84f2423802e00e9d9575f` (2017-04-08) and
  `40f56eb0f79e208fc4b1b4ed2f0fb49c69c13a2f` (2017-05-21):
  cumulative-inductive and strict/subtyping head comparison from which the
  2018 UniCoq block was adapted.
- `7395f5a7f86de3181df8b2a73f84f815447b745d` (2020-11-25):
  extraction and export of `compare_heads` specifically for UniCoq's use.

### The `beta-ziliani/coq` precursor

Standalone UniCoq did not begin with a fresh implementation.  Its import commit
says that it moved `beta-ziliani/coq/extra-pruning/munify.ml`.  The relevant
history in that precursor is:

- `e1f5f09765b5c0de0fc319ed5b893d0b82704380` (2014-01-09), “start new unif
  algorithm”: introduces the pair walkers, the ground conversion shortcut, and
  the same-head structural scaffold next to the then-current `evarconv.ml`.
- `3507e162dd14eb7eecbbaca54b2e529fb36a3db2` (2014-01-13), “added CS”:
  copies `check_conv_record`, its long comment, and `conv_record`.
- `99bd1eace77a574e0cbe05ceb93992ed52cff821` (2014-03-26): copies/adapts
  `evar_apprec` and `is_unnamed` to implement `is_stuck`.
- `40150fa7285bd02533461b38b2d42853e024f1e5` (2014-03-27): temporarily adds
  an `apprec_nohdbeta` adaptation.
- `b10e13a2e80184d74eb4e331168541a589a78d74` (2014-03-31): removes that
  `apprec_nohdbeta` use while retaining `evar_apprec`.
- `f5074dea4c26dba04b5aa8cb82757a20937852f6` (2015-01-23) is the last
  precursor revision touching `munify.ml` before the standalone import.

### Standalone UniCoq

- `e88d2c30f76e5284e563d7b23b432ea06982cf58` (2015-02-18), “Moved
  beta-ziliani/coq/extra-pruning/munify.ml in unicoq”: imports all seven current
  copy families.
- `fd5f41f32f5f7cb94de81d66a42dff18df7084a2` (2018-02-07): adds the explicit
  `Stolen from evarconv` cumulative-inductive block.
- `14b671d7657fd65b404a6362cc9d59de557e6ba8` (2018-04-18): removes that block
  and delegates the relevant comparison to `Evarconv`.
- `65fda5e8db25c0b81f8025ac526c8edf198c7f04` (2020-11-25), committed seven
  minutes after Rocq's API extraction by the same author: switches UniCoq to
  `Evarconv.compare_heads`.

## Detailed findings

### 1. `ise_list2`

**Current UniCoq:** `src/munify.ml:269-277`<br>
**Current Rocq:** `pretyping/evarconv.ml:422-433`

The first precursor revision, `e1f5f097...`, has the same function name, nested
recursive shape, special two-singleton case, sequential threading of the evar
map, and failure rollback as the adjacent `evarconv.ml`.  The principal
mechanical change is that the precursor represented success as `(bool,
evar_map)` rather than `(evar_map, bool)`.  UniCoq later replaced that pair with
its logger plus `Evarsolve.unification_result`, but the helper is a direct
lineage of the copied version.

Rocq has also changed its implementation to continuation-building, so current
textual similarity is small.

**Interface assessment.**  Rocq's function is top-level and all types needed by
a signature are public; adding a `val` is easy.  It would not remove the UniCoq
copy, because UniCoq's callback and result must preserve `Logger.log`.  A truly
shared helper would have to be generic over bind/failure, at which point a
standard list traversal in a shared utility module is preferable to exposing an
`evarconv` implementation detail.

### 2. `ise_array2`

**Current UniCoq:** `src/munify.ml:278-291`<br>
**Current Rocq:** `pretyping/evarconv.ml:435-446`

This was introduced beside `ise_list2` in `e1f5f097...` by adapting Rocq's array
walker.  It deliberately changed behavior: the first array may be shorter and
is compared with a suffix of the second.  That behavior survives at HEAD and is
used by UniCoq's first-order approximation.  Current Rocq instead rejects
unequal lengths and visits equal-length arrays from the last element to the
first.

**Interface assessment.**  A declaration is mechanically possible but cannot
be used as a replacement.  Exposing it under the same name would obscure the
semantic mismatch.  Do not add this API solely for UniCoq.

### 3. Ground-conversion fast path

**Current UniCoq:** `ground_spine` and `try_conv`,
`src/munify.ml:952-969`<br>
**Current Rocq:** `infer_conv_noticing_evars` and `evar_conv_x`'s `ground_test`,
`pretyping/evarconv.ml:659-678,720-735`

The initial precursor starts its recursive unifier by applying
`whd_head_evar` to both terms, testing both with `is_ground_term`, and calling
`is_trans_fconv`.  This is a shortened adaptation of the corresponding
`evarconv` entry path in its parent tree.  The unusual motivation is the same:
a general conversion check is safe before evar-oriented unification only when
it will not erase useful evars.

UniCoq now checks each head and spine argument, requires reduction permission on
both sides, and calls `Reductionops.infer_conv`; a failed fast path falls through
to the rest of UniCoq.  Current Rocq uses `infer_conv_noticing_evars`, which can
distinguish definitive failure from failure affected by an undefined evar
hidden in the environment/reduction.

**Interface assessment.**  `infer_conv_noticing_evars` is already top-level and
can be exposed with a signature equivalent to:

```ocaml
val infer_conv_noticing_evars :
  pb:Conversion.conv_pb -> ts:TransparentState.t ->
  Environ.env -> Evd.evar_map -> EConstr.t -> EConstr.t ->
  Evarsolve.unification_result option
```

No private type appears.  This is a reasonable small API if Rocq wants external
unifiers to use exactly its safe-conversion test.  UniCoq would still wrap the
result to retain its log and its `wreduce` policy.

### 4. Rigid/same-head structural scaffold

**Current UniCoq:** `try_app_fo` and `compare_heads`, principally
`src/munify.ml:1090-1105,1181-1273`<br>
**Current Rocq:** stack comparison and rigid/rigid matching, principally
`pretyping/evarconv.ml:497-641,1235-1424`

The precursor's first unifier is not a wholesale fork of `evarconv`; most of its
instantiation and reduction strategy is new.  Its structural decomposition is,
however, a close adaptation of the neighboring `evarconv` scaffold.  Historical
evidence includes the same rule labels and ordering (`Type-Same`, `Lam-Same`,
`Prod-Same`, `Let-Same`, `Rigid-Same`, `CoFix-Same`, `Case-Same`, `Fix-Same`),
the same environment extension for binders, and the same pair/array sequencing
shape.  These arms were imported in `e88d2c30...` and remain recognizable after
conversion to `EConstr` and UniCoq's logging monad.

The primitive-projection same-head arm was added to UniCoq in
`f7f870b4d6e19fc0558576828f920be44ada518f` (2020-04-30).  It is a simplified
adaptation of `evarconv`'s existing `Proj`/`Proj` arm and belongs to this family.
The larger later projection-reduction implementation is not counted; see the
boundary section below.

Constants, inductives, and constructors are now a successful deduplication:
UniCoq's `ev_compare_heads` calls the public `Evarconv.compare_heads`.

**Interface assessment.**

- `Evarconv.compare_heads` is already public and already used.
- `evar_eqappr_x` is already exposed in the debugging section of
  `evarconv.mli`, but calling it delegates the whole problem to Rocq rather than
  allowing UniCoq to reuse only structural decomposition.
- The remaining code is distributed between stack walkers and local branches
  closed over Rocq's flags and recursive unifier.  A useful API would need a
  callback such as “compare these children with the caller's unifier,” plus a
  result abstraction capable of retaining UniCoq's log.  Merely exposing the
  current internal functions would not deduplicate UniCoq.

### 5. Canonical-structure recognition: `check_conv_record`

**Current UniCoq:** `src/munify.ml:681-718`<br>
**Current Rocq:** `pretyping/evarconv.ml:300-398`

Commit `3507e162...` added a near-verbatim copy of Rocq's long
`check_conv_record` comment and implementation.  Distinctive copied operations
include classification into `Prod_cs`, `Sort_cs`, `Const_cs`, and `Default_cs`,
lookup of the canonical conversion, splitting parameters and canonical-value
arguments, and returning the large plan consumed by `conv_record`.

The copy happened even though `check_conv_record` had been public since
`df73f477...` in 2009.  There was a concrete reason in the precursor: its
modified `evarconv.ml` called `Munify.unify_evar_conv` while executing canonical
structure steps, so having `Munify` call back into `Evarconv` would have created
a compilation/dependency cycle.  That cycle does not exist for the standalone
plugin.

Both implementations were subsequently ported through API changes, but Rocq's
version now additionally has:

- a separate public `decompose_proj` step;
- abstract reduction stacks and primitive projections;
- canonical-structure hooks;
- richer value patterns and updated universe handling;
- a changed plan/result shape.

**Interface assessment.**  This functionality is already public in
`evarconv.mli`: both `decompose_proj` and `check_conv_record` are declared.
UniCoq can construct a pure application stack from its argument list, call the
two functions, and convert returned applicative stacks back to lists.  Handling
`params1 : EConstr.t list option`, hooks, and newer exceptions makes this an
adapter rather than a one-line replacement, but no Rocq interface change is
required.  This is the best remaining candidate for deleting a copied block.
Behavioral tests are necessary because reusing it also adopts Rocq's newer
hooks and recognition cases.

### 6. Canonical-structure dispatch and execution

**Current UniCoq:** `try_canonical_structures` and `conv_record`,
`src/munify.ml:1059-1088`<br>
**Current Rocq:** canonical-structure attempts in `evar_eqappr_x` and
`conv_record`, principally `pretyping/evarconv.ml:1165-1195,1426-1485`

`3507e162...` also copied/adapted the attempt in both orientations and the
execution half: fold over abstraction types,
insert the canonical value at the distinguished abstraction, create fresh
evars for the others, substitute earlier choices into later types, then unify
parameters, canonical-value arguments, the record value, and trailing
arguments.  The fresh-evar fold still has direct historical textual matches.

The implementations have diverged in stack shape checks, typeclass-candidate
selection, a type check for the inserted value, final head comparison, result
plumbing, and logging.  Their recursive calls must intentionally use different
unifiers.

**Interface assessment.**  Since Rocq's `conv_record` is a top-level member of
the mutual recursive group, it could technically be added to `evarconv.mli`
with its large tuple argument.  That is not a useful UniCoq API: its child
constraints call the lexically recursive Rocq `evar_conv_x`, not UniCoq and not
the public hook installed later.

A reusable design would instead do one of the following:

1. expose a typed canonical-structure *plan* and leave execution to each
   unifier (the existing `check_conv_record` result is already close to this);
2. generalize execution over callbacks for child unification, fresh-evar
   creation/result bind, and stack comparison.

Until then, retaining a small UniCoq-specific executor after deleting only its
recognizer copy is more appropriate than exposing Rocq's executor as-is.

### 7. `evar_apprec`

**Current UniCoq:** `src/munify.ml:720-731`<br>
**Historical Rocq:** the pre-abstract-stack `evar_apprec`, e.g. Coq `V8.4pl5`

Commit `99bd1eac...` copied the old wrapper almost line for line: invoke
`whd_betaiota_deltazeta_for_iota_state`, chase defined evars, and turn the
resulting application stack back into a head/list pair.  The precursor added an
initial unfolding operation.  Signature order and modern API names changed
later, but the current function is its direct descendant.

On Rocq's main history, `ec3bff58...` removed this wrapper while converting
`evarconv` to abstract-machine states.  Current `evarconv` calls the state
reducer directly.  Its `apprec_nohdbeta` is related but deliberately avoids
head beta reduction and returns a term, so it is not equivalent to UniCoq's
helper.

**Interface assessment.**  There is no current `Evarconv.evar_apprec` to put in
the interface.  The operations needed to implement it are already public:
`Reductionops.whd_betaiota_deltazeta_for_iota_state`,
`Reductionops.Stack.append_app_list`, `list_of_app_stack`, and `zip`.  If sharing
this wrapper is desired, it belongs more naturally in `Reductionops` than in
`Evarconv`.

### 8. `is_unnamed`, now inside `is_stuck`

**Current UniCoq:** `src/munify.ml:1438-1451`<br>
**Current Rocq:** local helper at `pretyping/evarconv.ml:1196-1213`

Rocq introduced the unusual `is_unnamed` classification in `4a0fc5c2...` to
choose unfolding order around canonical structures.  The precursor copied the
same name, constructor classification, lambda assertion, let reduction, and
comment in `99bd1eac...`; it placed the predicate behind `is_stuck`.  That code
was imported into standalone UniCoq.

Both versions later acquired constructors for newer term forms, but they no
longer have identical semantics.  Among other differences:

- Rocq inspects non-applicative stack frames; UniCoq has only an argument list.
- Rocq's result for rigid heads and evars can depend on those frames.
- Rocq treats a projection as unnamed when it is unfolded or has a
  non-applicative stack; UniCoq currently returns false for `Proj`.
- Rocq's reduction state should make `Case` impossible at that point, while
  UniCoq classifies it as stuck/unnamed.

**Interface assessment.**  Rocq's helper cannot be exposed merely by adding a
`val`, because it is nested in `f3` and closes over `flags`, `env`, and `i`.
It could be hoisted to a function over `unify_flags`, `env`, `evar_map`, and
`Reductionops.state`, all public types.  Replacing UniCoq's predicate would
still require a pure-application-stack adapter and an explicit decision to
adopt Rocq's changed semantics.  This is possible but is an unstable heuristic,
not an obvious public API commitment.

### 9. Historical-only cumulative-inductive/universe comparison

**UniCoq lifetime:** `fd5f41f3...` (2018-02-07) through `14b671d7...`
(2018-04-18)

The added block contained:

- `explain_univ_and_fail`;
- `check_leq_inductives`, preceded by the explicit comment
  `(** Stolen from evarconv *)`;
- `check_strict`;
- `check_subtyping_constraints`;
- replacement constant/inductive/constructor arms in UniCoq's
  `compare_heads`.

`check_leq_inductives` was a direct copy adjusted for the then-current universe
API.  The strict and subtyping helpers extracted/adapted logic that was nested
inside contemporaneous `evarconv`.  This family is important to the inventory
even though no duplicate remains at HEAD.

`14b671d7...` deleted the copied helpers and temporarily delegated those heads
to the broader `Evarconv.unify_delay`.  Rocq commit `7395f5a7...` then extracted
the narrower `compare_heads` operation into `evarconv.mli`; UniCoq commit
`65fda5e8...` immediately switched to it.

**Interface assessment.**  This is the model successful outcome: the
corresponding implementation is already public and current UniCoq reuses it.
No further exposure is needed.

### 10. Precursor-only `apprec_nohdbeta`

The precursor added an adaptation of Rocq's `apprec_nohdbeta` in
`40150fa7...` and stopped using/removed it in `b10e13a2...`, four days later.
It was absent from the file imported by standalone UniCoq in 2015, so it is not
counted among current or historical files in the UniCoq repository proper.  It
is recorded because it is part of the imported file's prehistory and otherwise
looks like a missed copy.

**Interface assessment.**  Current Rocq's function is top-level and has a
signature made entirely of public types, so it could easily be declared in
`evarconv.mli`.  Doing so would not remove any current UniCoq code and would not
replace `evar_apprec`.

## Similar code reviewed but not classified as an `evarconv` copy

The following were checked and deliberately excluded:

- `make_evar_instance` / `instantiate_evar` at `src/munify.ml:187-198`.
  UniCoq itself says these were borrowed from Coq 8.4, but their source is
  `Evd`, not `evarconv`.
- UniCoq's inversion, pruning, `meta_fo`, `check_product`, and `eta_match`.
  They solve related unification problems but their initial implementations and
  control flow are distinct from `evarconv`.
- The general beta/zeta/delta reduction rules in `try_step`.  They use standard
  reduction equations and share vocabulary with `evarconv`, but the precursor
  begins with its own reduction strategy and there is not enough textual or
  historical evidence to call those blocks copies.  The specifically copied
  `is_unnamed`/`evar_apprec` heuristic is listed separately above.
- Later primitive-projection fixes, including
  `4e169fcf967fa93da859b77d69c96981a01dfc8a`,
  `8d9c9d1677294e95fba1fa464ae6e07d7465c53b`,
  `4ef41ac43d7d6e6503ed9e0be88fe14b75f4b00d`,
  `bde9aee908e97a6a4a13da5a44458a53596f2168`, and
  `0e070529b3919f9cfb1cc428a3c20c789af798d9`.  These are adaptations and bug
  fixes rather than copied `evarconv` blocks.  The small `Proj`/`Proj`
  same-head arm is already included in the structural-scaffold family.
- Generic option-registration boilerplate and ordinary constructor pattern
  matches.  Short current textual matches of this kind are incidental.
- `ev_compare_heads`: this is a call to the public Rocq implementation, not a
  duplicate.

## Suggested deduplication order

1. **Use the already-public `decompose_proj` and `check_conv_record`.**  This can
   remove the clearest substantial current copy without changing Rocq.
2. **Consider exporting `infer_conv_noticing_evars`.**  This is a small,
   technically clean API for external unifiers and would centralize the subtle
   hidden-evar failure rule.
3. **Keep UniCoq's `conv_record` executor unless Rocq first generalizes it over a
   recursive unifier callback.**  Exporting the current function would silently
   switch algorithms inside the canonical-structure subproblems.
4. **Do not export `ise_list2`/`ise_array2` just to remove these copies.**  Their
   result and, for arrays, semantics differ.
5. **Only expose a hoisted `is_unnamed` if Rocq deliberately wants this heuristic
   to be a supported external policy.**  First decide which side's current
   projection/stack behavior is intended.
6. **Continue using public `compare_heads`.**  It has already eliminated the
   historical universe-comparison copy.

## Method used to establish completeness

The inventory was produced by:

1. comparing every current function in `src/munify.ml` with current
   `pretyping/evarconv.ml`, including normalized line and token matching;
2. blaming each candidate through both `src/munify.ml` and its historical
   `src/munify.ml4` form;
3. following standalone import `e88d2c30...` into the
   `beta-ziliani/coq` `extra-prunning` branch and inspecting the introducing
   patches there;
4. comparing those precursor revisions with the `evarconv.ml` in their own
   parent trees and with Coq `V8.4pl5`;
5. searching all UniCoq revisions for `evarconv`, explicit provenance comments,
   removed helper names, and API-adaptation commits;
6. tracing each corresponding function and interface declaration through the
   full Rocq history; and
7. reviewing related same-head, eta, first-order, reduction, canonical-
   structure, universe, and primitive-projection code to separate copying from
   independently implemented analogous rules.

## Licensing note

This is a technical provenance report, not legal advice.  Current Rocq
`evarconv.ml` carries the GNU LGPL 2.1 notice, while the UniCoq repository states
that it is MIT-licensed.  Because several UniCoq blocks began as verbatim or
close source copies, maintainers should review attribution and license treatment
for those portions rather than assuming that later API drift erased their
provenance.  Moving future shared behavior behind public Rocq APIs reduces new
copying but does not by itself resolve the status of existing copied text.
