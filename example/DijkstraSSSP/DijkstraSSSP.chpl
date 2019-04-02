use Time;
use Sort;
use PriorityQueue;

// Compile-time constant
param unreached : real(64) = INFINITY;

// Can be set via command line: './dijkstra --graphFile=graph.txt'
config const graphFile : string = "graphs/example_graph.txt";

class Vertex {
    var id : int(64);
    var distance : real(64);
    var incidentDom = {0..-1};
    var incident : [incidentDom] borrowed Edge;

    proc init(id : integral, distance = unreached) {
        this.id = id : int(64);
        this.distance = distance;
    }

    // Return adjacent neighbors... A vertex 'v' is
    // adjacent to a vertex 'u' if it is incident in an
    // edge '(v,u)'.
    iter neighbors() : (real(64), borrowed Vertex) {
        for e in incident {
            if e.v1 == this {
                yield (e.weight, e.v2);
            } else if e.v2 == this {
                yield (e.weight, e.v1);
            } else {
                halt("An edge ", e, " does not contain vertex ", this, " even though we are incident in it!");
            }
        }
    }

    // Parallel Iterator Example; the parallel iterator for 'incident', a Chapel array, is used as the backbone.
    // 'forall' results in this parallel iterator being selected, while 'for' results in the above serial iterator
    // being selected. 
    // https://chapel-lang.org/docs/master/primers/parIters.html#primers-pariters
    iter neighbors(param tag : iterKind) : (real(64), borrowed Vertex) where tag == iterKind.standalone {
        forall e in incident {
            if e.v1 == this {
                yield (e.weight, e.v2);
            } else if e.v2 == this {
                yield (e.weight, e.v1);
            } else {
                halt("An edge ", e, " does not contain vertex ", this, " even though we are incident in it!");
            }
        }
    }

    proc readWriteThis(f) {
        f   <~> new ioLiteral("Vertex(") 
            <~> this.id 
            <~> new ioLiteral(",") 
            <~> this.distance 
            <~> new ioLiteral(")");
    }
}

proc >(v1 : Vertex, v2 : Vertex) {
    return v1.distance > v2.distance;
}

proc <(v1 : Vertex, v2 : Vertex) {
    return v1.distance < v2.distance;
}


class Edge {
    var v1 : borrowed Vertex;
    var v2 : borrowed Vertex;
    var weight : real(64);

    proc init(v1 : borrowed Vertex, v2 : borrowed Vertex, weight : real(64)) {
        this.v1 = v1;
        this.v2 = v2;
        this.weight = weight;
    }

    proc other(v : borrowed Vertex) : borrowed Vertex {
        if this.v1 == v {
            return this.v2;
        } else if this.v2 == v {
            return this.v1;
        } else {
            halt("Vertex ", v, " not included in an edge that it is incident on...");
        }
    }

    proc readWriteThis(f) {
        f   <~> new ioLiteral("Edge(") 
            <~> this.v1 
            <~> new ioLiteral(",") 
            <~> this.v2 
            <~> new ioLiteral(",")
            <~> this.weight
            <~> new ioLiteral(")");
    }
}

class Graph {
    var vertexDom = {0..-1};
    var edgeDom = {0..-1};
    var vertices : [vertexDom] owned Vertex;
    var edges : [edgeDom] owned Edge;

    proc init() {}

    // Adds a vertex to the graph; this transfers ownership!
    proc addVertex(v : owned Vertex) {
        this.vertices.push_back(v);
    }

    // Adds an edge to the graph; this transfers ownership
    proc addEdge(e : owned Edge) {
        e.v1.incident.push_back(e);
        e.v2.incident.push_back(e);
        this.edges.push_back(e);
    }

    // vertex = Graph[idx]; 
    proc this(idx : integral) : borrowed Vertex {
        return this.vertices[idx];
    }

    proc readWriteThis(f) {
        f   <~> new ioLiteral("Graph(") 
            <~> this.vertices 
            <~> new ioLiteral(",") 
            <~> this.edges 
            <~> new ioLiteral(")");
    }
}

proc loadGraph(fileName : string) : owned Graph {
    var graph = new owned Graph();
    var freader = open(fileName, iomode.r).reader();
    
    // Read header...
    var numVertices : int(64);
    var numEdges : int(64);
    // |V| |E|
    assert(freader.readln(numVertices, numEdges));

    // Allocate all vertices...
    for i in 0..#numVertices {
        graph.addVertex(new owned Vertex(i));
    }

    // Extract edges...
    var v1 : int(64);
    var v2 : int(64);
    var weight : real(64);
    while (freader.readln(v1, v2, weight)) {
        graph.addEdge(new owned Edge(graph[v1], graph[v2], weight));
    }

    return graph;
}

proc Dijkstra(graph : borrowed Graph, source : borrowed Vertex) {
    var pq = new owned PriorityQueue((real(64), borrowed Vertex));
    source.distance = 0;

    pq.add((source.distance, source));
    while (!pq.isEmpty()) {
        var (hasElt, elt) = pq.remove();
        assert(hasElt, "Priority Queue is not being empty but no element was returned...");
        var (dist, v) = elt;
        if (dist != v.distance) {
            continue;
        }

        for (weight, neighbor) in v.neighbors() {
            var altDist = v.distance + weight;
            
            if (isnan(neighbor.distance) || altDist < neighbor.distance) {
                neighbor.distance = altDist;
                pq.add((altDist, neighbor));
            }
        }
    }
}

proc main() {
    var graph = loadGraph(graphFile);
    var expectedDistance : [graph.vertexDom] real(64);
    var maximalSSSP : (real(64), int(64));
    
    Dijkstra(graph, graph.vertices[0]);
    forall (v, dist) in zip(graph.vertices, expectedDistance) with (max reduce maximalSSSP) {
        dist = v.distance;
        maximalSSSP = max(maximalSSSP, (v.distance, v.id));
    }
    writeln("Maximal Shortest Path is between #0 and #", maximalSSSP[2], " = ", maximalSSSP[1]);
}
