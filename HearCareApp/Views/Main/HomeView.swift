//
//  HomeView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// HomeView.swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0
    
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
            
            historyView
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
                        }
                    }
                    
                    // Hearing summary
                    InfoCard(title: "Hearing Summary", icon: "chart.bar.fill") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                            Text("Based on your latest test results:")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Right Ear")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Text("Normal")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                // HomeView.swift (continued)
                                VStack(alignment: .leading) {
                                    Text("Left Ear")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Text("Mild Loss")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            // Mini audiogram preview
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 100)
                                    .cornerRadius(AppTheme.Radius.small)
                                
                                Text("Tap to view detailed audiogram")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .onTapGesture {
                                // Navigate to detailed audiogram
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
        }
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
    
    private var historyView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Test history
                    ForEach(0..<3) { index in
                        testHistoryCard(
                            date: Calendar.current.date(byAdding: .day, value: -index * 30, to: Date()) ?? Date(),
                            rightEarStatus: index == 0 ? "Normal" : (index == 1 ? "Mild Loss" : "Normal"),
                            leftEarStatus: index == 0 ? "Mild Loss" : (index == 1 ? "Normal" : "Mild Loss")
                        )
                    }
                }
                .padding(.vertical, AppTheme.Spacing.large)
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Test History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func testHistoryCard(date: Date, rightEarStatus: String, leftEarStatus: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(date, style: .date)
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                Text(date, style: .time)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Right Ear")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(rightEarStatus)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(rightEarStatus == "Normal" ? .green : .orange)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Left Ear")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(leftEarStatus)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(leftEarStatus == "Normal" ? .green : .orange)
                }
                
                Spacer()
                
                Button(action: {
                    // View details action
                }) {
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
        .padding(.horizontal)
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
