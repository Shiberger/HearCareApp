//
//  HearingHealthProfileView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 18/3/2568 BE.
//

import SwiftUI
import Charts

struct HearingHealthProfileView: View {
    @StateObject private var viewModel = HearingHealthProfileViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.testResults.isEmpty {
                    emptyStateView
                } else {
                    hearingProfileContent
                }
            }
            .padding(.vertical, AppTheme.Spacing.large)
        }
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Hearing Health Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your hearing profile...")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, AppTheme.Spacing.medium)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "ear.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor.opacity(0.5))
            
            Text("No Hearing Data Available")
                .font(AppTheme.Typography.title3)
            
            Text("Complete your first hearing test to generate your hearing health profile.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 20)
            
            NavigationLink(destination: HearingTestView()) {
                Text("Take a Hearing Test")
                    .primaryButton()
                    .padding(.horizontal, 40)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var hearingProfileContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Overall Hearing Health Summary
            InfoCard(title: "Hearing Health Summary", icon: "waveform.path.ecg") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Overall Status")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(viewModel.overallStatus.title)
                                .font(AppTheme.Typography.title3)
                                .foregroundColor(viewModel.overallStatus.color)
                        }
                        
                        Spacer()
                        
                        CircularProgressView(progress: viewModel.overallStatus.score / 100,
                                            color: viewModel.overallStatus.color,
                                            lineWidth: 8)
                            .frame(width: 60, height: 60)
                    }
                    
                    Divider()
                    
                    Text(viewModel.overallStatus.description)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            
            // Ear-specific summary
            InfoCard(title: "Ear Summary", icon: "ear.fill") {
                HStack(spacing: AppTheme.Spacing.large) {
                    // Left ear
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Text("Left Ear")
                                .font(AppTheme.Typography.headline)
                        }
                        
                        Text(viewModel.leftEarStatus)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(colorForClassification(viewModel.leftEarStatus))
                        
                        Text("Last: \(viewModel.latestLeftEarReading) dB")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(Color.white)
                    )
                    
                    // Right ear
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text("Right Ear")
                                .font(AppTheme.Typography.headline)
                        }
                        
                        Text(viewModel.rightEarStatus)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(colorForClassification(viewModel.rightEarStatus))
                        
                        Text("Last: \(viewModel.latestRightEarReading) dB")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(Color.white)
                    )
                }
            }
            
            // Trend analysis
            InfoCard(title: "Hearing Trend Analysis", icon: "chart.line.uptrend.xyaxis") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    if viewModel.hasTrendData {
                        Picker("Frequency", selection: $viewModel.selectedFrequency) {
                            ForEach(viewModel.frequencies, id: \.self) { frequency in
                                Text("\(frequency) Hz").tag(frequency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.bottom, AppTheme.Spacing.small)
                        
                        trendChart
                            .frame(height: 200)
                        
                        Text(viewModel.trendAnalysis)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text("Not enough data to show trends. Complete more hearing tests to see your hearing trends over time.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            
            // Frequency breakdown
            InfoCard(title: "Frequency Response", icon: "waveform") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Your hearing sensitivity at different frequencies:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    frequencyChart
                        .frame(height: 200)
                    
                    frequencyBreakdownText
                }
            }
            
            // AI Analysis
            InfoCard(title: "AI Health Insights", icon: "brain") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    ForEach(viewModel.aiInsights.indices, id: \.self) { index in
                        insightRow(insight: viewModel.aiInsights[index])
                        
                        if index < viewModel.aiInsights.count - 1 {
                            Divider()
                            .padding(.vertical, 4)
                        }
                    }
                    
                    if viewModel.aiInsights.isEmpty {
                        Text("Complete more hearing tests to unlock AI-powered insights about your hearing health.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            
            // Recommendations
            InfoCard(title: "Recommendations", icon: "lightbulb.fill") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    ForEach(viewModel.recommendations.indices, id: \.self) { index in
                        recommendationRow(number: index + 1, text: viewModel.recommendations[index])
                        
                        if index < viewModel.recommendations.count - 1 {
                            Divider()
                        }
                    }
                    
                    Button(action: {
                        // Schedule follow-up
                    }) {
                        HStack {
                            Spacer()
                            Text("Schedule Professional Follow-up")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.primaryColor)
                            Spacer()
                        }
                    }
                    .padding(.top, AppTheme.Spacing.small)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var trendChart: some View {
        Chart {
            ForEach(viewModel.getFilteredTrendData(), id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Level", dataPoint.level)
                )
                .foregroundStyle(dataPoint.ear == .left ? Color.blue : Color.red)
                
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Level", dataPoint.level)
                )
                .foregroundStyle(dataPoint.ear == .left ? Color.blue : Color.red)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(dateFormatter.string(from: date))
                            .font(.caption)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let level = value.as(Float.self) {
                        Text("\(Int(level)) dB")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: [0, 100])
        .padding(.trailing, 20)
    }
    
    private var frequencyChart: some View {
        Chart {
            ForEach(viewModel.frequencyResponse, id: \.frequency) { point in
                BarMark(
                    x: .value("Frequency", "\(point.frequency) Hz"),
                    y: .value("Response", point.level)
                )
                .foregroundStyle(
                    colorForLevel(point.level).opacity(0.7)
                )
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                if let level = value.as(Int.self) {
                    AxisGridLine()
                    AxisValueLabel {
                        Text("\(level) dB")
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: [0, 100])
    }
    
    private var frequencyBreakdownText: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Low Frequencies (500-1000 Hz)")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(viewModel.lowFrequencyStatus.color)
            Text(viewModel.lowFrequencyStatus.description)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Mid Frequencies (1000-4000 Hz)")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(viewModel.midFrequencyStatus.color)
                .padding(.top, 4)
            Text(viewModel.midFrequencyStatus.description)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("High Frequencies (4000-8000 Hz)")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(viewModel.highFrequencyStatus.color)
                .padding(.top, 4)
            Text(viewModel.highFrequencyStatus.description)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
    
    private func insightRow(insight: HearingHealthProfileViewModel.AIInsight) -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: insight.icon)
                .font(.system(size: 24))
                .foregroundColor(insight.color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(insight.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(AppTheme.Typography.headline)
                
                Text(insight.description)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
    
    private func recommendationRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(number)")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.primaryColor))
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
    }
    
    private func colorForClassification(_ classification: String) -> Color {
        switch classification {
        case "Normal Hearing":
            return .green
        case "Mild Hearing Loss":
            return .blue
        case "Moderate Hearing Loss":
            return .orange
        case "Moderately Severe Hearing Loss":
            return .orange
        case "Severe Hearing Loss":
            return .red
        case "Profound Hearing Loss":
            return .red
        default:
            return .gray
        }
    }
    
    private func colorForLevel(_ level: Float) -> Color {
        switch level {
        case 0..<25:
            return .green
        case 25..<40:
            return .yellow
        case 40..<55:
            return .orange
        case 55..<70:
            return .orange
        case 70..<90:
            return .red
        default:
            return .purple
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            Text("\(Int(progress * 100))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
    }
}

#Preview {
    NavigationView {
        HearingHealthProfileView()
    }
}
