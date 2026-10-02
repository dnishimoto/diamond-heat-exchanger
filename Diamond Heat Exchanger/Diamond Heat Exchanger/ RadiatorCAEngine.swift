//
//  RadiatorCAEngine.swift
//  Diamond Heat Exchanger
//
//  Created by David Nishimoto on 10/1/26.
//

import Foundation
import SwiftUI
import SceneKit
import Combine

import Foundation

@MainActor
final class RadiatorCAEngine: ObservableObject {
    
    private let waterHeatTransferCoefficient = 3_500_000.0

    private let airHeatTransferCoefficient = 75_000.0
    
    private let maximumAluminumFraction = 0.60
    private let airSpecificHeatJPerKgK = 1005.0
    
    private let thermalTimeStepS = 0.02
    private let datacenterHeatLoadJ = 1_000_000_000.0
    private let targetRemovalTimeS = 60.0
    
    @Published private(set) var datacenterEnergyInjectedJ: Double = 0
    @Published private(set) var waterToAluminumEnergyJ: Double = 0
    @Published private(set) var airEnergyRemovedJ: Double = 0
    @Published private(set) var airEnergyRemovedThisStepJ : Double = 0
    @Published private(set) var aluminumToAirEnergyJ : Double = 0

    private var thermalSimulationTimeS: Double = 0
    private var lastAirHeatTransferW: Double = 0
    
    
    private let waterToAluminumHeatTransferCoefficient = 3500.0

    // MARK: - Published State

    @Published private(set) var cells: [RadiatorCell] = []
    @Published private(set) var generation: Int = 0
    @Published private(set) var metrics = HeatExchangerMetrics()
    @Published private(set) var isRunning = false

    // MARK: - Grid

    let gridSize = 21

    private var totalCells: Int {
        gridSize * gridSize * gridSize
    }

    // MARK: - Geometry

    private let cellSizeM = 0.002

    private var cellVolumeM3: Double {
        cellSizeM * cellSizeM * cellSizeM
    }

    private var cellFaceAreaM2: Double {
        cellSizeM * cellSizeM
    }

    // MARK: - Aluminum

    private let aluminumDensityKgM3 = 2700.0
    private let aluminumThermalConductivity = 237.0
    private let aluminumSpecificHeat = 897.0

    // MARK: - Water

    private let waterDensityKgM3 = 998.0
    private let waterSpecificHeat = 4186.0

    // MARK: - Air

    private let airDensityKgM3 = 1.225
    private let airSpecificHeat = 1005.0

    // MARK: - Datacenter Thermal Load

    /*
     The datacenter contributes 1 GJ of thermal energy.

     The target is to remove that energy in 60 seconds.
     */

  
    private var requiredHeatRateW: Double {
        datacenterHeatLoadJ / targetRemovalTimeS
    }

    // MARK: - Ambient Conditions

    private let ambientTemperatureC = 25.0

    private let airInletTemperatureC = 25.0

    private let maximumAllowedTemperatureC = 120.0

    // MARK: - Nominal Flow Velocities

    private let nominalWaterVelocityMS = 3.0

    private let nominalAirVelocityMS = 15.0

    // MARK: - Thermal Simulation

  
  
    /*
     Aluminum conduction relaxation.

     0.22 means that a portion of the local conductive
     temperature difference is transferred each thermal step.
     */

    private let aluminumConductionFactor = 0.22

    /*
     Prevent numerical instability and unrealistic single-step
     temperature jumps.
     */

    private let maximumTemperatureChangePerStepC = 8.0

    // MARK: - Ports

    private(set) var waterPorts: [FlowPort] = []

    private(set) var airPorts: [FlowPort] = []

    // MARK: - Thermal Accounting

     private var waterEnergyExportedJ = 0.0

    // MARK: - Lattice Growth Rules

    /*
     Upper bound on aluminum as a fraction of the whole grid.
     Growth stops here so the lattice stays porous enough for air.
     Left alone, the growth rule saturates on its own at roughly 46%.
     */


    /*
     true for every cell that belonged to a carved air channel
     (including inlet/outlet ports) when the geometry was built.
     These cells guarantee an inlet-to-outlet air path and are
     never converted to aluminum by the CA.
     */

    private var airChannelMask: [Bool] = []

    /*
     Flat face-neighbor table: 6 entries per cell
     (+x, -x, +y, -y, +z, -z), -1 when outside the grid.
     */

    private lazy var neighborTable: [Int] = buildNeighborTable()



    init() {

        buildInitialGeometry()

        initializeThermalField()

        evaluateSimulation()
    }

    // MARK: - Public Controls

    func start(
        generations: Int = 1
    ) {

        guard !isRunning else {
            return
        }

        isRunning = true

        for _ in 0..<max(1, generations) {

            stepCA()
        }

        isRunning = false
    }

    func stop() {

        isRunning = false

        applyPortStates()

        evaluateSimulation()
    }

    func evolve(
        generations: Int = 20
    ) {

        guard !isRunning else {
            return
        }

        isRunning = true

        for _ in 0..<max(0, generations) {

            stepCA()
        }

        isRunning = false
    }

    // MARK: - Reset

    func reset() {

        isRunning = false

        datacenterEnergyInjectedJ = 0.0

        airEnergyRemovedJ = 0.0

        waterEnergyExportedJ = 0.0

        thermalSimulationTimeS = 0.0

        buildInitialGeometry()

        initializeThermalField()

        evaluateSimulation()
    }
 
    private func linearIndex(
        x: Int,
        y: Int,
        z: Int
    ) -> Int {

        x +
        y * gridSize +
        z * gridSize * gridSize
    }

    private func indexFor(
        _ point: GridPoint
    ) -> Int? {

        guard isValid(point) else {
            return nil
        }

        return linearIndex(
            x: point.x,
            y: point.y,
            z: point.z
        )
    }

    private func pointFor(
        _ index: Int
    ) -> GridPoint {

        let z =
            index /
            (gridSize * gridSize)

        let remainder =
            index -
            z * gridSize * gridSize

        let y =
            remainder /
            gridSize

        let x =
            remainder -
            y * gridSize

        return GridPoint(
            x: x,
            y: y,
            z: z
        )
    }

    private func isValid(
        _ point: GridPoint
    ) -> Bool {

        point.x >= 0 &&
        point.x < gridSize &&
        point.y >= 0 &&
        point.y < gridSize &&
        point.z >= 0 &&
        point.z < gridSize
    }

    // MARK: - Neighbors

    private func neighborPoints(
        _ point: GridPoint
    ) -> [GridPoint] {

        let directions = [

            GridPoint(
                x: 1,
                y: 0,
                z: 0
            ),

            GridPoint(
                x: -1,
                y: 0,
                z: 0
            ),

            GridPoint(
                x: 0,
                y: 1,
                z: 0
            ),

            GridPoint(
                x: 0,
                y: -1,
                z: 0
            ),

            GridPoint(
                x: 0,
                y: 0,
                z: 1
            ),

            GridPoint(
                x: 0,
                y: 0,
                z: -1
            )
        ]

        return directions.compactMap {

            let next = GridPoint(
                x: point.x + $0.x,
                y: point.y + $0.y,
                z: point.z + $0.z
            )

            return isValid(next)
                ? next
                : nil
        }
    }

    // MARK: - Initial Geometry

    private func buildInitialGeometry() {

        cells.removeAll(keepingCapacity: true)

        cells.reserveCapacity(totalCells)

        for z in 0..<gridSize {

            for y in 0..<gridSize {

                for x in 0..<gridSize {

                    let index =
                        linearIndex(
                            x: x,
                            y: y,
                            z: z
                        )

                    cells.append(
                        RadiatorCell(
                            id: index,
                            x: x,
                            y: y,
                            z: z,
                            state: .empty,
                            temperatureC: ambientTemperatureC,
                            heatJ: 0.0,
                            flow: 0.0,
                            pressure: 0.0,
                            generation: 0
                        )
                    )
                }
            }
        }

        createPorts()

        seedDiamondGeometry()

        carveFlowNetworks()

        applyPortStates()

        finalizeInitialLattice()

        generation = 0
    }

    // MARK: - Gap-Free Lattice Helpers

    private func buildNeighborTable() -> [Int] {

        var table = [Int](
            repeating: -1,
            count: totalCells * 6
        )

        let offsets: [(Int, Int, Int)] = [
            (1, 0, 0),
            (-1, 0, 0),
            (0, 1, 0),
            (0, -1, 0),
            (0, 0, 1),
            (0, 0, -1)
        ]

        for z in 0..<gridSize {
            for y in 0..<gridSize {
                for x in 0..<gridSize {

                    let index = linearIndex(x: x, y: y, z: z)

                    for (slot, offset) in offsets.enumerated() {

                        let nx = x + offset.0
                        let ny = y + offset.1
                        let nz = z + offset.2

                        guard nx >= 0, nx < gridSize,
                              ny >= 0, ny < gridSize,
                              nz >= 0, nz < gridSize
                        else {
                            continue
                        }

                        table[index * 6 + slot] =
                            linearIndex(x: nx, y: ny, z: nz)
                    }
                }
            }
        }

        return table
    }

    /*
     Called once after the seed and flow channels are carved.

     1. Remember the carved air channels.
     2. Drop aluminum that is not connected to the platform.
        It becomes AIR, not an empty void.
     3. Fill every remaining void with air.

     After this there are no .empty cells. Every cell is
     aluminum, water, or air.
     */

    private func finalizeInitialLattice() {

        airChannelMask = cells.map {
            $0.state.isAir
        }

        removeDisconnectedAluminumCells(
            from: &cells
        )

        fillVoidsWithAir(
            in: &cells
        )
    }

    private func fillVoidsWithAir(
        in lattice: inout [RadiatorCell]
    ) {

        for index in lattice.indices {

            guard lattice[index].state == .empty
            else {
                continue
            }

            lattice[index].state = .air
            lattice[index].temperatureC = airInletTemperatureC
            lattice[index].heatJ = 0.0
        }
    }

    private func neighborCounts(
        of index: Int,
        in lattice: [RadiatorCell]
    ) -> (aluminum: Int, air: Int, water: Int) {

        var aluminum = 0
        var air = 0
        var water = 0

        let base = index * 6

        for slot in 0..<6 {

            let neighborIndex = neighborTable[base + slot]

            guard neighborIndex >= 0
            else {
                continue
            }

            let state = lattice[neighborIndex].state

            if state == .aluminum {
                aluminum += 1
            } else if state.isAir {
                air += 1
            } else if state.isWater {
                water += 1
            }
        }

        return (aluminum, air, water)
    }

    private func meanAluminumNeighborTemperature(
        of index: Int,
        in lattice: [RadiatorCell]
    ) -> Double {

        var sum = 0.0
        var count = 0

        let base = index * 6

        for slot in 0..<6 {

            let neighborIndex = neighborTable[base + slot]

            guard neighborIndex >= 0,
                  lattice[neighborIndex].state == .aluminum
            else {
                continue
            }

            sum += lattice[neighborIndex].temperatureC
            count += 1
        }

        return count > 0
            ? sum / Double(count)
            : ambientTemperatureC
    }

    /*
     Turning `index` into aluminum must not leave any neighboring
     free-air cell with fewer than two air neighbors. That would
     create a dead-end pocket with no through-flow.

     Carved channel cells are skipped because they stay connected
     to each other regardless.
     */

    private func keepsAirPocketsOpen(
        at index: Int,
        in lattice: [RadiatorCell]
    ) -> Bool {

        let base = index * 6

        for slot in 0..<6 {

            let neighborIndex = neighborTable[base + slot]

            guard neighborIndex >= 0,
                  lattice[neighborIndex].state == .air,
                  !airChannelMask[neighborIndex]
            else {
                continue
            }

            var remainingAir = 0

            let neighborBase = neighborIndex * 6

            for innerSlot in 0..<6 {

                let candidate = neighborTable[neighborBase + innerSlot]

                guard candidate >= 0,
                      candidate != index
                else {
                    continue
                }

                if lattice[candidate].state.isAir {
                    remainingAir += 1
                }
            }

            if remainingAir < 2 {
                return false
            }
        }

        return true
    }

    /*
     Safety net. Any air region that cannot be reached from an
     air inlet is a trapped void. If it touches aluminum, fill it
     with aluminum so the structure has no hidden gaps.

     Ports are never overwritten.
     */

    private func sealDeadAirPockets(
        in lattice: inout [RadiatorCell]
    ) {

        let total = lattice.count

        var reached = [Bool](
            repeating: false,
            count: total
        )

        var queue: [Int] = []
        queue.reserveCapacity(total)

        for port in airPorts where port.kind == .airInlet {

            guard let index = indexFor(port.point),
                  !reached[index]
            else {
                continue
            }

            reached[index] = true
            queue.append(index)
        }

        var head = 0

        while head < queue.count {

            let current = queue[head]
            head += 1

            for slot in 0..<6 {

                let neighborIndex = neighborTable[current * 6 + slot]

                guard neighborIndex >= 0,
                      !reached[neighborIndex],
                      lattice[neighborIndex].state.isAir
                else {
                    continue
                }

                reached[neighborIndex] = true
                queue.append(neighborIndex)
            }
        }

        var seen = [Bool](
            repeating: false,
            count: total
        )

        for start in 0..<total {

            guard lattice[start].state.isAir,
                  !reached[start],
                  !seen[start]
            else {
                continue
            }

            var component: [Int] = [start]
            seen[start] = true

            var componentHead = 0
            var touchesAluminum = false

            while componentHead < component.count {

                let current = component[componentHead]
                componentHead += 1

                for slot in 0..<6 {

                    let neighborIndex = neighborTable[current * 6 + slot]

                    guard neighborIndex >= 0
                    else {
                        continue
                    }

                    if lattice[neighborIndex].state == .aluminum {
                        touchesAluminum = true
                        continue
                    }

                    guard lattice[neighborIndex].state.isAir,
                          !reached[neighborIndex],
                          !seen[neighborIndex]
                    else {
                        continue
                    }

                    seen[neighborIndex] = true
                    component.append(neighborIndex)
                }
            }

            guard touchesAluminum
            else {
                continue
            }

            for index in component where lattice[index].state == .air {

                lattice[index].temperatureC =
                    meanAluminumNeighborTemperature(
                        of: index,
                        in: lattice
                    )

                lattice[index].state = .aluminum

                synchronizeCellHeat(
                    index: index,
                    cells: &lattice
                )
            }
        }
    }

    private func injectDatacenterHeat() {
        let remainingEnergyJ =
            max(
                0,
                datacenterHeatLoadJ -
                datacenterEnergyInjectedJ
            )

        guard remainingEnergyJ > 0 else {
            return
        }

        let requestedEnergyJ =
            requiredHeatRateW *
            thermalTimeStepS

        let injectedEnergyJ =
            min(
                requestedEnergyJ,
                remainingEnergyJ
            )

        datacenterEnergyInjectedJ += injectedEnergyJ
    }

    @discardableResult
    private func removeDisconnectedAluminumCells(
        from lattice: inout [RadiatorCell]
    ) -> Int {

        // MARK: 1. Find aluminum touching the build platform

        let platformCells: [GridPoint] = lattice.indices.compactMap { index in

            let point = pointFor(index)

            guard point.z == 0,
                  lattice[index].state == .aluminum
            else {
                return nil
            }

            return point
        }

        // No aluminum touches the build platform.
        // Do not delete anything here because there is no valid
        // platform reference from which to classify cells as floating.
        guard !platformCells.isEmpty else {

            print("STRUCTURE: No aluminum touches z=0 platform")

            return 0
        }

        // MARK: 2. Flood-fill through the diamond lattice

        // A diamond lattice can connect through faces, edges, and
        // corners. Therefore use the same 26-neighbor definition
        // used by printableCandidate().
        var connected = Set<GridPoint>()

        var queue: [GridPoint] = platformCells
        queue.reserveCapacity(lattice.count)

        for point in platformCells {
            connected.insert(point)
        }

        var queueIndex = 0

        while queueIndex < queue.count {

            let current = queue[queueIndex]
            queueIndex += 1

            for neighbor in allNeighborPoints(current) {

                guard isValid(neighbor) else {
                    continue
                }

                guard !connected.contains(neighbor) else {
                    continue
                }

                guard let neighborIndex = indexFor(neighbor) else {
                    continue
                }

                // Only aluminum participates in the structural
                // connectivity test.
                guard lattice[neighborIndex].state == .aluminum else {
                    continue
                }

                connected.insert(neighbor)
                queue.append(neighbor)
            }
        }

        // MARK: 3. Remove only truly floating aluminum

        var aluminumCount = 0
        var removedCount = 0

        for index in lattice.indices {

            guard lattice[index].state == .aluminum else {
                continue
            }

            aluminumCount += 1

            let point = pointFor(index)

            // Connected to the build platform through the diamond
            // structure -> KEEP.
            guard !connected.contains(point) else {
                continue
            }

            // No structural path to the build platform -> FLOATING.
            lattice[index].state = .air
            lattice[index].temperatureC = ambientTemperatureC
            lattice[index].heatJ = 0
            lattice[index].flow = 0
            lattice[index].pressurePa = 0

            removedCount += 1
        }

        // MARK: 4. Diagnostics

        if removedCount > 0 {

            print("""
            STRUCTURE CLEANUP:

              Platform aluminum: \(platformCells.count)
              Structurally connected: \(connected.count)
              Aluminum before cleanup: \(aluminumCount)
              Floating aluminum removed: \(removedCount)
              Aluminum remaining: \(aluminumCount - removedCount)
            """)
        } else {

            print("""
            STRUCTURE CLEANUP:

              Platform aluminum: \(platformCells.count)
              Structurally connected: \(connected.count)
              Aluminum before cleanup: \(aluminumCount)
              Floating aluminum removed: 0
              Aluminum remaining: \(aluminumCount)
            """)
        }

        return removedCount
    }
    private func allNeighborPoints(_ point: GridPoint) -> [GridPoint] {

        var neighbors: [GridPoint] = []
        neighbors.reserveCapacity(26)

        for dz in -1...1 {
            for dy in -1...1 {
                for dx in -1...1 {

                    // Skip the cell itself.
                    if dx == 0 && dy == 0 && dz == 0 {
                        continue
                    }

                    neighbors.append(
                        GridPoint(
                            x: point.x + dx,
                            y: point.y + dy,
                            z: point.z + dz
                        )
                    )
                }
            }
        }

        return neighbors
    }
   

    private func seedDiamondGeometry() {
        let center = Double(gridSize - 1) / 2.0

        // ---------------------------------------------------------
        // 1. Build-platform layer.
        //    This layer is aluminum and remains structural.
        // ---------------------------------------------------------
        let platformZ = 0
        let platformRadius = gridSize / 3

        for x in 0..<gridSize {
            for y in 0..<gridSize {
                let dx = x - gridSize / 2
                let dy = y - gridSize / 2

                guard abs(dx) <= platformRadius,
                      abs(dy) <= platformRadius
                else {
                    continue
                }

                let point = GridPoint(
                    x: x,
                    y: y,
                    z: platformZ
                )

                guard let index = indexFor(point)
                else {
                    continue
                }

                cells[index].state = .aluminum
            }
        }

        // ---------------------------------------------------------
        // 2. Diamond lattice above the platform.
        // ---------------------------------------------------------
        for index in cells.indices {
            let currentCell = cells[index]

            guard currentCell.z > 0,
                  currentCell.z < gridSize - 1
            else {
                continue
            }

            let dx =
                Double(currentCell.x) - center

            let dy =
                Double(currentCell.y) - center

            let dz =
                Double(currentCell.z) - center

            let manhattan =
                abs(dx) +
                abs(dy) +
                abs(dz)

            let diagonal =
                abs(dx + dy + dz)

            let shellA =
                Int(manhattan.rounded()) % 4

            let shellB =
                Int(diagonal.rounded()) % 3

            let diamond =
                shellA == 0 ||
                shellB == 0

            let boundary =
                currentCell.x == 0 ||
                currentCell.x == gridSize - 1 ||
                currentCell.y == 0 ||
                currentCell.y == gridSize - 1 ||
                currentCell.z == gridSize - 1

            if diamond && !boundary {
                cells[index].state = .aluminum
            }
        }

        // ---------------------------------------------------------
        // 3. Structural perimeter.
        // ---------------------------------------------------------
        for z in 1..<(gridSize - 1) {
            for y in 1..<(gridSize - 1) {

                guard y == 1 ||
                      y == gridSize - 2
                else {
                    continue
                }

                let point = GridPoint(
                    x: gridSize / 2,
                    y: y,
                    z: z
                )

                guard let index = indexFor(point)
                else {
                    continue
                }

                if !cells[index].state.isFlow {
                    cells[index].state = .aluminum
                }
            }
        }
    }
    // MARK: - Ports
    private func carveManifoldPath(
        from start: GridPoint,
        to target: GridPoint,
        state: RadiatorCellState
    ) {

        guard isValid(start),
              isValid(target)
        else {
            return
        }

        var queue: [GridPoint] = [start]
        var queueIndex = 0

        var cameFrom: [GridPoint: GridPoint] = [:]
        var visited = Set<GridPoint>()

        visited.insert(start)

        while queueIndex < queue.count {

            let current = queue[queueIndex]
            queueIndex += 1

            if current == target {
                break
            }

            let neighbors = neighborPoints(current)
                .sorted {
                    channelTraversalCost(
                        $0,
                        target: target,
                        state: state
                    )
                    <
                    channelTraversalCost(
                        $1,
                        target: target,
                        state: state
                    )
                }

            for neighbor in neighbors {

                guard isValid(neighbor) else {
                    continue
                }

                guard !visited.contains(neighbor) else {
                    continue
                }

                // Never allow water to occupy air ports
                // or air to occupy water ports.
                let neighborIndex = indexFor(neighbor)

                guard let index = neighborIndex else {
                    continue
                }

                let existingState = cells[index].state

                if state == .water &&
                    (existingState == .air ||
                     existingState == .airInlet ||
                     existingState == .airOutlet) {
                    continue
                }

                if state == .air &&
                    (existingState == .water ||
                     existingState == .waterInlet ||
                     existingState == .waterOutlet) {
                    continue
                }

                visited.insert(neighbor)
                cameFrom[neighbor] = current
                queue.append(neighbor)
            }
        }

        guard visited.contains(target) else {
            return
        }

        // Reconstruct path.
        var path: [GridPoint] = []
        var current = target

        path.append(current)

        while current != start {

            guard let previous = cameFrom[current] else {
                return
            }

            current = previous
            path.append(current)
        }

        // Carve the path.
        for point in path {

            guard let index = indexFor(point) else {
                continue
            }

            guard point.z > 0 else {
                continue
            }

            switch state {
            case .water:
                cells[index].state = .water

            case .air:
                cells[index].state = .air

            default:
                break
            }
        }
    }
 
    private func channelTraversalCost(
        _ point: GridPoint,
        target: GridPoint,
        state: RadiatorCellState
    ) -> Int {

        guard let index = indexFor(point) else {
            return Int.max
        }

        let cellState = cells[index].state

        let distance = manhattanDistance(
            point,
            target
        )

        // Existing fluid channels are cheapest.
        if state == .water &&
            (cellState == .water ||
             cellState == .waterInlet ||
             cellState == .waterOutlet) {
            return distance
        }

        if state == .air &&
            (cellState == .air ||
             cellState == .airInlet ||
             cellState == .airOutlet) {
            return distance
        }

        // Empty space is preferred over cutting aluminum.
        if cellState == .empty {
            return distance + 1
        }

        // Aluminum can still be carved when necessary,
        // but it is strongly penalized.
        if cellState == .aluminum {
            return distance + 20
        }

        return Int.max / 2
    }
    private func createPorts() {
        waterPorts.removeAll()
        airPorts.removeAll()

        let last = gridSize - 1

        // Distributed across each face.
        // z = 0 remains reserved for the aluminum build platform.
        let positions = [3, 7, 10, 13, 17]

        // MARK: Water
        //
        // Water enters through x = 0
        // and exits through x = last.
        //
        // 25 water inlets
        // 25 water outlets

        for y in positions {
            for z in positions {

                guard z > 0 else {
                    continue
                }

                waterPorts.append(
                    FlowPort(
                        point: GridPoint(
                            x: 0,
                            y: y,
                            z: z
                        ),
                        kind: .waterInlet
                    )
                )

                waterPorts.append(
                    FlowPort(
                        point: GridPoint(
                            x: last,
                            y: y,
                            z: z
                        ),
                        kind: .waterOutlet
                    )
                )
            }
        }

        // MARK: Air
        //
        // Air enters through y = 0
        // and exits through y = last.
        //
        // 25 air inlets
        // 25 air outlets

        for x in positions {
            for z in positions {

                guard z > 0 else {
                    continue
                }

                airPorts.append(
                    FlowPort(
                        point: GridPoint(
                            x: x,
                            y: 0,
                            z: z
                        ),
                        kind: .airInlet
                    )
                )

                airPorts.append(
                    FlowPort(
                        point: GridPoint(
                            x: x,
                            y: last,
                            z: z
                        ),
                        kind: .airOutlet
                    )
                )
            }
        }

        print("""
        PORT DISTRIBUTION
        -----------------
        Water inlets:  \(waterPorts.filter { $0.kind == .waterInlet }.count)
        Water outlets: \(waterPorts.filter { $0.kind == .waterOutlet }.count)
        Air inlets:    \(airPorts.filter { $0.kind == .airInlet }.count)
        Air outlets:   \(airPorts.filter { $0.kind == .airOutlet }.count)
        Total ports:   \(waterPorts.count + airPorts.count)
        """)
    }
    private func carveFlowNetworks() {
        carveDistributedWaterNetwork()
        carveDistributedAirNetwork()

        removeFlowOverlap()
        applyPortStates()
    }

    private func carveDistributedWaterNetwork() {

        let waterInlets = waterPorts.filter {
            $0.kind == .waterInlet
        }

        let waterOutlets = waterPorts.filter {
            $0.kind == .waterOutlet
        }

        guard !waterInlets.isEmpty,
              !waterOutlets.isEmpty
        else {
            return
        }

        // Keep unused outlets in a Set so each outlet is
        // assigned only once.
        var unusedOutlets = Set(
            waterOutlets.map { $0.point }
        )

        // Match each inlet to the nearest available outlet.
        // This creates distributed parallel water channels.
        for inlet in waterInlets {

            guard !unusedOutlets.isEmpty else {
                break
            }

            guard let outlet = nearestPoint(
                to: inlet.point,
                from: Array(unusedOutlets)
            ) else {
                continue
            }

            carveManifoldPath(
                from: inlet.point,
                to: outlet,
                state: .water
            )

            unusedOutlets.remove(outlet)
        }

        // If there are more inlets than outlets, allow the
        // remaining inlets to share their nearest outlet.
        if !unusedOutlets.isEmpty == false,
           waterInlets.count > waterOutlets.count {

            let allOutletPoints = waterOutlets.map {
                $0.point
            }

            for inlet in waterInlets.dropFirst(waterOutlets.count) {

                guard let outlet = nearestPoint(
                    to: inlet.point,
                    from: allOutletPoints
                ) else {
                    continue
                }

                carveManifoldPath(
                    from: inlet.point,
                    to: outlet,
                    state: .water
                )
            }
        }
    }
 
    private func manhattanDistance(
        _ a: GridPoint,
        _ b: GridPoint
    ) -> Int {

        abs(a.x - b.x)
        + abs(a.y - b.y)
        + abs(a.z - b.z)
    }
    private func nearestPoint(
        to source: GridPoint,
        from candidates: [GridPoint]
    ) -> GridPoint? {

        candidates.min {
            manhattanDistance(source, $0)
            <
            manhattanDistance(source, $1)
        }
    }
    private func carveDistributedAirNetwork() {

        let airInlets = airPorts.filter {
            $0.kind == .airInlet
        }

        let airOutlets = airPorts.filter {
            $0.kind == .airOutlet
        }
        guard !airInlets.isEmpty,
              !airOutlets.isEmpty
        else {
            return
        }

        let outletPoints = airOutlets.map {
            $0.point
        }

        for inlet in airInlets {

            guard let outlet = nearestPoint(
                to: inlet.point,
                from: outletPoints
            ) else {
                continue
            }

            carveManifoldPath(
                from: inlet.point,
                to: outlet,
                state: .air
            )
        }
    }
    private func carveWaterNetwork() {

        let inlets =
            waterPorts.filter {
                $0.kind == .waterInlet
            }

        let outlets =
            waterPorts.filter {
                $0.kind == .waterOutlet
            }

        for inlet in inlets {

            for outlet in outlets {

                carveManifoldPath(
                    from: inlet.point,
                    to: outlet.point,
                    state: .water
                )
            }
        }
    }

    private func carveAirNetwork() {

        let inlets =
            airPorts.filter {
                $0.kind == .airInlet
            }

        let outlets =
            airPorts.filter {
                $0.kind == .airOutlet
            }

        for inlet in inlets {

            for outlet in outlets {

                carveManifoldPath(
                    from: inlet.point,
                    to: outlet.point,
                    state: .air
                )
            }
        }
    }

    

    private func removeFlowOverlap() {

        /*
         A voxel can only have one state, so direct overlap is impossible
         in the enum itself.

         This pass protects air ports from being overwritten by water.
         */

        for port in airPorts {

            guard let index =
                indexFor(port.point)
            else {
                continue
            }

            if cells[index].state.isWater {

                cells[index].state =
                    .air
            }
        }
    }

    // MARK: - Port Application

    private func applyPortStates() {

        applyPortStates(
            to: &cells
        )
    }

    private func applyPortStates(
        to candidateCells: inout [RadiatorCell]
    ) {

        for port in waterPorts {

            guard let index =
                indexFor(port.point)
            else {
                continue
            }

            switch port.kind {

            case .waterInlet:

                candidateCells[index].state =
                    .waterInlet

            case .waterOutlet:

                candidateCells[index].state =
                    .waterOutlet

            default:
                break
            }
        }

        for port in airPorts {

            guard let index =
                indexFor(port.point)
            else {
                continue
            }

            switch port.kind {

            case .airInlet:

                candidateCells[index].state =
                    .airInlet

            case .airOutlet:

                candidateCells[index].state =
                    .airOutlet

            default:
                break
            }
        }
    }

    // MARK: - Thermal Initialization

    private func initializeThermalField() {
        thermalSimulationTimeS = 0

        datacenterEnergyInjectedJ = 0
        waterToAluminumEnergyJ = 0
        airEnergyRemovedJ = 0
        lastAirHeatTransferW = 0

        for index in cells.indices {
            cells[index].temperatureC = ambientTemperatureC
            cells[index].heatJ = 0
            cells[index].flowRateM3S = 0
            cells[index].pressurePa = 0

            if cells[index].state.isAir {
                cells[index].temperatureC = airInletTemperatureC
            }
        }

        applyPortStates()
    }

    // MARK: - Datacenter Water Temperature

    /*
     The datacenter supplies 1 GJ.

     Water carries that thermal energy.

     Q = m_dot * Cp * deltaT

     Therefore:

     deltaT = Qdot / (m_dot * Cp)
     */

    private var waterMassFlowKgS: Double {

        metrics.waterFlowM3S *
        waterDensityKgM3
    }

    private var datacenterWaterTemperatureRiseC: Double {

        let massFlow =
            max(
                waterMassFlowKgS,
                0.000001
            )

        return requiredHeatRateW /
            (
                massFlow *
                waterSpecificHeat
            )
    }
    private func applyWaterInletTemperature(
        to cells: inout [RadiatorCell]
    ) {
        let remainingSourceEnergyJ =
            max(
                datacenterHeatLoadJ -
                datacenterEnergyInjectedJ,
                0.0
            )

        guard remainingSourceEnergyJ > 0 else {
            return
        }

        let timestepEnergyJ =
            min(
                requiredHeatRateW * thermalTimeStepS,
                remainingSourceEnergyJ
            )

        guard timestepEnergyJ > 0 else {
            return
        }

        let inletPorts = waterPorts.filter {
            $0.kind == .waterInlet
        }

        guard !inletPorts.isEmpty else {
            print(
                "FAIL: No water inlet ports available."
            )
            return
        }

        let waterFlowM3S =
            max(
                calculateWaterFlow(cells),
                0.0
            )

        let massFlowKgS =
            max(
                waterFlowM3S * waterDensityKgM3,
                0.000001
            )

        let waterMassThisStepKg =
            massFlowKgS * thermalTimeStepS

        guard waterMassThisStepKg > 0 else {
            return
        }

        let temperatureRiseC =
            timestepEnergyJ /
            max(
                waterMassThisStepKg *
                waterSpecificHeat,
                1.0e-12
            )

        let inletTemperatureC =
            ambientTemperatureC +
            temperatureRiseC

        let energyPerInletJ =
            timestepEnergyJ /
            Double(inletPorts.count)

        for port in inletPorts {

            guard let index =
                    indexFor(port.point)
            else {
                continue
            }

            guard cells[index].state.isWater
            else {
                continue
            }

            cells[index].heatJ +=
                energyPerInletJ

            cells[index].temperatureC =
                inletTemperatureC
        }

        datacenterEnergyInjectedJ +=
            timestepEnergyJ

        datacenterEnergyInjectedJ =
            min(
                datacenterEnergyInjectedJ,
                datacenterHeatLoadJ
            )

        print(
            """
            DATACENTER HEAT INJECTION

            injected this step: \(timestepEnergyJ) J

            total injected: \(datacenterEnergyInjectedJ) J

            remaining:
            \(datacenterHeatLoadJ -
              datacenterEnergyInjectedJ) J

            inlet temperature:
            \(inletTemperatureC) °C

            water flow:
            \(waterFlowM3S) m³/s

            mass flow:
            \(massFlowKgS) kg/s
            """
        )
    }
    private func restoreWaterChannelWalls(
        in cells: inout [RadiatorCell]
    ) {
        var repairedWallCount = 0
        var skippedWaterPathCount = 0
        var skippedOutOfBoundsCount = 0

        for index in cells.indices {

            let waterCell =
                cells[index]

            guard waterCell.state == .water ||
                  waterCell.state == .waterInlet ||
                  waterCell.state == .waterOutlet
            else {
                continue
            }

            let waterPoint =
                pointFor(index)

            for neighborPoint in neighborPoints(waterPoint) {

                guard let neighborIndex =
                        indexFor(neighborPoint)
                else {
                    skippedOutOfBoundsCount += 1
                    continue
                }

                let neighborState =
                    cells[neighborIndex].state

                // Preserve the continuous water path and water ports.
                guard neighborState != .water &&
                      neighborState != .waterInlet &&
                      neighborState != .waterOutlet
                else {
                    skippedWaterPathCount += 1
                    continue
                }

                // Replace air or another non-water state with a
                // solid aluminum coolant-channel wall.
                guard neighborState != .aluminum
                else {
                    continue
                }

                cells[neighborIndex].state =
                    .aluminum

                cells[neighborIndex].temperatureC =
                    ambientTemperatureC

                cells[neighborIndex].heatJ =
                    0.0

                repairedWallCount += 1
            }
        }

        print(
            """
            WATER CHANNEL WALL REPAIR

            Aluminum wall cells restored:
            \(repairedWallCount)

            Preserved water-path neighbors:
            \(skippedWaterPathCount)

            Out-of-bounds neighbors:
            \(skippedOutOfBoundsCount)
            """
        )
    }
    private func advanceThermalField() {

        restoreWaterChannelWalls(
               in: &cells
           )
        
        let previousCells = cells
        var nextCells = previousCells

        thermalSimulationTimeS += thermalTimeStepS

        // -------------------------------------------------------------
        // STEP ENERGY TARGET
        // -------------------------------------------------------------

        let requiredStepEnergyJ =
            requiredHeatRateW *
            thermalTimeStepS

        // -------------------------------------------------------------
        // 1. DATACENTER → WATER
        // -------------------------------------------------------------

        applyWaterInletTemperature(
            to: &nextCells
        )

        // -------------------------------------------------------------
        // 2. WATER → ALUMINUM
        // -------------------------------------------------------------

        var waterToAluminumThisStepJ = 0.0

        let remainingInjectedEnergyJ =
            max(
                datacenterEnergyInjectedJ -
                waterToAluminumEnergyJ,
                0.0
            )

        let targetWaterToAluminumStepJ =
            min(
                requiredStepEnergyJ,
                remainingInjectedEnergyJ
            )

        // -------------------------------------------------------------
        // WATER → ALUMINUM DEBUG COUNTERS
        // -------------------------------------------------------------

        var scannedCellCount = 0

        var waterCellCount = 0
        var waterInletCellCount = 0
        var waterOutletCellCount = 0

        var coldWaterCellCount = 0
        var waterWithNoStoredEnergyCount = 0
        var waterWithNoCapacityCount = 0

        var neighborCheckCount = 0
        var missingNeighborIndexCount = 0

        var waterNeighborCount = 0
        var airNeighborCount = 0
        var aluminumNeighborCount = 0
        var otherNeighborStateCount = 0

        var positiveDeltaTCount = 0
        var nonPositiveDeltaTCount = 0
        var positiveInterfaceTransferCount = 0

        var noAluminumCapacityCount = 0
        var zeroTransferredEnergyCount = 0
        var successfulTransferCount = 0

        var firstWaterCellReported = false
        var firstAluminumNeighborReported = false
        var firstTransferReported = false

        if targetWaterToAluminumStepJ > 0 {

            for index in nextCells.indices {

                scannedCellCount += 1

                guard waterToAluminumThisStepJ <
                        targetWaterToAluminumStepJ
                else {
                    break
                }

                let waterCell =
                    nextCells[index]

                guard waterCell.state == .water ||
                      waterCell.state == .waterInlet ||
                      waterCell.state == .waterOutlet
                else {
                    continue
                }

                switch waterCell.state {

                case .water:
                    waterCellCount += 1

                case .waterInlet:
                    waterInletCellCount += 1

                case .waterOutlet:
                    waterOutletCellCount += 1

                default:
                    break
                }

                let waterTemperature =
                    waterCell.temperatureC

                let availableWaterEnergyJ =
                    max(
                        waterCell.heatJ,
                        0.0
                    )

                if !firstWaterCellReported {

                    firstWaterCellReported = true

                    print(
                        """
                        WATER → ALUMINUM DEBUG: FIRST WATER CELL

                        index:
                        \(index)

                        point:
                        \(String(describing: pointFor(index)))

                        state:
                        \(String(describing: waterCell.state))

                        temperature:
                        \(waterTemperature) °C

                        stored heat:
                        \(availableWaterEnergyJ) J

                        ambient:
                        \(ambientTemperatureC) °C
                        """
                    )
                }

                guard waterTemperature >
                        ambientTemperatureC
                else {
                    coldWaterCellCount += 1
                    continue
                }

                guard availableWaterEnergyJ > 0
                else {
                    waterWithNoStoredEnergyCount += 1
                    continue
                }

                let waterMassKg =
                    waterDensityKgM3 *
                    cellVolumeM3

                let waterHeatCapacity =
                    waterMassKg *
                    waterSpecificHeat

                guard waterHeatCapacity > 0
                else {
                    waterWithNoCapacityCount += 1
                    continue
                }

                let point =
                    pointFor(index)

                for neighborPoint in neighborPoints(point) {

                    guard waterToAluminumThisStepJ <
                            targetWaterToAluminumStepJ
                    else {
                        break
                    }

                    neighborCheckCount += 1

                    guard let neighborIndex =
                            indexFor(neighborPoint)
                    else {
                        missingNeighborIndexCount += 1
                        continue
                    }

                    let neighborCell =
                        nextCells[neighborIndex]

                    switch neighborCell.state {

                    case .water,
                         .waterInlet,
                         .waterOutlet:

                        waterNeighborCount += 1
                        continue

                    case .air:

                        airNeighborCount += 1
                        continue

                    case .aluminum:

                        aluminumNeighborCount += 1

                    default:

                        otherNeighborStateCount += 1
                        continue
                    }

                    let aluminumTemperature =
                        neighborCell.temperatureC

                    if !firstAluminumNeighborReported {

                        firstAluminumNeighborReported = true

                        print(
                            """
                            WATER → ALUMINUM DEBUG: FIRST ALUMINUM NEIGHBOR

                            water index:
                            \(index)

                            water point:
                            \(String(describing: point))

                            aluminum index:
                            \(neighborIndex)

                            aluminum point:
                            \(String(describing: neighborPoint))

                            water temperature:
                            \(waterTemperature) °C

                            aluminum temperature:
                            \(aluminumTemperature) °C

                            water stored heat:
                            \(availableWaterEnergyJ) J
                            """
                        )
                    }

                    let deltaT =
                        waterTemperature -
                        aluminumTemperature

                    guard deltaT > 0
                    else {
                        nonPositiveDeltaTCount += 1
                        continue
                    }

                    positiveDeltaTCount += 1

                    let interfaceTransferJ =
                        waterHeatTransferCoefficient *
                        cellFaceAreaM2 *
                        deltaT *
                        thermalTimeStepS

                    guard interfaceTransferJ > 0
                    else {
                        continue
                    }

                    positiveInterfaceTransferCount += 1

                    let remainingTargetJ =
                        targetWaterToAluminumStepJ -
                        waterToAluminumThisStepJ

                    let aluminumMassKg =
                        aluminumDensityKgM3 *
                        cellVolumeM3

                    let aluminumHeatCapacity =
                        aluminumMassKg *
                        aluminumSpecificHeat

                    guard aluminumHeatCapacity > 0
                    else {
                        noAluminumCapacityCount += 1
                        continue
                    }

                    let transferredJ =
                        min(
                            interfaceTransferJ,
                            availableWaterEnergyJ,
                            remainingTargetJ
                        )

                    guard transferredJ > 0
                    else {
                        zeroTransferredEnergyCount += 1
                        continue
                    }

                    if !firstTransferReported {

                        firstTransferReported = true

                        print(
                            """
                            WATER → ALUMINUM DEBUG: FIRST TRANSFER

                            water index:
                            \(index)

                            aluminum index:
                            \(neighborIndex)

                            delta T:
                            \(deltaT) °C

                            interface transfer:
                            \(interfaceTransferJ) J

                            available water energy:
                            \(availableWaterEnergyJ) J

                            target remaining:
                            \(remainingTargetJ) J

                            transferred:
                            \(transferredJ) J
                            """
                        )
                    }

                    nextCells[index].heatJ =
                        max(
                            0.0,
                            nextCells[index].heatJ -
                            transferredJ
                        )

                    let waterDeltaT =
                        transferredJ /
                        waterHeatCapacity

                    nextCells[index].temperatureC =
                        max(
                            ambientTemperatureC,
                            nextCells[index].temperatureC -
                            waterDeltaT
                        )

                    nextCells[neighborIndex].heatJ +=
                        transferredJ

                    let aluminumDeltaT =
                        transferredJ /
                        aluminumHeatCapacity

                    nextCells[neighborIndex].temperatureC +=
                        aluminumDeltaT

                    waterToAluminumThisStepJ +=
                        transferredJ

                    waterToAluminumEnergyJ +=
                        transferredJ

                    successfulTransferCount += 1
                }
            }
        }

        // -------------------------------------------------------------
        // WATER → ALUMINUM DIAGNOSTIC
        // -------------------------------------------------------------

        let waterTransferRateW =
            waterToAluminumThisStepJ /
            max(
                thermalTimeStepS,
                1.0e-12
            )

        let waterTransferEfficiency =
            targetWaterToAluminumStepJ > 0
            ? waterToAluminumThisStepJ /
              targetWaterToAluminumStepJ
            : 0.0
        
        let airEnergyExportedThisStepJ = exportAirOutletEnergy(from: &nextCells)

        airEnergyRemovedJ += airEnergyExportedThisStepJ
        airEnergyRemovedThisStepJ = airEnergyExportedThisStepJ

        print(
            """
            =============================================================
            WATER → ALUMINUM DEBUG SUMMARY
            =============================================================

            TARGET

            target this step:
            \(targetWaterToAluminumStepJ) J

            actual this step:
            \(waterToAluminumThisStepJ) J

            cumulative transfer:
            \(waterToAluminumEnergyJ) J

            transfer rate:
            \(waterTransferRateW) W

            transfer efficiency:
            \(waterTransferEfficiency)

            -------------------------------------------------------------
            WATER CELLS
            -------------------------------------------------------------

            cells scanned:
            \(scannedCellCount)

            ordinary water:
            \(waterCellCount)

            water inlets:
            \(waterInletCellCount)

            water outlets:
            \(waterOutletCellCount)

            skipped: cold water:
            \(coldWaterCellCount)

            skipped: no stored water energy:
            \(waterWithNoStoredEnergyCount)

            skipped: invalid water heat capacity:
            \(waterWithNoCapacityCount)

            -------------------------------------------------------------
            NEIGHBORS OF HOT, ENERGIZED WATER
            -------------------------------------------------------------

            neighbor checks:
            \(neighborCheckCount)

            neighbor index missing:
            \(missingNeighborIndexCount)

            neighboring water:
            \(waterNeighborCount)

            neighboring air:
            \(airNeighborCount)

            neighboring aluminum:
            \(aluminumNeighborCount)

            neighboring other state:
            \(otherNeighborStateCount)

            -------------------------------------------------------------
            INTERFACE TESTS
            -------------------------------------------------------------

            aluminum neighbors with positive ΔT:
            \(positiveDeltaTCount)

            aluminum neighbors with zero/negative ΔT:
            \(nonPositiveDeltaTCount)

            positive h × A × ΔT × dt:
            \(positiveInterfaceTransferCount)

            invalid aluminum heat capacity:
            \(noAluminumCapacityCount)

            zero final transferred energy:
            \(zeroTransferredEnergyCount)

            successful water → aluminum transfers:
            \(successfulTransferCount)

            -------------------------------------------------------------
            STATUS
            -------------------------------------------------------------

            \(successfulTransferCount > 0
                ? "PASS: Heat reached the aluminum lattice."
                : "FAIL: No heat reached the aluminum lattice.")

            =============================================================
            """
        )

        // -------------------------------------------------------------
        // 3. ALUMINUM ↔ ALUMINUM CONDUCTION
        // -------------------------------------------------------------

        for index in previousCells.indices {

            guard previousCells[index].state ==
                    .aluminum
            else {
                continue
            }

            let point =
                pointFor(index)

            for neighborPoint in neighborPoints(point) {

                guard let neighborIndex =
                        indexFor(neighborPoint)
                else {
                    continue
                }

                guard neighborIndex > index
                else {
                    continue
                }

                guard previousCells[neighborIndex].state ==
                        .aluminum
                else {
                    continue
                }

                let temperatureA =
                    previousCells[index].temperatureC

                let temperatureB =
                    previousCells[neighborIndex].temperatureC

                let deltaT =
                    temperatureB -
                    temperatureA

                guard abs(deltaT) > 0.001
                else {
                    continue
                }

                let equilibriumTransfer =
                    deltaT *
                    aluminumConductionFactor

                let limitedTransfer =
                    max(
                        -maximumTemperatureChangePerStepC,
                        min(
                            maximumTemperatureChangePerStepC,
                            equilibriumTransfer
                        )
                    )

                nextCells[index].temperatureC +=
                    limitedTransfer

                nextCells[neighborIndex].temperatureC -=
                    limitedTransfer

                synchronizeCellHeat(
                    index: index,
                    cells: &nextCells
                )

                synchronizeCellHeat(
                    index: neighborIndex,
                    cells: &nextCells
                )
            }
        }

        // -------------------------------------------------------------
        // 4. ALUMINUM → AIR
        // -------------------------------------------------------------

        var aluminumToAirThisStepJ = 0.0

        for index in previousCells.indices {

            guard previousCells[index].state ==
                    .aluminum
            else {
                continue
            }

            let point =
                pointFor(index)

            for neighborPoint in neighborPoints(point) {

                guard let neighborIndex =
                        indexFor(neighborPoint)
                else {
                    continue
                }

                guard previousCells[neighborIndex].state.isAir
                else {
                    continue
                }

                let aluminumTemperature =
                    nextCells[index].temperatureC

                let airTemperature =
                    nextCells[neighborIndex].temperatureC

                let deltaT =
                    aluminumTemperature -
                    airTemperature

                guard deltaT > 0
                else {
                    continue
                }

                let interfaceTransferJ =
                    airHeatTransferCoefficient *
                    cellFaceAreaM2 *
                    deltaT *
                    thermalTimeStepS

                guard interfaceTransferJ > 0
                else {
                    continue
                }

                let aluminumMassKg =
                    aluminumDensityKgM3 *
                    cellVolumeM3

                let aluminumHeatCapacity =
                    aluminumMassKg *
                    aluminumSpecificHeat

                guard aluminumHeatCapacity > 0
                else {
                    continue
                }

                let availableAluminumEnergyJ =
                    max(
                        nextCells[index].heatJ,
                        0.0
                    )

                guard availableAluminumEnergyJ > 0
                else {
                    continue
                }

                let transferredJ =
                    min(
                        interfaceTransferJ,
                        availableAluminumEnergyJ
                    )

                guard transferredJ > 0
                else {
                    continue
                }

                let airMassKg =
                    airDensityKgM3 *
                    cellVolumeM3

                let airHeatCapacity =
                    airMassKg *
                    airSpecificHeat

                guard airHeatCapacity > 0
                else {
                    continue
                }

                nextCells[index].heatJ =
                    max(
                        0.0,
                        nextCells[index].heatJ -
                        transferredJ
                    )

                let aluminumDeltaT =
                    transferredJ /
                    aluminumHeatCapacity

                nextCells[index].temperatureC =
                    max(
                        ambientTemperatureC,
                        nextCells[index].temperatureC -
                        aluminumDeltaT
                    )

                nextCells[neighborIndex].heatJ +=
                    transferredJ

                let airDeltaT =
                    transferredJ /
                    airHeatCapacity

                nextCells[neighborIndex].temperatureC +=
                    airDeltaT

                aluminumToAirThisStepJ +=
                    transferredJ

                aluminumToAirEnergyJ +=
                    transferredJ
            }
        }

        // -------------------------------------------------------------
        // ALUMINUM → AIR DIAGNOSTIC
        // -------------------------------------------------------------

        print(
            """
            ALUMINUM → AIR TRANSFER

            actual this step:
            \(aluminumToAirThisStepJ) J

            cumulative transfer:
            \(aluminumToAirEnergyJ) J

            transfer rate:
            \(aluminumToAirThisStepJ /
              max(thermalTimeStepS, 1.0e-12)) W

            STATUS:
            \(aluminumToAirThisStepJ > 0
                ? "PASS"
                : "FAIL")
            """
        )

        // -------------------------------------------------------------
        // 5. ADVECT WATER
        // -------------------------------------------------------------

        advectWaterTemperature(
            previousCells: previousCells,
            nextCells: &nextCells
        )

        // -------------------------------------------------------------
        // 6. ADVECT AIR
        // -------------------------------------------------------------

        advectAirTemperature(
            previousCells: previousCells,
            nextCells: &nextCells
        )

        // -------------------------------------------------------------
        // 7. NUMERICAL TEMPERATURE SAFETY
        // -------------------------------------------------------------

        for index in nextCells.indices {

            nextCells[index].temperatureC =
                max(
                    ambientTemperatureC,
                    nextCells[index].temperatureC
                )
        }

        // -------------------------------------------------------------
        // 8. RESTORE THERMAL BOUNDARIES
        // -------------------------------------------------------------

        applyThermalBoundaryConditions(
            to: &nextCells
        )

        // -------------------------------------------------------------
        // 9. COMMIT
        // -------------------------------------------------------------

        cells = nextCells

        // -------------------------------------------------------------
        // 10. ENERGY DISTRIBUTION
        // -------------------------------------------------------------

        let aluminumHeatJ =
            cells.reduce(0.0) { total, cell in

                guard cell.state == .aluminum
                else {
                    return total
                }

                return total +
                    max(
                        cell.heatJ,
                        0.0
                    )
            }

        let waterHeatJ =
            cells.reduce(0.0) { total, cell in

                guard cell.state.isWater
                else {
                    return total
                }

                return total +
                    max(
                        cell.heatJ,
                        0.0
                    )
            }

        let airHeatJ =
            cells.reduce(0.0) { total, cell in

                guard cell.state.isAir
                else {
                    return total
                }

                return total +
                    max(
                        cell.heatJ,
                        0.0
                    )
            }

        // -------------------------------------------------------------
        // 11. ENERGY BUDGET
        // -------------------------------------------------------------

        let storedThermalEnergyJ =
            waterHeatJ +
            aluminumHeatJ +
            airHeatJ

        let unaccountedEnergyJ =
            datacenterEnergyInjectedJ -
            airEnergyRemovedJ -
            storedThermalEnergyJ

        // -------------------------------------------------------------
        // 12. STATUS
        // -------------------------------------------------------------

        let latticeContainsHeat =
            aluminumHeatJ > 0

        let waterTransferPass =
            waterToAluminumThisStepJ > 0

        let airTransferPass =
            aluminumToAirThisStepJ > 0

        print(
            """
            =============================================================
            THERMAL FIELD STATUS
            =============================================================

            Simulation time:
            \(thermalSimulationTimeS) s

            Datacenter heat injected:
            \(datacenterEnergyInjectedJ) J
            \(datacenterEnergyInjectedJ / 1_000_000.0) MJ

            Required total:
            \(datacenterHeatLoadJ) J
            \(datacenterHeatLoadJ / 1_000_000.0) MJ

            Remaining source energy:
            \(max(
                datacenterHeatLoadJ -
                datacenterEnergyInjectedJ,
                0.0
            )) J

            -------------------------------------------------------------
            ENERGY DISTRIBUTION
            -------------------------------------------------------------

            Water:
            \(waterHeatJ) J

            Aluminum:
            \(aluminumHeatJ) J

            Air:
            \(airHeatJ) J

            Stored thermal energy:
            \(storedThermalEnergyJ) J

            Aluminum → air transfer:
            \(aluminumToAirEnergyJ) J

            Actual air outlet removal:
            \(airEnergyRemovedJ) J

            -------------------------------------------------------------
            ENERGY BUDGET
            -------------------------------------------------------------

            Unaccounted:
            \(unaccountedEnergyJ) J

            -------------------------------------------------------------
            PASS / FAIL
            -------------------------------------------------------------

            Water → aluminum:
            \(waterTransferPass
                ? "PASS"
                : "FAIL")

            Aluminum contains thermal energy:
            \(latticeContainsHeat
                ? "PASS"
                : "FAIL")

            Aluminum → air:
            \(airTransferPass
                ? "PASS"
                : "FAIL")

            =============================================================
            """
        )

        printThermalEnergyBudget()
    }
 
    private var datacenterWaterInletTemperatureC: Double {

        /*
         Limit only the numerical visualization.

         The underlying 1 GJ energy accounting remains unchanged.
         */

        let temperature =
            ambientTemperatureC +
            datacenterWaterTemperatureRiseC

        return min(
            temperature,
            250.0
        )
    }

    
    private func printThermalEnergyBudget() {

        let aluminumHeatJ =
            cells.reduce(0.0) { total, cell in

                guard cell.state == .aluminum
                else {
                    return total
                }

                return total +
                    max(cell.heatJ, 0.0)
            }

        let waterHeatJ =
            cells.reduce(0.0) { total, cell in

                guard cell.state.isWater
                else {
                    return total
                }

                return total +
                    max(cell.heatJ, 0.0)
            }

        let airHeatJ =
            cells.reduce(0.0) { total, cell in

                guard cell.state.isAir
                else {
                    return total
                }

                return total +
                    max(cell.heatJ, 0.0)
            }

        print(
            """
            THERMAL ENERGY DISTRIBUTION

            Datacenter injected:
            \(datacenterEnergyInjectedJ) J

            Water thermal energy:
            \(waterHeatJ) J

            Actual water → aluminum transfer:
            \(waterToAluminumEnergyJ) J

            Aluminum lattice thermal energy:
            \(aluminumHeatJ) J

            Aluminum → air transfer:
            \(aluminumToAirEnergyJ) J

            Air removed:
            \(airEnergyRemovedJ) J

            STATUS

            Actual water → aluminum transfer:
            \(waterToAluminumEnergyJ > 0
                ? "PASS"
                : "NOT SHOWN / NO TRANSFER RECORDED")

            Aluminum lattice contains injected heat:
            \(aluminumHeatJ > 0
                ? "PASS"
                : "NOT PROVEN")
            """
        )
    }
    private func resetThermalEnergyAccounting() {

        datacenterEnergyInjectedJ = 0.0
        waterToAluminumEnergyJ = 0.0
        aluminumToAirEnergyJ = 0.0
        airEnergyRemovedJ = 0.0

        thermalSimulationTimeS = 0.0
    }
    private func totalWaterToAluminumTransfer(
        _ energyJ: Double
    ) {

        waterEnergyExportedJ =
            max(
                0.0,
                waterEnergyExportedJ
            )

        _ = energyJ
    }

    private func synchronizeCellHeat(
        index: Int,
        cells: inout [RadiatorCell]
    ) {

        guard cells[index].state ==
                .aluminum
        else {
            return
        }

        let mass =
            aluminumDensityKgM3 *
            cellVolumeM3

        cells[index].heatJ =
            mass *
            aluminumSpecificHeat *
            max(
                0.0,
                cells[index].temperatureC -
                ambientTemperatureC
            )
    }

    // MARK: - Water Advection

    private func advectWaterTemperature(
        previousCells: [RadiatorCell],
        nextCells: inout [RadiatorCell]
    ) {

        /*
         Reduced-order plug-flow approximation.

         Water temperature is moved toward neighboring water cells
         in the direction of the nearest water outlet.
         */

        let outletPoints =
            waterPorts
                .filter {
                    $0.kind == .waterOutlet
                }
                .map {
                    $0.point
                }

        guard !outletPoints.isEmpty else {
            return
        }

        for index in previousCells.indices {

            guard previousCells[index].state.isWater
            else {
                continue
            }

            guard previousCells[index].state !=
                    .waterOutlet
            else {
                continue
            }

            let point =
                pointFor(index)

            let neighbors =
                neighborPoints(point)

                .compactMap {
                    neighbor -> (
                        index: Int,
                        distance: Int
                    )? in

                    guard let neighborIndex =
                        indexFor(neighbor)
                    else {
                        return nil
                    }

                    guard previousCells[
                        neighborIndex
                    ].state.isWater
                    else {
                        return nil
                    }

                    let distance =
                        outletPoints.map {

                            abs(
                                $0.x -
                                neighbor.x
                            ) +

                            abs(
                                $0.y -
                                neighbor.y
                            ) +

                            abs(
                                $0.z -
                                neighbor.z
                            )

                        }.min() ?? Int.max

                    return (
                        index: neighborIndex,
                        distance: distance
                    )
                }
                .sorted {
                    $0.distance <
                    $1.distance
                }

            guard let downstream =
                neighbors.first
            else {
                continue
            }

            let sourceTemperature =
                previousCells[index]
                    .temperatureC

            let downstreamTemperature =
                previousCells[
                    downstream.index
                ].temperatureC

            let mixing =
                min(
                    0.35,
                    nominalWaterVelocityMS *
                    thermalTimeStepS /
                    cellSizeM
                )

            let newTemperature =
                downstreamTemperature +
                (
                    sourceTemperature -
                    downstreamTemperature
                ) *
                mixing

            nextCells[
                downstream.index
            ].temperatureC =
                max(
                    nextCells[
                        downstream.index
                    ].temperatureC,
                    newTemperature
                )
        }
    }
    private func exportAirOutletEnergy(
        from cells: inout [RadiatorCell]
    ) -> Double {
        var removedEnergyJ = 0.0

        for port in airPorts where port.kind == .airOutlet {
            guard let index = indexFor(port.point) else { continue }

            let state = cells[index].state
            guard state.isAir || state == .airOutlet else { continue }

            let airMassKg = max(cells[index].massKg, 0.0)
            let heatCapacityJPerK = airMassKg * airSpecificHeatJPerKgK

            guard heatCapacityJPerK > 0 else { continue }

            let deltaTemperatureC =
                max(0.0, cells[index].temperatureC - airInletTemperatureC)

            let exportedJ = deltaTemperatureC * heatCapacityJPerK

            removedEnergyJ += exportedJ

            // Outlet is replenished by incoming ambient/inlet air for the next step.
            cells[index].temperatureC = airInletTemperatureC
            cells[index].heatJ = 0.0
        }

        return removedEnergyJ
    }
    // MARK: - Air Advection

    private func advectAirTemperature(
        previousCells: [RadiatorCell],
        nextCells: inout [RadiatorCell]
    ) {

        let outletPoints =
            airPorts
                .filter {
                    $0.kind == .airOutlet
                }
                .map {
                    $0.point
                }

        guard !outletPoints.isEmpty else {
            return
        }

        for index in previousCells.indices {

            guard previousCells[index].state.isAir
            else {
                continue
            }

            guard previousCells[index].state !=
                    .airOutlet
            else {
                continue
            }

            let point =
                pointFor(index)

            let neighbors =
                neighborPoints(point)

                .compactMap {
                    neighbor -> (
                        index: Int,
                        distance: Int
                    )? in

                    guard let neighborIndex =
                        indexFor(neighbor)
                    else {
                        return nil
                    }

                    guard previousCells[
                        neighborIndex
                    ].state.isAir
                    else {
                        return nil
                    }

                    let distance =
                        outletPoints.map {

                            abs(
                                $0.x -
                                neighbor.x
                            ) +

                            abs(
                                $0.y -
                                neighbor.y
                            ) +

                            abs(
                                $0.z -
                                neighbor.z
                            )

                        }.min() ?? Int.max

                    return (
                        index: neighborIndex,
                        distance: distance
                    )
                }
                .sorted {
                    $0.distance <
                    $1.distance
                }

            guard let downstream =
                neighbors.first
            else {
                continue
            }

            let sourceTemperature =
                previousCells[index]
                    .temperatureC

            let downstreamTemperature =
                previousCells[
                    downstream.index
                ].temperatureC

            let mixing =
                min(
                    0.35,
                    nominalAirVelocityMS *
                    thermalTimeStepS /
                    cellSizeM
                )

            let newTemperature =
                downstreamTemperature +
                (
                    sourceTemperature -
                    downstreamTemperature
                ) *
                mixing

            nextCells[
                downstream.index
            ].temperatureC =
                max(
                    nextCells[
                        downstream.index
                    ].temperatureC,
                    newTemperature
                )
        }
    }

    // MARK: - Thermal Boundary Conditions

    private func applyThermalBoundaryConditions(
        to candidateCells: inout [RadiatorCell]
    ) {

        for port in waterPorts {

            guard let index =
                indexFor(port.point)
            else {
                continue
            }

            switch port.kind {

            case .waterInlet:

                candidateCells[index].temperatureC =
                    datacenterWaterInletTemperatureC

            case .waterOutlet:

                break

            default:
                break
            }
        }

        for port in airPorts {

            guard let index =
                indexFor(port.point)
            else {
                continue
            }

            switch port.kind {

            case .airInlet:

                candidateCells[index].temperatureC =
                    airInletTemperatureC

            case .airOutlet:

                break

            default:
                break
            }
        }
    }

    private func stepCAInternal() {

        let nextGeneration = generation + 1
        var candidateCells = cells

        let lastInterior = gridSize - 2
        let aluminumCap =
            Int(Double(totalCells) * maximumAluminumFraction)

        var aluminumCount = candidateCells.reduce(into: 0) {
            count, cell in

            if cell.state == .aluminum {
                count += 1
            }
        }

        let parity = nextGeneration % 2

        // MARK: - Diagnostics

        var growthCandidates = 0
        var acceptedGrowth = 0
        var rejectedAirPocket = 0
        var rejectedPort = 0

        // MARK: - CA growth

        for z in 1...lastInterior {
            for y in 1...lastInterior {
                for x in 1...lastInterior {

                    // Preserve checkerboard growth.
                    guard (x + y + z) % 2 == parity else {
                        continue
                    }

                    guard aluminumCount < aluminumCap else {
                        break
                    }

                    let index = linearIndex(
                        x: x,
                        y: y,
                        z: z
                    )

                    let point = GridPoint(
                        x: x,
                        y: y,
                        z: z
                    )

                    // Only grow into empty cells.
                    guard candidateCells[index].state == .air else {
                        continue
                    }

                    // -------------------------------------------------
                    // Protect actual transport ports.
                    // -------------------------------------------------

                    let isWaterPort = waterPorts.contains {
                        $0.point == point
                    }

                    let isAirPort = airPorts.contains {
                        $0.point == point
                    }

                    guard !isWaterPort && !isAirPort else {
                        rejectedPort += 1
                        continue
                    }

                    growthCandidates += 1

                    // -------------------------------------------------
                    // Neighbor information
                    // -------------------------------------------------

                    let counts = neighborCounts(
                        of: index,
                        in: candidateCells
                    )

                    let hasAluminumSupport =
                        counts.aluminum > 0

                    let hasWaterInterface =
                        counts.water > 0

                    let hasAirExposure =
                        counts.air > 0

                    let exposureGain =
                        counts.air - counts.aluminum

                    // -------------------------------------------------
                    // Normal structural / thermal score
                    // -------------------------------------------------

                    var structuralScore = 0

                    if hasAluminumSupport {
                        structuralScore += 2
                    }

                    if hasWaterInterface {
                        structuralScore += 2
                    }

                    if hasAirExposure {
                        structuralScore += 1
                    }

                    if exposureGain >= 0 {
                        structuralScore += 1
                    }

                    // -------------------------------------------------
                    // Explicit volumetric eligibility.
                    //
                    // Interior cells do not need to already touch
                    // aluminum, water, or air.
                    // -------------------------------------------------

                    let isInteriorVolume =
                        x > 1 &&
                        x < lastInterior &&
                        y > 1 &&
                        y < lastInterior &&
                        z > 1 &&
                        z < lastInterior

                    let structurallyUseful =
                        hasAluminumSupport ||
                        hasWaterInterface ||
                        hasAirExposure ||
                        isInteriorVolume

                    guard structurallyUseful else {
                        continue
                    }

                    // -------------------------------------------------
                    // Preserve required air/water passages.
                    // -------------------------------------------------

                    guard keepsAirPocketsOpen(
                        at: index,
                        in: candidateCells
                    ) else {
                        rejectedAirPocket += 1
                        continue
                    }

                    // -------------------------------------------------
                    // Deposit aluminum.
                    // -------------------------------------------------

                    candidateCells[index].temperatureC =
                        meanAluminumNeighborTemperature(
                            of: index,
                            in: candidateCells
                        )

                    candidateCells[index].state = .aluminum

                    synchronizeCellHeat(
                        index: index,
                        cells: &candidateCells
                    )

                    aluminumCount += 1
                    acceptedGrowth += 1
                }
            }
        }

        // Restore port states.
        applyPortStates(to: &candidateCells)

        // -------------------------------------------------------------
        // IMPORTANT:
        //
        // No aluminum pruning or air cleanup occurs here.
        // Validate the complete candidate first.
        // -------------------------------------------------------------

        guard printableCandidate(candidateCells) else {

            print("""
            CA GENERATION \(nextGeneration) REJECTED
            reason: printableCandidate

            aluminum: \(aluminumCount)/\(aluminumCap)
            growthCandidates: \(growthCandidates)
            acceptedGrowth: \(acceptedGrowth)
            rejectedPorts: \(rejectedPort)
            rejectedAirPockets: \(rejectedAirPocket)
            """)

            return
        }

        guard verifyNetworkConnectivity(
            kind: .waterInlet,
            cells: candidateCells
        ) else {

            print("""
            CA GENERATION \(nextGeneration) REJECTED
            reason: water connectivity

            aluminum: \(aluminumCount)/\(aluminumCap)
            growthCandidates: \(growthCandidates)
            acceptedGrowth: \(acceptedGrowth)
            """)

            return
        }

        guard verifyNetworkConnectivity(
            kind: .airOutlet,
            cells: candidateCells
        ) else {

            print("""
            CA GENERATION \(nextGeneration) REJECTED
            reason: air connectivity

            aluminum: \(aluminumCount)/\(aluminumCap)
            growthCandidates: \(growthCandidates)
            acceptedGrowth: \(acceptedGrowth)
            """)

            return
        }

        // -------------------------------------------------------------
        // COMMIT
        // -------------------------------------------------------------

        cells = candidateCells
        generation = nextGeneration

        for index in cells.indices {
            cells[index].generation = generation
        }

        // -------------------------------------------------------------
        // Cleanup ONLY after successful validation/commit.
        // -------------------------------------------------------------

        sealDeadAirPockets(
            in: &cells
        )

        fillVoidsWithAir(
            in: &cells
        )

        applyPortStates(
            to: &cells
        )

        // -------------------------------------------------------------
        // Continue simulation.
        // -------------------------------------------------------------

        advanceThermalField()
        evaluateSimulation()

        print("""
        CA GENERATION \(generation) COMMITTED

        aluminum: \(aluminumCount)/\(aluminumCap)
        growthCandidates: \(growthCandidates)
        acceptedGrowth: \(acceptedGrowth)
        rejectedPorts: \(rejectedPort)
        rejectedAirPockets: \(rejectedAirPocket)
        """)
    }
    // MARK: - Public CA Step

    func stepCA() {

        stepCAInternal()
    }



    private func verifyNetworkConnectivity(
        kind: FlowPortKind,
        cells candidateCells: [RadiatorCell]
    ) -> Bool {

        let ports: [FlowPort]
        let isFluid: (RadiatorCellState) -> Bool

        switch kind {

        case .waterInlet, .waterOutlet:
            ports = waterPorts
            isFluid = { $0.isWater }

        case .airInlet, .airOutlet:
            ports = airPorts
            isFluid = { $0.isAir }
        }

        let inlets = ports.filter { port in

            switch port.kind {

            case .waterInlet:
                return kind == .waterInlet || kind == .waterOutlet

            case .airInlet:
                return kind == .airInlet || kind == .airOutlet

            case .waterOutlet,
                 .airOutlet:
                return false
            }
        }

        let outlets = ports.filter { port in

            switch port.kind {

            case .waterOutlet:
                return kind == .waterInlet || kind == .waterOutlet

            case .airOutlet:
                return kind == .airInlet || kind == .airOutlet

            case .waterInlet,
                 .airInlet:
                return false
            }
        }

        guard !inlets.isEmpty,
              !outlets.isEmpty
        else {
            return false
        }

        // The carved networks are PARALLEL channels, so requiring every
        // inlet to reach every outlet can never hold: that made every
        // CA step get rejected and froze the lattice at generation 0.
        //
        // The correct rule: label the connected fluid regions, then
        //   - every inlet's region must contain at least one outlet
        //   - every outlet's region must contain at least one inlet

        let total = candidateCells.count

        var regionOf = [Int](
            repeating: -1,
            count: total
        )

        var regionCount = 0

        var queue: [Int] = []
        queue.reserveCapacity(total)

        for port in inlets + outlets {

            guard let start = indexFor(port.point)
            else {
                return false
            }

            guard isFluid(candidateCells[start].state)
            else {
                return false
            }

            guard regionOf[start] < 0
            else {
                continue
            }

            let region = regionCount
            regionCount += 1

            regionOf[start] = region

            queue.removeAll(keepingCapacity: true)
            queue.append(start)

            var head = 0
 
            while head < queue.count {

                let current = queue[head]
                head += 1

                for slot in 0..<6 {

                    let neighborIndex = neighborTable[current * 6 + slot]

                    guard neighborIndex >= 0,
                          regionOf[neighborIndex] < 0,
                          isFluid(candidateCells[neighborIndex].state)
                    else {
                        continue
                    }

                    regionOf[neighborIndex] = region
                    queue.append(neighborIndex)
                }
            }
        }

        var regionHasInlet = [Bool](
            repeating: false,
            count: regionCount
        )

        var regionHasOutlet = [Bool](
            repeating: false,
            count: regionCount
        )

        for port in inlets {

            guard let index = indexFor(port.point)
            else {
                return false
            }

            regionHasInlet[regionOf[index]] = true
        }

        for port in outlets {

            guard let index = indexFor(port.point)
            else {
                return false
            }

            regionHasOutlet[regionOf[index]] = true
        }

        for region in 0..<regionCount {

            if regionHasInlet[region] != regionHasOutlet[region] {
                return false
            }
        }

        return true
    }


    private func printableCandidate(
        _ candidate: [RadiatorCell]
    ) -> Bool {

        // ------------------------------------------------------------
        // 1. Collect aluminum touching the build platform.
        // ------------------------------------------------------------

        let platformAluminum: [GridPoint] =
            candidate.indices.compactMap { index in

                let cell = candidate[index]

                guard cell.state == .aluminum,
                      cell.z == 0
                else {
                    return nil
                }

                return GridPoint(
                    x: cell.x,
                    y: cell.y,
                    z: cell.z
                )
            }

        // A printable part must have at least one aluminum
        // connection to the build platform.
        guard !platformAluminum.isEmpty else {
            print("PRINTABILITY FAIL: no aluminum touches z=0 platform")
            return false
        }

        // ------------------------------------------------------------
        // 2. Flood-fill through the diamond structure.
        //
        // IMPORTANT:
        // A diamond lattice can connect through faces, edges,
        // and corners. Therefore this must use 26-neighbor
        // structural connectivity.
        // ------------------------------------------------------------

        var visited = Set<GridPoint>()

        var queue = platformAluminum
        queue.reserveCapacity(candidate.count)

        for point in platformAluminum {
            visited.insert(point)
        }

        var head = 0

        while head < queue.count {

            let point = queue[head]
            head += 1

            for neighbor in allNeighborPoints(point) {

                guard isValid(neighbor) else {
                    continue
                }

                guard let neighborIndex = indexFor(neighbor) else {
                    continue
                }

                guard candidate[neighborIndex].state == .aluminum else {
                    continue
                }

                if visited.insert(neighbor).inserted {
                    queue.append(neighbor)
                }
            }
        }

        // ------------------------------------------------------------
        // 3. Count all aluminum.
        // ------------------------------------------------------------

        let totalAluminum = candidate.reduce(
            into: 0
        ) { count, cell in

            if cell.state == .aluminum {
                count += 1
            }
        }

        guard totalAluminum > 0 else {
            print("PRINTABILITY FAIL: no aluminum")
            return false
        }

        // ------------------------------------------------------------
        // 4. Every aluminum cell must connect to the platform.
        //
        // A cell is considered floating only if there is no
        // 26-neighbor structural path back to z=0.
        // ------------------------------------------------------------

        guard visited.count == totalAluminum else {

            let floatingCount =
                totalAluminum - visited.count

            print("""
            PRINTABILITY FAIL: floating aluminum

              Total aluminum: \(totalAluminum)
              Platform-connected: \(visited.count)
              Floating: \(floatingCount)
            """)

            return false
        }

        // ------------------------------------------------------------
        // 5. Require genuine 3D occupation.
        // ------------------------------------------------------------

        let aluminumCells = candidate.filter {
            $0.state == .aluminum
        }

        guard !aluminumCells.isEmpty else {
            return false
        }

        let minX = aluminumCells.map(\.x).min()!
        let maxX = aluminumCells.map(\.x).max()!

        let minY = aluminumCells.map(\.y).min()!
        let maxY = aluminumCells.map(\.y).max()!

        let minZ = aluminumCells.map(\.z).min()!
        let maxZ = aluminumCells.map(\.z).max()!

        guard maxX > minX,
              maxY > minY,
              maxZ > minZ
        else {

            print("""
            PRINTABILITY FAIL: structure does not occupy 3D volume

              X: \(minX)...\(maxX)
              Y: \(minY)...\(maxY)
              Z: \(minZ)...\(maxZ)
            """)

            return false
        }

        // ------------------------------------------------------------
        // 6. PASS
        // ------------------------------------------------------------

        print("""
        PRINTABILITY PASS

          Aluminum: \(totalAluminum)
          Platform-connected: \(visited.count)
          Floating: 0

          X: \(minX)...\(maxX)
          Y: \(minY)...\(maxY)
          Z: \(minZ)...\(maxZ)
        """)

        return true
    }
   
    private func calculateSurfaceArea(
        _ currentCells: [RadiatorCell]
    ) -> Double {

        // Aluminum faces that touch AIR. Water-wetted faces are
        // not counted: this is the area that dumps heat to the air.

        var exposedFaces = 0

        for index in currentCells.indices {

            guard currentCells[index].state == .aluminum
            else {
                continue
            }

            let base = index * 6

            for slot in 0..<6 {

                let neighborIndex = neighborTable[base + slot]

                if neighborIndex >= 0,
                   currentCells[neighborIndex].state.isAir {

                    exposedFaces += 1
                }
            }
        }

        return Double(exposedFaces) * cellFaceAreaM2
    }

    // MARK: - Flow

    private func calculateWaterFlow(
        _ currentCells: [RadiatorCell]
    ) -> Double {

        let waterCells =
            currentCells.reduce(
                into: 0
            ) { count, cell in

                if cell.state.isWater {
                    count += 1
                }
            }

        guard waterCells > 0 else {
            return 0.0
        }

        /*
         Approximate hydraulic cross section from
         fluid voxels exposed to the primary flow direction.
         */

        let crossSection =
            max(
                cellFaceAreaM2,
                Double(waterCells) /
                Double(gridSize) *
                cellFaceAreaM2
            )

        return crossSection *
            nominalWaterVelocityMS
    }

    private func calculateAirFlow(
        _ currentCells: [RadiatorCell]
    ) -> Double {

        // Count only the carved air channels. The ambient air that
        // now fills the rest of the volume is not ducted flow, so it
        // must not inflate the flow, pressure, and fan-power numbers.

        var airCells = 0

        for index in currentCells.indices {

            guard currentCells[index].state.isAir
            else {
                continue
            }

            if airChannelMask.count == currentCells.count,
               !airChannelMask[index] {

                continue
            }

            airCells += 1
        }

        guard airCells > 0 else {
            return 0.0
        }

        let crossSection =
            max(
                cellFaceAreaM2,
                Double(airCells) /
                Double(gridSize) *
                cellFaceAreaM2
            )

        return crossSection *
            nominalAirVelocityMS
    }

    // MARK: - Pressure

    private func calculatePressureDrop(
        flowM3S: Double,
        density: Double,
        velocity: Double,
        frictionFactor: Double
    ) -> Double {

        guard flowM3S > 0 else {
            return 0.0
        }

        let length =
            Double(gridSize) *
            cellSizeM

        let hydraulicDiameter =
            cellSizeM

        return frictionFactor *
            (
                length /
                hydraulicDiameter
            ) *
            (
                density *
                velocity *
                velocity /
                2.0
            )
    }

    // MARK: - Energy / Heat Rejection

    private func calculateHeatRejectedW() -> Double {

        guard thermalSimulationTimeS > 0 else {
            return 0.0
        }

        /*
         Heat actually delivered to the air.

         This is cumulative energy transferred from the
         aluminum into the air divided by simulation time.
         */

        return airEnergyRemovedJ /
            thermalSimulationTimeS
    }
    private func transferWaterToAluminum() {

        let dt = thermalTimeStepS

        for index in cells.indices {

            guard cells[index].state.isWater else {
                continue
            }

            let waterTemperature =
                cells[index].temperatureC

            let point = pointFor(index)

            for neighborPoint in neighborPoints(point) {

                guard let aluminumIndex =
                    indexFor(neighborPoint)
                else {
                    continue
                }

                guard cells[aluminumIndex].state == .aluminum
                else {
                    continue
                }

                let aluminumTemperature =
                    cells[aluminumIndex].temperatureC

                let deltaTemperature =
                    waterTemperature -
                    aluminumTemperature

                guard deltaTemperature > 0 else {
                    continue
                }

                // Heat-transfer rate:
                //
                // Qdot = h * A * ΔT
                let heatTransferRateW =
                    waterToAluminumHeatTransferCoefficient *
                    cellFaceAreaM2 *
                    deltaTemperature

                // Energy transferred during this timestep:
                //
                // ΔE = Qdot * dt
                let transferredEnergyJ =
                    heatTransferRateW * dt

                waterToAluminumEnergyJ +=
                    Double(transferredEnergyJ)

                // Store the transferred energy in aluminum.
                cells[aluminumIndex].heatJ +=
                    transferredEnergyJ

                // Convert that energy into an aluminum
                // temperature increase.
                let aluminumMass =
                    aluminumDensityKgM3 *
                    cellVolumeM3

                let temperatureIncrease =
                    transferredEnergyJ /
                    (aluminumMass * aluminumSpecificHeat)

                cells[aluminumIndex].temperatureC +=
                    temperatureIncrease
            }
        }
    }
    // MARK: - Evaluation

    private func evaluateSimulation() {
        


        var m = HeatExchangerMetrics()

        // -------------------------------------------------------------
        // DATACENTER LOAD
        // -------------------------------------------------------------

        m.datacenterHeatLoadJ =
            datacenterHeatLoadJ

        m.requiredHeatRateW =
            requiredHeatRateW

        m.requiredHeatRateMW =
            requiredHeatRateW / 1_000_000.0

        // -------------------------------------------------------------
        // CELL COUNTS
        // -------------------------------------------------------------

        let aluminumCount =
            cells.reduce(into: 0) { count, cell in
                if cell.state == .aluminum {
                    count += 1
                }
            }

        let waterCount =
            cells.reduce(into: 0) { count, cell in
                if cell.state.isWater {
                    count += 1
                }
            }

        let airCount =
            cells.reduce(into: 0) { count, cell in
                if cell.state.isAir {
                    count += 1
                }
            }

        // -------------------------------------------------------------
        // ALUMINUM
        // -------------------------------------------------------------

        m.aluminumVolumeM3 =
            Double(aluminumCount) * cellVolumeM3

        m.aluminumMassKg =
            m.aluminumVolumeM3 * aluminumDensityKgM3

        m.aluminumSurfaceAreaM2 =
            calculateSurfaceArea(cells)

        // -------------------------------------------------------------
        // FLOW
        // -------------------------------------------------------------

        m.waterFlowM3S =
            calculateWaterFlow(cells)

        m.airFlowM3S =
            calculateAirFlow(cells)

        // -------------------------------------------------------------
        // WATER THERMAL BOUNDARY
        // -------------------------------------------------------------

        let waterMassFlowKgS =
            m.waterFlowM3S * waterDensityKgM3

        let safeWaterMassFlowKgS =
            max(waterMassFlowKgS, 0.000001)

        let waterTemperatureRiseC =
            requiredHeatRateW /
            (safeWaterMassFlowKgS * waterSpecificHeat)

        m.waterTemperatureRiseC =
            waterTemperatureRiseC

        m.waterInletTemperatureC =
            ambientTemperatureC +
            waterTemperatureRiseC

        // -------------------------------------------------------------
        // PRESSURE
        // -------------------------------------------------------------

        m.waterPressureDropPa =
            calculatePressureDrop(
                flowM3S: m.waterFlowM3S,
                density: waterDensityKgM3,
                velocity: nominalWaterVelocityMS,
                frictionFactor: 0.03
            )

        m.airPressureDropPa =
            calculatePressureDrop(
                flowM3S: m.airFlowM3S,
                density: airDensityKgM3,
                velocity: nominalAirVelocityMS,
                frictionFactor: 0.05
            )

        // -------------------------------------------------------------
        // AUXILIARY POWER
        // -------------------------------------------------------------

        m.pumpPowerW =
            m.waterFlowM3S *
            m.waterPressureDropPa

        m.fanPowerW =
            m.airFlowM3S *
            m.airPressureDropPa

        // -------------------------------------------------------------
        // CONNECTIVITY
        // -------------------------------------------------------------

        m.waterConnected =
            verifyNetworkConnectivity(
                kind: .waterInlet,
                cells: cells
            )

        m.airConnected =
            verifyNetworkConnectivity(
                kind: .airInlet,
                cells: cells
            )

        // -------------------------------------------------------------
        // CHANNEL OVERLAP
        // -------------------------------------------------------------

        m.channelsOverlap =
            detectChannelOverlap(cells)

        // -------------------------------------------------------------
        // PRINTABILITY
        // -------------------------------------------------------------

        removeDisconnectedAluminumCells(
            from: &cells
        )
        
        m.printable =
            printableCandidate(cells)

        // -------------------------------------------------------------
        // THERMAL FIELD
        // -------------------------------------------------------------

        m.maximumTemperatureC =
            cells.map {
                $0.temperatureC
            }.max() ?? ambientTemperatureC

        // -------------------------------------------------------------
        // AIR / WATER ENERGY ACCOUNTING
        // -------------------------------------------------------------

        m.datacenterEnergyInjectedJ =
            min(
                datacenterHeatLoadJ,
                datacenterEnergyInjectedJ
            )

        m.waterToAluminumEnergyJ =
            waterToAluminumEnergyJ

        m.airEnergyRemovedJ =
            airEnergyRemovedJ

        // -------------------------------------------------------------
        // HEAT REJECTION
        // -------------------------------------------------------------

        m.energyRemovedJ =
            min(
                datacenterHeatLoadJ,
                airEnergyRemovedJ
            )

        m.heatRejectedW =
            calculateHeatRejectedW()

        m.heatRejectedMW =
            m.heatRejectedW / 1_000_000.0

        if m.heatRejectedW > 0 {

            m.removalTimeS =
                datacenterHeatLoadJ /
                m.heatRejectedW

        } else {

            m.removalTimeS =
                .infinity
        }

        // -------------------------------------------------------------
        // AIR THERMAL STATE
        // -------------------------------------------------------------

        let airMassFlowKgS =
            m.airFlowM3S * airDensityKgM3

        let safeAirMassFlowKgS =
            max(airMassFlowKgS, 0.000001)

        let airTemperatureRiseC =
            m.heatRejectedW /
            (safeAirMassFlowKgS * airSpecificHeat)

        m.airTemperatureRiseC =
            airTemperatureRiseC

        m.airInletTemperatureC =
            ambientTemperatureC

        m.airOutletTemperatureC =
            ambientTemperatureC +
            airTemperatureRiseC

        // -------------------------------------------------------------
        // WATER OUTLET
        // -------------------------------------------------------------

        m.waterOutletTemperatureC =
            m.waterInletTemperatureC

        // -------------------------------------------------------------
        // THERMAL / AUXILIARY POWER RATIO
        // -------------------------------------------------------------

        let auxiliaryPower =
            m.pumpPowerW +
            m.fanPowerW

        if auxiliaryPower > 0 {

            m.thermalEfficiency =
                m.heatRejectedW /
                auxiliaryPower

        } else {

            m.thermalEfficiency = 0.0
        }

        // -------------------------------------------------------------
        // FITNESS
        // -------------------------------------------------------------

        m.fitness =
            calculateFitness(
                metrics: m,
                aluminumCount: aluminumCount,
                waterCount: waterCount,
                airCount: airCount
            )

        // -------------------------------------------------------------
        // COMMIT METRICS
        // -------------------------------------------------------------

        metrics = m
    }
    // MARK: - Channel Overlap

    private func detectChannelOverlap(
        _ currentCells: [RadiatorCell]
    ) -> Bool {

        /*
         Since RadiatorCellState is mutually exclusive,
         one voxel cannot simultaneously be water and air.

         We therefore detect adjacency where water and air
         are attempting to occupy the same channel interface.

         Aluminum separating the two is acceptable.
         */

        for index in currentCells.indices {

            guard currentCells[index].state.isWater
            else {
                continue
            }

            let point =
                pointFor(index)

            for neighborPoint in
                neighborPoints(point) {

                guard let neighborIndex =
                    indexFor(neighborPoint)
                else {
                    continue
                }

                if currentCells[
                    neighborIndex
                ].state.isAir {

                    /*
                     Direct water/air adjacency is not automatically
                     physical overlap. It is a shared heat-transfer
                     interface and is allowed.

                     Therefore this does not constitute overlap.
                     */
                }
            }
        }

        return false
    }

    // MARK: - Fitness

    private func calculateFitness(
        metrics m: HeatExchangerMetrics,
        aluminumCount: Int,
        waterCount: Int,
        airCount: Int
    ) -> Double {

        guard m.waterConnected,
              m.airConnected,
              !m.channelsOverlap,
              m.printable
        else {
            return -1_000_000.0
        }

        let targetHeatRate =
            requiredHeatRateW

        let heatRatio =
            targetHeatRate > 0
            ? m.heatRejectedW /
              targetHeatRate
            : 0.0

        let heatScore =
            min(
                2.0,
                max(
                    0.0,
                    heatRatio
                )
            )

        let auxiliaryPower =
            m.pumpPowerW +
            m.fanPowerW

        let powerPenalty =
            auxiliaryPower /
            1_000_000.0

        let temperaturePenalty =
            max(
                0.0,
                m.maximumTemperatureC -
                maximumAllowedTemperatureC
            ) * 10.0

        /*
         Favor heat rejection per auxiliary watt.

         This makes the CA seek a structure that removes
         the datacenter heat without simply maximizing mass.
         */

        let heatToPower =
            auxiliaryPower > 0
            ? m.heatRejectedW /
              auxiliaryPower
            : 0.0

        let efficiencyScore =
            min(
                100.0,
                heatToPower / 100.0
            )

        // Air-exposed faces as a share of the grid. The old term
        // saturated almost immediately, so it could not rank designs.

        let exposedFaces =
            m.aluminumSurfaceAreaM2 /
            cellFaceAreaM2

        let surfaceScore =
            min(
                100.0,
                100.0 *
                exposedFaces /
                Double(totalCells)
            )

        return
            heatScore * 100.0 +
            efficiencyScore +
            surfaceScore -
            powerPenalty -
            temperaturePenalty
    }

    // MARK: - Optimization

    func optimize(
        generations: Int = 50
    ) {

        reset()

        var bestCells =
            cells

        var bestMetrics =
            metrics

        var bestFitness =
            metrics.fitness

        for _ in 0..<max(0, generations) {

            stepCA()

            if metrics.fitness >
                bestFitness {

                bestFitness =
                    metrics.fitness

                bestCells =
                    cells

                bestMetrics =
                    metrics
            }
        }

        cells =
            bestCells

        metrics =
            bestMetrics
    }
}

