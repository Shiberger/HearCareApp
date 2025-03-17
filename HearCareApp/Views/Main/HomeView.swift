//
//  HomeView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0
    @State private var showingDebugTools = false
    
    // State for last test data
    @State private var lastTestResult: TestResult?
    @State private var isLoadingLastTest = false
    @State private var lastTestError: String?
    @State private var navigateToLastTestDetails = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            dashboardView
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            NavigationView {
                HearingTestView()
            }
            .tabItem {
                Label("Test", systemImage: "ear.fill")
            }
            .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
            
            profileView
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(AppTheme.primaryColor)
        .sheet(isPresented: $showingDebugTools) {
            DebugTestView()
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 0 {
                // Refresh data when returning to dashboard tab
                fetchLastTest()
            }
        }
    }
    
    private var dashboardView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // User greeting
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Hello, \(authService.user?.displayName?.components(separatedBy: " ").first ?? "there")!")
                            .font(AppTheme.Typography.title2)
                        
                        Text("Track and monitor your hearing health")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal)
                    
                    // Quick actions
                    InfoCard(title: "Quick Actions", icon: "bolt.fill") {
                        VStack(spacing: AppTheme.Spacing.medium) {
                            NavigationLink(destination: HearingTestView()) {
                                HStack {
                                    Image(systemName: "ear.fill")
                                        .foregroundColor(AppTheme.primaryColor)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Take Hearing Test")
                                        .font(AppTheme.Typography.headline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                        .fill(Color.white)
                                )
                            }
                            
                            Button(action: {
                                // View last test action
                                if lastTestResult != nil {
                                    navigateToLastTestDetails = true
                                } else {
                                    // Try to fetch the last test
                                    fetchLastTest()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(AppTheme.primaryColor)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("View Last Test")
                                        .font(AppTheme.Typography.headline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                        .fill(Color.white)
                                )
                            }
                            
                            // Debug Button
                            Button(action: {
                                showingDebugTools = true
                            }) {
                                HStack {
                                    Image(systemName: "hammer.fill")
                                        .foregroundColor(AppTheme.primaryColor)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Debug Tools")
                                        .font(AppTheme.Typography.headline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                        .fill(Color.white)
                                )
                            }
                            .opacity(isDevelopmentMode() ? 1.0 : 0.0)
                            .disabled(!isDevelopmentMode())
                        }
                    }
                    
                    // Hearing summary
                    InfoCard(title: "Hearing Summary", icon: "chart.bar.fill") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            if isLoadingLastTest {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            } else if let lastTest = lastTestResult {
                                // Display actual data from last test
                                Text("Based on your latest test results:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Right Ear")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                        
                                        Text(lastTest.rightEarClassification)
                                            .font(AppTheme.Typography.headline)
                                            .foregroundColor(colorForClassification(lastTest.rightEarClassification))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading) {
                                        Text("Left Ear")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                        
                                        Text(lastTest.leftEarClassification)
                                            .font(AppTheme.Typography.headline)
                                            .foregroundColor(colorForClassification(lastTest.leftEarClassification))
                                    }
                                }
                                
                                // Mini audiogram preview
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 100)
                                        .cornerRadius(AppTheme.Radius.small)
                                    
                                    // Mini audiogram visualization
                                    simpleAudiogramPreview
                                }
                                .onTapGesture {
                                    // Navigate to detailed audiogram
                                    navigateToLastTestDetails = true
                                }
                                
                                Text("Last test: \(dateFormatter.string(from: lastTest.testDate))")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            } else {
                                // No test results available
                                Text("No test results available yet.")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding()
                                
                                Button(action: {
                                    // Navigate to take a test
                                    selectedTab = 1
                                }) {
                                    Text("Take Your First Test")
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundColor(AppTheme.primaryColor)
                                }
                            }
                            
                            Button(action: {
                                // Schedule professional test
                            }) {
                                Text("Schedule Professional Test")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                            .padding(.top, AppTheme.Spacing.small)
                        }
                    }
                    
                    // Tips and education
                    InfoCard(title: "Hearing Health Tips", icon: "lightbulb.fill") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            tipRow(
                                icon: "volume.3.fill",
                                title: "Safe Listening",
                                description: "Keep volume below 60% when using headphones"
                            )
                            
                            Divider()
                            
                            tipRow(
                                icon: "ear.and.waveform",
                                title: "Noise Protection",
                                description: "Use earplugs in loud environments"
                            )
                            
                            Divider()
                            
                            tipRow(
                                icon: "clock.fill",
                                title: "Regular Testing",
                                description: "Test your hearing every 6-12 months"
                            )
                            
                            Button(action: {
                                // View all tips
                            }) {
                                Text("View All Tips")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                            .padding(.top, AppTheme.Spacing.small)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.large)
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("HearCare")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                fetchLastTest()
            }
            .background(
                NavigationLink(
                    destination: lastTestResult.map { testResult in
                        TestResultDetailView(testResult: testResult)
                    },
                    isActive: $navigateToLastTestDetails,
                    label: { EmptyView() }
                )
            )
        }
    }
    
    // A simple audiogram preview based on the last test result
    private var simpleAudiogramPreview: some View {
        Group {
            if let lastTest = lastTestResult,
               !lastTest.rightEarData.isEmpty || !lastTest.leftEarData.isEmpty {
                
                ZStack {
                    // Background reference lines
                    VStack(spacing: 20) {
                        ForEach(0..<4) { _ in
                            Divider().background(Color.gray.opacity(0.3))
                        }
                    }
                    
                    // Sample audiogram points
                    HStack(spacing: 30) {
                        // Just show a few key frequencies
                        ForEach([500, 1000, 2000, 4000, 8000], id: \.self) { freq in
                            VStack(spacing: 0) {
                                // Right ear marker (circle)
                                if let rightPoint = lastTest.rightEarData.first(where: { Int($0.frequency) == freq }) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(y: CGFloat(min(rightPoint.hearingLevel / 2, 40)))
                                }
                                
                                // Left ear marker (X)
                                if let leftPoint = lastTest.leftEarData.first(where: { Int($0.frequency) == freq }) {
                                    Text("×")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                        .offset(y: CGFloat(min(leftPoint.hearingLevel / 2, 40)))
                                }
                                
                                // Frequency label
                                Text(freq >= 1000 ? "\(freq/1000)k" : "\(freq)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                    .offset(y: 45)
                            }
                        }
                    }
                    
                    // View details indicator
                    Text("Tap to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .offset(y: -40)
                }
            } else {
                Text("Tap to view detailed audiogram")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
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
    
    // Fetch last test from Firestore
    private func fetchLastTest() {
        isLoadingLastTest = true
        lastTestError = nil
        
        let firestoreService = FirestoreService()
        firestoreService.getLastTestForCurrentUser { result in
            DispatchQueue.main.async {
                isLoadingLastTest = false
                
                switch result {
                case .success(let testResult):
                    self.lastTestResult = testResult
                case .failure(let error):
                    self.lastTestError = error.localizedDescription
                    print("Failed to load last test: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper function to check if app is running in development mode
    private func isDevelopmentMode() -> Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.primaryColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                
                Text(description)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
    }
    
    private var profileView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Profile header
                    VStack(spacing: AppTheme.Spacing.medium) {
                        if let photoURL = authService.user?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(AppTheme.primaryColor)
                        }
                        
                        Text(authService.user?.displayName ?? "User")
                            .font(AppTheme.Typography.title3)
                        
                        Text(authService.user?.email ?? "")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding()
                    
                    // Profile options
                    VStack(spacing: 0) {
                        profileOption(icon: "bell.fill", title: "Notifications", hasToggle: true)
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        profileOption(icon: "person.fill", title: "Personal Information")
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        profileOption(icon: "ear.fill", title: "Hearing Health Profile")
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        profileOption(icon: "doc.text.fill", title: "Export Test Results")
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        profileOption(icon: "questionmark.circle.fill", title: "Help & Support")
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        profileOption(icon: "gear", title: "Settings")
                    }
                    .background(Color.white)
                    .cornerRadius(AppTheme.Radius.medium)
                    .padding(.horizontal)
                    
                    // Sign out button
                    Button(action: {
                        authService.signOut()
                    }) {
                        Text("Sign Out")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(AppTheme.Radius.medium)
                    }
                    .padding(.horizontal)
                    
                    Text("HearCare v1.0.0")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.top)
                    // Add triple tap to show debug tools
                        .onTapGesture(count: 3) {
                            showingDebugTools = true
                        }
                }
                .padding(.vertical, AppTheme.Spacing.large)
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func profileOption(icon: String, title: String, hasToggle: Bool = false) -> some View {
        Button(action: {
            // Handle option tap
            if title == "Settings" {
                // Alternative way to access debug tools through settings
                showingDebugTools = true
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(width: 24, height: 24)
                    .padding(.leading, 16)
                
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.leading, 16)
                
                Spacer()
                
                if hasToggle {
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
