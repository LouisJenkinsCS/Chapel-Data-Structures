import argparse
import numpy as np
import random
import graphviz
import copy
from scipy import special as sp

# Creates a graph with the specified number of vertices and edges. Graph is randomized such that
# it first ensures that there is always a path from any vertex to each other by first constructing
# a tree, and then adding randomly sampled edges to ensure we get a more interesting looking graph.

parser = argparse.ArgumentParser()
parser.add_argument('-numVertices', default='1000')
parser.add_argument('-numEdges', default='10000')
parser.add_argument('-outputDot')
args = parser.parse_args()
N = int(args.numVertices)
M = int(args.numEdges)

safeMaxEdges = sp.binom(N,2)
if M > safeMaxEdges:
    print("%d exceeds safe maximum %d (binom(%d,2))" % (M, safeMaxEdges, N))
    M = safeMaxEdges

def completeGraph():
    vertices = [0]
    edges = set()

    # Create tree
    for i in range(1,N):
        v1 = random.choice(vertices)
        v2 = i
        vertices.append(i)
        edges.add((v1, v2))

    # Create edge between arbitrarily random edges
    i = 0
    while i <= (M - N):
        (v1,v2) = np.random.choice(N, (1, 2), True)[0]
        if v1 == v2:
            continue
        if (v1, v2) in edges or (v2, v1) in edges:
            continue
        edges.add((v1, v2))
        i += 1
    return edges

edges = completeGraph()
print("%d %d" % (N, len(edges)))
G=graphviz.Graph()

for e in edges:
    weight = random.uniform(0,1)
    G.edge(str(e[0]), str(e[1]), label="%.2f" % weight)
    print("%d %d %.2f" % (e[0], e[1], weight))

if args.outputDot is not None:
    with open(args.outputDot, 'w+') as f:
        f.write(str(G))
