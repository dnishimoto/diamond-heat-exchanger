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

struct ContentView: View {

    @StateObject private var engine = RadiatorCAEngine()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerRibbon

                scenePanel

                metricsRibbon

                controlsRibbon
            }

            if engine.isRunning {
                progressOverlay
                    .transition(.opacity)
            }
        }
        .background(Color.black)
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .animation(
            .easeInOut(duration: 0.20),
            value: engine.isRunning
        )
    }

    // MARK: - Header Ribbon

    private var headerRibbon: some View {
        HStack(spacing: 12) {
            Image(systemName: "cube.transparent")
                .font(.title3)
                .foregroundStyle(.cyan)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Diamond Heat Exchanger")
                    .font(.headline.bold())

                Text(
                    "3D Cellular Automaton • 1 GJ Thermal Load"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(white: 0.075))
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.white.opacity(0.10))
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption2.bold())
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            statusColor.opacity(0.13),
            in: Capsule()
        )
    }

    private var statusText: String {
        if engine.isRunning {
            return "RUNNING"
        }

        return designIsValid
            ? "VALID"
            : "CHECK DESIGN"
    }

    private var statusColor: Color {
        if engine.isRunning {
            return .cyan
        }

        return designIsValid
            ? .green
            : .orange
    }

    private var designIsValid: Bool {
        engine.metrics.waterConnected &&
        engine.metrics.airConnected &&
        engine.metrics.printable &&
        !engine.metrics.channelsOverlap
    }

    // MARK: - Large Scene

    private var scenePanel: some View {
        ZStack(alignment: .topLeading) {
            RadiatorSceneView(
                cells: engine.cells,
                gridSize: engine.gridSize,
                cellSize: 0.18
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(Color.black)

            sceneLegend
                .padding(14)

            sceneStatusReadout
                .padding(14)
        }
        .layoutPriority(1)
    }

    private var sceneLegend: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            Text("LATTICE VIEW")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            legendRow(
                color: .purple,
                label: "Aluminum"
            )

            legendRow(
                color: .blue,
                label: "Water"
            )

            legendRow(
                color: .green,
                label: "Air inlet"
            )

            legendRow(
                color: .orange,
                label: "Air outlet"
            )

            Text("Drag to rotate • Pinch to zoom")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 3)
        }
        .padding(9)
        .background(
            Color.black.opacity(0.72),
            in: RoundedRectangle(
                cornerRadius: 9
            )
        )
    }

    private var sceneStatusReadout: some View {
        VStack(
            alignment: .trailing,
            spacing: 4
        ) {
            Text("GENERATION \(engine.generation)")
                .font(
                    .system(
                        .caption,
                        design: .monospaced
                    )
                    .bold()
                )
                .foregroundStyle(.cyan)

            Text(
                String(
                    format: "%.3f MW",
                    engine.metrics.heatRejectedMW
                )
            )
            .font(
                .system(
                    .caption,
                    design: .monospaced
                )
            )
            .foregroundStyle(.orange)
        }
        .padding(9)
        .background(
            Color.black.opacity(0.72),
            in: RoundedRectangle(
                cornerRadius: 9
            )
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topTrailing
        )
    }

    private func legendRow(
        color: Color,
        label: String
    ) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(label)
                .font(.caption2)
        }
    }

    // MARK: - Metrics Ribbon

    private var metricsRibbon: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                metricPill(
                    title: "Fitness",
                    value: String(
                        format: "%.2e",
                        engine.metrics.fitness
                    ),
                    color: .mint
                )

                metricPill(
                    title: "Max Temp",
                    value: String(
                        format: "%.1f °C",
                        engine.metrics.maximumTemperatureC
                    ),
                    color: temperatureColor
                )

                metricPill(
                    title: "1 GJ Time",
                    value: formattedRemovalTime,
                    color: .orange
                )

                metricPill(
                    title: "Aluminum",
                    value: String(
                        format: "%.2f kg",
                        engine.metrics.aluminumMassKg
                    ),
                    color: .purple
                )

                metricPill(
                    title: "Surface",
                    value: String(
                        format: "%.3f m²",
                        engine.metrics.aluminumSurfaceAreaM2
                    ),
                    color: .pink
                )

                metricPill(
                    title: "Water",
                    value: String(
                        format: "%.5f m³/s",
                        engine.metrics.waterFlowM3S
                    ),
                    color: .blue
                )

                metricPill(
                    title: "Air",
                    value: String(
                        format: "%.4f m³/s",
                        engine.metrics.airFlowM3S
                    ),
                    color: .cyan
                )

                metricPill(
                    title: "Pump",
                    value: String(
                        format: "%.2f kW",
                        engine.metrics.pumpPowerW / 1000.0
                    ),
                    color: .blue
                )

                metricPill(
                    title: "Fan",
                    value: String(
                        format: "%.2f kW",
                        engine.metrics.fanPowerW / 1000.0
                    ),
                    color: .cyan
                )

                healthPill(
                    title: "Water Path",
                    isPassing: engine.metrics.waterConnected
                )

                healthPill(
                    title: "Air Path",
                    isPassing: engine.metrics.airConnected
                )

                healthPill(
                    title: "Printable",
                    isPassing: engine.metrics.printable
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.065))
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color.white.opacity(0.10))
        }
    }

    private func metricPill(
        title: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .system(
                        .caption,
                        design: .monospaced
                    )
                    .bold()
                )
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    private func healthPill(
        title: String,
        isPassing: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Image(
                systemName: isPassing
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .foregroundStyle(
                isPassing ? Color.green : Color.red
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title.uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)

                Text(
                    isPassing
                        ? "Connected"
                        : "Check"
                )
                .font(.caption.bold())
                .foregroundStyle(
                    isPassing ? Color.green : Color.red
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    // MARK: - Controls Ribbon

    private var controlsRibbon: some View {
        HStack(spacing: 9) {
            Button {
                engine.reset()
            } label: {
                Label(
                    "Reset",
                    systemImage: "arrow.counterclockwise"
                )
            }
            .buttonStyle(.bordered)
            .disabled(engine.isRunning)

            Button {
                engine.evolve(generations: 1)
            } label: {
                Label(
                    "Step",
                    systemImage: "forward.frame.fill"
                )
            }
            .buttonStyle(.bordered)
            .disabled(engine.isRunning)

            Button {
                engine.evolve(generations: 20)
            } label: {
                Label(
                    "Run",
                    systemImage: "play.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(engine.isRunning)

            Button {
                engine.optimize(generations: 50)
            } label: {
                Label(
                    "Optimize",
                    systemImage: "wand.and.stars"
                )
            }
            .buttonStyle(.bordered)
            .disabled(engine.isRunning)

            if engine.isRunning {
                Button(
                    role: .destructive
                ) {
                    engine.stop()
                } label: {
                    Label(
                        "Stop",
                        systemImage: "stop.fill"
                    )
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Group {
                if engine.isRunning {
                    ProgressView()
                        .controlSize(.small)

                    Text(
                        "Evaluating generation \(engine.generation)"
                    )
                } else {
                    Text(
                        "Step = one CA update • Run = 20 updates"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color(white: 0.085))
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color.white.opacity(0.10))
        }
    }

    // MARK: - Progress Overlay

    private var progressOverlay: some View {
        ZStack {
            Color.black
                .opacity(0.32)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.cyan)

                Text("Simulation Running")
                    .font(.headline)

                Text(
                    "Evaluating generation \(engine.generation)"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(
                    "The scene remains visible and updates after each CA generation."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                Button(
                    role: .destructive
                ) {
                    engine.stop()
                } label: {
                    Label(
                        "Stop",
                        systemImage: "stop.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(22)
            .frame(width: 310)
            .background(
                Color(white: 0.10),
                in: RoundedRectangle(
                    cornerRadius: 16
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    Color.cyan.opacity(0.32),
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Formatting

    private var temperatureColor: Color {
        let temperature = engine.metrics.maximumTemperatureC

        if temperature >= 110 {
            return .red
        }

        if temperature >= 85 {
            return .orange
        }

        return .green
    }

    private var formattedRemovalTime: String {
        let time = engine.metrics.removalTimeS

        guard time.isFinite else {
            return "—"
        }

        if time >= 3_600 {
            return String(
                format: "%.1f hr",
                time / 3_600
            )
        }

        if time >= 60 {
            return String(
                format: "%.1f min",
                time / 60
            )
        }

        return String(
            format: "%.1f s",
            time
        )
    }
}
// MARK: - Preview

#Preview {

    ContentView()
}

