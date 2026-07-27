From Unicoq Require Import Unicoq.

(* Rocq commit 292ed7a2ed3c0d78a3903c36486c4b7049e0a2d8:
   canonical-structure projection problems must keep coherent surrounding
   stacks/extra arguments. *)
Module ExtraArgs.
  Structure Fun := { apply : nat -> nat }.

  Canonical S_Fun := {| apply := S |}.
  Check eq_refl : apply _ = S.
  Check eq_refl : apply _ 0 = S 0.

  Canonical generic_Fun (f : nat -> nat) := {| apply := f |}.
  Check fun (f : nat -> nat) => eq_refl : apply _ = f.
  Check fun (f : nat -> nat) => eq_refl : apply _ 0 = f 0.
End ExtraArgs.
