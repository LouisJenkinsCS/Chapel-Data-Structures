/*
  Sequential and single-locale wrapper around associative domains
*/

class Set {
  type eltType;
  var dom : domain(eltType);

  // Construct a new set
  proc init(type eltType) {
    this.eltType = eltType;
  }

  // Constructs a set from another associative domain.
  proc init(dom : domain) where isAssociativeDom(dom) {
    this.eltType = dom.idxType;
    this.dom = dom;
  }

  // Takes arbitrary iterable and constructs set from it.
  proc init(ir: _iteratorRecord) {
    this.eltType = iteratorToArrayElementType(ir.type);
    this.complete();
    for a in ir do dom += a;
  }

  proc init(other) {
    assert(__primitive("method call resolves", other, "these"), "Iterable of type `", other.type : string, "` does not support iteration!");
    init(other.these());

  }

  //  Makes a copy of another set
  proc init(other : Set(?eltType)) {
    this.eltType = other.eltType;
    this.dom = other.dom;
  }
}

proc main() {
  // Create empty set...
  var set1 = new Set(int);
  // Create set form original set
  var set2 = new Set(set1);
  assert(set1.type == set2.type);
  
  // Create a set from a domain
  var dom : domain(int);
  var set3 = new Set(dom);
  assert(set3.type == set2.type && set3.type == dom.idxType);
  
  // Create a set from an iterable
  var set4 = new Set(1..10);
  assert(set4.type == set3.type);
}
