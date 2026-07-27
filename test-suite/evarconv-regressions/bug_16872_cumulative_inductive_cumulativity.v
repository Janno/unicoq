From Unicoq Require Import Unicoq.

(* Rocq commit 531a7103f9082b6d6fc7df31fb8193a9cc68585a:
   evarconv respects the cumulative variance of inductive universes. *)
Local Set Universe Polymorphism.
Cumulative Inductive TM@{t} : Type@{t} -> Type :=
| tmReturn {A : Type@{t}} : A -> TM A
| tmBind {A B : Type@{t}} : TM A -> (A -> TM B) -> TM B.

Definition tmFix_body'@{a b f1 f2 fx fr}
  {A : Type@{a}} {B : Type@{b}}
  (f : (A -> TM@{f1} B) -> (A -> TM@{f2} B))
  (tmFix : unit -> A -> TM@{fx} B) : A -> TM@{fr} B :=
  f (fun a => tmBind@{fr} (tmReturn@{fr} tmFix)
         (fun tmFix => tmFix tt a)).
