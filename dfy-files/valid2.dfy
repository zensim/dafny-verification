// Valid Dafny file - Array sum
method Sum(arr: array<int>) returns (total: int)
  requires arr.Length > 0
  ensures total >= 0 ==> forall i :: 0 <= i < arr.Length ==> arr[i] >= 0
{
  total := 0;
  var i := 0;
  while i < arr.Length
    invariant 0 <= i <= arr.Length
  {
    total := total + arr[i];
    i := i + 1;
  }
}
