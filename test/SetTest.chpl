use Set;

// Creates sets in various ways; used to test for compiler errors introduced in newer
// releases of chapel.
proc initTest() {
  // Create empty set...
  var set1 = new Set(int);
  // Create set form original set
  var set2 = new Set(set1);
  assert(set1.type == set2.type);
  
  // Create a set from a domain
  var dom : domain(int);
  var set3 = new Set(dom);
  assert(set3.type == set2.type && set3.eltType == dom.idxType);
  
  // Create a set from an iterable
  var set4 = new Set(1..10);
  assert(set4.type == set3.type);

  // Create a set from a parallel iterable
  var set5 = new Set([i in 1..10] i * 2);
  assert(set5.type == set4.type);
}

proc main() {
  initTest();
  writeln("SUCCESS!");
}
