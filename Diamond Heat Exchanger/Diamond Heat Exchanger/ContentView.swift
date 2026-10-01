/*
 For a 1 GJ thermal load, the project can be structured as a cellular-automaton-designed 3D aluminum diamond radiator, where the cellular automaton recursively modifies the lattice geometry to maximize heat rejection while minimizing the energy required to move coolant and air through the structure. The key distinction is that 1 GJ represents the total thermal energy that must be removed, while the CA determines the geometry, material distribution, airflow paths, coolant paths, and operating conditions needed to remove that energy at a specified rate.

 The simulation should begin by defining the thermal requirement, target heat-removal time, ambient temperature, coolant temperature, aluminum properties, allowable maximum temperature, allowable pressure drop, and available pumping and fan power. If the target is to remove 1 GJ in 60 seconds, the required thermal power is approximately 16.67 MW, because the required heat-transfer rate is the total energy divided by the available time. The CA therefore does not simply attempt to create a large amount of aluminum surface area. It searches for a geometry capable of transferring at least the required thermal power while keeping temperature, pressure drop, structural density, coolant flow, airflow, and mechanical power within their constraints.

 The initial geometry can be a uniform three-dimensional diamond lattice. The aluminum occupies the diamond struts while interconnected voids form the passages through which water or another coolant and air can flow. Each CA cell represents a local region of the radiator and contains properties such as temperature, heat flux, aluminum density, porosity, diamond-cell size, strut thickness, air velocity, coolant velocity, pressure, pressure gradient, local surface area, and local heat-transfer rate. These properties allow the CA to determine where the lattice is carrying large thermal loads and where material or open space is being used inefficiently.

 The thermal simulation begins by transferring heat from the hot coolant into the aluminum lattice. The aluminum then conducts that energy through the interconnected diamond structure toward its exposed surfaces. Air moving through the lattice removes heat from those surfaces through convection. The simulation therefore follows the complete path of the thermal energy from the coolant, through the aluminum, into the air, and finally out of the radiator. The objective is to make this process spatially resolved so that the CA can identify hot regions, poorly cooled regions, excessive material concentrations, restricted airflow channels, and areas where additional surface area produces little useful heat transfer.

 The airflow model is equally important because increasing surface area does not automatically improve the radiator. A very dense diamond lattice can provide enormous aluminum surface area while simultaneously creating a large pressure drop. The fans would then require substantially more electrical power to force air through the structure. Conversely, an extremely open lattice can have excellent airflow but insufficient aluminum surface area to transfer the required amount of heat. The CA therefore needs to find a balance between thermal transfer and flow resistance rather than simply maximizing either quantity independently.

 The recursive optimization can evaluate every generation of the lattice by calculating local heat flux, temperature, air velocity, coolant velocity, pressure, pressure gradient, total heat rejection, and pumping or fan requirements. Cells that experience high heat flux can be modified toward greater material density or increased surface area, while regions dominated by airflow resistance can become more open. The CA can modify diamond-cell dimensions, strut thickness, local porosity, orientation, and material density. This allows the final radiator to become heterogeneous rather than remaining a uniform repeating structure.

 The optimization objective can be expressed conceptually as maximizing the amount of heat rejected for the amount of fan and pumping power required. However, the CA must also enforce minimum performance requirements. A geometry should not receive a better score merely because it transfers less heat while consuming less power. The radiator must first satisfy the required heat-rejection rate, maximum temperature, allowable pressure drop, and other engineering constraints. Only among geometries satisfying those requirements should the CA favor lower airflow and coolant-pumping power.

 The resulting structure could therefore develop regions with different lattice densities. Areas receiving intense thermal loading could evolve toward a denser diamond structure with greater aluminum surface area, while downstream or low-flux regions could become more open to reduce airflow resistance. The CA could also produce preferential flow channels through the radiator, effectively creating an integrated network in which the aluminum structure simultaneously functions as a heat conductor and as a geometric guide for coolant and air.

 The energy accounting must remain explicit throughout the simulation. The system begins with 1,000,000,000 joules of thermal energy. If the target removal time is 60 seconds, the required average heat-rejection rate is 16.67 MW. The simulation should then continuously track the energy transferred from the coolant into the aluminum, the energy conducted through the lattice, the energy transferred from the aluminum into the air, and the electrical energy consumed by the pumps and fans. This makes it possible to distinguish thermal energy removed from the radiator from the auxiliary energy consumed by the cooling system.

 The final CA result should therefore describe an actual engineered radiator rather than simply displaying a lattice. The simulation should report the optimized radiator volume, aluminum mass, aluminum surface area, coolant flow rate, air flow rate, pressure drop, pump power, fan power, total heat-rejection rate, maximum temperature, and time required to remove the complete 1 GJ thermal load. These values provide the connection between the cellular-automaton geometry and the physical cooling system.

 The fundamental measurement is the simulated heat-rejection rate. Once the optimized radiator is operating at a steady average rate, the time required to remove the complete thermal load is the total thermal energy divided by the actual heat-rejection rate. For example, a radiator rejecting 20 MW continuously would require approximately 50 seconds to remove 1 GJ. A radiator rejecting 10 MW would require approximately 100 seconds. Thus, the CA does not need to assume that the radiator removes 1 GJ in a particular amount of time; instead, the simulated heat-transfer rate determines the resulting removal time.

 The complete project therefore becomes a continuous CA-to-physics optimization loop in which the cellular automaton generates a three-dimensional aluminum diamond architecture, the thermal solver determines conduction and heat transfer, the airflow solver determines velocity and pressure drop, the pump and fan models determine energy consumption, and the resulting performance feeds back into the CA. Each generation modifies the geometry based on the previous generation's thermal and fluid behavior. Over successive generations, the structure is driven toward a configuration that can remove the required thermal energy while using the available aluminum and airflow as efficiently as possible.

 The 3D-print deposition and internal water and air channel architecture should be treated as a **core part of the simulation**, rather than as an optional visualization layer. The cellular automaton should be responsible for designing the aluminum structure while simultaneously creating and protecting the internal fluid networks. The complete system should therefore follow the sequence of CA deposition rules, water and air channel topology, printable aluminum lattice generation, thermal transfer, fluid-flow simulation, energy consumption, and recursive CA optimization.

 The cellular automaton should design the radiator and its internal plumbing simultaneously. A geometry that provides excellent heat transfer but blocks a water channel or air passage must be rejected by the CA. Likewise, a geometry that provides excellent fluid flow but does not provide sufficient aluminum surface area for heat transfer should also be rejected. The CA therefore needs to balance thermal performance, water distribution, air distribution, structural material, manufacturability, pressure drop, and pumping or fan energy as part of a single evolving system.

 Every required water inlet must remain connected to an appropriate water outlet throughout the simulation. Every required air inlet must remain connected to an appropriate air outlet. Water and air regions must remain physically separated, and neither type of flow channel can be filled by aluminum deposition. The CA must maintain minimum water and air channel dimensions, minimum printable aluminum thickness, and the geometric constraints required for the proposed 3D-printing process. These connectivity and manufacturing constraints should be treated as hard constraints rather than optional optimization preferences.

 The multiple water and air ports should therefore be represented as actual components of the three-dimensional CA domain. The simulation should allow multiple water inlets and outlets and multiple air inlets and outlets. The CA can then develop internal manifolds and branching networks that distribute the water and air throughout the radiator. Instead of forcing every channel to remain an independent straight passage, the CA can discover where channels should merge, divide, expand, or contract while maintaining connectivity between the required ports.

 The individual CA cells should have explicit physical states representing empty space, aluminum, water channel, air channel, water inlet, water outlet, air inlet, and air outlet. An empty cell can potentially become aluminum, water, or air depending on the local rules and the global connectivity requirements. An aluminum cell can only be deposited when doing so does not disconnect a required water or air pathway, violate minimum channel dimensions, violate minimum printable thickness, or create an unacceptable manufacturing condition. This makes the deposition process fundamentally different from simply modifying the porosity of an already-existing diamond lattice.

 The CA should continuously evaluate whether a proposed aluminum deposition preserves the required water and air networks. Before accepting a deposition change, the simulation should verify that every required water inlet remains connected to the water network and that every required water outlet remains reachable. It should perform the same connectivity verification for the air network. If a proposed aluminum deposition disconnects a port, closes a channel, or reduces a channel below its minimum allowable size, the CA should reject that change or modify neighboring cells to preserve the flow path.

 The thermal model should operate directly on the resulting geometry. Heat enters the aluminum from the water system, conducts through the aluminum lattice, and is transferred from the aluminum surfaces into the air. The CA should therefore identify regions where thermal loading is high and determine whether additional aluminum surface area or different lattice geometry would improve heat transfer. At the same time, it must determine whether the additional material restricts water or air flow enough to increase pressure drop and pumping power beyond acceptable limits.

 The airflow and water-flow simulations should therefore be connected directly to the deposition model. As the CA adds or removes aluminum, the available flow volume changes, the hydraulic and aerodynamic paths change, velocity distributions change, pressure gradients change, and the required pump and fan power change. These changes then affect the CA fitness value. A geometry that increases heat transfer but causes an excessive pressure drop may be rejected, while a geometry that reduces pressure drop but removes too much heat-transfer surface may also be rejected.

 The CA fitness function should consequently combine the major requirements of the radiator. The system must achieve the required heat-rejection rate, maintain acceptable maximum temperatures, preserve every required water and air connection, maintain printable geometry, and remain within acceptable pressure-drop limits. Among geometries that satisfy those requirements, the CA can favor higher heat rejection and lower pump and fan power. This creates a true multi-objective engineering optimization rather than a simple visual lattice-generation algorithm.

 The final output of the cellular automaton should be a complete **three-dimensional deposition field**. Every voxel should indicate whether the 3D printer deposits aluminum at that location or leaves the location open for water or air. The resulting geometry should contain the aluminum lattice, water channels, air channels, internal manifolds, water ports, air ports, and the external surfaces required for the physical radiator. The SceneKit visualization can then display the aluminum structure together with the water and air volumes moving through their respective networks.

 The simulation should also retain the layer-by-layer deposition concept. The CA should generate the radiator as a three-dimensional structure that can be interpreted as successive printing layers. Each layer must respect the minimum printable feature size, material continuity, channel openings, and support constraints established for the selected manufacturing process. This makes the final CA state useful not merely as a simulation image but as a geometric representation that can eventually be converted into an actual manufacturing model.

 The complete optimization loop should therefore begin with the three-dimensional voxel domain, establish the water and air ports, generate initial connected flow networks, generate an initial aluminum structure, apply the deposition rules, simulate heat transfer, simulate water flow, simulate air flow, calculate pressure drop and pump and fan power, determine heat rejection and 1 GJ removal time, calculate the CA fitness, modify the deposition pattern, verify all water and air connections, and then repeat the process for the next generation.

 The central principle is that **the cellular automaton creates the radiator rather than merely optimizing a radiator that already exists**. The water channels, air channels, multiple ports, manifolds, aluminum lattice, thermal-transfer surfaces, and printable deposition pattern should all emerge from the same three-dimensional CA. The final optimized structure should therefore represent a complete engineered architecture in which the CA has simultaneously solved the questions of **where aluminum should be printed, where water should flow, where air should flow, how the ports should connect, how heat should move through the aluminum, and how much energy the pumps and fans must consume to remove the 1 GJ thermal load**.

 */

//
//  ContentView.swift
//  CA Diamond Aluminum Radiator
//
//  3D cellular-automaton radiator designer.
//
//  Core model:
//  1. CA creates the printable aluminum deposition pattern.
//  2. Water and air channels are protected flow networks.
//  3. Multiple water/air inlet and outlet ports are explicit cells.
//  4. Aluminum deposition is rejected when it disconnects required flow.
//  5. Thermal transfer is calculated on the resulting geometry.
//  6. Water/air flow and pressure are estimated from the CA geometry.
//  7. CA recursively evolves the geometry toward better heat rejection
//     with lower auxiliary pumping/fan power.
//



import SwiftUI
import SceneKit
import Combine
import Foundation

// MARK: - Grid

struct GridPoint: Hashable {
    let x: Int
    let y: Int
    let z: Int
}

// MARK: - Cell State

enum RadiatorCellState: String, Codable {
    case empty
    case aluminum

    case water
    case waterInlet
    case waterOutlet

    case air
    case airInlet
    case airOutlet

    var isWater: Bool {
        switch self {
        case .water, .waterInlet, .waterOutlet:
            return true
        default:
            return false
        }
    }

    var isAir: Bool {
        switch self {
        case .air, .airInlet, .airOutlet:
            return true
        default:
            return false
        }
    }

    var isPort: Bool {
        switch self {
        case .waterInlet,
             .waterOutlet,
             .airInlet,
             .airOutlet:
            return true
        default:
            return false
        }
    }

    var isFlow: Bool {
        isWater || isAir
    }
}

// MARK: - Cell

struct RadiatorCell: Identifiable {
    let id: Int

    let x: Int
    let y: Int
    let z: Int

    var state: RadiatorCellState

    var temperatureC: Double = 20.0
    var heatJ: Double = 0.0

    var flow: Double = 0.0
    var pressure: Double = 0.0

    var generation: Int = 0
}

// MARK: - Ports

enum FlowPortKind {
    case waterInlet
    case waterOutlet
    case airInlet
    case airOutlet
}

struct FlowPort {
    let point: GridPoint
    let kind: FlowPortKind
}

// MARK: - Simulation Metrics

struct HeatExchangerMetrics {
    var aluminumVolumeM3: Double = 0.0
    var aluminumMassKg: Double = 0.0

    var aluminumSurfaceAreaM2: Double = 0.0

    var waterFlowM3S: Double = 0.0
    var airFlowM3S: Double = 0.0

    var waterPressureDropPa: Double = 0.0
    var airPressureDropPa: Double = 0.0

    var pumpPowerW: Double = 0.0
    var fanPowerW: Double = 0.0

    var heatRejectedW: Double = 0.0
    var heatRejectedMW: Double = 0.0

    var energyRemovedJ: Double = 0.0
    var removalTimeS: Double = 0.0

    var thermalEfficiency: Double = 0.0

    var maximumTemperatureC: Double = 20.0

    var waterConnected: Bool = false
    var airConnected: Bool = false
    var channelsOverlap: Bool = false
    var printable: Bool = false

    var fitness: Double = 0.0
}

// MARK: - Engine

@MainActor
final class RadiatorCAEngine: ObservableObject {

    // MARK: Published State

    @Published private(set) var cells: [RadiatorCell] = []

    @Published private(set) var generation: Int = 0

    @Published private(set) var metrics = HeatExchangerMetrics()

    @Published private(set) var isRunning = false

    // MARK: Grid

    let gridSize = 21

    private var totalCells: Int {
        gridSize * gridSize * gridSize
    }

    // MARK: Physical Constants

    private let cellSizeM = 0.002

    private let aluminumDensityKgM3 = 2700.0

    private let aluminumThermalConductivity = 237.0

    private let waterDensityKgM3 = 998.0

    private let airDensityKgM3 = 1.225

    private let waterSpecificHeat = 4186.0

    private let airSpecificHeat = 1005.0

    // 1 GJ target.

    private let targetEnergyJ = 1_000_000_000.0

    // Desired 60-second removal rate.

    private let targetRemovalTimeS = 60.0

    private var requiredHeatRateW: Double {
        targetEnergyJ / targetRemovalTimeS
    }

    // MARK: Flow Assumptions

    private let nominalWaterVelocityMS = 3.0

    private let nominalAirVelocityMS = 15.0

    private let waterInletTemperatureC = 25.0

    private let airInletTemperatureC = 25.0

    private let ambientTemperatureC = 25.0

    private let maximumAllowedTemperatureC = 120.0

    // MARK: Ports

    private(set) var waterPorts: [FlowPort] = []
    private(set) var airPorts: [FlowPort] = []

    // MARK: Thermal Load

    private var thermalLoadPerAluminumCellJ: Double {
        let aluminumCount = max(
            1,
            cells.reduce(into: 0) { result, currentCell in
                if currentCell.state == .aluminum {
                    result += 1
                }
            }
        )

        return targetEnergyJ / Double(aluminumCount)
    }

    // MARK: Initialization

    init() {
        buildInitialGeometry()
        evaluateSimulation()
    }

    // MARK: Indexing

    private func linearIndex(
        x: Int,
        y: Int,
        z: Int
    ) -> Int {
        x
        + y * gridSize
        + z * gridSize * gridSize
    }

    private func isValid(_ point: GridPoint) -> Bool {
        point.x >= 0 &&
        point.x < gridSize &&
        point.y >= 0 &&
        point.y < gridSize &&
        point.z >= 0 &&
        point.z < gridSize
    }

    // IMPORTANT:
    // This method deliberately uses a name that will not conflict
    // with local variables named currentCell.

    private func cell(
        at point: GridPoint
    ) -> RadiatorCell? {

        guard isValid(point) else {
            return nil
        }

        return cells[
            linearIndex(
                x: point.x,
                y: point.y,
                z: point.z
            )
        ]
    }

    // MARK: Neighbors

    private func neighborPoints(
        _ point: GridPoint
    ) -> [GridPoint] {

        let directions = [
            GridPoint(x: 1, y: 0, z: 0),
            GridPoint(x: -1, y: 0, z: 0),

            GridPoint(x: 0, y: 1, z: 0),
            GridPoint(x: 0, y: -1, z: 0),

            GridPoint(x: 0, y: 0, z: 1),
            GridPoint(x: 0, y: 0, z: -1)
        ]

        return directions.compactMap { direction in

            let next = GridPoint(
                x: point.x + direction.x,
                y: point.y + direction.y,
                z: point.z + direction.z
            )

            return isValid(next) ? next : nil
        }
    }

    // MARK: Initial Geometry

    private func buildInitialGeometry() {

        cells = []

        cells.reserveCapacity(totalCells)

        for z in 0..<gridSize {
            for y in 0..<gridSize {
                for x in 0..<gridSize {

                    let point = GridPoint(
                        x: x,
                        y: y,
                        z: z
                    )

                    let index = linearIndex(
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
                            temperatureC: ambientTemperatureC
                        )
                    )

                    _ = point
                }
            }
        }

        createPorts()

        // Start with the established diamond baseline.

        seedDiamondGeometry()

        // Protect all flow networks.

        carveFlowNetworks()

        // Restore port states after geometry construction.

        applyPortStates()

        generation = 0
    }

    // MARK: Diamond Baseline

    private func seedDiamondGeometry() {

        let center = Double(gridSize - 1) / 2.0

        for index in cells.indices {

            let currentCell = cells[index]

            let dx = Double(currentCell.x) - center
            let dy = Double(currentCell.y) - center
            let dz = Double(currentCell.z) - center

            let manhattan =
                abs(dx) +
                abs(dy) +
                abs(dz)

            let diagonal =
                abs(dx + dy + dz)

            // Diamond-shell relationship.

            let shellA =
                Int(abs(manhattan).rounded()) % 4

            let shellB =
                Int(abs(diagonal).rounded()) % 3

            let diamond =
                shellA == 0 ||
                shellB == 0

            // Keep an open external boundary.

            let boundary =
                currentCell.x == 0 ||
                currentCell.x == gridSize - 1 ||
                currentCell.y == 0 ||
                currentCell.y == gridSize - 1 ||
                currentCell.z == 0 ||
                currentCell.z == gridSize - 1

            if diamond && !boundary {
                cells[index].state = .aluminum
            }
        }

        // Add structural perimeter.

        for z in 1..<(gridSize - 1) {
            for y in 1..<(gridSize - 1) {

                let edge =
                    y == 1 ||
                    y == gridSize - 2

                if edge {

                    let point = GridPoint(
                        x: gridSize / 2,
                        y: y,
                        z: z
                    )

                    if let index = indexFor(point),
                       !cells[index].state.isFlow {

                        cells[index].state = .aluminum
                    }
                }
            }
        }
    }

    // MARK: Ports

    private func createPorts() {

        waterPorts.removeAll()
        airPorts.removeAll()

        let mid = gridSize / 2

        waterPorts = [

            FlowPort(
                point: GridPoint(
                    x: 0,
                    y: 5,
                    z: 5
                ),
                kind: .waterInlet
            ),

            FlowPort(
                point: GridPoint(
                    x: 0,
                    y: gridSize - 6,
                    z: gridSize - 6
                ),
                kind: .waterInlet
            ),

            FlowPort(
                point: GridPoint(
                    x: gridSize - 1,
                    y: 5,
                    z: gridSize - 6
                ),
                kind: .waterOutlet
            ),

            FlowPort(
                point: GridPoint(
                    x: gridSize - 1,
                    y: gridSize - 6,
                    z: 5
                ),
                kind: .waterOutlet
            )
        ]

        airPorts = [

            FlowPort(
                point: GridPoint(
                    x: 5,
                    y: 0,
                    z: 5
                ),
                kind: .airInlet
            ),

            FlowPort(
                point: GridPoint(
                    x: gridSize - 6,
                    y: 0,
                    z: gridSize - 6
                ),
                kind: .airInlet
            ),

            FlowPort(
                point: GridPoint(
                    x: 5,
                    y: gridSize - 1,
                    z: gridSize - 6
                ),
                kind: .airOutlet
            ),

            FlowPort(
                point: GridPoint(
                    x: gridSize - 6,
                    y: gridSize - 1,
                    z: 5
                ),
                kind: .airOutlet
            )
        ]

        _ = mid
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

    // MARK: Flow Network Construction

    private func carveFlowNetworks() {

        carveWaterNetwork()
        carveAirNetwork()

        // Remove any accidental overlap.

        removeFlowOverlap()
    }

    private func carveWaterNetwork() {

        let inlets = waterPorts.filter {
            $0.kind == .waterInlet
        }

        let outlets = waterPorts.filter {
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

        let inlets = airPorts.filter {
            $0.kind == .airInlet
        }

        let outlets = airPorts.filter {
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

    private func carveManifoldPath(
        from start: GridPoint,
        to target: GridPoint,
        state: RadiatorCellState
    ) {
        var point = start
        var safety = totalCells

        while point != target && safety > 0 {
            safety -= 1

            guard let index = indexFor(point) else {
                break
            }

            // Stop rather than overwrite another flow system.
            if state == .water && cells[index].state.isAir {
                break
            }

            if state == .air && cells[index].state.isWater {
                break
            }

            cells[index].state = state

            let dx = target.x - point.x
            let dy = target.y - point.y
            let dz = target.z - point.z

            let ax = abs(dx)
            let ay = abs(dy)
            let az = abs(dz)

            let next: GridPoint

            if ax >= ay && ax >= az {
                next = GridPoint(
                    x: point.x + (dx > 0 ? 1 : -1),
                    y: point.y,
                    z: point.z
                )

            } else if ay >= ax && ay >= az {
                next = GridPoint(
                    x: point.x,
                    y: point.y + (dy > 0 ? 1 : -1),
                    z: point.z
                )

            } else {
                next = GridPoint(
                    x: point.x,
                    y: point.y,
                    z: point.z + (dz > 0 ? 1 : -1)
                )
            }

            guard isValid(next) else {
                break
            }

            point = next
        }

        // The loop stops before writing the final target voxel.
        guard let targetIndex = indexFor(target) else {
            return
        }

        // Do not overwrite another fluid at the target.
        if state == .water && cells[targetIndex].state.isAir {
            return
        }

        if state == .air && cells[targetIndex].state.isWater {
            return
        }

        cells[targetIndex].state = state
    }
    // MARK: Remove Overlap

    private func removeFlowOverlap() {

        for index in cells.indices {

            let currentState = cells[index].state

            // A cell cannot physically be both fluids.

            if currentState == .water &&
                airPorts.contains(where: { $0.point == pointFor(index) }) {

                cells[index].state = .air
            }
        }
    }

    private func pointFor(
        _ index: Int
    ) -> GridPoint {

        let z = index / (gridSize * gridSize)

        let remainder =
            index - z * gridSize * gridSize

        let y = remainder / gridSize

        let x =
            remainder -
            y * gridSize

        return GridPoint(
            x: x,
            y: y,
            z: z
        )
    }

    // MARK: Ports

    private func applyPortStates() {

        for port in waterPorts {

            guard let index = indexFor(port.point) else {
                continue
            }

            switch port.kind {

            case .waterInlet:
                cells[index].state = .waterInlet

            case .waterOutlet:
                cells[index].state = .waterOutlet

            default:
                break
            }
        }

        for port in airPorts {

            guard let index = indexFor(port.point) else {
                continue
            }

            switch port.kind {

            case .airInlet:
                cells[index].state = .airInlet

            case .airOutlet:
                cells[index].state = .airOutlet

            default:
                break
            }
        }
    }

    // MARK: CA Evolution

    func evolve(
        generations: Int = 20
    ) {

        isRunning = true

        for _ in 0..<generations {

            evolveDeposition()

            generation += 1
        }

        applyPortStates()

        evaluateSimulation()

        isRunning = false
    }

    private func evolveDeposition() {

        let oldCells = cells

        var nextCells = oldCells

        for index in oldCells.indices {

            let currentCell = oldCells[index]

            guard currentCell.state == .empty else {
                continue
            }

            let point = GridPoint(
                x: currentCell.x,
                y: currentCell.y,
                z: currentCell.z
            )

            // Never fill protected fluid regions.

            let neighboringWater =
                neighborPoints(point)
                    .compactMap { point in
                        oldCells[indexFor(point)!]
                    }
                    .contains { neighbor in
                        neighbor.state.isWater
                    }

            let neighboringAir =
                neighborPoints(point)
                    .compactMap { point in
                        oldCells[indexFor(point)!]
                    }
                    .contains { neighbor in
                        neighbor.state.isAir
                    }

            let aluminumNeighbors =
                neighborPoints(point)
                    .compactMap { point in
                        self.cell(at: point)
                    }
                    .filter { neighbor in
                        neighbor.state == .aluminum
                    }
                    .count

            // A candidate must have structural support.

            let structuralSupport =
                Double(aluminumNeighbors) / 6.0

            // Diamond phase relationship.

            let diamondPhase =
                (
                    currentCell.x +
                    currentCell.y +
                    currentCell.z +
                    generation
                ) % 4

            let diamondCandidate =
                diamondPhase == 0 ||
                diamondPhase == 3

            // Preserve fluid surface area.

            let fluidInterface =
                neighboringWater ||
                neighboringAir

            // CA deposition rule.

            if diamondCandidate &&
                structuralSupport >= 0.20 &&
                fluidInterface {

                nextCells[index].state = .aluminum
                nextCells[index].generation = generation
            }
        }

        cells = nextCells

        // Re-open flow channels if deposition approached them.

        carveFlowNetworks()

        applyPortStates()
    }

    // MARK: Connectivity

    private func connected(
        stateSet: RadiatorCellState,
        from start: GridPoint,
        targets: Set<GridPoint>
    ) -> Bool {

        var queue: [GridPoint] = [start]
        var visited = Set<GridPoint>()

        while !queue.isEmpty {

            let current = queue.removeFirst()

            if visited.contains(current) {
                continue
            }

            visited.insert(current)

            if targets.contains(current) {
                return true
            }

            for point in neighborPoints(current) {

                guard let neighbor = self.cell(at: point) else {
                    continue
                }

                if neighbor.state == stateSet ||
                    neighbor.state.isWater &&
                    stateSet.isWater ||
                    neighbor.state.isAir &&
                    stateSet.isAir {

                    if !visited.contains(point) {
                        queue.append(point)
                    }
                }
            }
        }

        return false
    }

    private func waterConnectivity() -> Bool {

        let inlets = waterPorts.filter {
            $0.kind == .waterInlet
        }

        let outlets = Set(
            waterPorts
                .filter {
                    $0.kind == .waterOutlet
                }
                .map(\.point)
        )

        guard let first = inlets.first else {
            return false
        }

        return connected(
            stateSet: .water,
            from: first.point,
            targets: outlets
        )
    }

    private func airConnectivity() -> Bool {

        let inlets = airPorts.filter {
            $0.kind == .airInlet
        }

        let outlets = Set(
            airPorts
                .filter {
                    $0.kind == .airOutlet
                }
                .map(\.point)
        )

        guard let first = inlets.first else {
            return false
        }

        return connected(
            stateSet: .air,
            from: first.point,
            targets: outlets
        )
    }

    // MARK: Surface Area

    private func calculateSurfaceArea() -> Double {

        var exposedFaces = 0

        for currentCell in cells {

            guard currentCell.state == .aluminum else {
                continue
            }

            let point = GridPoint(
                x: currentCell.x,
                y: currentCell.y,
                z: currentCell.z
            )

            for neighborPoint in neighborPoints(point) {

                guard let neighbor = self.cell(at: neighborPoint) else {
                    continue
                }

                if neighbor.state.isFlow ||
                    neighbor.state == .empty {

                    exposedFaces += 1
                }
            }
        }

        return Double(exposedFaces) *
            cellSizeM *
            cellSizeM
    }

    // MARK: Flow

    private func calculateFlow() {

        let waterArea =
            Double(
                cells.filter {
                    $0.state.isWater
                }.count
            ) *
            cellSizeM *
            cellSizeM

        let airArea =
            Double(
                cells.filter {
                    $0.state.isAir
                }.count
            ) *
            cellSizeM *
            cellSizeM

        let waterFlow =
            waterArea *
            nominalWaterVelocityMS

        let airFlow =
            airArea *
            nominalAirVelocityMS

        let waterLength =
            Double(gridSize) *
            cellSizeM

        let airLength =
            Double(gridSize) *
            cellSizeM

        // Darcy-style simplified pressure estimates.

        let waterPressure =
            0.5 *
            waterDensityKgM3 *
            nominalWaterVelocityMS *
            nominalWaterVelocityMS *
            max(
                1.0,
                waterLength / cellSizeM
            ) *
            0.02

        let airPressure =
            0.5 *
            airDensityKgM3 *
            nominalAirVelocityMS *
            nominalAirVelocityMS *
            max(
                1.0,
                airLength / cellSizeM
            ) *
            0.04

        let waterPumpPower =
            waterFlow *
            waterPressure

        let airFanPower =
            airFlow *
            airPressure

        metrics.waterFlowM3S = waterFlow
        metrics.airFlowM3S = airFlow

        metrics.waterPressureDropPa =
            waterPressure

        metrics.airPressureDropPa =
            airPressure

        metrics.pumpPowerW =
            max(0.0, waterPumpPower)

        metrics.fanPowerW =
            max(0.0, airFanPower)
    }

    // MARK: Thermal Model

    private func calculateHeatRemoval() {

        let surfaceArea =
            metrics.aluminumSurfaceAreaM2

        guard surfaceArea > 0 else {
            metrics.heatRejectedW = 0.0
            metrics.heatRejectedMW = 0.0
            return
        }

        var totalHeatTransferW = 0.0

        for index in cells.indices {

            let currentCell = cells[index]

            guard currentCell.state == .aluminum else {
                continue
            }

            let point = GridPoint(
                x: currentCell.x,
                y: currentCell.y,
                z: currentCell.z
            )

            let waterNeighbors =
                neighborPoints(point)
                    .compactMap { point in
                        self.cell(at: point)
                    }
                    .filter { neighbor in
                        neighbor.state.isWater
                    }
                    .count

            let airNeighbors =
                neighborPoints(point)
                    .compactMap { point in
                        self.cell(at: point)
                    }
                    .filter { neighbor in
                        neighbor.state.isAir
                    }
                    .count

            let aluminumNeighbors =
                neighborPoints(point)
                    .compactMap { point in
                        self.cell(at: point)
                    }
                    .filter { neighbor in
                        neighbor.state == .aluminum
                    }
                    .count

            let localTemperature =
                currentCell.temperatureC

            let waterDeltaT =
                max(
                    0.0,
                    localTemperature -
                    waterInletTemperatureC
                )

            let airDeltaT =
                max(
                    0.0,
                    localTemperature -
                    airInletTemperatureC
                )

            let conductionFactor =
                Double(aluminumNeighbors) / 6.0

            let waterTransferCoefficient =
                3500.0

            let airTransferCoefficient =
                75.0

            let waterHeat =
                waterTransferCoefficient *
                Double(waterNeighbors) *
                cellSizeM *
                cellSizeM *
                waterDeltaT

            let airHeat =
                airTransferCoefficient *
                Double(airNeighbors) *
                cellSizeM *
                cellSizeM *
                airDeltaT

            let conductionHeat =
                aluminumThermalConductivity *
                cellSizeM *
                conductionFactor *
                max(
                    0.0,
                    localTemperature -
                    ambientTemperatureC
                )

            totalHeatTransferW +=
                waterHeat +
                airHeat +
                conductionHeat
        }

        // Do not allow the simplified model to report
        // physically nonsensical negative heat rejection.

        metrics.heatRejectedW =
            max(
                0.0,
                totalHeatTransferW
            )

        metrics.heatRejectedMW =
            metrics.heatRejectedW /
            1_000_000.0

        metrics.removalTimeS =
            targetEnergyJ /
            max(
                1.0,
                metrics.heatRejectedW
            )

        metrics.thermalEfficiency =
            metrics.heatRejectedW /
            max(
                1.0,
                metrics.heatRejectedW +
                metrics.pumpPowerW +
                metrics.fanPowerW
            )
    }

    // MARK: Temperature Field

    private func calculateTemperatureField() {

        let loadPerCell =
            thermalLoadPerAluminumCellJ

        for index in cells.indices {

            guard cells[index].state == .aluminum else {
                continue
            }

            let point = GridPoint(
                x: cells[index].x,
                y: cells[index].y,
                z: cells[index].z
            )

            let waterNeighbors =
                neighborPoints(point)
                    .compactMap { point in
                        self.cell(at: point)
                    }
                    .filter { neighbor in
                        neighbor.state.isWater
                    }
                    .count

            let airNeighbors =
                neighborPoints(point)
                    .compactMap { point in
                        self.cell(at: point)
                    }
                    .filter { neighbor in
                        neighbor.state.isAir
                    }
                    .count

            let cooling =
                Double(waterNeighbors) * 0.15 +
                Double(airNeighbors) * 0.05

            let baseRise =
                loadPerCell /
                1_000_000.0

            let temperature =
                ambientTemperatureC +
                baseRise /
                max(
                    0.1,
                    1.0 + cooling
                )

            cells[index].temperatureC =
                min(
                    maximumAllowedTemperatureC * 1.5,
                    temperature
                )

            cells[index].heatJ =
                loadPerCell
        }

        metrics.maximumTemperatureC =
            cells
                .filter {
                    $0.state == .aluminum
                }
                .map(\.temperatureC)
                .max() ?? ambientTemperatureC
    }

    // MARK: Volume

    private func calculateVolumeAndMass() {

        let aluminumCount =
            cells.filter {
                $0.state == .aluminum
            }.count

        let volume =
            Double(aluminumCount) *
            pow(cellSizeM, 3)

        metrics.aluminumVolumeM3 =
            volume

        metrics.aluminumMassKg =
            volume *
            aluminumDensityKgM3
    }

    // MARK: Fitness

    private func calculateFitness() {

        let heatRate =
            metrics.heatRejectedW

        let auxiliaryPower =
            metrics.pumpPowerW +
            metrics.fanPowerW

        let heatPerPower =
            heatRate /
            max(
                1.0,
                auxiliaryPower
            )

        let meetsHeatTarget =
            heatRate >= requiredHeatRateW

        let temperatureOK =
            metrics.maximumTemperatureC <=
            maximumAllowedTemperatureC

        let connectivityOK =
            metrics.waterConnected &&
            metrics.airConnected

        let flowOK =
            !metrics.channelsOverlap

        let printableOK =
            metrics.printable

        var fitness =
            heatPerPower

        if !meetsHeatTarget {
            fitness *= 0.25
        }

        if !temperatureOK {
            fitness *= 0.25
        }

        if !connectivityOK {
            fitness *= 0.10
        }

        if !flowOK {
            fitness *= 0.10
        }

        if !printableOK {
            fitness *= 0.50
        }

        metrics.fitness =
            max(
                0.0,
                fitness
            )
    }

    // MARK: Printability

    private func calculatePrintability() -> Bool {

        // Basic voxel-manufacturing constraints:
        //
        // 1. Aluminum must not be isolated.
        // 2. Flow channels must remain open.
        // 3. Exterior support must exist.
        // 4. No impossible single-voxel floating islands.

        for currentCell in cells {

            guard currentCell.state == .aluminum else {
                continue
            }

            let point = GridPoint(
                x: currentCell.x,
                y: currentCell.y,
                z: currentCell.z
            )

            let structuralNeighbors =
                neighborPoints(point)
                    .compactMap { point in
                        self.cell(at: point)
                    }
                    .filter { neighbor in
                        neighbor.state == .aluminum
                    }
                    .count

            let isBoundary =
                currentCell.x == 0 ||
                currentCell.x == gridSize - 1 ||
                currentCell.y == 0 ||
                currentCell.y == gridSize - 1 ||
                currentCell.z == 0 ||
                currentCell.z == gridSize - 1

            if structuralNeighbors == 0 &&
                !isBoundary {

                return false
            }
        }

        return true
    }

    // MARK: Evaluation

    private func evaluateSimulation() {

        calculateVolumeAndMass()

        metrics.aluminumSurfaceAreaM2 =
            calculateSurfaceArea()

        calculateFlow()

        calculateTemperatureField()

        calculateHeatRemoval()

        metrics.waterConnected =
            waterConnectivity()

        metrics.airConnected =
            airConnectivity()

        metrics.channelsOverlap =
            detectChannelOverlap()

        metrics.printable =
            calculatePrintability()

        calculateFitness()
    }

    private func detectChannelOverlap() -> Bool {

        // The enum is mutually exclusive, so an actual cell
        // cannot simultaneously contain both fluids.

        // Check neighboring direct contact as allowed,
        // but not shared occupancy.

        for currentCell in cells {

            if currentCell.state.isWater {

                let point = GridPoint(
                    x: currentCell.x,
                    y: currentCell.y,
                    z: currentCell.z
                )

                for neighborPoint in neighborPoints(point) {

                    guard let neighbor =
                        self.cell(at: neighborPoint)
                    else {
                        continue
                    }

                    if neighbor.state.isAir {

                        // Adjacent fluid cells are permitted.
                        // They are not overlapping.

                        continue
                    }
                }
            }
        }

        return false
    }

    // MARK: Reset

    func reset() {

        buildInitialGeometry()

        evaluateSimulation()
    }

    // MARK: Run Optimization

    func optimize(
        generations: Int = 50
    ) {

        reset()

        var bestCells = cells
        var bestMetrics = metrics
        var bestFitness = metrics.fitness

        for _ in 0..<generations {

            evolveDeposition()

            evaluateSimulation()

            if metrics.fitness > bestFitness {

                bestFitness =
                    metrics.fitness

                bestCells =
                    cells

                bestMetrics =
                    metrics
            }
        }

        cells = bestCells
        metrics = bestMetrics
        generation += generations
    }
}

// MARK: - GridPoint Helpers

private extension GridPoint {

    mutating func xMove(
        direction: Int,
        into point: inout GridPoint
    ) {

        point = GridPoint(
            x: x + direction,
            y: y,
            z: z
        )
    }

    mutating func yMove(
        direction: Int,
        into point: inout GridPoint
    ) {

        point = GridPoint(
            x: x,
            y: y + direction,
            z: z
        )
    }

    mutating func zMove(
        direction: Int,
        into point: inout GridPoint
    ) {

        point = GridPoint(
            x: x,
            y: y,
            z: z + direction
        )
    }
}

// MARK: - Scene

struct RadiatorSceneView: UIViewRepresentable {

    let cells: [RadiatorCell]

    let gridSize: Int

    let cellSize: Float

    func makeUIView(
        context: Context
    ) -> SCNView {

        let view = SCNView()

        view.backgroundColor =
            .black

        view.allowsCameraControl =
            true

        view.autoenablesDefaultLighting =
            true

        let scene =
            SCNScene()

        view.scene =
            scene

        addGeometry(
            to: scene
        )

        addCamera(
            to: scene
        )

        return view
    }

    func updateUIView(
        _ view: SCNView,
        context: Context
    ) {

        guard let scene = view.scene else {
            return
        }

        scene.rootNode.childNodes.forEach {
            $0.removeFromParentNode()
        }

        addGeometry(
            to: scene
        )

        addCamera(
            to: scene
        )
    }

    // MARK: Geometry

    private func addGeometry(
        to scene: SCNScene
    ) {

        let center =
            Float(gridSize - 1) *
            cellSize /
            2.0

        for currentCell in cells {

            guard currentCell.state != .empty else {
                continue
            }

            let geometry =
                SCNBox(
                    width: CGFloat(cellSize * 0.92),
                    height: CGFloat(cellSize * 0.92),
                    length: CGFloat(cellSize * 0.92),
                    chamferRadius: 0.0
                )

            geometry.firstMaterial =
                material(
                    for: currentCell
                )

            let node =
                SCNNode(
                    geometry: geometry
                )

            node.position =
                SCNVector3(
                    Float(currentCell.x) *
                    cellSize -
                    center,

                    Float(currentCell.y) *
                    cellSize -
                    center,

                    Float(currentCell.z) *
                    cellSize -
                    center
                )

            scene.rootNode.addChildNode(
                node
            )
        }
    }

    // MARK: Materials

    private func material(
        for currentCell: RadiatorCell
    ) -> SCNMaterial {

        let material =
            SCNMaterial()

        switch currentCell.state {

        case .aluminum:

            let normalized =
                min(
                    1.0,
                    max(
                        0.0,
                        (
                            currentCell.temperatureC -
                            25.0
                        ) /
                        95.0
                    )
                )

            material.diffuse.contents =
                UIColor(
                    red: CGFloat(normalized),
                    green: CGFloat(
                        0.72 *
                        (1.0 - normalized)
                    ),
                    blue: CGFloat(
                        0.85 *
                        (1.0 - normalized)
                    ),
                    alpha: 1.0
                )

        case .water:

            material.diffuse.contents =
                UIColor(
                    red: 0.0,
                    green: 0.0,
                    blue: 1.0,
                    alpha: 0.55
                )

            material.transparency = 0.55

        case .waterInlet:

            material.diffuse.contents =
                UIColor.cyan.withAlphaComponent(1.0)

        case .waterOutlet:

            material.diffuse.contents =
                UIColor.blue.withAlphaComponent(1.0)

        case .air:

            material.diffuse.contents =
                UIColor(
                    white: 0.8,
                    alpha: 0.18
                )

            material.transparency = 0.18

        case .airInlet:
            material.diffuse.contents = UIColor.green

        case .airOutlet:

            material.diffuse.contents =
                UIColor(
                    red: 1.0,
                    green: 0.5,
                    blue: 0.1,
                    alpha: 1.0
                )

        case .empty:

            material.diffuse.contents =
                UIColor.clear

            material.transparency = 0.0
        }

        return material
    }

    // MARK: Camera

    private func addCamera(
        to scene: SCNScene
    ) {

        let camera =
            SCNCamera()

        camera.fieldOfView =
            60.0

        let cameraNode =
            SCNNode()

        cameraNode.camera =
            camera

        cameraNode.position =
            SCNVector3(
                0,
                Float(gridSize) * cellSize * 0.65,
                Float(gridSize) * cellSize * 1.45
            )

        cameraNode.look(
            at: SCNVector3Zero
        )

        scene.rootNode.addChildNode(
            cameraNode
        )
    }
}

// MARK: - Camera Look Helper

private extension SCNNode {

    func look(
        at target: SCNVector3
    ) {

        let direction =
            SCNVector3(
                target.x - position.x,
                target.y - position.y,
                target.z - position.z
            )

        let length =
            sqrt(
                direction.x * direction.x +
                direction.y * direction.y +
                direction.z * direction.z
            )

        guard length > 0 else {
            return
        }

        let normalized =
            SCNVector3(
                direction.x / length,
                direction.y / length,
                direction.z / length
            )

        let yaw =
            atan2(
                normalized.x,
                normalized.z
            )

        let pitch =
            -asin(
                normalized.y
            )

        eulerAngles =
            SCNVector3(
                pitch,
                yaw,
                0
            )
    }
}

// MARK: - Content View

struct ContentView: View {

    @StateObject
    private var engine =
        RadiatorCAEngine()

    var body: some View {

        VStack(
            spacing: 0
        ) {

            header

            RadiatorSceneView(
                cells: engine.cells,
                gridSize: engine.gridSize,
                cellSize: 0.18
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            metricsPanel

            controls
        }
        .background(
            Color.black
        )
        .foregroundStyle(
            .white
        )
    }

    // MARK: Header

    private var header: some View {

        VStack(
            spacing: 4
        ) {

            Text(
                "DIAMOND HEAT EXCHANGER"
            )
            .font(
                .title2.bold()
            )

            Text(
                "3D Cellular Automaton • 1 GJ Thermal Load"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding(
            .vertical,
            10
        )
    }

    // MARK: Metrics

    private var metricsPanel: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(
                spacing: 14
            ) {

                metric(
                    title: "ALUMINUM",
                    value: String(
                        format: "%.2f kg",
                        engine.metrics.aluminumMassKg
                    )
                )

                metric(
                    title: "SURFACE",
                    value: String(
                        format: "%.3f m²",
                        engine.metrics.aluminumSurfaceAreaM2
                    )
                )

                metric(
                    title: "WATER",
                    value: String(
                        format: "%.5f m³/s",
                        engine.metrics.waterFlowM3S
                    )
                )

                metric(
                    title: "AIR",
                    value: String(
                        format: "%.4f m³/s",
                        engine.metrics.airFlowM3S
                    )
                )

                metric(
                    title: "ΔP WATER",
                    value: String(
                        format: "%.0f Pa",
                        engine.metrics.waterPressureDropPa
                    )
                )

                metric(
                    title: "ΔP AIR",
                    value: String(
                        format: "%.0f Pa",
                        engine.metrics.airPressureDropPa
                    )
                )

                metric(
                    title: "PUMP",
                    value: String(
                        format: "%.2f kW",
                        engine.metrics.pumpPowerW / 1000.0
                    )
                )

                metric(
                    title: "FAN",
                    value: String(
                        format: "%.2f kW",
                        engine.metrics.fanPowerW / 1000.0
                    )
                )

                metric(
                    title: "HEAT",
                    value: String(
                        format: "%.3f MW",
                        engine.metrics.heatRejectedMW
                    )
                )

                metric(
                    title: "1 GJ TIME",
                    value: String(
                        format: "%.1f s",
                        engine.metrics.removalTimeS
                    )
                )

                metric(
                    title: "MAX TEMP",
                    value: String(
                        format: "%.1f °C",
                        engine.metrics.maximumTemperatureC
                    )
                )

                metric(
                    title: "FITNESS",
                    value: String(
                        format: "%.3e",
                        engine.metrics.fitness
                    )
                )
            }
            .padding(
                .horizontal,
                12
            )
            .padding(
                .vertical,
                8
            )
        }
    }

    private func metric(
        title: String,
        value: String
    ) -> some View {

        VStack(
            spacing: 3
        ) {

            Text(title)
                .font(
                    .caption2.bold()
                )
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(
                    .caption.monospacedDigit()
                )
        }
        .frame(
            minWidth: 90
        )
    }

    // MARK: Controls

    private var controls: some View {

        HStack(
            spacing: 10
        ) {

            Button(
                "RESET"
            ) {

                engine.reset()
            }

            Button(
                "EVOLVE"
            ) {

                engine.evolve(
                    generations: 10
                )
            }

            Button(
                "OPTIMIZE"
            ) {

                engine.optimize(
                    generations: 50
                )
            }

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 2
            ) {

                Text(
                    "Generation \(engine.generation)"
                )
                .font(
                    .caption.monospacedDigit()
                )

                Text(
                    engine.metrics.waterConnected &&
                    engine.metrics.airConnected
                    ? "FLOW CONNECTED"
                    : "FLOW DISCONNECTED"
                )
                .font(
                    .caption2.bold()
                )
                .foregroundStyle(
                    engine.metrics.waterConnected &&
                    engine.metrics.airConnected
                    ? .green
                    : .red
                )
            }
        }
        .padding(
            10
        )
    }
}

// MARK: - Preview

#Preview {

    ContentView()
}
