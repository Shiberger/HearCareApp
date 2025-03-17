//
//  AudiogramChartView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI
import Charts

struct AudiogramChartView: View {
    let rightEarData: [FrequencyDataPoint]
    let leftEarData: [FrequencyDataPoint]
    
    // Define hearing loss ranges for the background coloring
    private let normalHearingRange = -10..<25
    private let mildLossRange = 25..<40
    private let moderateLossRange = 40..<55
    private let moderatelySevereLossRange = 55..<70
    private let severeLossRange = 70..<90
    private let profoundLossRange = 90..<120
    
    // Define ordered frequencies for X-axis (in clinical order)
    private let orderedFrequencies = ["500", "1k", "2k", "4k", "8k"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pure Tone Audiogram")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            chartContent
                .frame(height: 400)
            
            legendView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var chartContent: some View {
        Chart {
            // Background ranges to indicate hearing loss severity
            RectangleMark(
                xStart: .value("Frequency", orderedFrequencies.first!),
                xEnd: .value("Frequency", orderedFrequencies.last!),
                yStart: .value("Level", normalHearingRange.lowerBound),
                yEnd: .value("Level", normalHearingRange.upperBound)
            )
            .foregroundStyle(Color.green.opacity(0.1))
            
            RectangleMark(
                xStart: .value("Frequency", orderedFrequencies.first!),
                xEnd: .value("Frequency", orderedFrequencies.last!),
                yStart: .value("Level", mildLossRange.lowerBound),
                yEnd: .value("Level", mildLossRange.upperBound)
            )
            .foregroundStyle(Color.yellow.opacity(0.1))
            
            RectangleMark(
                xStart: .value("Frequency", orderedFrequencies.first!),
                xEnd: .value("Frequency", orderedFrequencies.last!),
                yStart: .value("Level", moderateLossRange.lowerBound),
                yEnd: .value("Level", moderateLossRange.upperBound)
            )
            .foregroundStyle(Color.orange.opacity(0.1))
            
            RectangleMark(
                xStart: .value("Frequency", orderedFrequencies.first!),
                xEnd: .value("Frequency", orderedFrequencies.last!),
                yStart: .value("Level", moderatelySevereLossRange.lowerBound),
                yEnd: .value("Level", moderatelySevereLossRange.upperBound)
            )
            .foregroundStyle(Color.orange.opacity(0.2))
            
            RectangleMark(
                xStart: .value("Frequency", orderedFrequencies.first!),
                xEnd: .value("Frequency", orderedFrequencies.last!),
                yStart: .value("Level", severeLossRange.lowerBound),
                yEnd: .value("Level", severeLossRange.upperBound)
            )
            .foregroundStyle(Color.red.opacity(0.1))
            
            RectangleMark(
                xStart: .value("Frequency", orderedFrequencies.first!),
                xEnd: .value("Frequency", orderedFrequencies.last!),
                yStart: .value("Level", profoundLossRange.lowerBound),
                yEnd: .value("Level", profoundLossRange.upperBound)
            )
            .foregroundStyle(Color.purple.opacity(0.1))
            
            // Right ear data with circles - sort and normalize frequency labels
            ForEach(filteredRightEarData) { point in
                LineMark(
                    x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                    y: .value("Hearing Level", point.hearingLevel)
                )
                .foregroundStyle(.red)
                .interpolationMethod(.linear)
            }
            
            ForEach(filteredRightEarData) { point in
                PointMark(
                    x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                    y: .value("Hearing Level", point.hearingLevel)
                )
                .foregroundStyle(.red)
                .symbol(.circle)
                .symbolSize(100)
            }
            
            // Left ear data with X's - sort and normalize frequency labels
            ForEach(filteredLeftEarData) { point in
                LineMark(
                    x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                    y: .value("Hearing Level", point.hearingLevel)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.linear)
            }
            
            ForEach(filteredLeftEarData) { point in
                PointMark(
                    x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                    y: .value("Hearing Level", point.hearingLevel)
                )
                .foregroundStyle(.blue)
                .symbol(.cross)
                .symbolSize(100)
            }
        }
        // Most critical part: set Y-axis scale from -10 to 120 with -10 at top
        .chartYScale(domain: -10...120)
        .chartYAxis {
            AxisMarks(position: .leading, values: [-10, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                    }
                }
            }
        }
        // Critical: Use orderedFrequencies array to ensure correct X-axis order
        .chartXAxis {
            AxisMarks(values: orderedFrequencies) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                AxisValueLabel()
            }
        }
        .chartXScale(domain: orderedFrequencies)
        .chartYAxisLabel("Hearing Level (dB)")
        .chartXAxisLabel("Frequency (Hz)")
    }
    
    // Filter out data points for frequencies not in our ordered list
    private var filteredRightEarData: [FrequencyDataPoint] {
        return rightEarData
            .filter { isFrequencyInOrderedList(standardizeFrequencyLabel($0.frequencyLabel)) }
            .sorted { frequencyOrder($0.frequencyLabel) < frequencyOrder($1.frequencyLabel) }
    }
    
    private var filteredLeftEarData: [FrequencyDataPoint] {
        return leftEarData
            .filter { isFrequencyInOrderedList(standardizeFrequencyLabel($0.frequencyLabel)) }
            .sorted { frequencyOrder($0.frequencyLabel) < frequencyOrder($1.frequencyLabel) }
    }
    
    // Helper function to check if a frequency is in our ordered list
    private func isFrequencyInOrderedList(_ frequency: String) -> Bool {
        return orderedFrequencies.contains(frequency)
    }
    
    // Helper function to convert any frequency label format to our standard format
    private func standardizeFrequencyLabel(_ label: String) -> String {
        if label.contains("500") { return "500" }
        if label.contains("1000") || label.contains("1k") { return "1k" }
        if label.contains("2000") || label.contains("2k") { return "2k" }
        if label.contains("4000") || label.contains("4k") { return "4k" }
        if label.contains("8000") || label.contains("8k") { return "8k" }
        return label // fallback
    }
    
    // Helper function to determine the order of frequency labels
    private func frequencyOrder(_ label: String) -> Int {
        let standardLabel = standardizeFrequencyLabel(label)
        if let index = orderedFrequencies.firstIndex(of: standardLabel) {
            return index
        }
        return orderedFrequencies.count // Put any unknown values at the end
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 20) {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Right Ear")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("×")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Left Ear")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Hearing Loss Ranges:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                    GridRow {
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("Normal (-10-25 dB)")
                            .font(.caption)
                        
                        Rectangle()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("Mild (25-40 dB)")
                            .font(.caption)
                    }
                    
                    GridRow {
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("Moderate (40-55 dB)")
                            .font(.caption)
                        
                        Rectangle()
                            .fill(Color.orange.opacity(0.4))
                            .frame(width: 12, height: 12)
                        Text("Mod-Severe (55-70 dB)")
                            .font(.caption)
                    }
                    
                    GridRow {
                        Rectangle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("Severe (70-90 dB)")
                            .font(.caption)
                        
                        Rectangle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("Profound (90+ dB)")
                            .font(.caption)
                    }
                }
            }
        }
    }
}
