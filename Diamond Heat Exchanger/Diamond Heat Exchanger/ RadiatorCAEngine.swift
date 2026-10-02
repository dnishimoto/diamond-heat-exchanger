//
//  File2.swift
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
    
    @Published private(set) var datacenterEnergyInjectedJ: Double = 0
    @Published private(set) var waterToAluminumEnergyJ: Double = 0
    @Published private(set) var airEnergyRemovedJ: Double = 0
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

    private let datacenterHeatLoadJ = 1_000_000_000.0

    private let targetRemovalTimeS = 60.0

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
     Reduced-order thermal timestep.

     This is a CA thermal timestep rather than a CFD timestep.
     */

    private let thermalTimeStepS = 0.02

    /*
     Water/aluminum and aluminum/air interface coefficients.

     These are effective reduced-order coefficients used by the CA.
     */

    private let waterHeatTransferCoefficient = 3500.0

    private let airHeatTransferCoefficient = 75.0

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

    // MARK: - Indexing

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

        generation = 0
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

        // No platform-connected aluminum exists.
        guard !platformCells.isEmpty else {
            print("STRUCTURE: No aluminum touches z=0 platform")
            return 0
        }

        // MARK: 2. Flood-fill through FACE-CONNECTED aluminum only

        var connected = Set<GridPoint>()
        var queue: [GridPoint] = platformCells
        var queueIndex = 0

        for point in platformCells {
            connected.insert(point)
        }

        while queueIndex < queue.count {

            let current = queue[queueIndex]
            queueIndex += 1

            for neighbor in neighborPoints(current) {

                guard isValid(neighbor) else {
                    continue
                }

                guard !connected.contains(neighbor) else {
                    continue
                }

                guard let neighborIndex = indexFor(neighbor) else {
                    continue
                }

                guard lattice[neighborIndex].state == .aluminum else {
                    continue
                }

                connected.insert(neighbor)
                queue.append(neighbor)
            }
        }

        // MARK: 3. Remove disconnected aluminum

        var aluminumCount = 0
        var removedCount = 0

        for index in lattice.indices {

            guard lattice[index].state == .aluminum else {
                continue
            }

            aluminumCount += 1

            let point = pointFor(index)

            guard !connected.contains(point) else {
                continue
            }

            lattice[index].state = .empty
            lattice[index].temperatureC = ambientTemperatureC
            lattice[index].heatJ = 0
            lattice[index].flow = 0
            lattice[index].pressurePa = 0

            removedCount += 1
        }

        print("""
        STRUCTURE CLEANUP:
          Platform aluminum: \(platformCells.count)
          Connected aluminum: \(connected.count)
          Aluminum before cleanup: \(aluminumCount)
          Disconnected removed: \(removedCount)
          Aluminum remaining: \(aluminumCount - removedCount)
        """)

        return removedCount
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

        let waterFlowM3S = calculateWaterFlow(cells)
        
        let massFlowKgS =
            max(
                waterFlowM3S * waterDensityKgM3,
                0.000001
            )

        let temperatureRiseC =
            requiredHeatRateW /
            (
                massFlowKgS *
                waterSpecificHeat
            )

        let inletTemperatureC =
            ambientTemperatureC +
            temperatureRiseC

        for port in waterPorts
        where port.kind == .waterInlet {

            guard let index = indexFor(port.point)
            else {
                continue
            }

            cells[index].temperatureC =
                inletTemperatureC
        }
        
        print(
            "Water inlet:",
            inletTemperatureC,
            "°C | flow:",
            waterFlowM3S,
            "m³/s"
        )
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

    // MARK: - Thermal CA

    private func advanceThermalField() {

        let previousCells = cells
        var nextCells = previousCells

        thermalSimulationTimeS += thermalTimeStepS

        // -------------------------------------------------------------
        // 1. DATACENTER → WATER
        // -------------------------------------------------------------

        applyWaterInletTemperature(
            to: &nextCells
        )

        // -------------------------------------------------------------
        // 2. WATER → ALUMINUM
        // -------------------------------------------------------------

        for index in previousCells.indices {

            let current = previousCells[index]

            guard current.state == .water ||
                  current.state == .waterInlet ||
                  current.state == .waterOutlet
            else {
                continue
            }

            let point = pointFor(index)

            let waterTemperature =
                current.temperatureC

            for neighborPoint in neighborPoints(point) {

                guard let neighborIndex =
                    indexFor(neighborPoint)
                else {
                    continue
                }

                let neighbor =
                    previousCells[neighborIndex]

                guard neighbor.state == .aluminum
                else {
                    continue
                }

                let deltaT =
                    waterTemperature -
                    neighbor.temperatureC

                guard deltaT > 0
                else {
                    continue
                }

                let interfaceArea =
                    cellFaceAreaM2

                let idealTransfer =
                    waterHeatTransferCoefficient *
                    interfaceArea *
                    deltaT *
                    thermalTimeStepS

                let waterMass =
                    waterDensityKgM3 *
                    cellVolumeM3

                let availableWaterEnergy =
                    max(
                        0.0,
                        waterMass *
                        waterSpecificHeat *
                        max(
                            waterTemperature -
                            ambientTemperatureC,
                            0.0
                        )
                    )

                let transferred =
                    min(
                        idealTransfer,
                        availableWaterEnergy
                    )

                guard transferred > 0
                else {
                    continue
                }

                let waterDeltaT =
                    transferred /
                    max(
                        waterMass *
                        waterSpecificHeat,
                        1.0e-12
                    )

                let aluminumMass =
                    aluminumDensityKgM3 *
                    cellVolumeM3

                let aluminumDeltaT =
                    transferred /
                    max(
                        aluminumMass *
                        aluminumSpecificHeat,
                        1.0e-12
                    )

                nextCells[index].temperatureC =
                    max(
                        ambientTemperatureC,
                        nextCells[index].temperatureC -
                        min(
                            waterDeltaT,
                            maximumTemperatureChangePerStepC
                        )
                    )

                nextCells[neighborIndex].temperatureC +=
                    min(
                        aluminumDeltaT,
                        maximumTemperatureChangePerStepC
                    )

                nextCells[index].heatJ =
                    max(
                        0.0,
                        nextCells[index].heatJ -
                        transferred
                    )

                nextCells[neighborIndex].heatJ +=
                    transferred

                // -----------------------------------------------------
                // CUMULATIVE ENERGY ACCOUNTING
                // -----------------------------------------------------

                waterToAluminumEnergyJ += transferred
            }
        }

        // -------------------------------------------------------------
        // 3. ALUMINUM ↔ ALUMINUM CONDUCTION
        // -------------------------------------------------------------

        for index in previousCells.indices {

            guard previousCells[index].state == .aluminum
            else {
                continue
            }

            let point = pointFor(index)

            for neighborPoint in neighborPoints(point) {

                guard let neighborIndex =
                    indexFor(neighborPoint)
                else {
                    continue
                }

                // Process each aluminum pair once.
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

        for index in previousCells.indices {

            guard previousCells[index].state == .aluminum
            else {
                continue
            }

            let point = pointFor(index)

            let aluminumTemperature =
                previousCells[index].temperatureC

            for neighborPoint in neighborPoints(point) {

                guard let neighborIndex =
                    indexFor(neighborPoint)
                else {
                    continue
                }

                let neighbor =
                    previousCells[neighborIndex]

                guard neighbor.state.isAir
                else {
                    continue
                }

                let airTemperature =
                    neighbor.temperatureC

                let deltaT =
                    aluminumTemperature -
                    airTemperature

                guard deltaT > 0
                else {
                    continue
                }

                let interfaceArea =
                    cellFaceAreaM2

                let idealTransfer =
                    airHeatTransferCoefficient *
                    interfaceArea *
                    deltaT *
                    thermalTimeStepS

                let aluminumMass =
                    aluminumDensityKgM3 *
                    cellVolumeM3

                let availableAluminumEnergy =
                    max(
                        0.0,
                        aluminumMass *
                        aluminumSpecificHeat *
                        max(
                            aluminumTemperature -
                            ambientTemperatureC,
                            0.0
                        )
                    )

                let transferred =
                    min(
                        idealTransfer,
                        availableAluminumEnergy
                    )

                guard transferred > 0
                else {
                    continue
                }

                let aluminumDeltaT =
                    transferred /
                    max(
                        aluminumMass *
                        aluminumSpecificHeat,
                        1.0e-12
                    )

                let airMass =
                    airDensityKgM3 *
                    cellVolumeM3

                let airDeltaT =
                    transferred /
                    max(
                        airMass *
                        airSpecificHeat,
                        1.0e-12
                    )

                nextCells[index].temperatureC =
                    max(
                        ambientTemperatureC,
                        nextCells[index].temperatureC -
                        min(
                            aluminumDeltaT,
                            maximumTemperatureChangePerStepC
                        )
                    )

                nextCells[neighborIndex].temperatureC +=
                    min(
                        airDeltaT,
                        maximumTemperatureChangePerStepC
                    )

                nextCells[index].heatJ =
                    max(
                        0.0,
                        nextCells[index].heatJ -
                        transferred
                    )

                nextCells[neighborIndex].heatJ +=
                    transferred

                // -----------------------------------------------------
                // CUMULATIVE ENERGY ACCOUNTING
                // -----------------------------------------------------

                aluminumToAirEnergyJ += transferred
                airEnergyRemovedJ += transferred
            }
        }

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
        // 7. NUMERICAL TEMPERATURE LIMIT
        // -------------------------------------------------------------

        for index in nextCells.indices {

            nextCells[index].temperatureC =
                max(
                    ambientTemperatureC,
                    min(
                        250.0,
                        nextCells[index].temperatureC
                    )
                )
        }

        // -------------------------------------------------------------
        // 8. RESTORE THERMAL BOUNDARIES
        // -------------------------------------------------------------

        applyThermalBoundaryConditions(
            to: &nextCells
        )

        cells = nextCells
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

    // MARK: - CA Step

    private func stepCAInternal() {
        let previousGeneration = generation
        let previousCells = cells
        var candidateCells = previousCells
        let nextGeneration = previousGeneration + 1

        for index in previousCells.indices {
            let currentCell = previousCells[index]

            // Ports are fixed and are never modified by the CA.
            guard !currentCell.state.isPort else {
                continue
            }

            // Only aluminum and empty cells participate
            // in geometry evolution. Fluid channels remain intact.
            guard currentCell.state == .empty ||
                  currentCell.state == .aluminum
            else {
                continue
            }

            let point = pointFor(index)
            let neighbors = neighborPoints(point)

            var aluminumNeighbors = 0
            var waterNeighbors = 0
            var airNeighbors = 0

            for neighborPoint in neighbors {
                guard let neighborIndex = indexFor(neighborPoint)
                else {
                    continue
                }

                let neighbor = previousCells[neighborIndex]

                if neighbor.state == .aluminum {
                    aluminumNeighbors += 1
                }

                if neighbor.state.isWater {
                    waterNeighbors += 1
                }

                if neighbor.state.isAir {
                    airNeighbors += 1
                }
            }

            let fluidInterface =
                waterNeighbors > 0 ||
                airNeighbors > 0

            let structuralSupport =
                Double(aluminumNeighbors) / 6.0

            let diamondPhase =
                (
                    currentCell.x +
                    currentCell.y +
                    currentCell.z +
                    nextGeneration
                ) % 4

            let diamondCandidate =
                diamondPhase == 0 ||
                diamondPhase == 3

            // Grow aluminum where the CA pattern,
            // structural support, and fluid interface agree.
            if currentCell.state == .empty &&
                diamondCandidate &&
                structuralSupport >= 0.20 &&
                fluidInterface {

                candidateCells[index].state = .aluminum

            } else if currentCell.state == .aluminum {

                let isolated =
                    aluminumNeighbors == 0

                let buried =
                    waterNeighbors == 0 &&
                    airNeighbors == 0 &&
                    aluminumNeighbors >= 5

                if isolated || buried {
                    candidateCells[index].state = .empty
                }
            }
        }

        // Ports remain explicitly defined.
        applyPortStates(
            to: &candidateCells
        )
        
        removeDisconnectedAluminumCells(
            from: &candidateCells
        )


        // Structural validation is ONLY aluminum-to-platform
        // connectivity. Air, water, channels, and voids are ignored.
        guard printableCandidate(candidateCells)
        else {
            return
        }

        // Fluid-network validation remains separate from
        // printable aluminum connectivity.
        guard verifyNetworkConnectivity(
            kind: .waterInlet,
            cells: candidateCells
        ) else {
            return
        }

        guard verifyNetworkConnectivity(
            kind: .airOutlet,
            cells: candidateCells
        ) else {
            return
        }

        cells = candidateCells
        generation = nextGeneration

        for index in cells.indices {
            cells[index].generation = generation
        }

        advanceThermalField()
        evaluateSimulation()
    }

    // MARK: - Public CA Step

    func stepCA() {

        stepCAInternal()
    }

    // MARK: - Candidate Validation

   

    // MARK: - Network Connectivity

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

        for inlet in inlets {

            guard let inletIndex = indexFor(inlet.point)
            else {
                return false
            }

            var visited = Set<Int>()

            var queue: [Int] = [
                inletIndex
            ]

            visited.insert(inletIndex)

            while !queue.isEmpty {

                let currentIndex = queue.removeFirst()

                let point = pointFor(currentIndex)

                for neighborPoint in neighborPoints(point) {

                    guard let neighborIndex =
                        indexFor(neighborPoint)
                    else {
                        continue
                    }

                    guard !visited.contains(neighborIndex)
                    else {
                        continue
                    }

                    guard isFluid(
                        candidateCells[neighborIndex].state
                    )
                    else {
                        continue
                    }

                    visited.insert(neighborIndex)

                    queue.append(neighborIndex)
                }
            }

            for outlet in outlets {

                guard let outletIndex =
                    indexFor(outlet.point)
                else {
                    return false
                }

                if !visited.contains(outletIndex) {
                    return false
                }
            }
        }

        return true
    }


    private func printableCandidate(
        _ candidate: [RadiatorCell]
    ) -> Bool {

        // Find every aluminum cell touching the build platform.
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

        // The candidate must actually touch the build platform.
        guard !platformAluminum.isEmpty else {
            return false
        }

        // Flood fill uses GridPoint directly.
        var visited = Set<GridPoint>()
        var queue = platformAluminum

        for point in platformAluminum {
            visited.insert(point)
        }

        var queueIndex = 0

        while queueIndex < queue.count {
            let point = queue[queueIndex]
            queueIndex += 1

            for neighbor in neighborPoints(point) {

                // Only aluminum participates in structural
                // connectivity.
                guard let neighborIndex = indexFor(neighbor),
                      candidate[neighborIndex].state == .aluminum
                else {
                    continue
                }

                if visited.insert(neighbor).inserted {
                    queue.append(neighbor)
                }
            }
        }

        // Count every aluminum cell in the candidate.
        let aluminumCount =
            candidate.reduce(into: 0) { count, cell in
                if cell.state == .aluminum {
                    count += 1
                }
            }

        // Every aluminum cell must connect back to z == 0.
        return visited.count == aluminumCount
    }

    // MARK: - Surface Area

    private func calculateSurfaceArea(
        _ currentCells: [RadiatorCell]
    ) -> Double {

        var area = 0.0

        for index in currentCells.indices {

            guard currentCells[index].state ==
                    .aluminum
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

                let neighbor =
                    currentCells[neighborIndex]

                if neighbor.state.isWater ||
                   neighbor.state.isAir {

                    area += cellFaceAreaM2
                }
            }
        }

        return area
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

        let airCells =
            currentCells.reduce(
                into: 0
            ) { count, cell in

                if cell.state.isAir {
                    count += 1
                }
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

        let surfaceScore =
            min(
                50.0,
                m.aluminumSurfaceAreaM2 *
                10_000.0
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
