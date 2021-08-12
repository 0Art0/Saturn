open Nat

class Prover(α: Type) where
  statement : (x : α) → Prop
  proof : (x : α) → statement x

def getProof{α : Type}[pr : Prover α](x: α) := pr.proof x 

def getProp{α : Type}[pr : Prover α](x: α) : Prop := pr.statement x 

def skip : Nat → Nat → Nat :=
    fun k =>
      match k with
      | 0 => 
          fun i =>
            i + 1
      | l + 1 => 
          fun j =>
            match j with
            | 0 => 0
            | i + 1 => 
                (skip l i) + 1

inductive SkipEquations(n m : Nat) where
  | lt : m < n → skip n m = m → SkipEquations n m
  | ge : n ≤ m → skip n m = m + 1 → SkipEquations n m   

inductive SkipImageCase(n m : Nat) where
  | diag : m = n → SkipImageCase n m
  | image : (k : Nat) → skip n k = m →  SkipImageCase n m

def skipEquations: (n : Nat) →  (m : Nat) →  SkipEquations n m := 
  fun k =>
      match k with
      | 0 => 
          fun i =>
            SkipEquations.ge (zeroLe _) rfl
      | l+1 => 
          fun j =>
            match j with
            | 0 => 
              SkipEquations.lt (zeroLtSucc _) rfl
            | i + 1 =>
              let unfold : skip (l + 1) (i + 1) = skip l i + 1 := by rfl 
                match skipEquations l i with
                | SkipEquations.lt ineq eqn => 
                  SkipEquations.lt 
                    (succ_lt_succ ineq) (
                      by  
                        rw unfold
                        rw eqn
                        done)
                | SkipEquations.ge ineq eqn =>
                    SkipEquations.ge (succLeSucc ineq) (
                      by  
                        rw unfold
                        rw eqn
                        done)

def skipImageCase : (n : Nat) →  (m : Nat) →  SkipImageCase n m := 
  fun k =>
      match k with
      | 0 => 
          fun j =>
            match j with 
            | 0 => SkipImageCase.diag rfl
            | i + 1 => SkipImageCase.image i rfl
      | l + 1 => 
          fun j =>
            match j with
            | 0 => 
              SkipImageCase.image 0 rfl
            | i + 1 =>               
                match skipImageCase l i with
                | SkipImageCase.diag  eqn => 
                    SkipImageCase.diag (by rw eqn)
                | SkipImageCase.image p eqn =>
                    let unfold : skip (l + 1) (p + 1) = skip l p + 1 := by rfl
                    SkipImageCase.image (p + 1) (by (rw unfold) (rw eqn))

theorem skipSuccNotZero : (n: Nat) → (j: Nat) → Not (skip n (succ j) = 0) :=
  fun n =>
  match n with 
  | 0 => 
    fun j =>
      fun hyp : succ (succ j) = 0 =>
        Nat.noConfusion hyp
  | m + 1 => 
    fun j =>
            match j with
            | 0 => 
              fun hyp : succ (skip m 0)  = 0 =>
                Nat.noConfusion hyp
            | i + 1 => 
              fun hyp =>
                let lem1 : skip (m + 1) (succ (i + 1)) = skip m (succ i) + 1 := by rfl
                let lem2 := Eq.trans (Eq.symm hyp) lem1
                Nat.noConfusion lem2

theorem skipInjective: (n: Nat) → (j1 : Nat) → (j2 : Nat) → 
                              (skip n j1 = skip n j2) → j1 = j2 :=
      fun n =>
      match n with
      | 0 =>
        fun j1 j2 =>
          fun eqn : succ j1 = succ j2 =>  
              by 
                injection eqn
                assumption
                done
      | m + 1 => 
        fun j1 =>
        match j1 with
        | 0 =>
          fun j2 =>
            match j2 with
            | 0 => fun _ => rfl
            | i2 + 1 => 
              fun hyp : 0 = skip (m + 1) (i2 + 1) =>
                let lem := skipSuccNotZero (m + 1) i2
                absurd (Eq.symm hyp) lem
        | i1 + 1 => 
          fun j2 =>
            match j2 with
            | 0 => fun hyp : skip (m + 1) (i1 + 1) = 0 =>
                let lem := skipSuccNotZero (m + 1) i1
                absurd hyp lem
            | i2 + 1 => 
              fun hyp : skip m i1 + 1 = skip m i2 + 1 =>
                let hyp1 : skip m i1 = skip m i2 := by
                  injection hyp
                  assumption
                  done
                let lem := skipInjective m i1 i2 hyp1
                congrArg succ lem


theorem skipBound: (k j: Nat) →  skip k j < j + 2 :=
    fun k j =>
      match skipEquations k j with
      | SkipEquations.lt _ eqn => 
          by 
            rw eqn
            apply Nat.leStep
            apply Nat.leRefl
            done
      | SkipEquations.ge _ eqn => 
        by 
          rw eqn
          apply Nat.leRefl
          done 

theorem skipLowerBound :(k j: Nat) →  j ≤ skip k j  :=
    fun k j =>
      match skipEquations k j with
      | SkipEquations.lt ineqn eqn => 
          by 
            rw eqn
            apply Nat.leRefl
            done
      | SkipEquations.ge ineqn eqn => 
        by 
          rw eqn
          apply Nat.leStep
          apply Nat.leRefl
          done

theorem skipSharpLowerBound :(k j: Nat) →  Or (j + 1 ≤ skip k j) (j <  k)  :=
    fun k j =>
      match skipEquations k j with
      | SkipEquations.lt ineqn eqn => 
          Or.inr ineqn
      | SkipEquations.ge ineqn eqn => 
          Or.inl (by 
                    rw eqn
                    apply Nat.leRefl
                    done)

def skipPlusOne {n k j : Nat} : j < n → skip k j < n + 1 := 
  fun h =>
    Nat.leTrans (skipBound k j) h

theorem skipNotDiag (k: Nat) : (j: Nat) → Not (skip k j = k) :=
  fun j =>
    match skipEquations k j with
    | SkipEquations.lt ineqn eqn => 
      fun hyp =>
        let lem1 : k ≤  j := by
          rw ←hyp 
          rw eqn
          apply Nat.leRefl
          done
        let lem2  := Nat.ltOfLtOfLe ineqn lem1
        notSuccLeSelf j lem2
    | SkipEquations.ge ineqn eqn => 
      fun hyp =>  
        let lem1 : j + 1 ≤ k := by
          rw ←hyp 
          rw eqn
          apply Nat.leRefl
          done
        let lem2 : j < j := Nat.leTrans lem1 ineqn
        Nat.ltIrrefl j lem2

def FinSeq (n: Nat) (α : Type) : Type := (k : Nat) → k < n → α

def FinSeq.cons {α : Type}{n: Nat}(head : α)(tail : FinSeq n α) : FinSeq (n + 1) α :=
  fun k =>
  match k with
  | 0 => fun _ => head
  | j + 1 => 
    fun w =>
      tail j (leOfSuccLeSucc w)

def FinSeq.empty {α: Type} : FinSeq 0 α := 
  fun j jw => nomatch jw

def seq{α : Type}(l : List α) : FinSeq (l.length) α := 
  fun j jw => l.get j jw


infixr:66 "+:" => FinSeq.cons

def tail {α : Type}{n: Nat}(seq : FinSeq (n + 1) α): FinSeq n α := 
  fun k w =>
      seq (k + 1) (succ_lt_succ w)

def head{α : Type}{n: Nat}(seq : FinSeq (n + 1) α): α :=
  seq 0 (zeroLtSucc _)

theorem headTail{α : Type}{n: Nat}(seq : FinSeq (n + 1) α): 
      (head seq) +: (tail seq) = seq := 
        funext (
          fun k => 
            match k with
            | 0 => by rfl 
            | i + 1 => by rfl
        )

def list{α : Type}{n : Nat}: FinSeq n α → List α :=
  match n with
  | 0 => fun _ => []
  | l + 1 => fun s => (head s) :: (list (tail s))


theorem nullsEqual{α: Type}(s1 s2 : FinSeq 0 α) : s1 = s2 :=
  funext (fun j =>
            funext (fun lt =>
              nomatch lt))

def delete{α : Type}{n: Nat}(k : Nat) (kw : k < (n + 1)) (seq : FinSeq (n + 1) α): FinSeq n α := 
  fun j w =>
    seq (skip k j) (skipPlusOne w)

structure ProvedInsert{α : Type}{n: Nat}(value : α) (seq : FinSeq n α)
                (k : Nat)(kw : k < n + 1)(j: Nat) (jw : j < n + 1) where
  result : α
  checkImage : (i : Nat) → (iw : i < n) → (skip  k i = j) → result = seq i iw
  checkFocus : j = k → result = value

theorem witnessIndependent{α : Type}{n : Nat}(seq: FinSeq n α) :
    (i : Nat)→ (j : Nat) → (iw : i < n) → (jw : j < n) → 
        (i = j) → seq i iw = seq j jw :=
        fun i j iw jw eqn =>
          match j, eqn, jw with 
          | .(i), rfl, ijw =>
               rfl

theorem skipPreImageBound {i j k n : Nat}: (k < n + 1) → (j < n + 1) → 
                                skip k i = j → i < n :=
          fun kw jw eqn =>
            match skipSharpLowerBound k i with
              | Or.inl ineq =>
                by 
                  have lem1 : i <  j
                  by
                    rw ← eqn
                    exact ineq
                    done                 
                  have lem2 : i < n
                  by
                    apply Nat.ltOfLtOfLe
                    apply lem1
                    apply jw
                    done 
                  exact lem2
                  done
              | Or.inr ineqn => 
                  Nat.ltOfLtOfLe ineqn kw

def provedInsert{α : Type}(n: Nat)(value : α) (seq : FinSeq n α)
                (k : Nat)(kw : k < n + 1)(j: Nat) (jw : j < n + 1) : 
                  ProvedInsert value seq k kw j jw := 
          match skipImageCase k j with
          | SkipImageCase.diag eqn => 
            let result := value
            let checkImage : 
              (i : Nat) → (iw : i < n) → (skip  k i = j) → result = seq i iw := 
                fun i iw hyp =>
                  let lem : skip k i = k := by
                    rw hyp
                    rw eqn
                    done
                  let contra := skipNotDiag k i lem
                  nomatch contra
            let  checkFocus : j = k → result = value := fun  _  => rfl
            ⟨result, checkImage, checkFocus⟩
          | SkipImageCase.image i eqn => 
            let bound : i < n  := skipPreImageBound kw jw eqn
            let result := seq i bound
            let checkImage : 
              (i : Nat) → (iw : i < n) → (skip  k i = j) → result = seq i iw := 
                fun i1 iw1 hyp =>
                  let lem1 : i1 = i := by 
                    apply (skipInjective k)
                    rw hyp
                    rw (Eq.symm eqn)
                    done
                  let lem2 : seq i1 iw1 = seq i bound := 
                    witnessIndependent seq i1 i iw1 bound lem1
                  by
                    rw lem2
                    done
            let  checkFocus : j = k → result = value := 
              fun  hyp  => 
                let lem : skip k i = k := by
                    rw eqn
                    rw hyp
                    done
                  let contra := skipNotDiag k i lem
                  nomatch contra 
            ⟨result, checkImage, checkFocus⟩

def insert{α : Type}(value: α) : (n : Nat) →  (k: Nat) → 
    (lt : k < succ n) → (FinSeq n   α) →  (FinSeq (Nat.succ n)  α) := 
  fun n k lt seq j w =>  
    (provedInsert n value seq k lt j w).result

def insertAtFocus{α : Type}(value: α) : (n : Nat) →  (k: Nat) → 
    (lt : k < succ n) → (seq :FinSeq n   α) →  
      insert value n k lt seq k lt = value :=
    fun n k lt seq  =>   
      (provedInsert n value seq k lt k lt).checkFocus rfl

def insertAtImage(value: α) : (n : Nat) →  (k: Nat) → 
    (lt : k < succ n) → (seq :FinSeq n   α) → (i : Nat) → (iw : i < n) → 
      insert value n k lt seq (skip k i) (skipPlusOne iw) = seq i iw :=
      fun n k lt seq i iw => 
       (provedInsert n value seq k lt (skip k i) (skipPlusOne iw)).checkImage i iw rfl 

def insertDelete{α : Type}{n: Nat}(k : Nat) (kw : k < (n + 1)) (seq : FinSeq (n + 1) α) :
  insert (seq k kw) n k kw (delete k kw seq) = seq := 
    let delSeq := delete k kw seq
    funext (
      fun j =>
        funext (
          fun jw => 
            match skipImageCase k j with
            | SkipImageCase.diag eqn => 
              by
              have lem1 : insert (seq k kw) n k kw (delete k kw seq) j jw =
                insert (seq k kw) n k kw (delete k kw seq) k kw 
                by
                  apply witnessIndependent
                  apply eqn
                  done 
              rw lem1
              rw (insertAtFocus (seq k kw) n k kw (delete k kw seq))
              apply witnessIndependent
              rw ← eqn
              done  
            | SkipImageCase.image i eqn => 
              let iw : i < n := skipPreImageBound kw jw eqn
              let lem1 : insert (seq k kw) n k kw (delete k kw seq) j jw
                = insert (seq k kw) n k kw (delete k kw seq) (skip k i) (skipPlusOne iw) := 
                  by 
                    apply witnessIndependent
                    rw ← eqn
                    done
              let lem2 := insertAtImage (seq k kw) n k kw (delete k kw seq) i iw
              let lem3 : delete k kw seq i iw = seq (skip k i) (skipPlusOne iw) := by rfl
              by
                rw lem1
                rw lem2
                rw lem3
                apply witnessIndependent
                exact eqn
                done
        )
    )

structure ElemInSeq{α: Type}{n : Nat} (seq : FinSeq n α) (elem : α) where
  index: Nat
  bound : index < n
  equation : seq index bound = elem

inductive ExistsElem{α: Type}{n : Nat} (seq : FinSeq n α) (elem : α) where
  | exsts : (index: Nat) →  (bound : index < n) → 
            (equation : seq index bound = elem) → ExistsElem seq elem
  | notExst : ((index: Nat) →  (bound : index < n) → 
                 Not (seq index bound = elem)) → ExistsElem seq elem 



structure ElemSeqPred{α: Type}{n : Nat} (seq : FinSeq n α) (pred : α → Prop) where
  index: Nat
  bound : index < n
  equation : pred (seq index bound)

def find?{α: Type}{n : Nat}(pred : α → Prop)[DecidablePred pred]:
  (seq : FinSeq n α) → Option (ElemSeqPred seq pred) :=
  match n with
  | 0 => fun seq => none
  | m + 1 =>
      fun seq =>
        if c : pred (head seq) then
          some ⟨0, zeroLtSucc _, c⟩
        else 
          (find? pred (tail seq)).map (fun ⟨i, iw, eqn⟩ => 
            ⟨i +1, succ_lt_succ iw, eqn⟩)

def findElem?{α: Type}[deq: DecidableEq α]{n: Nat}: 
  (seq: FinSeq n  α) → (elem: α) →  Option (ElemInSeq seq elem) :=
    match n with
    | 0 => fun _  => fun _ => none
    | m + 1 => 
      fun fn =>
        fun x =>
          if pf : fn 0 (zeroLtSucc m) =  x then
            some ⟨0, (zeroLtSucc m), pf⟩
          else
            let pred := findElem? (tail fn) x
            pred.map (fun ⟨j, jw, eql⟩ => 
              let l1 : fn (j + 1) (succ_lt_succ jw) = (tail fn) j jw := by rfl 
              let l2 : fn (j + 1) (succ_lt_succ jw) = x := by 
                    rw l1
                    exact eql
              ⟨j + 1 , succ_lt_succ jw, l2⟩ 
            )

def searchElem{α: Type}[deq: DecidableEq α]{n: Nat}: 
  (seq: FinSeq n  α) → (elem: α) →  ExistsElem seq elem :=
    match n with
    | 0 => fun seq  => fun elem => ExistsElem.notExst (fun j jw => nomatch jw)
    | m + 1 => 
      fun fn =>
        fun x =>
          if pf0 : fn 0 (zeroLtSucc m) =  x then
            ExistsElem.exsts 0 (zeroLtSucc m) pf0
          else
            match searchElem (tail fn) x with
            | ExistsElem.exsts j jw eql => 
              let l1 : fn (j + 1) (succ_lt_succ jw) = (tail fn) j jw := by rfl 
              let l2 : fn (j + 1) (succ_lt_succ jw) = x := by 
                    rw l1
                    exact eql
              ExistsElem.exsts (j + 1) (succ_lt_succ jw) l2              
            | ExistsElem.notExst tailPf => 
                  ExistsElem.notExst (
                    fun j =>
                    match j with
                    | 0 => fun jw => pf0 
                    | i + 1 => fun iw => tailPf i (leOfSuccLeSucc iw)
                  )

structure ProvedUpdate{α β: Type}(fn : α → β)( a : α )( val : β )( x : α) where
  result : β
  checkFocus : (x = a) → result = val
  checkNotFocus : Not (x = a) → result = fn x

def provedUpdate{α β: Type}[DecidableEq α](fn : α → β)( a : α )( val : β )( x : α) : 
  ProvedUpdate fn a val x :=
    if c : x = a then 
      let result := val
      let checkFocus : (x = a) → result = val := fun _ => rfl
      let checkNotFocus : Not (x = a) → result = fn x := fun d => absurd c d
      ⟨result, checkFocus, checkNotFocus⟩
    else 
      let result := fn x
      let checkFocus : (x = a) → result = val := fun d => absurd d c
      let checkNotFocus : Not (x = a) → result = fn x := fun _ => rfl 
      ⟨result, checkFocus, checkNotFocus⟩

def update{α β : Type}[DecidableEq α](fn : α → β)( a : α )( val : β )( x : α) : β :=
  (provedUpdate fn a val x).result

def updateAtFocus{α β: Type}[DecidableEq α](fn : α → β)( a : α )( val : β ) :
  (update fn a val a = val) := (provedUpdate fn a val a).checkFocus rfl

def updateNotAtFocus{α β: Type}[DecidableEq α](fn : α → β)( a : α )( val : β )( x : α) :
  Not (x = a) →  (update fn a val x = fn x) :=
    fun hyp =>
      (provedUpdate fn a val x).checkNotFocus hyp

structure ProvedUpdateType{α : Type}(fn : α → Type)( a : α )( val : Type )( x : α) where
  result : Type
  checkFocus : (x = a) → result = val
  checkNotFocus : Not (x = a) → result = fn x

def provedUpdateType{α : Type}[DecidableEq α](fn : α → Type)( a : α )( val : Type )( x : α) : 
  ProvedUpdateType fn a val x :=
    if c : x = a then 
      let result := val
      let checkFocus : (x = a) → result = val := fun _ => rfl
      let checkNotFocus : Not (x = a) → result = fn x := fun d => absurd c d
      ⟨result, checkFocus, checkNotFocus⟩
    else 
      let result := fn x
      let checkFocus : (x = a) → result = val := fun d => absurd d c
      let checkNotFocus : Not (x = a) → result = fn x := fun _ => rfl 
      ⟨result, checkFocus, checkNotFocus⟩

def updateType{α: Type}[DecidableEq α](fn : α → Type)( a : α )( val : Type )( x : α) : Type :=
  (provedUpdateType fn a val x).result

def updateAtFocusType{α : Type}[DecidableEq α](fn : α → Type)( a : α )( val : Type ) :
  (updateType fn a val a = val) := (provedUpdateType fn a val a).checkFocus rfl

def updateNotAtFocusType{α : Type}[DecidableEq α](fn : α → Type)( a : α )( val : Type )( x : α) :
  Not (x = a) →  (updateType fn a val x = fn x) :=
    fun hyp =>
      (provedUpdateType fn a val x).checkNotFocus hyp


structure ProvedDepUpdate{α :Type}[DecidableEq α]{β : α → Type}(fn : (x :α) → β x)
          ( a : α )(ValType : Type)( val : ValType )
            ( x : α) where
  result : updateType β a ValType x
  checkFocus : (eqn : x = a) → result = 
          Eq.mpr (by 
            rw eqn
            apply updateAtFocusType
            done 
            ) val
  checkNotFocus : (neq:  Not (x = a)) → result = 
          Eq.mpr (by
            apply updateNotAtFocusType 
            exact neq
            done)  (fn x)


structure GroupedSequence {n: Nat} {α β : Type}(part : α → β)(seq : FinSeq n α) where
  length : β → Nat
  seqs : (b : β) → FinSeq (length b) α
  proj: (j : Nat) → (jw : j < n) → ElemInSeq (seqs (part (seq j jw))) (seq j jw)
  sects : (b : β) → (j : Nat) → (jw : j < length b) → Nat
  sectsBound : (b : β) → (j : Nat) → (jw : j < length b) → sects b j jw < n
  equations: (b : β) → (j : Nat) → (jw : j < length b) → 
          (proj (sects b j jw) (sectsBound b j jw)).index = j


structure GroupedSequenceBranch{n: Nat} {α β : Type}(part : α → β)
      (seq : FinSeq n α)(b : β) where
  length : Nat
  seqs : FinSeq (length) α
  proj: (j : Nat) → (jw : j < n) → part (seq j jw) = b  → ElemInSeq seqs (seq j jw)
  sects : (j : Nat) → (jw : j < length) → ElemInSeq seq (seqs j jw)
  groupPart : (j : Nat) → (jw : j < length) → part (seqs j jw) = b
  
def groupedPrepend{n: Nat} {α β : Type}[DecidableEq β]{part : α → β}{seq : FinSeq n α} 
      (gps : (b: β) →   GroupedSequenceBranch part seq b) :
              (head: α) → 
                ((b: β) →  GroupedSequenceBranch part (head +: seq) b) := 
                fun head b =>
                  let seqN := head +: seq
                  let br := gps b 
                  if c : part head = b then                    
                    let lengthN := br.length + 1
                    let seqsN := head +: br.seqs
                    let projN : 
                      (j : Nat) → (jw : j < n + 1) → part (seqN j jw) = 
                          b  → ElemInSeq seqsN (seqN j jw) := 
                          fun j =>
                          match j with
                          | 0 =>
                            fun jw eqn =>
                            ⟨0, zeroLtSucc _, rfl⟩
                          | l + 1 => 
                            fun jw eqn =>
                            let lw : l < n := leOfSuccLeSucc jw
                            let ⟨i, iw, ieq⟩ := br.proj l lw eqn
                            let lem1 : seqN (l + 1) jw = seq l lw := rfl
                            let lem2 : seqsN (i + 1) (succ_lt_succ iw) =
                                    br.seqs i iw := by rfl
                            ⟨i + 1, succ_lt_succ iw, by (
                              rw lem2
                              rw lem1
                              exact ieq
                            )⟩
                    let sectsN : (j : Nat) → (jw : j < lengthN) → 
                          ElemInSeq seqN (seqsN j jw) :=
                        fun j =>
                          match j with
                          | 0 =>
                            fun jw  =>
                            ⟨0, zeroLtSucc _, rfl⟩
                          | l + 1 => 
                            fun jw  =>
                            let lw : l < br.length := leOfSuccLeSucc jw
                            let ⟨i, iw, ieq⟩ := br.sects l lw
                            let lem1 : seqsN (l + 1) jw = br.seqs l lw := rfl
                            let lem2 : seqN (i + 1) (succ_lt_succ iw) =
                                    seq i iw := by rfl
                            ⟨i + 1, succ_lt_succ iw, by (
                              rw lem2
                              rw lem1
                              exact ieq
                            )⟩
                      let groupPartN : (j : Nat) → (jw : j < lengthN) → 
                        part (seqsN j jw) = b := 
                          fun j =>
                          match j with
                          | 0 =>
                            fun jw  =>
                            c
                          | l + 1 => 
                            fun jw  =>
                            let lw : l < br.length := leOfSuccLeSucc jw
                            let ⟨i, iw, ieq⟩ := br.sects l lw
                            br.groupPart l lw
                    ⟨lengthN, seqsN, projN, sectsN, groupPartN⟩
                  else
                    let lengthN := br.length
                    let seqsN := br.seqs 
                    let projN : 
                      (j : Nat) → (jw : j < n + 1) → part (seqN j jw) = 
                          b  → ElemInSeq seqsN (seqN j jw) := 
                          fun j =>
                          match j with
                          | 0 =>
                            fun jw eqn =>
                              absurd eqn c
                          | l + 1 => 
                            fun jw eqn =>
                            let lw : l < n := leOfSuccLeSucc jw
                            br.proj l lw eqn
                    let sectsN : (j : Nat) → (jw : j < lengthN) → 
                          ElemInSeq seqN (seqsN j jw) := 
                          fun j jw =>
                            let ⟨i, iw, ieq⟩ := br.sects j jw
                            let lem1 : seqsN j jw = br.seqs j jw := rfl
                            let lem2 : seqN (i + 1) (succ_lt_succ iw) =
                                    seq i iw := by rfl
                            ⟨i + 1, succ_lt_succ iw, by (
                              rw lem2
                              rw lem1
                              exact ieq
                            )⟩
                    let groupPartN : (j : Nat) → (jw : j < lengthN) → 
                        part (seqsN j jw) = b := 
                          fun j jw => br.groupPart j jw
                    ⟨lengthN, seqsN, projN, sectsN, groupPartN⟩ 

def groupedSequence{n: Nat} {α β : Type}[DecidableEq β](part : α → β) :
      (seq: FinSeq n α) → 
      ((b: β) →   GroupedSequenceBranch part seq b) :=  
          match n with 
          | 0 => fun seq b => 
            ⟨0, FinSeq.empty, fun j jw => nomatch jw , fun j jw => nomatch jw, 
                fun j jw => nomatch jw⟩
          | m + 1 => 
            fun seq  =>
              let step :=
                groupedPrepend (fun b => groupedSequence part (tail seq) b) (head seq)
              let lem1 := headTail seq
              by
                rw Eq.symm lem1
                exact step
                done


def enumOptBool : (n : Nat) → n < 2 → Option Bool :=
  fun n =>
  match n with
  | 0 => fun _ => some true
  | 1 => fun _ => some false
  | 2 => fun _ => none
  | l + 2 => fun w => nomatch w

class FinType(α : Type) where
  length : Nat
  enum : (j: Nat) → j < n → α
  enumInv : α → Nat
  enumInvBound : (x : α) → enumInv x < length
  enumEnumInv : (x : α) → enum (enumInv x) (enumInvBound x) = x
  enumInvEnum : (j: Nat) → (jw : j < n) → enumInv (enum j jw) = j

def element{α: Type}[ft : FinType α]: (j : Nat) → (j < ft.length) → α :=
      fun j jw => ft.enum j jw

def ordinal{α: Type}[ft : FinType α]: α → Nat :=
  fun x => ft.enumInv x

def size(α: Type)[ft : FinType α]: Nat := ft.length

def ordinalBound{α: Type}[ft : FinType α]: (x : α) → ordinal x < size α :=
  fun x => ft.enumInvBound x

def ordElem{α: Type}[ft : FinType α]: (j : Nat) → (jw : j < ft.length) → 
              ordinal (element j jw) = j := ft.enumInvEnum 

def elemOrd{α: Type}[ft : FinType α]: (x : α) → 
              element (ordinal x) (ordinalBound x) = x := ft.enumEnumInv

structure FlattenSeq{α : Type}{n: Nat}(lengths : (j : Nat) → j < n → Nat)
                                    (seqs : (j : Nat) → (jw : j < n) → FinSeq (lengths j jw) α) where
          length : Nat
          seq : FinSeq length α
          forward: (j : Nat) → (jw : j < length) → Σ (i : Nat), (iw : i < n) → 
                      ElemInSeq (seqs i iw) (seq j jw)
          reverse: (i : Nat) → (iw : i < n) → (j : Nat) → (jw : j < lengths i iw) → 
                      ElemInSeq seq (seqs i iw j jw)

#check Nat.zeroLe

structure PartialFlattenSeq{α : Type}{n: Nat}(lengths : (j : Nat) → j < n → Nat)
                            (seqs : (j : Nat) → (jw : j < n) → FinSeq (lengths j jw) α) 
                            (gp : Nat)(gpBound : gp < n)(max: Nat)(maxBound : max ≤  lengths gp gpBound)
                                        where
          length : Nat
          seq : FinSeq length α
          forward: (j : Nat) → (jw : j < length) → Σ (i : Nat), (iw : i < n) → 
                      ElemInSeq (seqs i iw) (seq j jw)
          reverse: (i : Nat) → (iw : i < n) → (j : Nat) → (jw : j < lengths i iw) → 
                    i < gp ∨ (i = gp ∧ j < max)  → 
                      ElemInSeq seq (seqs i iw j jw)

def partToFullFlatten{α : Type}{n: Nat}(lengths : (j : Nat) → j < n + 1 → Nat)
                                    (seqs : (j : Nat) → (jw : j < n + 1) → FinSeq (lengths j jw) α) :
                PartialFlattenSeq lengths seqs n (Nat.leRefl _) 
                    (lengths n (Nat.leRefl _)) (Nat.leRefl _) → 
                    FlattenSeq lengths seqs  := 
                    fun pfs => 
                      let reverseN : (i : Nat) → (iw : i < (n +1)) → 
                        (j : Nat) → (jw : j < lengths i iw) → 
                        ElemInSeq pfs.seq (seqs i iw j jw) := 
                          fun i iw j jw =>
                            let lem : i < n ∨ (i = n ∧ 
                              j < lengths n (Nat.leRefl (succ n))) :=
                                let switch := Nat.eqOrLtOfLe iw
                                match switch with 
                                | Or.inl p => 
                                  let p1 : i = n := by
                                    injection p
                                    assumption
                                  let lem : lengths n (Nat.leRefl (succ n)) =
                                            lengths i iw := by
                                          apply witnessIndependent
                                          exact Eq.symm p1
                                          done
                                  Or.inr (And.intro p1 (by 
                                                          rw lem
                                                          exact jw))
                                | Or.inr p => 
                                    Or.inl (leOfSuccLeSucc p)
                            pfs.reverse i iw j jw lem
                      ⟨pfs.length, pfs.seq, pfs.forward, reverseN⟩

#check Eq.ndrec
#check 1 ≅ [3]
#check HEq.ndrec


def partFlatInGp{α : Type}{n: Nat}(lengths : (j : Nat) → j < n → Nat)
                          (seqs : (j : Nat) → (jw : j < n) → FinSeq (lengths j jw) α) 
                          (gp : Nat)(gpBound : gp < n)
                            (base: PartialFlattenSeq lengths seqs gp gpBound 0 (Nat.zeroLe _)):
                          (max: Nat) → (maxBound : max ≤  lengths gp gpBound) → 
                            PartialFlattenSeq lengths seqs gp gpBound max maxBound := 
                  fun max => 
                  match max with
                  | 0 => fun _ =>
                      base
                  | k + 1 =>
                    fun maxBound => 
                      let prev := partFlatInGp lengths seqs gp gpBound base k (leStep maxBound)
                      let head := seqs gp gpBound k maxBound
                      let lengthN := prev.length +1
                      let seqN := head +: prev.seq 
                      let forwardN : (j : Nat) → (jw : j < lengthN) → Σ (i : Nat), (iw : i < n) → 
                            ElemInSeq (seqs i iw) (seqN j jw) := 
                              fun j =>
                              match j with
                              | 0 => 
                                fun jw =>
                                  ⟨gp, fun w => ⟨k, maxBound, rfl⟩⟩
                              | l + 1 => 
                                fun jw =>
                                  let lw := leOfSuccLeSucc jw
                                  by
                                    apply (prev.forward l lw)
                                    done
                      let reverseN : (i : Nat) → (iw : i < n) → (j : Nat) → (jw : j < lengths i iw) → 
                          i < gp ∨ (i = gp ∧ j < k + 1)  → 
                          ElemInSeq seqN (seqs i iw j jw) := 
                          fun i iw j jw p =>
                            if c : i < gp then 
                              let ⟨ind, bd, eqn⟩ := prev.reverse i iw j jw (Or.inl c)
                              let lem : seqN (ind + 1) (succ_lt_succ bd) =
                                      prev.seq ind bd := by rfl
                              ⟨ind + 1, succ_lt_succ bd, (by 
                                      rw lem
                                      exact eqn
                                      )⟩
                            else
                              let q : i = gp ∧ j < k + 1 := 
                                match p with
                                | Or.inl eqn => absurd eqn c
                                | Or.inr eqn => eqn
                              let q1 : i = gp := q.left
                              let q2 := q.right
                              if mc : j = k then
                                let lem : 
                                  seqN 0 (zeroLtSucc prev.length) = seqs gp gpBound k maxBound := by rfl
                                let lem1 : lengths i iw = lengths gp gpBound := by
                                  apply witnessIndependent
                                  rw q1
                                  done
                                let lem2 := congrArg FinSeq lem1
                                let trnsport : FinSeq (lengths i iw) α  → FinSeq (lengths gp gpBound) α  :=
                                  fun fs =>
                                    by 
                                      rw (Eq.symm lem2)
                                      exact fs
                                      done                                    
                                let lem3 : seqs i  ≅ seqs gp  := by
                                    rw q1
                                    apply HEq.rfl
                                    done
                                  
                                let goal : seqs gp gpBound k maxBound = seqs i iw j jw := 
                                    match i, q1, j, mc, iw, jw with  
                                    | .(gp), rfl, .(k), rfl, iww, jww => rfl 
                                ⟨0, zeroLtSucc _, (by 
                                  rw lem
                                  exact goal
                                  done
                                )⟩
                              else 
                                let jww : j < k := 
                                  match Nat.eqOrLtOfLe q2 with
                                  | Or.inl ee => 
                                      let ll : j = k := by
                                      injection ee
                                      assumption 
                                    absurd ll mc
                                  | Or.inr ee => leOfSuccLeSucc ee
                                let ⟨ind, bd, eqn⟩ := prev.reverse i iw j jw (Or.inr (And.intro q1 jww))
                                let lem : seqN (ind + 1) (succ_lt_succ bd) =
                                      prev.seq ind bd := by rfl
                               ⟨ind + 1, succ_lt_succ bd, (by 
                                      rw lem
                                      exact eqn
                                      )⟩
                      ⟨lengthN , seqN, forwardN, reverseN⟩ 

def partFlatOrigin{α : Type}{n: Nat} : (lengths : (j : Nat) → j < n → Nat) → 
                          (seqs : (j : Nat) → (jw : j < n) → FinSeq (lengths j jw) α) → 
                          (gpBound : 0 < n) → 
                            (PartialFlattenSeq lengths seqs 0 gpBound 0 (Nat.zeroLe _)) :=
              match n with
              | 0 => fun _ _ w => nomatch w
              | m + 1 =>
                fun lengths seqs gpBound =>
                  let seqN : FinSeq 0 α := FinSeq.empty
                  let forwardN : (j : Nat) → (jw : j < 0) → Σ (i : Nat), (iw : i < m + 1) → 
                      ElemInSeq (seqs i iw) (seqN j jw) := fun j jw => nomatch jw 
                  let reverseN : (i : Nat) → (iw : i < m + 1) → (j : Nat) → (jw : j < lengths i iw) → 
                    i < 0 ∨ (i = 0 ∧ j < 0)  → 
                      ElemInSeq seqN (seqs i iw j jw) :=   
                        fun i iw j jw p => 
                          let q : ¬(i < 0 ∨ i = 0 ∧ j < 0) := 
                            match p with
                            | Or.inl p1 => nomatch p1
                            | Or.inr p2 => nomatch p2
                          absurd p q 
                  ⟨0, seqN, forwardN, reverseN⟩

def partFlatZeroBound{α : Type}{n: Nat}(lengths : (j : Nat) → j < n + 1 → Nat)
                                    (seqs : (j : Nat) → (jw : j < n + 1) → FinSeq (lengths j jw) α) :                
            (gp : Nat) → (gpBound : gp < n + 1) → 
                            PartialFlattenSeq lengths seqs gp gpBound 0 (Nat.zeroLe _) :=
              fun gp => 
                match gp with
                | 0 => by 
                          intro gpBound
                          apply partFlatOrigin
                          done
                | l + 1 => 
                  fun gpBound => 
                    let base := partFlatZeroBound lengths seqs l (leStep gpBound)
                    let pfs := partFlatInGp lengths seqs l (leStep gpBound) base
                                  (lengths l (leStep gpBound)) (Nat.leRefl _)
                    let reverseN : (i : Nat) → (iw : i < (n +1)) → 
                        (j : Nat) → (jw : j < lengths i iw) → 
                        i < l + 1 ∨ (i = l + 1 ∧ j < 0)  →
                        ElemInSeq pfs.seq (seqs i iw j jw) := 
                          fun i iw j jw p0 =>
                            let lem : i < l ∨ (i = l ∧ 
                              j < lengths l (leStep gpBound)) := 
                               match p0 with
                               | Or.inr pw => 
                                      let w := pw.right
                                      nomatch w
                               | Or.inl pw => 
                                let switch := Nat.eqOrLtOfLe pw
                                match switch with 
                                | Or.inl p => 
                                  let p1 : i = l := by
                                    injection p
                                    assumption
                                  let lem : lengths l (leStep gpBound) =
                                            lengths i iw := by
                                          apply witnessIndependent
                                          exact Eq.symm p1
                                          done
                                  Or.inr (And.intro p1 (by 
                                                          rw lem
                                                          exact jw))
                                | Or.inr p => 
                                    Or.inl (leOfSuccLeSucc p)
                            pfs.reverse i iw j jw lem
                    ⟨pfs.length, pfs.seq, pfs.forward, reverseN⟩

def flattenSeq{α : Type}{n: Nat} : 
    (lengths : (j : Nat) → j < n → Nat) → 
      (seqs : (j : Nat) → (jw : j < n) → FinSeq (lengths j jw) α) → 
      FlattenSeq lengths seqs := 
        match n with
        | 0 => fun _ _ => ⟨0, FinSeq.empty, 
                            fun j jw => nomatch jw, 
                            fun i iw => nomatch iw⟩ 
        | m + 1 => 
          fun lengths seqs => 
            let base := partFlatZeroBound lengths seqs m (Nat.leRefl _) 
            let pfs := partFlatInGp lengths seqs m (Nat.leRefl _) base 
                          (lengths m (Nat.leRefl _)) (Nat.leRefl _)
            partToFullFlatten lengths seqs pfs



def findSome?{α β : Type}{n: Nat}(f : α → Option β) : (FinSeq n  α) → Option β :=
    match n with
    | 0 => fun _ => none
    | m + 1 => 
      fun seq => 
        (f (seq 0 (zeroLtSucc m))).orElse (
          findSome? f (fun t : Nat => fun w : t < m => seq (t + 1) w )
        ) 


def varSat (clVal: Option Bool)(valuatVal : Bool) : Prop := clVal = some valuatVal


def Clause(n : Nat) : Type := FinSeq n (Option Bool)

def Valuat(n: Nat) : Type := FinSeq n  Bool



structure ClauseSat{n: Nat}(clause : Clause n)(valuat: Valuat n) where
  coord : Nat
  bound : coord < n  
  witness: varSat (clause coord bound) (valuat coord bound)

def clauseSat {n: Nat}(clause : Clause n)(valuat: Valuat n) := 
  ∃ (k : Nat), ∃ (b : k < n), varSat (clause k b) (valuat k b)

instance {n: Nat}(clause : Clause n)(valuat: Valuat n): Prover (ClauseSat clause valuat) where 
  statement := fun cs => ∃ (k : Nat), ∃ (b : k < n), varSat (clause k b) (valuat k b)
  proof := fun cs => ⟨cs.coord, ⟨cs.bound, cs.witness⟩⟩

def contrad(n: Nat) : Clause n :=
  fun _ _ => none

theorem contradFalse (n: Nat) : ∀ valuat : Valuat n, Not (clauseSat (contrad n) valuat) :=
  fun valuat => fun ⟨k, ⟨b, p⟩⟩ => 
    let lem1 : (contrad n) k b = none := by rfl
    let lem2 := congrArg varSat lem1
    let lem3 : varSat (contrad n k b) (valuat k b) = 
                varSat none (valuat k b) := congr lem2 rfl
    let lem4 : (varSat none (valuat k b)) = (none = some (valuat k b)) := rfl
    let lem5 : (none = some (valuat k b)) := by
      rw (Eq.symm lem4)
      rw lem4
      assumption
      done 
    Option.noConfusion lem5

theorem contradInsNone{n : Nat} (focus: Nat)(focusLt : focus < n + 1) :
      insert none n focus focusLt (contrad n) =
                            contrad (n + 1) :=
      let lem0 : (j: Nat) → (jw : j < n + 1) →  
            insert none n focus focusLt (contrad n) j jw  =
                      contrad (n + 1) j jw := 
                      fun j jw =>
                      let lem0 : contrad (n + 1) j jw = none := by rfl
                      match skipImageCase focus j with
                      | SkipImageCase.diag eqn => 
                        match focus, eqn, focusLt with
                        | .(j), rfl, .(jw) =>
                          by
                            apply insertAtFocus 
                            done                                
                      | SkipImageCase.image i eqn => 
                        let iw := skipPreImageBound focusLt jw eqn
                        match j, eqn, jw, lem0 with
                        | .(skip focus i), rfl, .(skipPlusOne iw), lem1 =>  
                          by
                            rw lem1
                            apply insertAtImage
                            exact iw
                            done                               
                 by
                    apply funext
                    intro j
                    apply funext
                    intro jw
                    apply lem0
                    done

def deqSeq {α : Type}[DecidableEq α] (n: Nat) : (c1 : FinSeq n  α) → 
                              (c2: FinSeq n  α) → Decidable (c1 = c2) := 
  match n with
  | 0 => 
    fun c1 c2 => 
      isTrue (funext 
        (fun x => 
          funext (fun w => nomatch w)))
  | m + 1 => 
    fun c1 c2 =>
      match deqSeq _ (tail c1) (tail c2) with
      | isTrue h => 
          if c : c1 0 (zeroLtSucc m) = c2 (0) (zeroLtSucc m) then
            isTrue 
              (funext fun k =>
                match k with
                | 0 => funext (fun w =>  c)
                | j+ 1 => funext (fun  w => 
                  let l1 : tail c1 j w = c1 (j + 1) w := by rfl
                  let l2 : tail c2 j w = c2 (j + 1) w := by rfl
                  by 
                    rw (Eq.symm l1)                    
                    rw (Eq.symm l2)
                    rw h
                    done
                    ))
          else 
            isFalse (
              fun hyp =>
                let lem : c1 0 (zeroLtSucc m) = c2 0 (zeroLtSucc m) := by
                  rw hyp
                c lem
            )
      |isFalse h => 
        isFalse (
          fun hyp => 
            let lem : (tail c1) = (tail c2) := 
              funext (
                fun j =>
                funext (
                fun w =>
                  let l1 : tail c1 j w = c1 (j + 1) w := by rfl 
                  let l2 : tail c2 j w = c2 (j + 1) w := by rfl                   
                  by 
                    rw l1
                    rw hyp
                    apply Eq.symm
                    exact l2
                    done
                    )
              )
            h lem)

instance {n: Nat}[DecidableEq α] : DecidableEq (FinSeq n  α) := fun c1 c2 => deqSeq _ c1 c2


def unitClause(n : Nat)(b : Bool)(k : Nat) (w : k < n + 1):   Clause (n + 1):=
  insert (some b) n k w (contrad n) 

theorem unitDiag(n : Nat)(b : Bool)(k : Nat) (w : k < n + 1): 
          unitClause n b k w k w = b :=
          insertAtFocus (some b) n k w (contrad n)

theorem unitSkip(n : Nat)(b : Bool)(k : Nat) (w : k < n + 1): 
          (i: Nat) → (iw : i < n) →  unitClause n b k w (skip k i) 
                  (skipPlusOne iw) = none := fun i iw => 
          insertAtImage (some b) n k w (contrad n) i iw

structure IsUnitClause{n: Nat}(clause: Clause (n +1)) where
  index: Nat 
  bound : index < n + 1
  parity: Bool
  equality : clause = unitClause n parity index bound

def clauseUnit{n: Nat}(clause: Clause (n + 1)) : Option (IsUnitClause clause) :=
  let f : Fin (n + 1) →   (Option (IsUnitClause clause)) := 
    fun ⟨k, w⟩ =>
      match deqSeq _ clause  (unitClause n true k w) with 
      | isTrue pf => 
        let cl : IsUnitClause clause := IsUnitClause.mk k w true pf 
        some (cl)
      | isFalse _ => 
        match deqSeq _ clause  (unitClause n false k w) with 
      | isTrue pf => 
        let cl : IsUnitClause clause := IsUnitClause.mk k w false pf 
        some (cl)
      | isFalse _ => none  
  let seq : FinSeq (n + 1) (Fin (n + 1)) := fun k w => ⟨k, w⟩
  findSome? f seq

structure SomeUnitClause{l n : Nat}(clauses : FinSeq l  (Clause (n + 1))) where
  pos: Nat
  posBound : pos < l
  index: Nat 
  bound : index < n + 1
  parity: Bool
  equality : clauses pos posBound = unitClause n parity index bound

def someUnitClause {l : Nat} {n : Nat}: (clauses : FinSeq l  (Clause (n + 1))) →  
  Option (SomeUnitClause clauses)  := 
    match l with 
    | 0 => fun  _ =>  none
    | m + 1 => 
      fun  cls =>
        match clauseUnit (cls 0 (zeroLtSucc m)) with
        | some u => some ⟨0, zeroLtSucc _, u.index, u.bound, u.parity, u.equality⟩ 
        | none => 
          let tcls := tail cls
          let tail := someUnitClause  tcls
          match tail with
          | some ⟨i, w, index, bd, par, eql⟩ => 
            some ⟨i + 1, leOfSuccLeSucc w, index, bd, par, eql⟩
          | none => none

structure HasPureVar{dom n : Nat}(clauses : FinSeq dom  (Clause n)) where
  index : Nat
  bound : index < n
  parity : Bool
  evidence : (k : Nat) → (lt : k < dom) → 
          (clauses k lt index bound = none) ∨  (clauses k lt index bound = some parity)

structure IsPureVar{dom n : Nat}(clauses : FinSeq dom  (Clause n))
                      (index: Nat)(bound : index < n)(parity : Bool) where
  evidence : (k : Nat) → (lt : k < dom) → (clauses k lt index bound = none) ∨ 
                                (clauses k lt index bound = some parity)

def varIsPure{n : Nat}(index: Nat)(bound : index < n)(parity : Bool) : 
  (dom: Nat) →  (clauses : FinSeq dom  (Clause n)) → 
    Option (IsPureVar clauses index bound parity) :=
  fun dom =>
  match dom with
  | 0 => 
    fun clauses =>
      let evidence : (k : Nat) → (lt : k < 0) →  
        (clauses k lt index bound = none) ∨ (clauses k lt index bound = some parity) := 
          fun k lt => nomatch lt
      some ⟨evidence⟩
  | m + 1 => 
      fun clauses =>
        let head := clauses 0 (zeroLtSucc _) index bound
        if c : (head = none) ∨  (head = some parity) then
          let tailSeq  := tail clauses
          (varIsPure index bound parity _ tailSeq).map (
            fun ⟨ tpf ⟩ =>
              let pf : (j : Nat) → (w : j < (m +1)) → 
                (clauses j w index bound = none) ∨ (clauses j w index bound = some parity) := 
                fun j =>
                  match j with 
                  | 0 => fun w => c
                  | i + 1 => fun w =>
                    let tailWit : i < m := leOfSuccLeSucc w 
                    tpf i tailWit
              ⟨ pf ⟩
          )
        else none

def findPureAux{n : Nat} : (dom: Nat) →  (clauses : FinSeq dom (Clause (n +1))) → 
  (ub: Nat) → (lt : ub < n + 1) → 
      Option (HasPureVar clauses) :=
      fun dom clauses ub => 
        match ub with
        | 0 =>
          fun lt =>
           ((varIsPure 0 lt true dom clauses).map (
            fun ⟨evidence⟩ =>
              HasPureVar.mk 0 lt true evidence
              )).orElse (
                (varIsPure 0 lt false dom clauses).map (
            fun ⟨evidence⟩ =>
              HasPureVar.mk 0 lt false evidence
              )
              )
        | l + 1 =>
          fun lt =>
            ((findPureAux dom clauses l (leStep lt)).orElse (              
              (varIsPure l (leStep lt) true dom clauses).map (
            fun ⟨evidence⟩ =>
              HasPureVar.mk l (leStep lt) true evidence
              )
              )).orElse (              
              (varIsPure l (leStep lt) false dom clauses).map (
            fun ⟨evidence⟩ =>
              HasPureVar.mk l (leStep lt) false evidence
              )
              )
            
def hasPure{n : Nat}{dom: Nat}(clauses : FinSeq dom  (Clause (n +1))) 
             : Option (HasPureVar clauses) :=
          findPureAux dom clauses n (Nat.leRefl _)

