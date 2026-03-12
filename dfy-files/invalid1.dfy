// Invalid Dafny file - Missing postcondition proof
method Divide(a: int, b: int) returns (result: int)
  requires b != 0
  ensures result * b == a  // This postcondition cannot be proven for integer division
{
  result := a / b;
}
