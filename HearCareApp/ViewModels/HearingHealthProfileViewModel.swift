//
//  HearingModelService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 18/3/2568 BE.
//

import SwiftUI
import Combine
import FirebaseAuth

class HearingHealthProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var testResults: [TestResult] = []
    @Published var selectedFrequency: Int = 1000 // Default to 1000 Hz
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // Overall status
    @Published var overallStatus: StatusInfo = StatusInfo(
        title: "Good",
        description: "Your hearing is within normal ranges.",
        score: 85,
        color: .green
    )
    
    // Ear-specific status
    @Published var rightEarStatus: String = "Normal Hearing"
    @Published var leftEarStatus: String = "Normal Hearing"
    @Published var latestRightEarReading: String = "N/A"
    @Published var latestLeftEarReading: String = "N/A"
    
    // Frequency response data
    @Published var frequencyResponse: [FrequencyResponse] = []
    @Published var lowFrequencyStatus = StatusInfo(title: "Normal", description: "Good response to low frequencies like speech fundamentals.", score: 90, color: .green)
    @Published var midFrequencyStatus = StatusInfo(title: "Normal", description: "Good response to speech consonants and most everyday sounds.", score: 85, color: .green)
    @Published var highFrequencyStatus = StatusInfo(title: "Mild Loss", description: "Some difficulty with high-pitched sounds like birds chirping or whispers.", score: 70, color: .blue)
    
    // Trend data
    @Published var trendData: [TrendDataPoint] = []
    @Published var trendAnalysis: String = "Your hearing has been stable over the past 3 months."
    @Published var frequencies = [500, 1000, 2000, 4000, 8000]
    
    // AI Insights
    @Published var aiInsights: [AIInsight] = []
    
    // Recommendations
    @Published var recommendations: [String] = []
    
    // Services
    private let firestoreService = FirestoreService()
    private let hearingModelService = HearingModelService()
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var hasTrendData: Bool {
        return trendData.count >= 2
    }
    
    // MARK: - Data Models
    
    struct StatusInfo {
        var title: String
        var description: String
        var score: Double
        var color: Color
    }
    
    struct FrequencyResponse: Identifiable {
        var id = UUID()
        var frequency: Int
        var level: Float
    }
    
    struct TrendDataPoint {
        var date: Date
        var frequency: Int
        var level: Float
        var ear: AudioService.Ear
    }
    
    struct AIInsight {
        var title: String
        var description: String
        var icon: String
        var color: Color
    }
    
    // MARK: - Public Methods
    
    func loadData() {
        guard !isLoading else { return }
        
        isLoading = true
        
        firestoreService.getTestHistoryForCurrentUser { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let testResults):
                    self.testResults = testResults
                    
                    if !testResults.isEmpty {
                        self.processTestResults(testResults)
                    }
                    
                case .failure(let error):
                    self.alertMessage = "Failed to load test history: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    func getFilteredTrendData() -> [TrendDataPoint] {
        return trendData.filter { $0.frequency == selectedFrequency }
    }
    
    // MARK: - Private Methods
    
    private func processTestResults(_ results: [TestResult]) {
        // Process the most recent test result
        if let latestResult = results.first {
            processLatestResult(latestResult)
        }
        
        // Generate frequency response data
        generateFrequencyResponse(from: results)
        
        // Generate trend data
        generateTrendData(from: results)
        
        // Generate AI insights
        generateAIInsights(from: results)
        
        // Generate recommendations
        generateRecommendations()
    }
    
    private func processLatestResult(_ result: TestResult) {
        // Update ear status
        rightEarStatus = result.rightEarClassification
        leftEarStatus = result.leftEarClassification
        
        // Calculate average hearing levels
        let rightEarAvg = calculateAverageHearingLevel(result.rightEarData)
        let leftEarAvg = calculateAverageHearingLevel(result.leftEarData)
        
        latestRightEarReading = rightEarAvg.isNaN ? "N/A" : String(format: "%.1f", rightEarAvg)
        latestLeftEarReading = leftEarAvg.isNaN ? "N/A" : String(format: "%.1f", leftEarAvg)
        
        // Update overall status based on worst classification
        updateOverallStatus(rightEarStatus: result.rightEarClassification, leftEarStatus: result.leftEarClassification)
    }
    
    private func calculateAverageHearingLevel(_ dataPoints: [TestFrequencyDataPoint]) -> Float {
        guard !dataPoints.isEmpty else { return Float.nan }
        let sum = dataPoints.reduce(0) { $0 + $1.hearingLevel }
        return sum / Float(dataPoints.count)
    }
    
    private func updateOverallStatus(rightEarStatus: String, leftEarStatus: String) {
        // Map the classification strings to our internal model
        let rightClassification = mapToHearingClassification(rightEarStatus)
        let leftClassification = mapToHearingClassification(leftEarStatus)
        
        // Get the worse classification
        let worstClassification = getWorstClassification(rightClassification, leftClassification)
        
        switch worstClassification {
        case .normal:
            overallStatus = StatusInfo(
                title: "Excellent",
                description: "Your hearing is within normal ranges across all frequencies.",
                score: 90,
                color: .green
            )
        case .mild:
            overallStatus = StatusInfo(
                title: "Good",
                description: "You have mild hearing loss. You may have some difficulty hearing soft sounds or understanding speech in noisy environments.",
                score: 75,
                color: .blue
            )
        case .moderate:
            overallStatus = StatusInfo(
                title: "Fair",
                description: "You have moderate hearing loss that may impact your daily communication. Consider consulting with a hearing specialist.",
                score: 60,
                color: .yellow
            )
        case .moderatelySevere:
            overallStatus = StatusInfo(
                title: "Concerning",
                description: "Your hearing loss is significant and likely affects your quality of life. Please consult with an audiologist.",
                score: 45,
                color: .orange
            )
        case .severe, .profound:
            overallStatus = StatusInfo(
                title: "Poor",
                description: "You have severe hearing loss that requires professional attention. Please consult with an audiologist as soon as possible.",
                score: 25,
                color: .red
            )
        }
    }
    
    private func mapToHearingClassification(_ classificationString: String) -> HearingModelService.HearingClassification {
        switch classificationString {
        case "Normal Hearing":
            return .normal
        case "Mild Hearing Loss":
            return .mild
        case "Moderate Hearing Loss":
            return .moderate
        case "Moderately Severe Hearing Loss":
            return .moderatelySevere
        case "Severe Hearing Loss":
            return .severe
        case "Profound Hearing Loss":
            return .profound
        default:
            return .normal
        }
    }
    
    private func getWorstClassification(_ class1: HearingModelService.HearingClassification, _ class2: HearingModelService.HearingClassification) -> HearingModelService.HearingClassification {
        let allCases = HearingModelService.HearingClassification.allCases
        
        if let index1 = allCases.firstIndex(of: class1),
           let index2 = allCases.firstIndex(of: class2) {
            return index1 >= index2 ? class1 : class2
        }
        
        return class1 // Default to first classification if comparison fails
    }
    
    private func generateFrequencyResponse(from results: [TestResult]) {
        guard let latestResult = results.first else { return }
        
        // Combine data from both ears
        var frequencyMap: [Int: [Float]] = [:]
        
        // Process right ear data
        for point in latestResult.rightEarData {
            let freq = Int(point.frequency)
            if frequencyMap[freq] == nil {
                frequencyMap[freq] = []
            }
            frequencyMap[freq]?.append(point.hearingLevel)
        }
        
        // Process left ear data
        for point in latestResult.leftEarData {
            let freq = Int(point.frequency)
            if frequencyMap[freq] == nil {
                frequencyMap[freq] = []
            }
            frequencyMap[freq]?.append(point.hearingLevel)
        }
        
        // Calculate average for each frequency
        var responseData: [FrequencyResponse] = []
        for (frequency, levels) in frequencyMap {
            let avgLevel = levels.reduce(0, +) / Float(levels.count)
            responseData.append(FrequencyResponse(frequency: frequency, level: avgLevel))
        }
        
        // Sort by frequency
        responseData.sort { $0.frequency < $1.frequency }
        
        self.frequencyResponse = responseData
        
        // Update frequency range statuses
        updateFrequencyRangeStatus(from: responseData)
    }
    
    private func updateFrequencyRangeStatus(from response: [FrequencyResponse]) {
        // Low frequencies (500-1000 Hz)
        let lowFreqPoints = response.filter { $0.frequency >= 500 && $0.frequency <= 1000 }
        if !lowFreqPoints.isEmpty {
            let avgLevel = lowFreqPoints.map { $0.level }.reduce(0, +) / Float(lowFreqPoints.count)
            lowFrequencyStatus = getStatusForLevel(avgLevel, range: "low frequencies (500-1000 Hz)")
        }
        
        // Mid frequencies (1000-4000 Hz)
        let midFreqPoints = response.filter { $0.frequency > 1000 && $0.frequency <= 4000 }
        if !midFreqPoints.isEmpty {
            let avgLevel = midFreqPoints.map { $0.level }.reduce(0, +) / Float(midFreqPoints.count)
            midFrequencyStatus = getStatusForLevel(avgLevel, range: "mid frequencies (1000-4000 Hz)")
        }
        
        // High frequencies (4000-8000 Hz)
        let highFreqPoints = response.filter { $0.frequency > 4000 }
        if !highFreqPoints.isEmpty {
            let avgLevel = highFreqPoints.map { $0.level }.reduce(0, +) / Float(highFreqPoints.count)
            highFrequencyStatus = getStatusForLevel(avgLevel, range: "high frequencies (4000-8000 Hz)")
        }
    }
    
    private func getStatusForLevel(_ level: Float, range: String) -> StatusInfo {
        // Use HearingModelService's classification logic, which matches your existing code
        let classification = hearingModelService.classifyHearingManually(levels: [1000: level])
        
        switch classification {
        case .normal:
            return StatusInfo(
                title: "Normal",
                description: "Good response to \(range).",
                score: 90,
                color: .green
            )
        case .mild:
            return StatusInfo(
                title: "Mild Loss",
                description: "Slight difficulty with \(range).",
                score: 70,
                color: .blue
            )
        case .moderate:
            return StatusInfo(
                title: "Moderate Loss",
                description: "Noticeable difficulty with \(range).",
                score: 50,
                color: .yellow
            )
        case .moderatelySevere:
            return StatusInfo(
                title: "Moderate-Severe Loss",
                description: "Significant difficulty with \(range).",
                score: 35,
                color: .orange
            )
        case .severe:
            return StatusInfo(
                title: "Severe Loss",
                description: "Major difficulty with \(range).",
                score: 20,
                color: .red
            )
        case .profound:
            return StatusInfo(
                title: "Profound Loss",
                description: "Extreme difficulty with \(range).",
                score: 10,
                color: .purple
            )
        }
    }
    
    private func generateTrendData(from results: [TestResult]) {
        var trendPoints: [TrendDataPoint] = []
        
        // Only use the last 6 test results for trends
        let recentResults = results.prefix(6)
        
        for result in recentResults {
            // Process right ear data
            for point in result.rightEarData {
                trendPoints.append(TrendDataPoint(
                    date: result.testDate,
                    frequency: Int(point.frequency),
                    level: point.hearingLevel,
                    ear: .right
                ))
            }
            
            // Process left ear data
            for point in result.leftEarData {
                trendPoints.append(TrendDataPoint(
                    date: result.testDate,
                    frequency: Int(point.frequency),
                    level: point.hearingLevel,
                    ear: .left
                ))
            }
        }
        
        self.trendData = trendPoints
        
        // Generate trend analysis text
        if hasTrendData {
            generateTrendAnalysis()
        }
    }
    
    private func generateTrendAnalysis() {
        // Filter for selected frequency
        let filteredData = getFilteredTrendData()
        
        // Separate by ear
        let rightEarData = filteredData.filter { $0.ear == .right }.sorted { $0.date < $1.date }
        let leftEarData = filteredData.filter { $0.ear == .left }.sorted { $0.date < $1.date }
        
        // Check if we have enough data points
        guard rightEarData.count >= 2 || leftEarData.count >= 2 else {
            trendAnalysis = "Complete more tests to see hearing trends at \(selectedFrequency) Hz."
            return
        }
        
        var analysis = ""
        
        // Analyze right ear trend if we have enough data
        if rightEarData.count >= 2 {
            let firstPoint = rightEarData.first!
            let lastPoint = rightEarData.last!
            let change = lastPoint.level - firstPoint.level
            
            if abs(change) < 5 {
                analysis += "Your right ear hearing at \(selectedFrequency) Hz has been stable. "
            } else if change > 0 {
                analysis += "Your right ear shows a decline of \(Int(change)) dB at \(selectedFrequency) Hz. "
            } else {
                analysis += "Your right ear shows an improvement of \(Int(abs(change))) dB at \(selectedFrequency) Hz. "
            }
        }
        
        // Analyze left ear trend if we have enough data
        if leftEarData.count >= 2 {
            let firstPoint = leftEarData.first!
            let lastPoint = leftEarData.last!
            let change = lastPoint.level - firstPoint.level
            
            if abs(change) < 5 {
                analysis += "Your left ear hearing at \(selectedFrequency) Hz has been stable."
            } else if change > 0 {
                analysis += "Your left ear shows a decline of \(Int(change)) dB at \(selectedFrequency) Hz."
            } else {
                analysis += "Your left ear shows an improvement of \(Int(abs(change))) dB at \(selectedFrequency) Hz."
            }
        }
        
        trendAnalysis = analysis
    }
    
    private func generateAIInsights(from results: [TestResult]) {
        var insights: [AIInsight] = []
        
        // Only generate insights if we have enough data
        if results.count >= 2 {
            // Check for noise exposure pattern using your existing CoreML model
            if highFrequencyStatus.title == "Moderate Loss" || highFrequencyStatus.title == "Moderate-Severe Loss" {
                // Check for notch at 4000 Hz which is characteristic of noise exposure
                
                if let latestResult = results.first,
                   let frequency4k = latestResult.rightEarData.first(where: { Int($0.frequency) == 4000 })?.hearingLevel,
                   let frequency2k = latestResult.rightEarData.first(where: { Int($0.frequency) == 2000 })?.hearingLevel,
                   let frequency8k = latestResult.rightEarData.first(where: { Int($0.frequency) == 8000 })?.hearingLevel {
                    
                    let notchDepth = frequency4k - ((frequency2k + frequency8k) / 2)
                    
                    if notchDepth > 10 {
                        insights.append(AIInsight(
                            title: "Potential Noise Exposure",
                            description: "Your high-frequency hearing loss pattern is consistent with noise exposure. Consider using hearing protection.",
                            icon: "headphones",
                            color: .orange
                        ))
                    }
                }
            }
            
            // Check for asymmetric hearing loss
            if let latestResult = results.first {
                let rightEarAvg = calculateAverageHearingLevel(latestResult.rightEarData)
                let leftEarAvg = calculateAverageHearingLevel(latestResult.leftEarData)
                
                if abs(rightEarAvg - leftEarAvg) > 15 {
                    insights.append(AIInsight(
                        title: "Asymmetric Hearing",
                        description: "There's a significant difference between your ears. This should be evaluated by a professional.",
                        icon: "ear.trianglebadge.exclamationmark",
                        color: .red
                    ))
                }
            }
            
            // Check for progression
            if results.count >= 3 {
                // Check if there's a consistent decline over time
                let firstTest = results.last!
                let lastTest = results.first!
                
                let firstRightAvg = calculateAverageHearingLevel(firstTest.rightEarData)
                let lastRightAvg = calculateAverageHearingLevel(lastTest.rightEarData)
                let firstLeftAvg = calculateAverageHearingLevel(firstTest.leftEarData)
                let lastLeftAvg = calculateAverageHearingLevel(lastTest.leftEarData)
                
                let rightChange = lastRightAvg - firstRightAvg
                let leftChange = lastLeftAvg - firstLeftAvg
                
                if rightChange > 10 || leftChange > 10 {
                    insights.append(AIInsight(
                        title: "Progressive Hearing Loss",
                        description: "Your hearing shows a decline over time. Schedule a professional evaluation.",
                        icon: "chart.line.downtrend.xyaxis",
                        color: .red
                    ))
                } else if rightChange < -5 || leftChange < -5 {
                    insights.append(AIInsight(
                        title: "Hearing Improvement",
                        description: "Your hearing shows improvement over time. This could be due to resolved conditions or better testing environment.",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    ))
                } else {
                    insights.append(AIInsight(
                        title: "Stable Hearing",
                        description: "Your hearing has remained relatively stable over time. Continue regular monitoring.",
                        icon: "equal.circle",
                        color: .blue
                    ))
                }
            }
        }
        
        // Add age-related insight if appropriate
        if highFrequencyStatus.title != "Normal" && midFrequencyStatus.title == "Normal" {
            insights.append(AIInsight(
                title: "Age-Related Pattern",
                description: "Your hearing pattern shows typical age-related changes, with high frequencies affected first.",
                icon: "calendar",
                color: .blue
            ))
        }
        
        self.aiInsights = insights
    }
    
    private func generateRecommendations() {
        // Use the recommendations from the last test result, if available
        if let latestResult = testResults.first {
            var recommendations: [String] = []
            
            // Map from string classification back to HearingModelService.HearingClassification
            let rightClassification = mapToHearingClassification(latestResult.rightEarClassification)
            let leftClassification = mapToHearingClassification(latestResult.leftEarClassification)
            
            // Get worse classification
            let worseClassification = getWorstClassification(rightClassification, leftClassification)
            
            // Get base recommendations from your existing model
            recommendations.append(contentsOf: worseClassification.recommendations)
            
            // Add personalized recommendations based on frequency analysis
            if highFrequencyStatus.title != "Normal" && highFrequencyStatus.title != "Mild Loss" {
                recommendations.append("Your high-frequency hearing loss may affect your ability to hear certain consonants. Consider speech reading techniques to improve understanding.")
            }
            
            if lowFrequencyStatus.title != "Normal" && lowFrequencyStatus.title != "Mild Loss" {
                recommendations.append("Your low-frequency hearing loss may affect your ability to hear vowel sounds and deeper voices. Position yourself to better see speakers' faces.")
            }
            
            // AI-based recommendations
            for insight in aiInsights {
                switch insight.title {
                case "Potential Noise Exposure":
                    recommendations.append("Avoid loud noise exposure and always use hearing protection in noisy environments.")
                case "Asymmetric Hearing":
                    recommendations.append("Consult with an ENT specialist to evaluate the asymmetric hearing pattern between your ears.")
                case "Progressive Hearing Loss":
                    recommendations.append("Track your hearing more frequently, such as every 3-6 months, to monitor progression.")
                default:
                    break
                }
            }
            
            // Remove duplicates while preserving order
            var uniqueRecommendations: [String] = []
            for recommendation in recommendations {
                if !uniqueRecommendations.contains(recommendation) {
                    uniqueRecommendations.append(recommendation)
                }
            }
            
            self.recommendations = uniqueRecommendations
        } else {
            // Default recommendations if no test results are available
            self.recommendations = [
                "Complete a hearing test to get personalized recommendations.",
                "Protect your hearing by avoiding prolonged exposure to loud noises.",
                "Consider using hearing protection in noisy environments."
            ]
        }
    }
}
