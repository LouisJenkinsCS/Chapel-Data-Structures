use Random;
use DataStructures;

config const nElems = 1024 * 1024;
var pq = new PriorityQueue(int);

// Generate random elems
var rng = makeRandomStream(int);
var arr : [1..nElems] int;
rng.fillRandom(arr);

// Note: PriorityQueue is not inherently thread-safe; be careful
// to not use implicit parallelism such as promotion of arrays to scalars...
for a in arr do pq.add(a);

assert((+ reduce pq) == (+ reduce arr));
assert((+ reduce pq) == (+ reduce [e in pq] e));

var sortedArr = for 1..nElems do pq.remove()[1];

// Test result with default comparator.
assert(isSorted(sortedArr));
writeln("SUCCESS!");
