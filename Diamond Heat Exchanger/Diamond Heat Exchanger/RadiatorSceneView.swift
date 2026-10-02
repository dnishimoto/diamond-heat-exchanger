
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

 Thermal architecture:

 - cell.heatJ is the authoritative thermal state.
 - Aluminum temperature is NEVER read from cell.temperatureC.
 - Water temperature is NEVER read from cell.temperatureC.
 - Visualization uses heatJ directly.
 - Temperature is not used as the visualization authority.
 - A logarithmic heat scale makes both low and high heat visible.
 - 64 thermal buckets provide higher visualization resolution.

 Nodes are created once and reused.
 Each update selects shared geometry based on:

 - cell state
 - heatJ thermal bucket
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
        
        static let thermalBuckets = 64
        
        /*
         Visualization range only.
         
         These values are NOT physics limits.
         
         The actual maximum heat in the current lattice
         is measured dynamically during synchronization.
         */
        
        static let minimumVisibleHeatJ = 0.000001
        static let defaultMaximumVisibleHeatJ = 1_000_000.0
        
        static let coldRed: CGFloat = 0.05
        static let coldGreen: CGFloat = 0.15
        static let coldBlue: CGFloat = 1.00
        
        static let warmAlpha: CGFloat = 1.0
    }
    
    // MARK: - Coordinator
    
    struct GeometryKey: Hashable {
        
        let state: RadiatorCellState
        let bucket: Int
    }
    
    final class Coordinator {
        
        let latticeNode = SCNNode()
        
        var nodesByCellID: [Int: SCNNode] = [:]
        
        var geometryCache:
        [GeometryKey: SCNGeometry] = [:]
        
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
        
        scene.rootNode.addChildNode(
            cameraNode
        )
        
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
        
        /*
         Find the largest heatJ currently present.
         
         This makes the visualization adaptive to the
         actual thermal state instead of forcing all cells
         into a fixed 25–120 °C temperature range.
         */
        
        let maximumHeatJ =
        cells
            .filter {
                $0.state == .aluminum ||
                $0.state.isWater
            }
            .map {
                max(
                    $0.heatJ,
                    0.0
                )
            }
            .max()
        ?? 0.0
        
        /*
         Keep a useful minimum visualization range.
         
         This prevents a nearly cold lattice from producing
         an unusably compressed color range.
         */
        
        let visualizationMaximumHeatJ =
        max(
            maximumHeatJ,
            Style.defaultMaximumVisibleHeatJ
        )
        
        let center =
        Float(gridSize - 1) *
        cellSize /
        2.0
        
        for currentCell in cells {
            
            guard shouldRender(
                currentCell.state
            )
            else {
                
                coordinator
                    .nodesByCellID[currentCell.id]?
                    .isHidden = true
                
                continue
            }
            
            let node: SCNNode
            
            if let existing =
                coordinator.nodesByCellID[
                    currentCell.id
                ] {
                
                node = existing
                
            } else {
                
                node = SCNNode()
                
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
                
                coordinator.latticeNode.addChildNode(
                    node
                )
                
                coordinator.nodesByCellID[
                    currentCell.id
                ] = node
            }
            
            node.isHidden = false
            
            let geometry =
            sharedGeometry(
                for: currentCell,
                maximumHeatJ:
                    visualizationMaximumHeatJ,
                coordinator: coordinator
            )
            
            if node.geometry !== geometry {
                node.geometry = geometry
            }
        }
        
        /*
         If showAir changes, remove the previous cached
         air geometry so visibility/material changes are
         immediately reflected.
         */
        
        if coordinator.lastShowAir != showAir {
            coordinator.geometryCache.removeAll()
            coordinator.lastShowAir = showAir
        }
    }
    
    // MARK: - Render Filtering
    
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
        maximumHeatJ: Double,
        coordinator: Coordinator
    ) -> SCNGeometry {
        
        /*
         Every thermal material now uses heatJ.
         
         There is no temperatureC lookup here.
         */
        
        let bucket =
        heatBucket(
            heatJ: currentCell.heatJ,
            maximumHeatJ: maximumHeatJ
        )
        
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
            heatJ: currentCell.heatJ,
            maximumHeatJ: maximumHeatJ
        )
        
        coordinator.geometryCache[key] =
        sphere
        
        return sphere
    }
    
    // MARK: - HeatJ Bucket
    
    /*
     Converts heatJ directly into a logarithmic
     visualization bucket.
     
     This is deliberately NOT a temperature conversion.
     
     heatJ is the visualization input.
     */
    
    private func heatBucket(
        heatJ: Double,
        maximumHeatJ: Double
    ) -> Int {
        
        let heat =
        max(
            heatJ,
            0.0
        )
        
        guard heat > 0.0 else {
            return 0
        }
        
        let minimumHeatJ =
        Style.minimumVisibleHeatJ
        
        let maximumHeat =
        max(
            maximumHeatJ,
            minimumHeatJ
        )
        
        let clampedHeat =
        min(
            max(
                heat,
                minimumHeatJ
            ),
            maximumHeat
        )
        
        let logMinimum =
        log10(
            minimumHeatJ
        )
        
        let logMaximum =
        log10(
            maximumHeat
        )
        
        let logHeat =
        log10(
            clampedHeat
        )
        
        let normalized =
        (
            logHeat -
            logMinimum
        ) /
        max(
            logMaximum -
            logMinimum,
            1.0e-12
        )
        
        return Int(
            (
                normalized *
                Double(
                    Style.thermalBuckets - 1
                )
            )
            .rounded()
        )
    }
    
    // MARK: - Thermal Material
    
    private func material(
        for state: RadiatorCellState,
        heatJ: Double,
        maximumHeatJ: Double
    ) -> SCNMaterial {
        
        let material =
        SCNMaterial()
        
        material.lightingModel =
            .blinn
        
        switch state {
            
            // -------------------------------------------------
            // ALUMINUM
            // -------------------------------------------------
            
        case .aluminum:
            
            material.diffuse.contents =
            heatColor(
                heatJ: heatJ,
                maximumHeatJ: maximumHeatJ,
                alpha: 1.0
            )
            
            material.specular.contents =
            UIColor.white.withAlphaComponent(
                0.25
            )
            
            material.shininess = 0.35
            
            // -------------------------------------------------
            // WATER
            // -------------------------------------------------
            
        case .water:
            
            material.diffuse.contents =
            heatColor(
                heatJ: heatJ,
                maximumHeatJ: maximumHeatJ,
                alpha: 0.72
            )
            
            material.transparency =
            0.72
            
            material.specular.contents =
            UIColor.white.withAlphaComponent(
                0.40
            )
            
            material.shininess = 0.65
            
            // -------------------------------------------------
            // WATER INLET / OUTLET
            // -------------------------------------------------
            
        case .waterInlet,
                .waterOutlet:
            
            material.diffuse.contents =
            heatColor(
                heatJ: heatJ,
                maximumHeatJ: maximumHeatJ,
                alpha: 1.0
            )
            
            material.specular.contents =
            UIColor.white
            
            material.shininess = 0.8
            
            // -------------------------------------------------
            // AIR
            // -------------------------------------------------
            
        case .air:
            
            /*
             Air remains visually transparent.
             
             Its heatJ still participates in the thermal
             color system when an air cell is rendered.
             */
            
            material.diffuse.contents =
            heatColor(
                heatJ: heatJ,
                maximumHeatJ: maximumHeatJ,
                alpha: 0.18
            )
            
            material.transparency =
            0.82
            
            material.specular.contents =
            UIColor.white.withAlphaComponent(
                0.10
            )
            
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
            
            material.transparency =
            0.0
        }
        
        return material
    }
    
    // MARK: - HeatJ Color
    
    /*
     Converts heatJ directly to color.
     
     No temperatureC is used.
     
     The logarithmic scale allows a cell containing a
     small amount of thermal energy to remain visible
     while also displaying very large heat values.
     */
    
    private func heatColor(
        heatJ: Double,
        maximumHeatJ: Double,
        alpha: CGFloat
    ) -> UIColor {
        
        let heat =
        max(
            heatJ,
            0.0
        )
        
        guard heat > 0.0 else {
            
            return UIColor(
                red: Style.coldRed,
                green: Style.coldGreen,
                blue: Style.coldBlue,
                alpha: alpha
            )
        }
        
        let minimumHeatJ =
        Style.minimumVisibleHeatJ
        
        let maximumHeat =
        max(
            maximumHeatJ,
            minimumHeatJ
        )
        
        let clampedHeat =
        min(
            max(
                heat,
                minimumHeatJ
            ),
            maximumHeat
        )
        
        let logMinimum =
        log10(
            minimumHeatJ
        )
        
        let logMaximum =
        log10(
            maximumHeat
        )
        
        let logHeat =
        log10(
            clampedHeat
        )
        
        let normalized =
        min(
            1.0,
            max(
                0.0,
                (
                    logHeat -
                    logMinimum
                ) /
                max(
                    logMaximum -
                    logMinimum,
                    1.0e-12
                )
            )
        )
        
        /*
         Cold → cyan → green → yellow → orange → red
         */
        
        let stops:
        [(Double, CGFloat, CGFloat, CGFloat)] = [
            
            (0.00, 0.05, 0.15, 1.00),
            
            (0.20, 0.00, 0.85, 1.00),
            
            (0.40, 0.00, 1.00, 0.25),
            
            (0.60, 1.00, 1.00, 0.00),
            
            (0.80, 1.00, 0.35, 0.00),
            
            (1.00, 1.00, 0.00, 0.00)
        ]
        
        for index in
                0..<(stops.count - 1) {
            
            let lower =
            stops[index]
            
            let upper =
            stops[index + 1]
            
            guard normalized >= lower.0,
                  normalized <= upper.0
            else {
                continue
            }
            
            let range =
            upper.0 -
            lower.0
            
            let local =
            range > 0.0
            ? (
                normalized -
                lower.0
            ) / range
            : 0.0
            
            let red =
            lower.1 +
            (
                upper.1 -
                lower.1
            ) *
            CGFloat(local)
            
            let green =
            lower.2 +
            (
                upper.2 -
                lower.2
            ) *
            CGFloat(local)
            
            let blue =
            lower.3 +
            (
                upper.3 -
                lower.3
            ) *
            CGFloat(local)
            
            return UIColor(
                red: red,
                green: green,
                blue: blue,
                alpha: alpha
            )
        }
        
        return UIColor.red.withAlphaComponent(
            alpha
        )
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
    
    // MARK: - Camera
    
    private func makeCameraNode() -> SCNNode {
        
        let camera =
        SCNCamera()
        
        camera.fieldOfView =
        52
        
        camera.zNear =
        0.001
        
        camera.zFar =
        100
        
        let cameraNode =
        SCNNode()
        
        cameraNode.name =
        "mainCamera"
        
        cameraNode.camera =
        camera
        
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
