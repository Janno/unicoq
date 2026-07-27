From Unicoq Require Import Unicoq.

(* Rocq commit e2fd0336dd5b4bbef6d3e71e7b0c40132a507a83:
   remember canonical-structure keys while reducing, so a reducible RHS such
   as [pred 0] can still select the canonical instance keyed by [pred]. *)
Structure Pnat := mkP { getp : nat }.
Definition my_getp := getp.
Axiom W : nat -> Prop.

Definition pred n := match n with 0 => 0 | S m => m end.
Canonical Structure predSS n := mkP (pred n).

Definition reducible_cs_key :=
  (eq_refl : W (my_getp _) = W (pred 0)).
