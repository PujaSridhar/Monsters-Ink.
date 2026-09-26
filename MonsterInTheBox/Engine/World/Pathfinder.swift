import Foundation

/// Breadth-first search on the 4-way grid.
enum Pathfinder {
    /// Steps from `start` to `goal`, excluding `start` and including `goal`. Nil if unreachable.
    static func path(from start: GridPoint, to goal: GridPoint, isWalkable: (GridPoint) -> Bool) -> [GridPoint]? {
        guard start != goal else { return [] }
        var cameFrom: [GridPoint: GridPoint] = [start: start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            for next in current.neighbors where cameFrom[next] == nil && CityLayout.contains(next) && isWalkable(next) {
                cameFrom[next] = current
                if next == goal {
                    var path = [goal]
                    var step = current
                    while step != start {
                        path.append(step)
                        step = cameFrom[step]!
                    }
                    return path.reversed()
                }
                queue.append(next)
            }
        }
        return nil
    }
}
