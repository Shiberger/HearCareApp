//
//  ResultsViewModel.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

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
    @Published var testDuration: String = "5 minutes"
    @Published var isSavedResult: Bool = false // Track if results have been saved
    
    struct FrequencyBreakdownItem {
        let frequency: Float
        let frequencyLabel: String
        let rightLevel: Float
        let leftLevel: Float
    }
    
    var frequencyBreakdown: [FrequencyBreakdownItem] = []
    
    // Store test result when viewing from history
    private var historyTestResult: TestResult?
    
    private let resultsProcessor = ResultsProcessor()
    private let firestore = FirestoreService()
    private var cancellables = Set<AnyCancellable>()
    
    // Default initializer
    init() {
        // Empty initialization
    }
    
    // Initialize with test responses
    init(testResponses: [AudioService.TestResponse]) {
        processTestResponses(testResponses)
    }
    
    // Initialize with a test result (for history)
    init(testResult: TestResult) {
        // Store the original test result
        self.historyTestResult = testResult
        self.isSavedResult = true // Mark as already saved
        
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
    
    // Check if this is a historical result (already saved)
    var isHistoricalResult: Bool {
        return historyTestResult != nil
    }
    
    private func processTestResponses(_ responses: [AudioService.TestResponse]) {
        // Process with Core ML
        let results = resultsProcessor.processResults(from: responses)
        
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
    func updateFrequencyBreakdown() {
        let frequencies: [Float] = [500, 1000, 2000, 4000, 8000]
        frequencyBreakdown = frequencies.map { frequency in
            // Find the data points for this frequency
            let rightPoint = rightEarDataPoints.first { dataPoint in
                dataPoint.frequency == frequency
            }
            let leftPoint = leftEarDataPoints.first { dataPoint in
                dataPoint.frequency == frequency
            }
            
            let rightLevel = rightPoint?.hearingLevel ?? Float.infinity  // Indicate no data
            let leftLevel = leftPoint?.hearingLevel ?? Float.infinity
            
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
    func generateRecommendations() {
        // Basic recommendations based on classification
        var recommendations: [String] = []
        
        // Get worst classification
        let classifications = [rightEarClassification, leftEarClassification]
        let worstClassification = classifications.max(by: { severity($0) < severity($1) })
        
        
        switch worstClassification {
            case "Normal Hearing":
                recommendations = [
                    "การได้ยินของคุณอยู่ในเกณฑ์ปกติ",
                    "ดูแลรักษาการได้ยินโดยหลีกเลี่ยงการสัมผัสเสียงดังเป็นเวลานาน",
                    "ควรตรวจการได้ยินเป็นประจำทุกปีเพื่อเป็นส่วนหนึ่งของการดูแลสุขภาพ"
                ]
            case "Mild Hearing Loss":
                recommendations = [
                    "คุณมีการสูญเสียการได้ยินเล็กน้อยในหูข้างหนึ่งหรือทั้งสองข้าง",
                    "ควรพิจารณานัดพบแพทย์ผู้เชี่ยวชาญด้านการได้ยิน",
                    "หลีกเลี่ยงสภาพแวดล้อมที่มีเสียงดังเมื่อเป็นไปได้",
                    "พิจารณาใช้อุปกรณ์ช่วยฟังในสถานการณ์ที่มีความท้าทาย"
                ]
            case "Moderate Hearing Loss":
                recommendations = [
                    "คุณมีการสูญเสียการได้ยินระดับปานกลางซึ่งอาจส่งผลกระทบต่อการสื่อสารในชีวิตประจำวัน",
                    "เราแนะนำให้ปรึกษากับนักแก้ไขการได้ยินเพื่อหารือเกี่ยวกับตัวเลือกเครื่องช่วยฟัง",
                    "พิจารณากลยุทธ์เพื่อการสื่อสารที่ดีขึ้นในสภาพแวดล้อมที่มีเสียงดัง",
                    "ศึกษาเทคโนโลยีช่วยการได้ยินสำหรับโทรศัพท์และอุปกรณ์อื่นๆ"
                ]
            case "Moderately Severe Hearing Loss":
                recommendations = [
                    "คุณมีการสูญเสียการได้ยินระดับค่อนข้างรุนแรงซึ่งส่งผลกระทบอย่างมากต่อการสื่อสารในชีวิตประจำวัน",
                    "เครื่องช่วยฟังได้รับการแนะนำอย่างยิ่งสำหรับการสูญเสียการได้ยินในระดับนี้",
                    "พิจารณาอุปกรณ์ช่วยฟังเพิ่มเติมสำหรับสถานการณ์เฉพาะ",
                    "เรียนรู้กลยุทธ์การสื่อสารเพื่อเพิ่มความเข้าใจในการสนทนาให้มากที่สุด"
                ]
            case "Severe Hearing Loss", "Profound Hearing Loss":
                recommendations = [
                    "คุณมีการสูญเสียการได้ยินที่รุนแรงซึ่งต้องการความช่วยเหลือจากผู้เชี่ยวชาญ",
                    "กรุณาปรึกษากับนักแก้ไขการได้ยินโดยเร็วที่สุด",
                    "เครื่องช่วยฟังหรืออุปกรณ์ช่วยเหลืออื่นๆ อาจช่วยปรับปรุงคุณภาพชีวิตของคุณได้อย่างมาก",
                    "พิจารณาเรียนรู้เกี่ยวกับกลยุทธ์การสื่อสารเพิ่มเติมเช่นการอ่านริมฝีปากหรือการใช้ภาษามือ"
                ]
            default:
                recommendations = [
                    "จากผลการทดสอบของคุณ เราแนะนำให้ปรึกษาผู้เชี่ยวชาญด้านการได้ยิน",
                    "การตรวจการได้ยินเป็นประจำสามารถช่วยติดตามการเปลี่ยนแปลงในสุขภาพการได้ยินของคุณ"
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
    
    // MODIFIED: Updated to prevent duplicate saves and track save status
    func saveResults() {
        // Check if already saved to prevent duplicates
        if isSavedResult {
            print("Results already saved, skipping duplicate save")
            return
        }
        
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
        
        firestore.saveTestResult(testResult) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Test results saved successfully")
                    self.isSavedResult = true
                    self.objectWillChange.send() // Notify observers of change
                case .failure(let error):
                    print("Failed to save test results: \(error.localizedDescription)")
                }
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
        if let url = URL(string: "https://www.facebook.com/entswu/?locale=th_TH") {
            UIApplication.shared.open(url)
        }
    }
}
