//
//  ResultsViewModel.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// ResultsViewModel.swift
import SwiftUI
import Combine
import FirebaseAuth

class ResultsViewModel: ObservableObject {
    @Published var rightEarDataPoints: [FrequencyDataPoint] = []
    @Published var leftEarDataPoints: [FrequencyDataPoint] = []
    @Published var rightEarClassification: String = ""
    @Published var leftEarClassification: String = ""
    @Published var recommendations: [String] = []
    @Published var testDate: Date = Date()
    @Published var testDuration: String = "8 minutes"
    
    struct FrequencyBreakdownItem {
        let frequency: Float
        let frequencyLabel: String
        let rightLevel: Float
        let leftLevel: Float
    }
    
    var frequencyBreakdown: [FrequencyBreakdownItem] = []
    
    private let resultsProcessor = ResultsProcessor()
    private let firestore = FirestoreService()
    private var cancellables = Set<AnyCancellable>()
    
    // Default initializer needed for convenience init
    init() {
        // Empty initialization
    }
    
    init(testResponses: [AudioService.TestResponse]) {
        processTestResponses(testResponses)
    }
    
    // Convenience initializer for test history
    convenience init(testResult: TestResult) {
        self.init()
        
        // Populate view model properties from the test result
        self.rightEarDataPoints = testResult.rightEarData.map {
            FrequencyDataPoint(frequency: $0.frequency, hearingLevel: $0.hearingLevel)
        }
        .sorted(by: { $0.frequency < $1.frequency })
        
        self.leftEarDataPoints = testResult.leftEarData.map {
            FrequencyDataPoint(frequency: $0.frequency, hearingLevel: $0.hearingLevel)
        }
        .sorted(by: { $0.frequency < $1.frequency })
        
        self.rightEarClassification = testResult.rightEarClassification
        self.leftEarClassification = testResult.leftEarClassification
        self.testDate = testResult.testDate
        
        // Create frequency breakdown from the test result data
        updateFrequencyBreakdown()
        
        // Generate recommendations based on classifications
        generateRecommendations()
    }
    
    private func processTestResponses(_ responses: [AudioService.TestResponse]) {
        // Process with Core ML
        let results = resultsProcessor.processResults(from: responses)
        
        // Update right ear data
        rightEarDataPoints = results.rightEarHearingLevel.map { frequency, level in
            FrequencyDataPoint(frequency: frequency, hearingLevel: level)
        }
        .sorted(by: { $0.frequency < $1.frequency })
        
        // Update left ear data
        leftEarDataPoints = results.leftEarHearingLevel.map { frequency, level in
            FrequencyDataPoint(frequency: frequency, hearingLevel: level)
        }
        .sorted(by: { $0.frequency < $1.frequency })
        
        // Set classifications
        rightEarClassification = results.rightEarClassification.displayName
        leftEarClassification = results.leftEarClassification.displayName
        
        // Set recommendations
        recommendations = results.recommendations
        
        // Create frequency breakdown
        updateFrequencyBreakdown()
    }
    
    // Helper method to update frequency breakdown
    private func updateFrequencyBreakdown() {
        let frequencies: [Float] = [250, 500, 1000, 2000, 4000, 8000]
        frequencyBreakdown = frequencies.map { frequency in
            // Find the data points for this frequency
            let rightPoint = rightEarDataPoints.first { dataPoint in
                dataPoint.frequency == frequency
            }
            let leftPoint = leftEarDataPoints.first { dataPoint in
                dataPoint.frequency == frequency
            }
            
            let rightLevel = rightPoint?.hearingLevel ?? 0
            let leftLevel = leftPoint?.hearingLevel ?? 0
            
            let frequencyLabel = frequency >= 1000 ?
                "\(Int(frequency/1000))k Hz" :
                "\(Int(frequency)) Hz"
            
            return FrequencyBreakdownItem(
                frequency: frequency,
                frequencyLabel: frequencyLabel,
                rightLevel: rightLevel,
                leftLevel: leftLevel
            )
        }
    }
    
    // Helper method to generate recommendations if needed
    private func generateRecommendations() {
        // Basic recommendations based on classification
        var recommendations: [String] = []
        
        // Get worst classification
        let classifications = [rightEarClassification, leftEarClassification]
        let worstClassification = classifications.max(by: { severity($0) < severity($1) })
        
        switch worstClassification {
        case "Normal Hearing":
            recommendations = [
                "Your hearing appears to be within normal range.",
                "Continue to protect your hearing by avoiding prolonged exposure to loud noises.",
                "Get your hearing checked annually as part of your health routine."
            ]
        case "Mild Hearing Loss":
            recommendations = [
                "You have mild hearing loss in one or both ears.",
                "Consider scheduling a follow-up appointment with an audiologist.",
                "Avoid noisy environments when possible.",
                "Consider using assistive listening devices in challenging situations."
            ]
        case "Moderate Hearing Loss":
            recommendations = [
                "You have moderate hearing loss that may impact your daily communication.",
                "We recommend consulting with an audiologist to discuss hearing aid options.",
                "Consider strategies for better communication in noisy environments.",
                "Look into hearing assistive technologies for phones and other devices."
            ]
        case "Moderately Severe Hearing Loss":
            recommendations = [
                "You have moderately severe hearing loss that significantly impacts daily communication.",
                "Hearing aids are strongly recommended for this level of hearing loss.",
                "Consider additional assistive listening devices for specific situations.",
                "Learn communication strategies to maximize understanding in conversations."
            ]
        case "Severe Hearing Loss", "Profound Hearing Loss":
            recommendations = [
                "You have significant hearing loss that requires professional attention.",
                "Please consult with an audiologist as soon as possible.",
                "Hearing aids or other assistive devices may significantly improve your quality of life.",
                "Consider learning about additional communication strategies like speech reading."
            ]
        default:
            recommendations = [
                "Based on your test results, we recommend consulting with a hearing specialist.",
                "Regular hearing tests can help monitor changes in your hearing health."
            ]
        }
        
        self.recommendations = recommendations
    }
    
    // Helper to determine severity of hearing classification
    private func severity(_ classification: String) -> Int {
        switch classification {
        case "Normal Hearing": return 0
        case "Mild Hearing Loss": return 1
        case "Moderate Hearing Loss": return 2
        case "Moderately Severe Hearing Loss": return 3
        case "Severe Hearing Loss": return 4
        case "Profound Hearing Loss": return 5
        default: return -1
        }
    }
    
    func descriptionFor(classification: String) -> String {
        // Find the matching classification
        switch classification {
        case "Normal Hearing":
            return "You can hear soft sounds across most frequencies."
        case "Mild Hearing Loss":
            return "You may have difficulty hearing soft sounds and understanding speech in noisy environments."
        case "Moderate Hearing Loss":
            return "You likely have difficulty following conversations without hearing aids."
        case "Moderately Severe Hearing Loss":
            return "You have difficulty with normal conversations and may miss significant speech elements without amplification."
        case "Severe Hearing Loss":
            return "You may hear almost no speech when a person talks at a normal level."
        case "Profound Hearing Loss":
            return "You may not hear loud speech or sounds without powerful hearing aids or a cochlear implant."
        default:
            return "Unable to retrieve description for this hearing classification."
        }
    }
    
    func saveResults() {
        // Save to Firestore
        guard let user = Auth.auth().currentUser else {
            print("No authenticated user")
            return
        }
        
        // Create test result document
        let testResult = [
            "userId": user.uid,
            "testDate": testDate,
            "rightEarData": rightEarDataPoints.map { ["frequency": $0.frequency, "hearingLevel": $0.hearingLevel] },
            "leftEarData": leftEarDataPoints.map { ["frequency": $0.frequency, "hearingLevel": $0.hearingLevel] },
            "rightEarClassification": rightEarClassification,
            "leftEarClassification": leftEarClassification,
            "recommendations": recommendations
        ] as [String: Any]
        
        firestore.saveTestResult(testResult) { result in
            switch result {
            case .success:
                print("Test results saved successfully")
            case .failure(let error):
                print("Failed to save test results: \(error.localizedDescription)")
            }
        }
    }
    
    func shareResults() {
        // Generate PDF report and share
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Add content to PDF
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
            ]
            
            let title = "HearCare Hearing Test Results"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Add date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "Test Date: " + dateFormatter.string(from: testDate)
            let dateAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
            ]
            dateString.draw(at: CGPoint(x: 50, y: 90), withAttributes: dateAttributes)
            
            // Add classifications
            let rightEarString = "Right Ear: " + rightEarClassification
            rightEarString.draw(at: CGPoint(x: 50, y: 120), withAttributes: dateAttributes)
            
            let leftEarString = "Left Ear: " + leftEarClassification
            leftEarString.draw(at: CGPoint(x: 50, y: 140), withAttributes: dateAttributes)
            
            // Note: A complete implementation would include the audiogram and all results
        }
        
        // Share the PDF
        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func scheduleFollowUp() {
        // This would launch a calendar picker or integration with a booking system
        // For this example, we'll just provide a URL to a booking page
        if let url = URL(string: "https://hearcare-app.com/book-appointment") {
            UIApplication.shared.open(url)
        }
    }
}
