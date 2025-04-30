//
//  AudiogramChartView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//  Updated with correct symbol types

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
    
    // Define standard clinical audiogram symbols
    private let rightCircleSize: CGFloat = 40  // Red circle (right ear, air conduction)
    private let leftXSize: CGFloat = 50        // Blue X (left ear, air conduction)
    private let lineWidth: CGFloat = 2.5       // Line width for connecting marks
    
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
    
    // MARK: - Chart Content
    private var chartContent: some View {
        Chart {
            // Add background zones
            addBackgroundZones()
            
            // Add right ear data
            addRightEarData()
            
            // Add left ear data
            addLeftEarData()
            
            // Add no response markers
            addNoResponseMarkers()
        }
        // Critical: set Y-axis scale with proper domain and inversion for audiogram
        .chartYScale(domain: -10...120)
        .chartYAxis {
            AxisMarks(position: .leading, values: [-10, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                AxisTick(length: 5, stroke: StrokeStyle(lineWidth: 1))
            }
        }
        // Use ordered frequencies array for X-axis for consistent presentation
        .chartXAxis {
            AxisMarks(values: orderedFrequencies) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                AxisTick(length: 5, stroke: StrokeStyle(lineWidth: 1))
            }
        }
        .chartXScale(domain: orderedFrequencies)
        .chartYAxisLabel("Hearing Level (dB HL)")
        .chartXAxisLabel("Frequency (Hz)")
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
    
    // MARK: - Chart Components
    @ChartContentBuilder
    private func addBackgroundZones() -> some ChartContent {
        // Normal hearing zone
        RectangleMark(
            xStart: .value("Frequency", orderedFrequencies.first!),
            xEnd: .value("Frequency", orderedFrequencies.last!),
            yStart: .value("Level", normalHearingRange.lowerBound),
            yEnd: .value("Level", normalHearingRange.upperBound)
        )
        .foregroundStyle(Color.green.opacity(0.1))
        
        // Mild loss zone
        RectangleMark(
            xStart: .value("Frequency", orderedFrequencies.first!),
            xEnd: .value("Frequency", orderedFrequencies.last!),
            yStart: .value("Level", mildLossRange.lowerBound),
            yEnd: .value("Level", mildLossRange.upperBound)
        )
        .foregroundStyle(Color.yellow.opacity(0.1))
        
        // Moderate loss zone
        RectangleMark(
            xStart: .value("Frequency", orderedFrequencies.first!),
            xEnd: .value("Frequency", orderedFrequencies.last!),
            yStart: .value("Level", moderateLossRange.lowerBound),
            yEnd: .value("Level", moderateLossRange.upperBound)
        )
        .foregroundStyle(Color.orange.opacity(0.1))
        
        // Moderately severe loss zone
        RectangleMark(
            xStart: .value("Frequency", orderedFrequencies.first!),
            xEnd: .value("Frequency", orderedFrequencies.last!),
            yStart: .value("Level", moderatelySevereLossRange.lowerBound),
            yEnd: .value("Level", moderatelySevereLossRange.upperBound)
        )
        .foregroundStyle(Color.orange.opacity(0.2))
        
        // Severe loss zone
        RectangleMark(
            xStart: .value("Frequency", orderedFrequencies.first!),
            xEnd: .value("Frequency", orderedFrequencies.last!),
            yStart: .value("Level", severeLossRange.lowerBound),
            yEnd: .value("Level", severeLossRange.upperBound)
        )
        .foregroundStyle(Color.red.opacity(0.1))
        
        // Profound loss zone
        RectangleMark(
            xStart: .value("Frequency", orderedFrequencies.first!),
            xEnd: .value("Frequency", orderedFrequencies.last!),
            yStart: .value("Level", profoundLossRange.lowerBound),
            yEnd: .value("Level", profoundLossRange.upperBound)
        )
        .foregroundStyle(Color.purple.opacity(0.1))
    }
    
    @ChartContentBuilder
    private func addRightEarData() -> some ChartContent {
        // Right ear lines
        ForEach(0..<pairCount(for: filteredRightEarData), id: \.self) { index in
            let point1 = filteredRightEarData[index]
            let point2 = filteredRightEarData[index + 1]
            
            let x1 = standardizeFrequencyLabel(point1.frequencyLabel)
            let y1 = point1.hearingLevel
            let x2 = standardizeFrequencyLabel(point2.frequencyLabel)
            let y2 = point2.hearingLevel
            
            // Create line segment between adjacent points
            LineMark(
                x: .value("Frequency", x1),
                y: .value("Hearing Level", y1)
            )
            .foregroundStyle(.red)
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            
            LineMark(
                x: .value("Frequency", x2),
                y: .value("Hearing Level", y2)
            )
            .foregroundStyle(.red)
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
        }
        
        // Right ear points
        ForEach(filteredRightEarData) { point in
            PointMark(
                x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                y: .value("Hearing Level", point.hearingLevel)
            )
            .foregroundStyle(.red)
            .symbol(.circle)
            .symbolSize(rightCircleSize)
        }
    }
    
    @ChartContentBuilder
    private func addLeftEarData() -> some ChartContent {
        // Left ear lines
        ForEach(0..<pairCount(for: filteredLeftEarData), id: \.self) { index in
            let point1 = filteredLeftEarData[index]
            let point2 = filteredLeftEarData[index + 1]
            
            let x1 = standardizeFrequencyLabel(point1.frequencyLabel)
            let y1 = point1.hearingLevel
            let x2 = standardizeFrequencyLabel(point2.frequencyLabel)
            let y2 = point2.hearingLevel
            
            // Create line segment between adjacent points
            LineMark(
                x: .value("Frequency", x1),
                y: .value("Hearing Level", y1)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            
            LineMark(
                x: .value("Frequency", x2),
                y: .value("Hearing Level", y2)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
        }
        
        // Left ear points
        ForEach(filteredLeftEarData) { point in
            PointMark(
                x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                y: .value("Hearing Level", point.hearingLevel)
            )
            .foregroundStyle(.blue)
            .symbol(.cross)
            .symbolSize(leftXSize)
        }
    }
    
    @ChartContentBuilder
    private func addNoResponseMarkers() -> some ChartContent {
        // Right ear no response markers
        let rightNoResponsePoints = filteredRightEarData.filter { $0.hearingLevel >= 100 }
        ForEach(rightNoResponsePoints) { point in
            PointMark(
                x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                y: .value("Hearing Level", 120)
            )
            .foregroundStyle(.red)
            .symbol(.triangle)  // Changed from .arrow.down to .triangle
            .symbolSize(40)
        }
        
        // Left ear no response markers
        let leftNoResponsePoints = filteredLeftEarData.filter { $0.hearingLevel >= 100 }
        ForEach(leftNoResponsePoints) { point in
            PointMark(
                x: .value("Frequency", standardizeFrequencyLabel(point.frequencyLabel)),
                y: .value("Hearing Level", 120)
            )
            .foregroundStyle(.blue)
            .symbol(.triangle)  // Changed from .arrow.down to .triangle
            .symbolSize(40)
        }
    }
    
    // MARK: - Helper Functions
    // Helper to get count of pairs for line segments
    private func pairCount(for data: [FrequencyDataPoint]) -> Int {
        max(0, data.count - 1)
    }
    
    // Filter and process data points for right ear
    private var filteredRightEarData: [FrequencyDataPoint] {
        return processFrequencyData(rightEarData)
    }
    
    // Filter and process data points for left ear
    private var filteredLeftEarData: [FrequencyDataPoint] {
        return processFrequencyData(leftEarData)
    }
    
    // Common processing for both ears' data points
    private func processFrequencyData(_ data: [FrequencyDataPoint]) -> [FrequencyDataPoint] {
        // First step: Map and standardize labels
        let standardizedData = data.map { dataPoint in
            // Create a copy with standardized frequency label if needed
            var newPoint = dataPoint
            if standardizeFrequencyLabel(dataPoint.frequencyLabel) != dataPoint.frequencyLabel {
                newPoint = FrequencyDataPoint(
                    frequency: dataPoint.frequency,
                    hearingLevel: dataPoint.hearingLevel
                )
            }
            return newPoint
        }
        
        // Second step: Filter to include only frequencies in our ordered list
        let filteredData = standardizedData.filter {
            isFrequencyInOrderedList(standardizeFrequencyLabel($0.frequencyLabel))
        }
        
        // Third step: Sort by frequency order
        let sortedData = filteredData.sorted {
            frequencyOrder($0.frequencyLabel) < frequencyOrder($1.frequencyLabel)
        }
        
        return sortedData
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
    
    // MARK: - Legend
    // Enhanced legend with clearer clinical symbols and descriptions
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Symbols row
            HStack(spacing: 24) {
                // Right ear legend
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Right Ear (O)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Left ear legend
                HStack(spacing: 8) {
                    Image(systemName: "multiply")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(width: 12, height: 12)
                    Text("Left Ear (X)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // No response legend - updated to match the triangle symbol
                HStack(spacing: 8) {
                    Image(systemName: "triangle.fill")  // Changed to match the symbol used in the chart
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12, height: 12)
                    Text("No Response")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            Divider()
                .padding(.vertical, 5)
            
            // Classification legend
            hearingLossLegend
            
            // Note about clinical conventions
            Text("Note: This audiogram follows standard clinical conventions with better hearing shown at the top and worse hearing at the bottom.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    // Split out the hearing loss legend into its own view
    private var hearingLossLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hearing Loss Classification:")
                .font(.caption)
                .fontWeight(.medium)
            
            // First row of classification
            HStack(spacing: 10) {
                // Normal hearing
                legendItem(
                    color: Color.green.opacity(0.3),
                    text: "Normal (-10 to 25 dB)"
                )
                
                Spacer()
                
                // Mild loss
                legendItem(
                    color: Color.yellow.opacity(0.3),
                    text: "Mild (25 to 40 dB)"
                )
            }
            
            // Second row of classification
            HStack(spacing: 10) {
                // Moderate loss
                legendItem(
                    color: Color.orange.opacity(0.3),
                    text: "Moderate (40 to 55 dB)"
                )
                
                Spacer()
                
                // Moderately severe loss
                legendItem(
                    color: Color.orange.opacity(0.4),
                    text: "Mod-Severe (55 to 70 dB)"
                )
            }
            
            // Third row of classification
            HStack(spacing: 10) {
                // Severe loss
                legendItem(
                    color: Color.red.opacity(0.3),
                    text: "Severe (70 to 90 dB)"
                )
                
                Spacer()
                
                // Profound loss
                legendItem(
                    color: Color.purple.opacity(0.3),
                    text: "Profound (>90 dB)"
                )
            }
        }
    }
    
    // Helper for legend item
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.caption)
        }
    }
}

// Preview provider for SwiftUI canvas
struct AudiogramChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let rightEarData = [
            FrequencyDataPoint(frequency: 500, hearingLevel: 20),
            FrequencyDataPoint(frequency: 1000, hearingLevel: 25),
            FrequencyDataPoint(frequency: 2000, hearingLevel: 40),
            FrequencyDataPoint(frequency: 4000, hearingLevel: 65),
            FrequencyDataPoint(frequency: 8000, hearingLevel: 75)
        ]
        
        let leftEarData = [
            FrequencyDataPoint(frequency: 500, hearingLevel: 15),
            FrequencyDataPoint(frequency: 1000, hearingLevel: 20),
            FrequencyDataPoint(frequency: 2000, hearingLevel: 35),
            FrequencyDataPoint(frequency: 4000, hearingLevel: 55),
            FrequencyDataPoint(frequency: 8000, hearingLevel: 110) // No response example
        ]
        
        AudiogramChartView(rightEarData: rightEarData, leftEarData: leftEarData)
            .frame(height: 500)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
