for (N node : graph.nodes()) {
        if (!visitedNodes.contains(node)) {
          Set<N> reachableNodes = reachableNodes(graph, node);
          visitedNodes.addAll(reachableNodes);
          int pairwiseMatch = 1; // start at 1 to include self-loops
          for (N nodeU : reachableNodes) {
            for (N nodeV : Iterables.limit(reachableNodes, pairwiseMatch++)) {
              transitiveClosure.putEdge(nodeU, nodeV);
            }
          }
        }
      }