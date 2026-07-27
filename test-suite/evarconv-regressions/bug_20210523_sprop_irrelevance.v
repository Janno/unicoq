From Unicoq Require Import Unicoq.

(* Rocq commit 814dd17f534486be1ddc8896dc02666135c4c13d:
   if ordinary unification fails for terms in SProp, conversion succeeds by
   proof irrelevance. *)
Check fun (A : SProp) (f g : A -> A) (P : A -> Type)
          (a : A) (x : P (f a)) => x : P (g _).
