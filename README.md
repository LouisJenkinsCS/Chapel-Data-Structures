# Chapel-Data-Structures

**Travis:** [![Build Status](https://travis-ci.org/LouisJenkinsCS/Chapel-Data-Structures.svg?branch=master)](https://travis-ci.org/LouisJenkinsCS/Chapel-Data-Structures)

Data Structures written in Chapel.

**Sequential Data Structures:**

These data structures are intended to provide quality-of-life specialized data structures that may or may not already
exist in the language. If they do not exist, it's purpose and benefit is clear, but if it already exists it may not
be apparent. One thing that such explicit data structures allow is allowing the intent or usage of such constructs
to be readily identified. For example, think of your typical `Set`.

```chpl
var chapelSet : domain(eltType);
var newSet : Set(eltType);
```

Chapel's associative domains can be used directly as a set, but it has some 'gotchas', such as when it will be passed
by reference or by value, how expensive such copies are, etc. As well, one would need to disassociate it from its use
as a domain, a _set of indices_ that act as keys for a hash map. The generality of Chapel's first-class domais are
astounding, but they also lead to ambiguity; for example:

```chpl
var set : domain(eltType);
var keys : domain(keyType);
var values : [keys] valueType;
```

How would you disambiguate an associative domain meant to act as a set versus one that is used for a map? For example,
modifying 'keys' will result in changing 'values', which may be obvious and apparent if its used in a short-scope or 
closely together, it may not always be the case. Never-the-less, ambiguity melts aways when you have explicitly named types.

```chpl
var set = new Set(eltType);
var map = new Map(keyType, valueType);
```

Second, there are known issues with built-in types, such as invoking `push_back` on arrays being very slow, with a minimal implementation
being faster by over an order of magnitude. Lastly, there are many 'gotchas' when it comes to arrays sharing domains as just how often
they can implicitly share domains and trigger said issues. For example, creating a copy of an array does not copy the domain, both will
use the same domain and when you try to 'push_back' to your 'copy' you get a runtime error. For example, see this code snippet and [execution](https://tio.run/##S85ILEjN@f@/LLFIIbGoSMFKIdpQT8/QIFYhM6/EmgskZKtgaM0FlTcC8oCUNVd5UWZJak6ehhKQZ6WgpAMS1UQVNoKJG2mCDQLpNSJPp15BaXFGfFJicraGoab1//8A)

```chpl
var arr : [1..10] int;
arr = 1;
var arr2 = arr;
writeln("arr: ", arr);
writeln("arr2: ", arr2);
arr2 = 2;
writeln("arr: ", arr);
writeln("arr2: ", arr2);
arr2.push_back(1);
```

- [x] Priority Queue (Binary Heap)
- [ ] Vector (Lightweight Wrapper around Chapel Array)
- [ ] Stack (Wraps Vector)
- [ ] Queue (Wraps Vector)
- [ ] Set (Wraps Associative Domain)
- [ ] Map (Wraps Associative Array)

**Concurrent Data Structures:**

- [ ] Non-Blocking Queue (Michael and Scott's Queue)
- [ ] Non-Blocking Stack (Treiber Stack)

**Distributed Data Structures:**

- [ ] Distributed Deque ([Port](https://chapel-lang.org/docs/modules/packages/DistributedDeque.html))
- [ ] Distributed Bag ([Port](https://chapel-lang.org/docs/modules/packages/DistributedBag.html))
- [ ] Distributed RCUArray ([Paper](https://ieeexplore.ieee.org/abstract/document/8425513/))



