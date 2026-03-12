// Invalid Dafny file - Loop invariant violation
method FindMax(arr: array<int>) returns (max: int)
  requires arr.Length > 0
  ensures forall i :: 0 <= i < arr.Length ==> arr[i] <= max
{
  max := arr[0];
  var i := 1;
  while i < arr.Length
    invariant 1 <= i <= arr.Length
    // Missing invariant: max is actually the maximum so far
  {
    if arr[i] > max {
      max := arr[i];
    }
    i := i + 1;
  }
}
