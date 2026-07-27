From Unicoq Require Import Unicoq.

(* Rocq commit ffc2471986d33b76b5466113fd43d5ff4a923bed:
   canonical structures keyed by dependent products.  Rocq now accepts this;
   Unicoq leaves [h] unresolved and rejects the cast on [f]. *)
Structure hello := { hello_key : Type }.
Local Canonical Structure hello_dep :=
  {| hello_key := forall x : nat, x = x |}.

Definition dep_prod_cs :=
  let h := _ in
  fun f : hello_key h => (f : forall x : nat, x = x) 1.
