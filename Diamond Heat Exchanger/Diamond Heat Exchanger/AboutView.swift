//
//  AboutView.swift
//  Diamond Heat Exchanger
//
//  Created by David Nishimoto on 10/3/26.
//

import Foundation
import SwiftUI

struct AboutView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - Introduction

                    section(
                        title: "What This App Demonstrates",
                        icon: "cube.transparent"
                    ) {
                        paragraph("""
                        This app demonstrates how a computer can create and test a three-dimensional aluminum heat exchanger using a cellular automaton. Instead of starting with a finished radiator and only measuring it, the cellular automaton builds the structure from many small cells and changes the structure as the simulation runs.
                        """)
                    }

                    // MARK: - Heat Problem

                    section(
                        title: "The Heat Problem",
                        icon: "flame.fill"
                    ) {
                        paragraph("""
                        The system is designed around a total thermal load of 1 gigajoule, which is 1,000,000,000 joules of heat. The goal is to move this heat from hot water into moving air. If 1 gigajoule were removed in 60 seconds, the required average heat-removal rate would be about 16.67 megawatts. The simulation measures the heat removed by the radiator and uses that result to determine how long the full 1 gigajoule would take to remove.
                        """)
                    }

                    // MARK: - Heat Path

                    section(
                        title: "How the Heat Moves",
                        icon: "arrow.right"
                    ) {
                        paragraph("""
                        The heat follows a simple path through the system. Hot water enters the radiator carrying thermal energy. That heat moves from the water into the aluminum structure. Moving air then removes heat from the aluminum and carries it away. The aluminum acts as the connection between the hot water and the cooling air.
                        """)
                    }

                    // MARK: - CA

                    section(
                        title: "How the Cellular Automaton Works",
                        icon: "square.grid.3x3.fill"
                    ) {
                        paragraph("""
                        The radiator is divided into many small three-dimensional cells. These cells can become part of the aluminum structure or part of a water or air flow region. The cellular automaton applies rules to the cells and changes the structure over a series of generations. After each generation, the resulting structure can be evaluated again. This allows the radiator geometry to evolve instead of being fixed from the beginning.
                        """)
                    }

                    // MARK: - Flow

                    section(
                        title: "Water and Air Flow",
                        icon: "wind"
                    ) {
                        paragraph("""
                        Water and air must have separate paths through the radiator. Water needs a connected path from its inlet to its outlet, while air needs a connected path from its inlet to its outlet. The aluminum structure must provide enough material for heat transfer without blocking these required flow paths. The cellular automaton therefore has to balance aluminum, water space, and air space throughout the three-dimensional structure.
                        """)
                    }

                    // MARK: - Diamond

                    section(
                        title: "The Diamond Structure",
                        icon: "diamond.fill"
                    ) {
                        paragraph("""
                        The radiator uses a three-dimensional diamond-style lattice. The purpose of the structure is to provide a large amount of aluminum surface while leaving open regions for water and air to move through. A structure that is too dense can provide more material for heat transfer but can also make fluid movement more difficult. A structure that is too open can reduce flow resistance but may provide less surface for transferring heat. The simulation therefore looks for a useful balance between heat transfer and fluid movement.
                        """)
                    }

                    // MARK: - Energy

                    section(
                        title: "Energy Used by the System",
                        icon: "bolt.fill"
                    ) {
                        paragraph("""
                        Moving water and air through the radiator requires energy. The simulation evaluates the resistance to water and air movement and estimates the power required by the pump and fan. This makes it possible to look at the radiator as a complete system rather than looking only at how much heat it can remove.
                        """)
                    }

                    // MARK: - Heat Transfer

                    section(
                        title: "Heat Transfer",
                        icon: "thermometer.medium"
                    ) {
                        paragraph("""
                        The simulation follows thermal energy through the radiator. Heat enters with the hot water, moves into the aluminum, and is transferred from the aluminum to the air. The amount of heat removed is used to calculate the radiator's heat-removal performance. The simulation also monitors temperature so the structure can be checked against the allowed temperature limit.
                        """)
                    }

                    // MARK: - Evolution

                    section(
                        title: "How the Design Evolves",
                        icon: "arrow.triangle.2.circlepath"
                    ) {
                        paragraph("""
                        The design process is repeated over multiple generations. The computer creates a structure, evaluates its heat transfer and flow behavior, checks its required connections, and then continues evolving the structure. Each generation is another step in the search for a radiator that can transfer heat while maintaining usable water and air paths and a printable aluminum structure.
                        """)
                    }

                    // MARK: - Printable

                    section(
                        title: "Printable Structure",
                        icon: "printer.fill"
                    ) {
                        paragraph("""
                        The simulation also checks whether the aluminum structure can form a connected printable structure. Aluminum that is isolated from the build platform cannot simply be treated as a valid part of the radiator. The printable check therefore verifies the required aluminum support while allowing the water and air regions to remain open.
                        """)
                    }

                    // MARK: - Results

                    section(
                        title: "What the Simulation Measures",
                        icon: "chart.bar.xaxis"
                    ) {
                        paragraph("""
                        The simulation reports the characteristics of the resulting radiator, including aluminum amount and mass, heat-transfer surface area, water and air flow, pressure loss, pump power, fan power, maximum temperature, heat removed, and the estimated time required to remove 1 gigajoule. It also checks whether the water path, air path, and printable structure satisfy the required conditions.
                        """)
                    }

                    // MARK: - Main Idea

                    section(
                        title: "The Main Idea",
                        icon: "lightbulb.fill"
                    ) {
                        paragraph("""
                        The main idea is to let the computer create the heat exchanger instead of simply analyzing a radiator that was designed beforehand. The cellular automaton changes the three-dimensional structure while the simulation evaluates heat transfer, fluid movement, energy use, connectivity, temperature, and printability. The result is a computer-generated candidate radiator that can be examined as one complete thermal and flow system.
                        """)
                    }

                    // MARK: - Important Note

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Simulation Note")
                            .font(.headline)

                        Text("""
                        The results are computational results. Their accuracy depends on the physical models, assumptions, and parameters used by the simulation. The simulation demonstrates the design process and provides calculated results; it does not by itself replace physical testing of a manufactured radiator.
                        """)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color.black)
            .foregroundStyle(.white)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Section

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.cyan)
                    .frame(width: 28)

                Text(title)
                    .font(.title3.bold())
            }

            content()
        }
    }

    // MARK: - Paragraph

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.secondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}
