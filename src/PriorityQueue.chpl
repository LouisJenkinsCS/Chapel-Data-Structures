use Sort;

config param PriorityQueueInitialSize = 1024;

// Single-Locale Sequential Heap Priority Queue
class PriorityQueue {
    // Type of element
    type eltType;
    // Comparator: https://chapel-lang.org/docs/modules/packages/Sort.html#comparators
    var comparator;
    // When we clear the priority queue, we reset the domain as well to handle cases where
    // the elements have a lifetime (I.E 'owned')
    const initialSize;
    var dom = {0..-1};
    var arr : [dom] eltType;
    var size : int;

    proc init(type eltType, comparator : ?rec = defaultComparator, initialSize = PriorityQueueInitialSize) {
        assert(initialSize >= 0, "PriorityQueue's initial size must be >= 0 but given", initialSize);
        chpl_check_comparator(comparator, eltType);
        this.eltType = eltType;
        this.comparator = comparator;
        this.initialSize = initialSize;
        this.dom = {0..#initialSize};
    }

    // Insert element into priority queue. If called from another locale, it will jump
    // to the locale that it is allocated on.
    proc add(elt : eltType) : bool {
        on this {
            var idx = size;

            // Resize if needed
            if idx >= dom.size {
                dom = {0..max(1, ceil(dom.size * 1.5) : int)};
            }

            // Insert
            arr[idx] = elt;
            size += 1;

            // Rebalance
            if idx > 0 {
                var child = arr[idx];
                var parent = arr[getParent(idx)];

                // Heapify Up
                while idx != 0 && chpl_compare(child, parent, this.comparator) < 0 {
                    arr[idx] <=> arr[getParent(idx)];
                    idx = getParent(idx);
                    child = arr[idx];
                    parent = arr[getParent(idx)];
                }
            }
        }
        return true;
    }

    // Remove the top element from the heap and heapify up; Also jumps to the locale
    // this is allocated on. Returns pairs (hasElt, elt); if 'hasElt' is false, then the
    // value of 'elt' should not be used; if 'hasElt' is true, then 'elt' may be used as
    // it was removed from the priority queue.
    proc remove() : (bool, eltType) {
        var retval : (bool, eltType);
        on this {
            if size > 0 {
                retval = (true, arr[0]);
                arr[0] = arr[size - 1];
                size -= 1;

                heapify(0);
            }
        }
        return retval;
    }

    proc heapify(_idx : int) {
        var idx = _idx;
        if size <= 1 {
            return;
        }

        var l = getLeft(idx);
        var r = getRight(idx);
        var tmp = idx;
        var curr = arr[idx];

        // left > current
        if size > l && chpl_compare(curr, arr[l], this.comparator) < 0 {
            curr = arr[l];
            idx = l;
        }

        // right > current
        if size > r && chpl_compare(curr, arr[r], this.comparator) < 0 {
            curr = arr[r];
            idx = r;
        }

        if idx != tmp {
            arr[tmp] <=> arr[idx];
            heapify(idx);
        }
    }

    inline proc getParent(x:int) : int {
        return floor((x - 1) / 2) : int;
    }

    inline proc getLeft(x:int) : int {
        return 2 * x + 1; 
    }

    inline proc getRight(x:int) : int {
        return 2 * x + 2;
    }

    // Iterator to yield all elements in arbitrary order.
    // Returns a const ref to ensure that it is not modified; 
    // as well, should handle cases where we yield an 'owned' object.
    iter these() const ref : eltType {
        for i in 0..#size do yield arr[i];
    }

    // Parallel iterator that yields in arbitrary order.
    iter these(param tag : iterKind) const ref : eltType where tag == iterKind.standalone {
        forall i in 0..#size do yield arr[i];
    }

    // Clears priority queue; called 'empty' to avoid conflict with 'OwnedObject.owned.clear' method
    // so that 'owned PriorityQueue' is feasible.
    proc empty() {
        // Next insertion will begin inserting at beginning index...
        this.size = 0;

        // Set back to initial size
        this.dom = {1..initialSize};

        // Special case: Should eliminate any existing 'owned' objects to prevent memory leakage.
        if isOwnedClass(eltType) then [a in arr] a.clear();
    }
}


