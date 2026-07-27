From Unicoq Require Import Unicoq.
Require Import Ltac2.Ltac2 Ltac2.Unification Ltac2.Constr.

(* Rocq commit bb6d46e43fec5ce27a77010bd3d0cf093a263c28:
   tolerate primitive projections whose projected term has an evar type that
   has not yet reduced to an applied record inductive. *)
Module U.
  #[projections(primitive=yes)] Record r := R { r_car : Type }.
  #[projections(primitive=yes)] Record s := S { s_car : Type }.

  Canonical Structure foo (x : s) : (fun x => x) r := R (s_car x).
  Axiom a : s.

  Goal True.
    Ltac2 Eval
      let t1 := open_constr:((_ : _ r).(r_car)) in
      let t2 := constr:(a.(s_car)) in
      unify_with_full_ts t1 t2.
  Abort.
End U.
