# Rocq `pretyping/evarconv.ml` bug-fix comparison with Unicoq

## Scope and method

I mined the current Rocq checkout with `git log --follow --since=2019-01-01 -- pretyping/evarconv.ml`, then inspected the commits that had bug/fix/anomaly/test-suite/changelog evidence of a behavioral fix.  API-only, rename-only, profiling, and pure refactoring commits are not listed unless their patch introduced or changed a user-visible regression test.  I then reduced or reused the Rocq tests under current Unicoq.

Unicoq's paper describes a predictable unifier for CIC with universe polymorphism, controlled reduction/backtracking, higher-order pattern-style evar instantiation/pruning, and canonical structures; it deliberately omits constraint postponement.  I classify as "true bugs" the cases where current Rocq conversion/canonical-structure/universe behavior should succeed by that spirit.  I classify folded-vs-unfolded evar instantiation as not a true bug because the resulting terms are convertible and the paper does not promise preservation of surface constants.

## Applies to Unicoq and is a true bug

| Rocq commit | Rocq fix | Unicoq status | Test file |
|---|---|---|---|
| `ffc2471986d33b76b5466113fd43d5ff4a923bed` | Allow dependent products as canonical-structure keys. | Unicoq fails to use the canonical instance. | `bug_20210513_dependent_product_cs.v` |
| `2cbc36c6ae4ca22e000dbb045c865f54a454aca3` | Enable canonical `fun _ => _` / lambda projection keys. | Unicoq does not match the lambda key. | `bug_20210514_lambda_cs_key.v` |
| `814dd17f534486be1ddc8896dc02666135c4c13d` | Use proof irrelevance when unifying terms in `SProp`. | Unicoq rejects a coercion that Rocq accepts by SProp irrelevance. | `bug_20210523_sprop_irrelevance.v` |
| `531a7103f9082b6d6fc7df31fb8193a9cc68585a` | Respect covariant inductive cumulativity in evarconv. | Unicoq forces too-strict universe equality for a cumulative inductive. | `bug_16872_cumulative_inductive_cumulativity.v` |
| `292ed7a2ed3c0d78a3903c36486c4b7049e0a2d8` | Keep coherent surrounding stacks / extra arguments in canonical-structure projection problems. | Unicoq solves the unapplied projection case but fails the applied one. | `bug_20240207_cs_extra_args.v` |
| `bb6d46e43fec5ce27a77010bd3d0cf093a263c28` | Tolerate primitive projections applied to terms whose type is still an evar. | Unicoq fails before CS inference can refine the projected term's type. | `bug_19358_untyped_primitive_projection.v` |
| `e2fd0336dd5b4bbef6d3e71e7b0c40132a507a83` | Save canonical-structure keys while reducing and use LHS unfolding. | Unicoq loses the key for a reducible RHS such as `pred 0`. | `bug_19611_reducible_cs_key.v` |
| `171fbdd86880b37f2f8630fa91b99461e01d365b` | Try all saved CS keys, not only the first matching key that later fails. | Unicoq stops too early. | `bug_20250106_cs_try_all_keys.v` |
| `a551165587b844167f3f27a56db8e43cfa0bc8bb` | Reduce primitive operations in old and new unification even with evars in primitive arguments. | Unicoq does not reduce `PrimArray.get (make ...)` enough during unification. | `bug_20175_primitive_reduction.v` |

## Applies to Unicoq but is not a true bug in the paper's spirit

| Rocq commit | Rocq change | Unicoq status | Test file |
|---|---|---|---|
| `77f55d5d2813267770892c422f56468232b9f37e` | Refold before evar instantiation so tactics expose folded terms less often. | Unicoq instantiates with the unfolded but convertible term. | `non_bug_19987_refold_before_instantiation.v` |

## Examined fixes that do not currently apply to Unicoq

| Rocq commit | Fix examined | Unicoq result |
|---|---|---|
| `b4561c5047eb2383c2b718fd1cf9da8076497511` | `solve_simple_eqn` was weaker than Miller patterns (`#9663`). | Minimal `id_depfn` test passes. |
| `35a4196e8527da12ac63fb361211d138de8f62af` | Avoid stale evar map in `thin_evars` (`#10300`, `#10285`). | Minimal `himpl_refl` test passes. |
| `daba2d7a4546a7d869fd4358b05ca488877bfe18` | Turn an ill-typed evar-evar instance anomaly into an ordinary failure (`#5512`). | No crash found; the minimized script passes under Unicoq. |
| `a27fb3c67238cc41dc24308a233a02422e0f83f3` | Avoid primitive-projection `Retyping.RetypeError` anomaly (`#9971`). | No crash found; Unicoq reports an ordinary type error on the one-shot refine. |
| `c3853226d1325b452f797309fbb8461ee45a64db` | Do not encapsulate unhandled exceptions in `NotFoundInstance` (`#13266`). | The minimized induction script gives a normal failure. |
| `89f5d2503d68dae235b9c2153d34f0def30ff626` | Make primitive-array universe irrelevant (`#13354`). | Minimal array test passes. |
| `fa2e6446570286fd8e6fa9ba57ff86a7cc50206a` | Cleanup impossible-case default around `IDProp`; closes the old `#9240` regression. | Current Unicoq test passes. |
| `fdb272c418945f8aee62627d7ca1d77429f75780` | Canonical instance matching for `match` terms (`#17079`). | Unicoq already accepts the minimized test; the Rocq issue also notes this. |
| `3cabe16f6946fc89bdfe81b38905a176f7a21ba4` | Opaque primitive projections in evarconv (`#17774`). | A minimized `munify` version with opaque primitive projection passes; no Unicoq bug found. |
| `219e8b54dc176ede1c9dd8e04789f7d88380f14c` | Correct sort-polymorphic relevance checks for SProp (`#18845`). | The `Box` sort-polymorphic regression passes. |
| `d673328221530623d2837007d35b4980e7960e99` | Restrict checked conversion problems to those related to the current pretyped term (`#19054`). | Minimized regression passes. |
| `4fe0725059009585846623cb078c431a2b5f92ea` | Supply relevance when creating pure evars (`#20131`). | Minimized `sFalse -> sFalse` refine script passes. |
| `980c7ea217428b0f472a53abf1df747a3d7b0f98` | Preserve variable status in named contexts (`#6773`). | Minimized section-variable/`abstract` script passes. |

## Crashes found in Unicoq

None.  The crash/anomaly-oriented Rocq fixes above either pass with Unicoq or fail with ordinary user-facing type errors, so I did not add separate crash regression files.
