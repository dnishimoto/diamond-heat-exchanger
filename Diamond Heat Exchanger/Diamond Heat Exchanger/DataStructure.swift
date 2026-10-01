//
//  File.swift
//  Diamond Heat Exchanger
//
//  Created by David Nishimoto on 10/1/26.
//

import Foundation

// MARK: - Cell State

enum RadiatorCellState: String, CaseIterable, Identifiable {

    case empty
    case aluminum

    case water
    case waterInlet
    case waterOutlet

    case air
    case airInlet
    case airOutlet

    var id: String {
        rawValue
    }

    var isWater: Bool {
        self == .water ||
        self == .waterInlet ||
        self == .waterOutlet
    }

    var isAir: Bool {
        self == .air ||
        self == .airInlet ||
        self == .airOutlet
    }

    var isSolid: Bool {
        self == .aluminum
    }

    var isPort: Bool {
        self == .waterInlet ||
        self == .waterOutlet ||
        self == .airInlet ||
        self == .airOutlet
    }

    var isFlow: Bool {
        isWater || isAir
    }
}

// MARK: - Geometry

struct Point3D: Hashable {

    let x: Int
    let y: Int
    let z: Int
}

struct GridPoint: Hashable {

    let x: Int
    let y: Int
    let z: Int
}

// MARK: - Radiator Cell

struct RadiatorCell: Identifiable {

    let id: Int

    let x: Int
    let y: Int
    let z: Int

    var state: RadiatorCellState

    // MARK: Dynamic Thermal State

    var temperatureC: Double = 25.0

    /*
     Sensible thermal energy stored in this cell.

     For aluminum:
        heatJ = m * Cp * ΔT

     For water/air this represents the local
     thermal energy carried by the fluid voxel.
     */

    var heatJ: Double = 0.0

    // MARK: Hydraulic State

    /*
     Local flow magnitude.

     Units:
        m/s
     */

    var flow: Double = 0.0

    /*
     Local pressure.

     Units:
        Pa
     */

    var pressure: Double = 0.0

    // MARK: CA State

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

    // MARK: Geometry

    var aluminumVolumeM3: Double = 0.0

    var aluminumMassKg: Double = 0.0

    var aluminumSurfaceAreaM2: Double = 0.0

    // MARK: Flow

    var waterFlowM3S: Double = 0.0

    var airFlowM3S: Double = 0.0

    // MARK: Hydraulic Losses

    var waterPressureDropPa: Double = 0.0

    var airPressureDropPa: Double = 0.0

    var pumpPowerW: Double = 0.0

    var fanPowerW: Double = 0.0

    // MARK: Thermal Performance

    /*
     Instantaneous heat-transfer rate from
     aluminum into the air.

     Units:
         W
     */

    var heatRejectedW: Double = 0.0

    /*
     Same value expressed in megawatts.
     */

    var heatRejectedMW: Double = 0.0

    /*
     Cumulative thermal energy removed
     from the exchanger by the air.

     Maximum design target:
         1 GJ
     */

    var energyRemovedJ: Double = 0.0

    /*
     Projected time required to remove the
     complete 1 GJ datacenter load.

     Units:
         seconds
     */

    var removalTimeS: Double = 0.0

    /*
     Heat removed divided by auxiliary
     pump + fan power.

     Dimensionless ratio.
     */

    var thermalEfficiency: Double = 0.0

    /*
     Maximum temperature currently present
     in the thermal field.

     This should normally represent the
     hottest aluminum cell.
     */

    var maximumTemperatureC: Double = 25.0

    // MARK: Datacenter Load

    /*
     Total thermal energy supplied by
     the datacenter.

     Design value:
         1,000,000,000 J
         = 1 GJ
     */

    var datacenterHeatLoadJ: Double = 1_000_000_000.0

    /*
     Required average heat rejection rate
     to remove the datacenter load in the
     design time.

         1 GJ / 60 s
         = 16.67 MW
     */

    var requiredHeatRateW: Double = 0.0

    var requiredHeatRateMW: Double = 0.0

    // MARK: Water Thermal State

    /*
     Temperature of water entering the
     exchanger from the datacenter.

     This is calculated by the engine from:

         Q = m_dot * Cp * ΔT
     */

    var waterInletTemperatureC: Double = 25.0

    /*
     Temperature of water leaving the
     exchanger.
     */

    var waterOutletTemperatureC: Double = 25.0

    /*
     Temperature rise between water inlet
     and outlet.
     */

    var waterTemperatureRiseC: Double = 0.0

    // MARK: Air Thermal State

    var airInletTemperatureC: Double = 25.0

    var airOutletTemperatureC: Double = 25.0

    var airTemperatureRiseC: Double = 0.0

    // MARK: Energy Accounting

    /*
     Thermal energy injected into the water
     from the datacenter.
     */

    var datacenterEnergyInjectedJ: Double = 0.0

    /*
     Thermal energy transferred from aluminum
     into the air.
     */

    var airEnergyRemovedJ: Double = 0.0

    /*
     Thermal energy transferred from water
     into aluminum.
     */

    var waterToAluminumEnergyJ: Double = 0.0

    // MARK: CA / Geometry Validation

    var waterConnected: Bool = false

    var airConnected: Bool = false

    var channelsOverlap: Bool = false

    var printable: Bool = false

    // MARK: Optimization

    var fitness: Double = 0.0
}
