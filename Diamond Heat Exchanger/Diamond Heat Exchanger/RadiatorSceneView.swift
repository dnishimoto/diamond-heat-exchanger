//
//  File.swift
//  Diamond Heat Exchanger
//
//  Created by David Nishimoto on 10/1/26.
//



import SwiftUI
import SceneKit
import UIKit

struct RadiatorSceneView: UIViewRepresentable {

    let cells: [RadiatorCell]
    let gridSize: Int
    let cellSize: Float

    func makeUIView(
        context: Context
    ) -> SCNView {

        let view = SCNView()
        view.backgroundColor = .black
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true

        let scene = SCNScene()
        view.scene = scene

        addGeometry(to: scene)
        addCamera(to: scene)

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

        addGeometry(to: scene)
        addCamera(to: scene)
    }

    // MARK: - Geometry

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

            let geometry = SCNBox(
                width: CGFloat(cellSize * 0.92),
                height: CGFloat(cellSize * 0.92),
                length: CGFloat(cellSize * 0.92),
                chamferRadius: 0.0
            )

            geometry.firstMaterial =
                material(for: currentCell)

            let node =
                SCNNode(
                    geometry: geometry
                )

            node.position =
                SCNVector3(
                    Float(currentCell.x) * cellSize - center,
                    Float(currentCell.y) * cellSize - center,
                    Float(currentCell.z) * cellSize - center
                )

            scene.rootNode.addChildNode(node)
        }
    }

    // MARK: - Thermal Material

    private func material(
        for currentCell: RadiatorCell
    ) -> SCNMaterial {

        let material = SCNMaterial()

        switch currentCell.state {

        // -------------------------------------------------
        // ALUMINUM
        // -------------------------------------------------

        case .aluminum:

            material.diffuse.contents =
                temperatureColor(
                    currentCell.temperatureC,
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
                    currentCell.temperatureC,
                    alpha: 0.72
                )

            material.transparency = 0.72

            material.specular.contents =
                UIColor.white.withAlphaComponent(0.40)

            material.shininess = 0.65

        // -------------------------------------------------
        // WATER INLET
        // -------------------------------------------------

        case .waterInlet:

            material.diffuse.contents =
                temperatureColor(
                    currentCell.temperatureC,
                    alpha: 1.0
                )

            material.specular.contents =
                UIColor.white

            material.shininess = 0.8

        // -------------------------------------------------
        // WATER OUTLET
        // -------------------------------------------------

        case .waterOutlet:

            material.diffuse.contents =
                temperatureColor(
                    currentCell.temperatureC,
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

        let minimumTemperatureC = 25.0
        let maximumTemperatureC = 120.0

        let normalized =
            min(
                1.0,
                max(
                    0.0,
                    (
                        temperatureC -
                        minimumTemperatureC
                    ) /
                    (
                        maximumTemperatureC -
                        minimumTemperatureC
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

    private func addCamera(
        to scene: SCNScene
    ) {

        let targetNode = SCNNode()
        targetNode.name = "cameraTarget"
        targetNode.position = SCNVector3Zero

        scene.rootNode.addChildNode(
            targetNode
        )

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

        let lookAt =
            SCNLookAtConstraint(
                target: targetNode
            )

        lookAt.isGimbalLockEnabled = true

        cameraNode.constraints = [
            lookAt
        ]

        scene.rootNode.addChildNode(
            cameraNode
        )
    }
}
