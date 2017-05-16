{
    MutableGraph<N> transitiveClosure = GraphBuilder.from(graph).allowsSelfLoops(true).build();
    // Every node is, at a minimum, reachable from itself. Since the resulting transitive closure
    // will have no isolated nodes, we can skip adding nodes explicitly and let putEdge() do it.

    if (graph.isDirected()) {
      // Note: works for both directed and undirected graphs, but we only use in the directed case.
      for (N node : graph.nodes()) {
        for (N reachableNode : reachableNodes(graph, node)) {
          transitiveClosure.putEdge(node, reachableNode);
        }
      }
    } else {
      // An optimization for the undirected case: for every node B reachable from node A,
      // node A and node B have the same reachability set.
      Set<N> visitedNodes = new HashSet<N>();
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
    }

    return transitiveClosure;
  }