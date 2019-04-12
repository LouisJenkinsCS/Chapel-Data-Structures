/*
  Sequential and single-locale wrapper around associative domains
*/
module Set {

  class Set {
    type eltType;
    var dom : domain(eltType);
  
    // Construct a new set
    proc init(type eltType) {
      this.eltType = eltType;
    }
    
    // Constructs a set from another associative domain.
    proc init(dom : domain) where isAssocativeDom(dom) {
      this.eltType = dom.eltType;
      this.dom = dom;
    }

    // Takes arbitrary iterable and constructs set from it.
    proc init(ir: _iteratorRecord) {
      this.eltType = iteratorToArrayElementType(ir.type);
      for a in ir do dom += a;
    }
    

  }
}
