From Unicoq Require Import Unicoq.

(* Rocq commit 2cbc36c6ae4ca22e000dbb045c865f54a454aca3:
   canonical structures keyed by lambda/function values. *)
Structure cs_lambda := { cs_lambda_key : nat -> nat }.
Local Canonical Structure cs_lambda_func :=
  {| cs_lambda_key := fun x => x + 1 |}.

Check (eq_refl : cs_lambda_key _ = fun _ => _ + _).
