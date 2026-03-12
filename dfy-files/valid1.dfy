// Valid Dafny file - Simple function verification
method Max(a: int, b: int) returns (result: int)
  ensures result >= a && result >= b
  ensures result == a || result == b
{
  if a > b {
    result := a;
  } else {
    result := b;
  }
}
