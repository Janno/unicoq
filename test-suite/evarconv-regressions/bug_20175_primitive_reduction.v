From Unicoq Require Import Unicoq.
Require Import PrimArray PrimInt63.

(* Rocq commit a551165587b844167f3f27a56db8e43cfa0bc8bb:
   old and new unification reduce primitive operations even when evars occur
   in the primitive arguments. *)
Goal True.
Proof.
  let x := open_constr:(get (@make (unit * unit) 1%uint63 (tt, ?[u])) 0) in
  munify x (tt, tt).
Abort.
