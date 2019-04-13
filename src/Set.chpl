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
  
  // Adds a single element
  proc add(e : eltType) {
    this.dom += e;
  }
  
  // Adds elements from an iterable
  proc add(ir : _iteratorRecord) {
    for e in ir do dom += e;
  }

  // Adds items from object which supports iteration
  proc add(other) {
    assert(__primitive("method call resolves", other, "these"), "Iterable of type `", other.type : string, "` does not support iteration!");
    add(other.these());
  }
  
  // Removes element from set
  proc remove(e : eltType) {
    this.dom -= e;
  }
  
  // Removes all elements from set yielded by iterator
  proc remove(ir : _iteratorRecord) {
    for e in ir do dom -= e;
  }
  
  // Remove elements from object which supports iteration
  proc remove(other) {
    assert(__primitive("method call resolves", other, "these"), "Iterable of type `", other.type : string, "` does not support iteration!");
    remove(other.these());
  }

  iter these() const ref {
    for e in dom do yield e;
  }

  iter these(param tag : iterKind) const ref where tag == iterKind.standalone {
    forall e in dom do yield e;
  }

  proc readWriteThis(f) {
    f <~> new ioLiteral("Set(") <~> eltType : string <~> new ioLiteral(") = ") <~> dom;
  }
}

proc |(set1 : Set(?eltType), set2 : Set(eltType)) const : owned Set(eltType) {
  return new owned Set(set1.dom | set2.dom);
}

proc |(set1 : Set(?eltType), other) const : owned Set(eltType) {
  return set1 | new Set(other);
}

proc |=(ref set1 : Set(?eltType), set2 : Set(eltType)) {
  set1.dom |= set2.dom;
}

proc |=(ref set1 : Set(?eltType), other) {
  set1 |= new Set(other);
}

proc +(set1 : Set(?eltType), set2 : Set(eltType)) const : owned Set(eltType) {
  return new owned Set(set1.dom + set2.dom);
}

proc +=(ref set1 : Set(?eltType), set2 : Set(eltType)) {
  set1.dom += set2.dom;
}

proc -(set1 : Set(?eltType), set2 : Set(eltType)) const : owned Set(eltType) {
  return new owned Set(set1.dom - set2.dom);
}

proc -=(ref set1 : Set(?eltType), set2 : Set(eltType)) {
  set1.dom -= set2.dom;
}

proc &(set1 : Set(?eltType), set2 : Set(eltType)) const : owned Set(eltType) {
  return new owned Set(set1.dom & set2.dom);
}

proc &=(set1 : Set(?eltType), set2 : Set(eltType)) {
  set1.dom &= set2.dom;
}

proc ^(set1 : Set(?eltType), set2 : Set(eltType)) const : owned Set(eltType) {
  return set1.dom ^ set2.dom;
}

proc ^=(ref set1 : Set(?eltType), set2 : Set(eltType)) {
  set1.dom ^= set2.dom;
}

proc =(ref set1 : Set(?eltType), set2 : Set(eltType)) {
  set1.dom = set2.dom;
}

proc =(ref set : Set(?eltType), other) {
  set = new Set(other);
}

proc main() {
  var set1 = new Set(1..10);
  var set2 = new Set(11..20);
  var set3 = set1 | set2;
  writeln(set3);
}
