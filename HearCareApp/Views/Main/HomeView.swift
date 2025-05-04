// Home 2

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
    
    // Color palette - Pastel
    private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
    private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
    private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)
    private let pastelPurple = Color(red: 0.88, green: 0.83, blue: 0.98)
//    private let gradientBackground = LinearGradient(
//        gradient: Gradient(colors: [
//            Color(red: 0.89, green: 0.94, blue: 0.99),
//            Color(red: 0.95, green: 0.98, blue: 0.95)
//        ]),
//        startPoint: .topLeading,
//        endPoint: .bottomTrailing
//    )
    
    private var gradientBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [pastelBlue.opacity(0.6), pastelGreen.opacity(0.5)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
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
                    // User greeting with enhanced styling
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [pastelBlue, pastelBlue.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Hello, \(authService.user?.displayName?.components(separatedBy: " ").first ?? "there")!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                
                                Text("Track and monitor your hearing health")
                                    .font(AppTheme.Typography.callout)
                                    .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "ear.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6).opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    .padding(.horizontal)
                    
                    // Quick actions with updated styling
                    enhancedInfoCard(
                        title: "Quick Actions",
                        icon: "bolt.fill",
                        color: pastelGreen
                    ) {
                        VStack(spacing: AppTheme.Spacing.medium) {
                            NavigationLink(destination: HearingTestView()) {
                                enhancedActionButton(
                                    icon: "ear.fill",
                                    title: "Take Hearing Test",
                                    color: pastelBlue
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
                                enhancedActionButton(
                                    icon: "doc.text.fill",
                                    title: "View Last Test",
                                    color: pastelYellow
                                )
                            }
                            
                            // Debug Button
                            if isDevelopmentMode() {
                                Button(action: {
                                    showingDebugTools = true
                                }) {
                                    enhancedActionButton(
                                        icon: "hammer.fill",
                                        title: "Debug Tools",
                                        color: pastelPurple
                                    )
                                }
                            }
                        }
                    }
                    
                    // Hearing summary with pastel colors
                    enhancedInfoCard(
                        title: "Hearing Summary",
                        icon: "chart.bar.fill",
                        color: pastelYellow
                    ) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            if isLoadingLastTest {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(1.3)
                                        .padding()
                                    Spacer()
                                }
                            } else if let lastTest = lastTestResult {
                                // Display actual data from last test
                                Text("Based on your latest test results:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                HStack(spacing: 15) {
                                    // Left Ear Card
                                    earStatusCard(
                                        ear: "Left Ear",
                                        classification: lastTest.leftEarClassification,
                                        icon: "ear",
                                        color: .blue
                                    )
                                    
                                    // Right Ear Card
                                    earStatusCard(
                                        ear: "Right Ear",
                                        classification: lastTest.rightEarClassification,
                                        icon: "ear",
                                        color: .red
                                    )
                                }
                                
                                // Mini audiogram preview with enhanced styling
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        
                                    // Mini audiogram visualization
                                    simpleAudiogramPreview
                                        .padding()
                                }
                                .frame(height: 120)
                                .onTapGesture {
                                    // Navigate to detailed audiogram
                                    navigateToLastTestDetails = true
                                }
                                
                                HStack {
                                    Text("Last test: \(dateFormatter.string(from: lastTest.testDate))")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("Tap chart to view details")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.primaryColor)
                                }
                            } else {
                                // No test results available
                                VStack(spacing: 20) {
                                    Image(systemName: "waveform.path.badge.minus")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color.gray.opacity(0.6))
                                        .padding()
                                    
                                    Text("No test results available yet.")
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Button(action: {
                                        // Navigate to take a test
                                        selectedTab = 1
                                    }) {
                                        Text("Take Your First Test")
                                            .font(AppTheme.Typography.subheadline.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(AppTheme.primaryColor)
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            
                            Button(action: {
                                // Schedule professional test
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 14))
                                    Text("Schedule Professional Test")
                                        .font(AppTheme.Typography.subheadline.bold())
                                    Spacer()
                                }
                                .foregroundColor(AppTheme.primaryColor)
                                .padding(.vertical, 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                        .stroke(AppTheme.primaryColor, lineWidth: 1.5)
                                )
                            }
                            .padding(.top, AppTheme.Spacing.small)
                        }
                    }
                    
                    // Tips and education with card styling
                    enhancedInfoCard(
                        title: "Hearing Health Tips",
                        icon: "lightbulb.fill",
                        color: pastelBlue
                    ) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            enhancedTipRow(
                                icon: "volume.3.fill",
                                title: "Safe Listening",
                                description: "Keep volume below 60% when using headphones",
                                color: pastelBlue
                            )
                            
                            Divider()
                                .padding(.horizontal, 5)
                            
                            enhancedTipRow(
                                icon: "ear.and.waveform",
                                title: "Noise Protection",
                                description: "Use earplugs in loud environments",
                                color: pastelGreen
                            )
                            
                            Divider()
                                .padding(.horizontal, 5)
                            
                            enhancedTipRow(
                                icon: "clock.fill",
                                title: "Regular Testing",
                                description: "Test your hearing every 6-12 months",
                                color: pastelYellow
                            )
                            
                            Button(action: {
                                // View all tips
                            }) {
                                HStack {
                                    Spacer()
                                    Text("View All Tips")
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundColor(AppTheme.primaryColor)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.primaryColor)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                )
                            }
                            .padding(.top, AppTheme.Spacing.small)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.large)
            }
            .background(gradientBackground.ignoresSafeArea())
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
    
    // A simple audiogram preview with enhanced styling
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
                                        .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                
                                // Left ear marker (X)
                                if let leftPoint = lastTest.leftEarData.first(where: { Int($0.frequency) == freq }) {
                                    Text("×")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.blue)
                                        .offset(y: CGFloat(min(leftPoint.hearingLevel / 2, 40)))
                                }
                                
                                // Frequency label
                                Text(freq >= 1000 ? "\(freq/1000)k" : "\(freq)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.gray)
                                    .offset(y: 45)
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 24))
                            .foregroundColor(Color.gray.opacity(0.5))
                        
                        Text("Tap to view detailed audiogram")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // Create an ear status card with pastel styling
    private func earStatusCard(ear: String, classification: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ear)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Image(systemName: icon)
                    .foregroundColor(color.opacity(0.7))
                    .font(.system(size: 12))
            }
            
            Text(classification)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorForClassification(classification))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .frame(maxWidth: .infinity)
    }
    
    // Enhanced info card with pastel styling
    private func enhancedInfoCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Card header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            }
            
            // Card content
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // Enhanced action button with pastel background
    private func enhancedActionButton(icon: String, title: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(color.opacity(0.2))
                )
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray.opacity(0.6))
                .font(.system(size: 14))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // Enhanced tip row with pastel background
    private func enhancedTipRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                
                Text(description)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
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
    
    // Profile view with enhanced styling
    private var profileView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Profile header with enhanced styling
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [pastelBlue, pastelBlue.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 200)
                        
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
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            
                            Text(authService.user?.displayName ?? "User")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(authService.user?.email ?? "")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Profile options with enhanced styling
                    VStack(spacing: 0) {
                        enhancedProfileOption(icon: "bell.fill", title: "Notifications", color: pastelGreen, hasToggle: true)
                        
                        enhancedProfileOption(icon: "person.fill", title: "Personal Information", color: pastelBlue)
                        
                        enhancedProfileOption(icon: "ear.fill", title: "Hearing Health Profile", color: pastelYellow)
                        
                        enhancedProfileOption(icon: "doc.text.fill", title: "Export Test Results", color: pastelPurple)
                        
                        enhancedProfileOption(icon: "questionmark.circle.fill", title: "Help & Support", color: pastelGreen)
                        
                        enhancedProfileOption(icon: "gear", title: "Settings", color: pastelBlue)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // Sign out button with enhanced styling
                    Button(action: {
                        authService.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16))
                            Text("Sign Out")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                        )
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
            .background(gradientBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // Enhanced profile option with pastel styling
    private func enhancedProfileOption(icon: String, title: String, color: Color, hasToggle: Bool = false) -> some View {
        NavigationLink(
            destination: Group {
                if title == "Personal Information" {
                    PersonalInformationView()
                } else if title == "Hearing Health Profile" {
                    HearingHealthProfileView()
                } else if title == "Settings" {
                    // Handle navigation to settings (and potentially show debug tools)
                    EmptyView().onAppear {
                        showingDebugTools = true
                    }
                } else if title == "Export Test Results" {
                    Text("Coming Soon: \(title)")
                        .font(AppTheme.Typography.title2)
                        .padding()
                } else if title == "Help & Support" {
                    Text("Coming Soon: \(title)")
                        .font(AppTheme.Typography.title2)
                        .padding()
                } else {
                    Text("Coming Soon: \(title)")
                        .font(AppTheme.Typography.title2)
                        .padding()
                }
            }
        ) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.leading, 12)
                
                Spacer()
                
                if hasToggle {
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textSecondary)
                        .font(.system(size: 14))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

