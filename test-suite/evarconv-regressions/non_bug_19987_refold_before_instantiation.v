From Unicoq Require Import Unicoq.

(* Rocq commit 77f55d5d2813267770892c422f56468232b9f37e changes behaviour:
   evarconv now refolds before instantiating evars.  This test documents a
   Unicoq difference, but the summary classifies it as not a bug in the spirit
   of the Unicoq paper because [nat] and [nat'] are convertible. *)
Definition nat' : Type := nat.
Goal True.
Proof.
  let x := open_constr:(_ : Type) in
  munify (id x) nat';
  lazymatch x with
  | nat' => idtac
  | nat => fail "evar instantiated with unfolded nat"
  | _ => fail "unexpected evar instance" x
  end.
Abort.
