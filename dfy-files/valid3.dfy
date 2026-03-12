// Valid Dafny file - Factorial
function Factorial(n: nat): nat
{
  if n == 0 then 1 else n * Factorial(n - 1)
}

lemma FactorialPositive(n: nat)
  ensures Factorial(n) > 0
{
}
