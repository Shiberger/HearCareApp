//
//  DetailedResultsView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI

struct DetailedResultsView: View {
    @StateObject private var viewModel: ResultsViewModel
    @State private var selectedTab = 0
    @State private var isSaving = false
    @State private var lastSaveTime: Date? = nil
    @State private var resultsSaved = false
    
    private let tabs = ["Audiogram", "Summary", "Recommendations"]
    private let saveDebounceInterval: TimeInterval = 2.0 // 2 seconds debounce time
    
    // Original initializer for new test results
    init(testResults: [AudioService.TestResponse]) {
        self._viewModel = StateObject(wrappedValue: ResultsViewModel(testResponses: testResults))
    }
    
    // New initializer for historical test results
    init(testResult: TestResult) {
        self._viewModel = StateObject(wrappedValue: ResultsViewModel(testResult: testResult))
    }
    
    // Additional initializer that accepts a view model directly
    init(viewModel: ResultsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab View
            HStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                                
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(height: 3)
                                        .matchedGeometryEffect(id: "TAB", in: namespace)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Tab Content
            TabView(selection: $selectedTab) {
                audiogramView
                    .tag(0)
                
                summaryView
                    .tag(1)
                
                recommendationsView
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Test Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shareResults()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .background(Color("BackgroundColor").ignoresSafeArea())
    }
    
    @Namespace private var namespace
    
    private var audiogramView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Hearing Audiogram")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                // Use either the Swift Charts or WebView implementation
                AudiogramChartView(
                    rightEarData: viewModel.rightEarDataPoints,
                    leftEarData: viewModel.leftEarDataPoints
                )
                .padding(.horizontal)
                
                // Alternative: Use Plotly WebView
                // PlotlyAudiogramView(
                //     rightEarData: viewModel.rightEarDataPoints,
                //     leftEarData: viewModel.leftEarDataPoints
                // )
                // .frame(height: 400)
                // .padding(.horizontal)
                
                Text("About Your Audiogram")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("An audiogram shows your hearing ability across different frequencies. Lower values indicate better hearing. The chart shows results for both ears, helping identify patterns in hearing loss.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button(action: {
                    // Get current time
                    let now = Date()
                    
                    // Check if already saving or if last save was too recent
                    if isSaving || (lastSaveTime != nil && now.timeIntervalSince(lastSaveTime!) < saveDebounceInterval) {
                        return
                    }
                    
                    // Update state
                    isSaving = true
                    lastSaveTime = now
                    
                    // Save results
                    viewModel.saveResults()
                    
                    // Mark as saved
                    resultsSaved = true
                    
                    // Reset saving state after a delay to prevent multiple rapid taps
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isSaving = false
                    }
                }) {
                    Text("Save Results")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSaving ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .opacity(isSaving ? 0.7 : 1.0) // Visual feedback
                }
                .disabled(resultsSaved || isSaving)
                .padding()
            }
        }
    }
    
    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Results Summary")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                // Classification Cards
                VStack(spacing: 16) {
                    classificationCard(
                        title: "Right Ear",
                        classification: viewModel.rightEarClassification,
                        color: .blue
                    )
                    
                    classificationCard(
                        title: "Left Ear",
                        classification: viewModel.leftEarClassification,
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Frequency Breakdown
                Text("Frequency Breakdown")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                frequencyBreakdownGrid
                    .padding(.horizontal)
                
                // Test Information
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Information")
                        .font(.headline)
                    
                    HStack {
                        Text("Test Date:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.testDate, style: .date)
                    }
                    
                    HStack {
                        Text("Test Duration:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.testDuration)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
    }
    
    private func classificationCard(title: String, classification: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(classification)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(viewModel.descriptionFor(classification: classification))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var frequencyBreakdownGrid: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Frequency")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .leading)
                
                Text("Right Ear")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                
                Text("Left Ear")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Frequency rows
            ForEach(viewModel.frequencyBreakdown, id: \.frequency) { item in
                HStack {
                    Text(item.frequencyLabel)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    Text("\(Int(item.rightLevel)) dB")
                        .font(.caption)
                        .foregroundColor(colorFor(level: item.rightLevel))
                        .frame(maxWidth: .infinity)
                    
                    Text("\(Int(item.leftLevel)) dB")
                        .font(.caption)
                        .foregroundColor(colorFor(level: item.leftLevel))
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
                .background(
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                )
                
                Divider()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func colorFor(level: Float) -> Color {
        switch level {
        case 0..<25:
            return .green
        case 25..<40:
            return .yellow
        case 40..<60:
            return .orange
        case 60..<80:
            return .red
        default:
            return .purple
        }
    }
    
    private var recommendationsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Recommended Actions")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                ForEach(viewModel.recommendations.indices, id: \.self) { index in
                    recommendationCard(
                        number: index + 1,
                        recommendation: viewModel.recommendations[index]
                    )
                }
                
                Button(action: {
                    viewModel.scheduleFollowUp()
                }) {
                    Text("Schedule Follow-Up")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                Text("Disclaimer: This app provides a screening tool and is not a substitute for professional medical advice. Please consult an audiologist for a comprehensive evaluation.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
    }
    
    private func recommendationCard(number: Int, recommendation: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(recommendation)
                .font(.body)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}
