import Saturn.FinSeq
import Saturn.Clause 
import Saturn.Solverstep
import Saturn.DPLL

def pairs(n: Nat) : List (Nat × Nat) := 
  List.bind 
    (List.range n) 
    (fun x => 
      (List.range n).map (fun y => (x, y)))

#eval pairs 3

def row (index n: Nat) : Nat := index / n
def col (index n: Nat) : Nat := index % n

def threaten (index1 index2 n : Nat) : Bool :=
  (row index1 n == row index2 n) || (col index1 n == col index2 n) ||
  ((row index1 n) + (col index1 n) == (row index2 n) + (col index2 n)) ||
  ((row index1 n) + (col index2 n) == (row index2 n) + (col index1 n))

def forbiddenPairs (n: Nat) : List (Nat × Nat) :=
  (pairs (n * n)).filter (fun (x, y) => x < y && threaten x y n)

def forbidPairClauses (n: Nat) : List (Clause (n * n)) :=
  (forbiddenPairs n).map (
    fun (x, y) =>
      FinSeq.vec (fun i w => 
        if i == x || i == y then some false else none)
      )

def rowClause(r n: Nat) : Clause (n * n) := 
  FinSeq.vec (fun index _ => if row index n == r then some true else none)

def rowClauses (n: Nat) : List (Clause (n * n)) :=
  (List.range n).map (fun r => rowClause r n) 

def queensClauses(n: Nat) :=
  FinSeq.vec 
  ((seq (rowClauses n)) ++| (seq (forbidPairClauses n)))

#check queensClauses 8