//
//  RadiatorSceneView.swift
//  Diamond Heat Exchanger
//
//  Created by David Nishimoto on 10/1/26.
//

import SwiftUI
import SceneKit
import UIKit

/*
 Renders the lattice as small spheres, one per occupied cell.

 - Aluminum spheres have a diameter equal to the cell pitch, so every
   face-connected pair of cells touches. A connected lattice therefore
   looks connected, and a broken one shows its gap.
 - Water is drawn smaller so the channels stay readable inside the metal.
 - Plain air cells are hidden by default (showAir) because the whole
   free volume is air and would bury the structure. Air ports are
   always drawn.

 Nodes are created once and reused. Each update only swaps a shared
 geometry (state + temperature bucket) onto the node, instead of
 rebuilding thousands of nodes and materials every generation.
 */

struct RadiatorSceneView: UIViewRepresentable {

    let cells: [RadiatorCell]
    let gridSize: Int
    let cellSize: Float

    var showAir: Bool = false

    // MARK: - Style Constants
    //
    // Kept in a nested enum (not private stored properties) so the
    // memberwise initializer stays internal and ContentView can still
    // call RadiatorSceneView(cells:gridSize:cellSize:).

    private enum Style {

        /// Sphere diameter as a multiple of the cell pitch.
        static let aluminumDiameterScale: Float = 1.0
        static let waterDiameterScale: Float = 0.62
        static let waterPortDiameterScale: Float = 0.85
        static let airDiameterScale: Float = 0.30
        static let airPortDiameterScale: Float = 0.80

        static let temperatureBuckets = 48

        static let minimumTemperatureC = 25.0
        static let maximumTemperatureC = 120.0
    }

    // MARK: - Coordinator

    private struct GeometryKey: Hashable {
        let state: RadiatorCellState
        let bucket: Int
    }

    final class Coordinator {
        let latticeNode = SCNNode()
        var nodesByCellID: [Int: SCNNode] = [:]
        var geometryCache: [AnyHashable: SCNGeometry] = [:]
        var lastShowAir = false
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - UIViewRepresentable

    func makeUIView(
        context: Context
    ) -> SCNView {

        let view = SCNView()
        view.backgroundColor = .black
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X

        let scene = SCNScene()
        view.scene = scene

        scene.rootNode.addChildNode(
            context.coordinator.latticeNode
        )

        let cameraNode = makeCameraNode()
        scene.rootNode.addChildNode(cameraNode)
        view.pointOfView = cameraNode

        synchronize(
            coordinator: context.coordinator
        )

        return view
    }

    func updateUIView(
        _ view: SCNView,
        context: Context
    ) {

        synchronize(
            coordinator: context.coordinator
        )
    }

    // MARK: - Synchronization

    private func synchronize(
        coordinator: Coordinator
    ) {

        let center =
            Float(gridSize - 1) *
            cellSize /
            2.0

        for currentCell in cells {

            guard shouldRender(currentCell.state)
            else {

                coordinator.nodesByCellID[currentCell.id]?.isHidden = true
                continue
            }

            let node: SCNNode

            if let existing = coordinator.nodesByCellID[currentCell.id] {

                node = existing

            } else {

                node = SCNNode()

                node.position =
                    SCNVector3(
                        Float(currentCell.x) * cellSize - center,
                        Float(currentCell.y) * cellSize - center,
                        Float(currentCell.z) * cellSize - center
                    )

                coordinator.latticeNode.addChildNode(node)
                coordinator.nodesByCellID[currentCell.id] = node
            }

            node.isHidden = false

            let geometry =
                sharedGeometry(
                    for: currentCell,
                    coordinator: coordinator
                )

            if node.geometry !== geometry {
                node.geometry = geometry
            }
        }
    }

    private func shouldRender(
        _ state: RadiatorCellState
    ) -> Bool {

        switch state {

        case .empty:
            return false

        case .air:
            return showAir

        default:
            return true
        }
    }

    // MARK: - Shared Geometry

    private func sharedGeometry(
        for currentCell: RadiatorCell,
        coordinator: Coordinator
    ) -> SCNGeometry {

        let bucket: Int

        switch currentCell.state {

        case .aluminum,
             .water,
             .waterInlet,
             .waterOutlet:

            bucket = temperatureBucket(currentCell.temperatureC)

        default:

            bucket = 0
        }

        let key =
            GeometryKey(
                state: currentCell.state,
                bucket: bucket
            )

        if let cached = coordinator.geometryCache[key] {
            return cached
        }

        let diameter =
            CGFloat(cellSize * diameterScale(for: currentCell.state))

        let sphere =
            SCNSphere(
                radius: diameter / 2.0
            )

        sphere.segmentCount = segmentCount(for: currentCell.state)

        sphere.firstMaterial =
            material(
                for: currentCell.state,
                temperatureC: temperature(forBucket: bucket)
            )

        coordinator.geometryCache[key] = sphere

        return sphere
    }

    private func diameterScale(
        for state: RadiatorCellState
    ) -> Float {

        switch state {

        case .aluminum:
            return Style.aluminumDiameterScale

        case .water:
            return Style.waterDiameterScale

        case .waterInlet,
             .waterOutlet:
            return Style.waterPortDiameterScale

        case .air:
            return Style.airDiameterScale

        case .airInlet,
             .airOutlet:
            return Style.airPortDiameterScale

        case .empty:
            return 0.0
        }
    }

    private func segmentCount(
        for state: RadiatorCellState
    ) -> Int {

        switch state {

        case .aluminum:
            return 12

        case .water,
             .waterInlet,
             .waterOutlet,
             .airInlet,
             .airOutlet:
            return 10

        case .air,
             .empty:
            return 6
        }
    }

    // MARK: - Temperature Buckets

    private func temperatureBucket(
        _ temperatureC: Double
    ) -> Int {

        let normalized =
            min(
                1.0,
                max(
                    0.0,
                    (temperatureC - Style.minimumTemperatureC) /
                    (Style.maximumTemperatureC - Style.minimumTemperatureC)
                )
            )

        return Int(
            (normalized * Double(Style.temperatureBuckets - 1))
                .rounded()
        )
    }

    private func temperature(
        forBucket bucket: Int
    ) -> Double {

        Style.minimumTemperatureC +
        (Style.maximumTemperatureC - Style.minimumTemperatureC) *
        Double(bucket) /
        Double(Style.temperatureBuckets - 1)
    }

    // MARK: - Thermal Material

    private func material(
        for state: RadiatorCellState,
        temperatureC: Double
    ) -> SCNMaterial {

        let material = SCNMaterial()
        material.lightingModel = .blinn

        switch state {

        // -------------------------------------------------
        // ALUMINUM
        // -------------------------------------------------

        case .aluminum:

            material.diffuse.contents =
                temperatureColor(
                    temperatureC,
                    alpha: 1.0
                )

            material.specular.contents =
                UIColor.white.withAlphaComponent(0.25)

            material.shininess = 0.35

        // -------------------------------------------------
        // WATER
        // -------------------------------------------------

        case .water:

            material.diffuse.contents =
                temperatureColor(
                    temperatureC,
                    alpha: 0.72
                )

            material.transparency = 0.72

            material.specular.contents =
                UIColor.white.withAlphaComponent(0.40)

            material.shininess = 0.65

        // -------------------------------------------------
        // WATER INLET / OUTLET
        // -------------------------------------------------

        case .waterInlet,
             .waterOutlet:

            material.diffuse.contents =
                temperatureColor(
                    temperatureC,
                    alpha: 1.0
                )

            material.specular.contents =
                UIColor.white

            material.shininess = 0.8

        // -------------------------------------------------
        // AIR
        // -------------------------------------------------

        case .air:

            material.diffuse.contents =
                UIColor(
                    white: 0.8,
                    alpha: 0.12
                )

            material.transparency = 0.12

        // -------------------------------------------------
        // AIR INLET
        // -------------------------------------------------

        case .airInlet:

            material.diffuse.contents =
                UIColor.green

        // -------------------------------------------------
        // AIR OUTLET
        // -------------------------------------------------

        case .airOutlet:

            material.diffuse.contents =
                UIColor.orange

        // -------------------------------------------------
        // EMPTY
        // -------------------------------------------------

        case .empty:

            material.diffuse.contents =
                UIColor.clear

            material.transparency = 0.0
        }

        return material
    }

    // MARK: - Temperature Color

    private func temperatureColor(
        _ temperatureC: Double,
        alpha: CGFloat
    ) -> UIColor {

        let normalized =
            min(
                1.0,
                max(
                    0.0,
                    (
                        temperatureC -
                        Style.minimumTemperatureC
                    ) /
                    (
                        Style.maximumTemperatureC -
                        Style.minimumTemperatureC
                    )
                )
            )

        // Thermal progression:
        //
        // 25°C   → blue
        // 40°C   → cyan
        // 60°C   → green
        // 75°C   → yellow
        // 95°C   → orange
        // 120°C  → red

        let stops: [(Double, CGFloat, CGFloat, CGFloat)] = [
            (0.00, 0.05, 0.15, 1.00), // blue
            (0.20, 0.00, 0.85, 1.00), // cyan
            (0.40, 0.00, 1.00, 0.25), // green
            (0.60, 1.00, 1.00, 0.00), // yellow
            (0.80, 1.00, 0.35, 0.00), // orange
            (1.00, 1.00, 0.00, 0.00)  // red
        ]

        for index in 0..<(stops.count - 1) {

            let lower = stops[index]
            let upper = stops[index + 1]

            guard normalized >= lower.0,
                  normalized <= upper.0
            else {
                continue
            }

            let range =
                upper.0 - lower.0

            let local =
                range > 0
                ? (normalized - lower.0) / range
                : 0.0

            let red =
                lower.1 +
                (upper.1 - lower.1) *
                CGFloat(local)

            let green =
                lower.2 +
                (upper.2 - lower.2) *
                CGFloat(local)

            let blue =
                lower.3 +
                (upper.3 - lower.3) *
                CGFloat(local)

            return UIColor(
                red: red,
                green: green,
                blue: blue,
                alpha: alpha
            )
        }

        return UIColor.red.withAlphaComponent(alpha)
    }

    // MARK: - Camera

    private func makeCameraNode() -> SCNNode {

        let camera = SCNCamera()
        camera.fieldOfView = 52
        camera.zNear = 0.001
        camera.zFar = 100

        let cameraNode = SCNNode()
        cameraNode.name = "mainCamera"
        cameraNode.camera = camera

        cameraNode.position =
            SCNVector3(
                4.8,
                3.8,
                5.6
            )

        cameraNode.look(
            at: SCNVector3Zero
        )

        return cameraNode
    }
}
