//
//  DebugTestView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 14/3/2568 BE.
//

import SwiftUI

struct DebugTestView: View {
    @State private var showingResults = false
    @State private var selectedProfile: TestProfile = .normal
    @State private var testResults: [AudioService.TestResponse] = []
    
    enum TestProfile: String, CaseIterable, Identifiable {
        case normal = "Normal Hearing"
        case mild = "Mild Hearing Loss"
        case moderate = "Moderate Hearing Loss"
        case moderatelySevere = "Moderately Severe Loss"
        case severe = "Severe Hearing Loss"
        
        var id: String { self.rawValue }
        
        // Convert hearing level in dB to volume (0-1 scale)
        // This is the inverse of the volumeTodB function in ResultsProcessor
        func dBToVolume(_ dB: Float) -> Float {
            // Map from dB to volume based on the mapping in ResultsProcessor
            let dbToVolumeMap: [Float: Float] = [
                0: 0.05,
                10: 0.1,
                20: 0.2,
                30: 0.3,
                40: 0.4,
                50: 0.5,
                60: 0.7,
                70: 0.9,
                80: 1.0
            ]
            
            // Find closest match
            let sortedKeys = dbToVolumeMap.keys.sorted()
            if dB <= sortedKeys.first! {
                return dbToVolumeMap[sortedKeys.first!]!
            }
            if dB >= sortedKeys.last! {
                return dbToVolumeMap[sortedKeys.last!]!
            }
            
            // Linear interpolation
            for i in 0..<(sortedKeys.count - 1) {
                let db1 = sortedKeys[i]
                let db2 = sortedKeys[i + 1]
                if dB >= db1 && dB <= db2 {
                    let v1 = dbToVolumeMap[db1]!
                    let v2 = dbToVolumeMap[db2]!
                    return v1 + (v2 - v1) * (dB - db1) / (db2 - db1)
                }
            }
            
            // Fallback formula (inverse of what's in ResultsProcessor)
            return min(max(dB / 80.0, 0.05), 1.0)
        }
        
        func generateTestData() -> [AudioService.TestResponse] {
            let now = Date()
            var responses: [AudioService.TestResponse] = []
            
            // Standard frequencies to test
            let frequencies: [Float] = [500, 1000, 2000, 4000, 8000]
            
            // Generate levels based on the selected profile
            for frequency in frequencies {
                for ear in [AudioService.Ear.right, AudioService.Ear.left] {
                    // Set base level for this profile in dB
                    var levelDB: Float
                    
                    switch self {
                    case .normal:
                        levelDB = 15.0  // Normal: 0-25 dB
                    case .mild:
                        levelDB = 30.0  // Mild: 25-40 dB
                    case .moderate:
                        levelDB = 45.0  // Moderate: 40-55 dB
                    case .moderatelySevere:
                        levelDB = 60.0  // Moderately severe: 55-70 dB
                    case .severe:
                        levelDB = 80.0  // Severe: 70-90 dB
                    }
                    
                    // Add some variation based on frequency
                    let variation: Float
                    if frequency <= 1000 {
                        variation = -5.0  // Better hearing at lower frequencies
                    } else if frequency >= 4000 {
                        variation = 10.0  // Worse hearing at higher frequencies (common pattern)
                    } else {
                        variation = 0.0
                    }
                    
                    // Add a small random variation
                    let randomFactor = Float.random(in: -3.0...3.0)
                    
                    // Calculate final level with variation
                    levelDB = levelDB + variation + randomFactor
                    
                    // Ensure level stays in reasonable range
                    levelDB = max(0, min(levelDB, 90))
                    
                    // Convert dB level to volume (important!)
                    let volumeHeard = dBToVolume(levelDB)
                    
                    // Create response
                    let response = AudioService.TestResponse(
                        frequency: frequency,
                        volumeHeard: volumeHeard,  // Using volume, not dB!
                        ear: ear,
                        timestamp: now
                    )
                    
                    responses.append(response)
                }
            }
            
            return responses
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Debug Test Results")
                    .font(.title)
                    .padding(.top)
                
                Text("Select a hearing profile to simulate:")
                    .font(.headline)
                
                ForEach(TestProfile.allCases) { profile in
                    Button(action: {
                        selectedProfile = profile
                        testResults = profile.generateTestData()
                        showingResults = true
                    }) {
                        Text(profile.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonColor(for: profile))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    // Generate custom pattern - asymmetric hearing loss
                    testResults = generateAsymmetricLoss()
                    showingResults = true
                }) {
                    Text("Asymmetric Hearing Loss")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                NavigationLink(
                    destination: DetailedResultsView(testResults: testResults),
                    isActive: $showingResults
                ) {
                    EmptyView()
                }
                
                Spacer()
                
                Text("These buttons generate simulated test results without having to go through the actual test.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Debug Tools")
        }
    }
    
    private func buttonColor(for profile: TestProfile) -> Color {
        switch profile {
        case .normal:
            return .green
        case .mild:
            return .blue
        case .moderate:
            return .orange
        case .moderatelySevere:
            return .red
        case .severe:
            return .purple
        }
    }
    
    private func generateAsymmetricLoss() -> [AudioService.TestResponse] {
        let now = Date()
        var responses: [AudioService.TestResponse] = []
        
        // Standard frequencies to test
        let frequencies: [Float] = [500, 1000, 2000, 4000, 8000]
        
        for frequency in frequencies {
            // Right ear - normal to mild (in dB)
            let rightLevelDB: Float = 20.0 + (frequency > 2000 ? 10.0 : 0.0)
            
            // Left ear - moderate to severe (in dB)
            let leftLevelDB: Float = 50.0 + (frequency > 2000 ? 20.0 : 0.0)
            
            // Convert dB to volume
            let rightVolume = TestProfile.normal.dBToVolume(rightLevelDB)
            let leftVolume = TestProfile.normal.dBToVolume(leftLevelDB)
            
            // Create responses for both ears
            responses.append(AudioService.TestResponse(
                frequency: frequency,
                volumeHeard: rightVolume,  // Using volume, not dB!
                ear: .right,
                timestamp: now
            ))
            
            responses.append(AudioService.TestResponse(
                frequency: frequency,
                volumeHeard: leftVolume,  // Using volume, not dB!
                ear: .left,
                timestamp: now
            ))
        }
        
        return responses
    }
}

// MARK: - Preview

struct DebugTestView_Previews: PreviewProvider {
    static var previews: some View {
        DebugTestView()
    }
}
