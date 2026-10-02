
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

 Aluminum thermal state:
 - cell.heatJ is the ONLY authoritative aluminum thermal state.
 - Aluminum temperature is derived from heatJ only for visualization.
 - Aluminum cell.temperatureC is never read.

 Water thermal state:
 - Water continues to use cell.temperatureC.

 Nodes are created once and reused.
 Each update selects shared geometry based on:
 - cell state
 - thermal bucket
*/

struct RadiatorSceneView: UIViewRepresentable {

    let cells: [RadiatorCell]
    let gridSize: Int
    let cellSize: Float
    var showAir: Bool = false

    // MARK: - Style Constants

    private enum Style {

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

                coordinator
                    .nodesByCellID[currentCell.id]?
                    .isHidden = true

                continue
            }

            let node: SCNNode

            if let existing =
                coordinator.nodesByCellID[currentCell.id] {

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

        // -------------------------------------------------
        // ALUMINUM
        // -------------------------------------------------

        case .aluminum:

            /*
             IMPORTANT:

             Aluminum does NOT use cell.temperatureC.

             heatJ is converted to a derived temperature
             solely for visualization.
            */

            bucket =
                aluminumTemperatureBucket(
                    heatJ: currentCell.heatJ
                )

        // -------------------------------------------------
        // WATER
        // -------------------------------------------------

        case .water,
             .waterInlet,
             .waterOutlet:

            bucket =
                temperatureBucket(
                    currentCell.temperatureC
                )

        // -------------------------------------------------
        // AIR / PORTS
        // -------------------------------------------------

        default:

            bucket = 0
        }

        let key =
            GeometryKey(
                state: currentCell.state,
                bucket: bucket
            )

        if let cached =
            coordinator.geometryCache[key] {

            return cached
        }

        let diameter =
            CGFloat(
                cellSize *
                diameterScale(
                    for: currentCell.state
                )
            )

        let sphere =
            SCNSphere(
                radius: diameter / 2.0
            )

        sphere.segmentCount =
            segmentCount(
                for: currentCell.state
            )

        sphere.firstMaterial =
            material(
                for: currentCell.state,
                temperatureC:
                    temperature(
                        forBucket: bucket
                    )
            )

        coordinator.geometryCache[key] = sphere

        return sphere
    }

    // MARK: - Aluminum Thermal Visualization

    /*
     Converts aluminum heatJ into temperature.

     heatJ is the authoritative aluminum thermal state.

     This function does NOT modify the cell.
     It only derives a visualization temperature.
    */

    private func aluminumTemperatureC(
        from heatJ: Double
    ) -> Double {

        let aluminumHeatJ =
            max(
                heatJ,
                0.0
            )

        let aluminumMassKg =
            aluminumDensityKgM3 *
            cellVolumeM3

        let heatCapacityJPerK =
            aluminumMassKg *
            aluminumSpecificHeat

        guard heatCapacityJPerK > 0 else {
            return Style.minimumTemperatureC
        }

        return
            ambientTemperatureC +
            aluminumHeatJ /
            heatCapacityJPerK
    }

    private func aluminumTemperatureBucket(
        heatJ: Double
    ) -> Int {

        let temperatureC =
            aluminumTemperatureC(
                from: heatJ
            )

        return temperatureBucket(
            temperatureC
        )
    }

    // MARK: - Thermal Constants

    /*
     These match the thermal model used by the
     Diamond Heat Exchanger engine.

     Aluminum temperature is derived from heatJ.
    */

    private let aluminumDensityKgM3 =
        2700.0

    private let aluminumSpecificHeat =
        897.0

    private let ambientTemperatureC =
        25.0

    private var cellVolumeM3: Double {

        let size =
            Double(cellSize)

        return
            size *
            size *
            size
    }

    // MARK: - Diameter

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

    // MARK: - Segment Count

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

        return Int(
            (
                normalized *
                Double(
                    Style.temperatureBuckets - 1
                )
            )
            .rounded()
        )
    }

    private func temperature(
        forBucket bucket: Int
    ) -> Double {

        Style.minimumTemperatureC +
        (
            Style.maximumTemperatureC -
            Style.minimumTemperatureC
        ) *
        Double(bucket) /
        Double(
            Style.temperatureBuckets - 1
        )
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

        let stops:
            [(Double, CGFloat, CGFloat, CGFloat)] = [

            (0.00, 0.05, 0.15, 1.00),
            (0.20, 0.00, 0.85, 1.00),
            (0.40, 0.00, 1.00, 0.25),
            (0.60, 1.00, 1.00, 0.00),
            (0.80, 1.00, 0.35, 0.00),
            (1.00, 1.00, 0.00, 0.00)
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
