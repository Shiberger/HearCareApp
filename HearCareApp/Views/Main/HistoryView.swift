//
//  HistoryView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/3/2568 BE.
//

import SwiftUI
import Firebase

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading test history...")
                } else if viewModel.testResults.isEmpty {
                    emptyStateView
                } else {
                    testHistoryList
                }
            }
            .navigationTitle("Test History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshTestHistory()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadTestHistory()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor.opacity(0.5))
            
            Text("No Test History")
                .font(AppTheme.Typography.title3)
            
            Text("Complete a hearing test to see your results here.")
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
    }
    
    private var testHistoryList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.medium) {
                ForEach(viewModel.testResults) { result in
                    testHistoryCard(result: result)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func testHistoryCard(result: TestResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(dateFormatter.string(from: result.testDate))
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                Text(timeFormatter.string(from: result.testDate))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Right Ear")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(result.rightEarClassification)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(colorForClassification(result.rightEarClassification))
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Left Ear")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(result.leftEarClassification)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(colorForClassification(result.leftEarClassification))
                }
                
                Spacer()
                
                // Fixed: Use the correct initializer for DetailedResultsView with a TestResult
                NavigationLink(
                    destination: TestResultDetailView(testResult: result)
                ) {
                    Text("View Details")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.primaryColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func colorForClassification(_ classification: String) -> Color {
        switch classification {
        case "Normal Hearing":
            return .green
        case "Mild Hearing Loss":
            return .yellow
        case "Moderate Hearing Loss":
            return .orange
        case "Severe Hearing Loss", "Profound Hearing Loss":
            return .red
        default:
            return .gray
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// Add this view to handle test results from history
struct TestResultDetailView: View {
    let testResult: TestResult
    @StateObject private var viewModel: ResultsViewModel
    
    init(testResult: TestResult) {
        self.testResult = testResult
        self._viewModel = StateObject(wrappedValue: ResultsViewModel(testResult: testResult))
    }
    
    var body: some View {
        // You can reuse the UI from DetailedResultsView or create a custom layout
        // This is just a placeholder that redirects to the actual implementation
        DetailedResultsView(viewModel: viewModel)
    }
}
