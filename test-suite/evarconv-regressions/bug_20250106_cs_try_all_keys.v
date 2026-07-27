From Unicoq Require Import Unicoq.

(* Rocq commit 171fbdd86880b37f2f8630fa91b99461e01d365b:
   do not stop at the first saved canonical-structure key if the resulting
   unification problem fails; try later matching keys. *)
Module TestKeys.
  Structure Dummy (b : bool) := { T : Type }.
  Definition boolF := bool.
  Canonical Dummy_boolF : Dummy false := {| T := boolF |}.
  Definition boolT := boolF.
  Canonical Dummy_boolT : Dummy true := {| T := boolT |}.

  Check eq_refl : id (@T false _) = boolT.
End TestKeys.
