//HearingHealthProfileView ใหม่

//  HearingHealthProfileView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 18/3/2568 BE.
//
import SwiftUI
import Charts

struct HearingHealthProfileView: View {
    @StateObject private var viewModel = HearingHealthProfileViewModel()
    
    // MARK: - Color Scheme (Pastel)
    private let pastelBlue = Color(red: 0.7, green: 0.85, blue: 0.95)
    private let pastelGreen = Color(red: 0.8, green: 0.95, blue: 0.8)
    private let pastelYellow = Color(red: 1.0, green: 0.95, blue: 0.75)
    private let pastelPurple = Color(red: 0.85, green: 0.8, blue: 0.95)
    private let cardBackground = Color.white
    
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
        .background(
            LinearGradient(
                gradient: Gradient(colors: [pastelBlue.opacity(0.5), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Hearing Health Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        viewModel.refreshData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppTheme.primaryColor)
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            ZStack {
                Circle()
                    .fill(pastelBlue.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                ProgressView()
                    .scaleEffect(2)
                    .tint(AppTheme.primaryColor)
            }
            
            Text("Loading your hearing profile...")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, AppTheme.Spacing.medium)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(pastelBlue.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "ear.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.primaryColor)
            }
            .padding(.top, 20)
            
            Text("No Hearing Data Available")
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)
            
            Text("Complete your first hearing test to generate your hearing health profile.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 20)
            
            NavigationLink(destination: HearingTestView()) {
                HStack {
                    Image(systemName: "waveform")
                        .font(.system(size: 18))
                    Text("Take a Hearing Test")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 220, minHeight: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(color: AppTheme.primaryColor.opacity(0.4), radius: 5, x: 0, y: 3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    // MARK: - Main Content
    private var hearingProfileContent: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Overall Hearing Health Summary
            enhancedInfoCard(
                title: "Hearing Health Summary",
                icon: "waveform.path.ecg",
                color: pastelBlue
            ) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Overall Status")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(viewModel.overallStatus.title)
                                .font(AppTheme.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.overallStatus.color)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            EnhancedCircularProgressView(
                                progress: viewModel.overallStatus.score / 100,
                                color: viewModel.overallStatus.color,
                                lineWidth: 10
                            )
                            .frame(width: 70, height: 70)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                        .background(Color.clear)
                    
                    Text(viewModel.overallStatus.description)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Ear-specific summary
            enhancedInfoCard(
                title: "Ear Summary",
                icon: "ear.fill",
                color: pastelGreen
            ) {
                HStack(spacing: AppTheme.Spacing.large) {
                    // Left ear
                    earSummaryCard(
                        ear: "Left Ear",
                        color: .blue,
                        status: viewModel.leftEarStatus,
                        reading: viewModel.latestLeftEarReading
                    )
                    
                    // Right ear
                    earSummaryCard(
                        ear: "Right Ear",
                        color: .red,
                        status: viewModel.rightEarStatus,
                        reading: viewModel.latestRightEarReading
                    )
                }
            }
            
            // Trend analysis
            enhancedInfoCard(
                title: "Hearing Trend Analysis",
                icon: "chart.line.uptrend.xyaxis",
                color: pastelYellow
            ) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    if viewModel.hasTrendData {
                        Text("Select Frequency:")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.bottom, -5)
                        
                        enhancedPicker
                            .padding(.bottom, 5)
                        
                        enhancedTrendChart
                            .frame(height: 220)
                            .padding(.top, 5)
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 10, height: 10)
                            Text("Left Ear")
                                .font(AppTheme.Typography.caption)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .padding(.leading, 8)
                            Text("Right Ear")
                                .font(AppTheme.Typography.caption)
                        }
                        .padding(.top, -5)
                        
                        Text(viewModel.trendAnalysis)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.top, 5)
                    } else {
                        noTrendDataView
                    }
                }
            }
            
            // Frequency breakdown
            enhancedInfoCard(
                title: "Frequency Response",
                icon: "waveform",
                color: pastelPurple
            ) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Your hearing sensitivity at different frequencies:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    enhancedFrequencyChart
                        .frame(height: 220)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    enhancedFrequencyBreakdownText
                }
            }
            
            // AI Analysis
            enhancedInfoCard(
                title: "AI Health Insights",
                icon: "brain",
                color: pastelBlue
            ) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    if !viewModel.aiInsights.isEmpty {
                        ForEach(viewModel.aiInsights.indices, id: \.self) { index in
                            enhancedInsightRow(insight: viewModel.aiInsights[index])
                            
                            if index < viewModel.aiInsights.count - 1 {
                                Divider()
                                    .padding(.vertical, 8)
                            }
                        }
                    } else {
                        noInsightsView
                    }
                }
            }
            
            // Recommendations
            enhancedInfoCard(
                title: "Recommendations",
                icon: "lightbulb.fill",
                color: pastelGreen
            ) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    ForEach(viewModel.recommendations.indices, id: \.self) { index in
                        enhancedRecommendationRow(number: index + 1, text: viewModel.recommendations[index])
                        
                        if index < viewModel.recommendations.count - 1 {
                            Divider()
                                .padding(.vertical, 5)
                        }
                    }
                    
                    Button(action: {
                        // Schedule follow-up
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16))
                            Text("Schedule Professional Follow-up")
                                .font(AppTheme.Typography.subheadline.bold())
                            Spacer()
                        }
                        .foregroundColor(AppTheme.primaryColor)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.primaryColor, lineWidth: 1.5)
                        )
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Views
    private func earSummaryCard(ear: String, color: Color, status: String, reading: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(ear)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            // Status pill
            Text(status)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(colorForClassification(status))
                )
                .padding(.top, 4)
            
            Text("Last reading: \(reading) dB")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private var enhancedPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.frequencies, id: \.self) { frequency in
                    Button(action: {
                        withAnimation {
                            viewModel.selectedFrequency = frequency
                        }
                    }) {
                        Text("\(frequency) Hz")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.selectedFrequency == frequency ?
                                          AppTheme.primaryColor : Color.gray.opacity(0.1))
                            )
                            .foregroundColor(viewModel.selectedFrequency == frequency ?
                                            .white : AppTheme.textPrimary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var enhancedTrendChart: some View {
        Chart {
            ForEach(viewModel.getFilteredTrendData(), id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Level", dataPoint.level)
                )
                .lineStyle(StrokeStyle(lineWidth: 3))
                .foregroundStyle(dataPoint.ear == .left ? Color.blue : Color.red)
                
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Level", dataPoint.level)
                )
                .foregroundStyle(dataPoint.ear == .left ? Color.blue : Color.red)
                .symbolSize(50)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 12, weight: .medium))
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
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
        }
        .chartYScale(domain: [0, 100])
        .chartBackground { _ in
            Color.white.opacity(0.5)
        }
        .padding(.trailing, 20)
    }
    
    private var noTrendDataView: some View {
        VStack(spacing: 15) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                .padding()
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
                .padding()
            
            Text("Not enough data to show trends")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Complete more hearing tests to see your hearing trends over time")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var enhancedFrequencyChart: some View {
        Chart {
            ForEach(viewModel.frequencyResponse, id: \.frequency) { point in
                BarMark(
                    x: .value("Frequency", "\(point.frequency) Hz"),
                    y: .value("Response", point.level)
                )
                .cornerRadius(5)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [colorForLevel(point.level).opacity(0.7),
                                    colorForLevel(point.level)]
                        ),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                if let level = value.as(Int.self) {
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel {
                        Text("\(level) dB")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let freq = value.as(String.self) {
                        Text(freq)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
        }
        .chartYScale(domain: [0, 100])
        .chartBackground { _ in
            Color.white.opacity(0.5)
        }
    }
    
    private var enhancedFrequencyBreakdownText: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            frequencyRangeRow(
                title: "Low Frequencies (500-1000 Hz)",
                description: viewModel.lowFrequencyStatus.description,
                color: viewModel.lowFrequencyStatus.color
            )
            
            Divider()
            
            frequencyRangeRow(
                title: "Mid Frequencies (1000-4000 Hz)",
                description: viewModel.midFrequencyStatus.description,
                color: viewModel.midFrequencyStatus.color
            )
            
            Divider()
            
            frequencyRangeRow(
                title: "High Frequencies (4000-8000 Hz)",
                description: viewModel.highFrequencyStatus.description,
                color: viewModel.highFrequencyStatus.color
            )
        }
    }
    
    private func frequencyRangeRow(title: String, description: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var noInsightsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "brain")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                .padding()
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
                .padding()
            
            Text("AI Insights Coming Soon")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Complete more hearing tests to unlock AI-powered insights about your hearing health")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private func enhancedInsightRow(insight: HearingHealthProfileViewModel.AIInsight) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: insight.icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [insight.color, insight.color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: insight.color.opacity(0.3), radius: 3, x: 0, y: 2)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func enhancedRecommendationRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
    
    // MARK: - Enhanced Card Container
    private func enhancedInfoCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
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

// MARK: - Enhanced Circular Progress View
struct EnhancedCircularProgressView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Track circle
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.8), color]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 0)
            
            // Percentage text
            Text("\(Int(progress * 100))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}




