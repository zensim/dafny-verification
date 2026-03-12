// Invalid Dafny file - Precondition violation
method Sqrt(n: int) returns (result: int)
  requires n >= 0
  ensures result * result <= n < (result + 1) * (result + 1)
{
  result := 0;
  while (result + 1) * (result + 1) <= n
    invariant result * result <= n
  {
    result := result + 1;
  }
  // Postcondition fails - missing upper bound proof
}
