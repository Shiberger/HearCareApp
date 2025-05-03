//
//  TestResult.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import Foundation
import FirebaseFirestore

struct TestResult: Identifiable {
    let id: String
    let testDate: Date
    let rightEarClassification: String
    let leftEarClassification: String
    let rightEarData: [TestFrequencyDataPoint]
    let leftEarData: [TestFrequencyDataPoint]
    
    // Computed properties for average hearing levels
    var rightEarAverageLevel: Float {
        guard !rightEarData.isEmpty else { return 0 }
        let sum = rightEarData.reduce(0) { $0 + $1.hearingLevel }
        return sum / Float(rightEarData.count)
    }
    
    var leftEarAverageLevel: Float {
        guard !leftEarData.isEmpty else { return 0 }
        let sum = leftEarData.reduce(0) { $0 + $1.hearingLevel }
        return sum / Float(leftEarData.count)
    }
    
    // Factory method to create from Firestore data
    static func fromFirestore(id: String, data: [String: Any]) -> TestResult? {
        guard let testDateTimestamp = data["testDate"] as? Timestamp,
              let rightEarClassification = data["rightEarClassification"] as? String,
              let leftEarClassification = data["leftEarClassification"] as? String,
              let rightEarDataArray = data["rightEarData"] as? [[String: Any]],
              let leftEarDataArray = data["leftEarData"] as? [[String: Any]] else {
            return nil
        }
        
        let testDate = testDateTimestamp.dateValue()
        
        // Parse frequency data points
        let rightEarData = rightEarDataArray.compactMap { point -> TestFrequencyDataPoint? in
            guard let frequency = point["frequency"] as? Float,
                  let hearingLevel = point["hearingLevel"] as? Float else {
                return nil
            }
            return TestFrequencyDataPoint(frequency: frequency, hearingLevel: hearingLevel)
        }
        
        let leftEarData = leftEarDataArray.compactMap { point -> TestFrequencyDataPoint? in
            guard let frequency = point["frequency"] as? Float,
                  let hearingLevel = point["hearingLevel"] as? Float else {
                return nil
            }
            return TestFrequencyDataPoint(frequency: frequency, hearingLevel: hearingLevel)
        }
        
        return TestResult(
            id: id,
            testDate: testDate,
            rightEarClassification: rightEarClassification,
            leftEarClassification: leftEarClassification,
            rightEarData: rightEarData,
            leftEarData: leftEarData
        )
    }
    
    // Helper method to convert to Firestore document
    func toFirestoreData() -> [String: Any] {
        return [
            "testDate": testDate,
            "rightEarClassification": rightEarClassification,
            "leftEarClassification": leftEarClassification,
            "rightEarData": rightEarData.map { ["frequency": $0.frequency, "hearingLevel": $0.hearingLevel] },
            "leftEarData": leftEarData.map { ["frequency": $0.frequency, "hearingLevel": $0.hearingLevel] }
        ]
    }
    
    // Helper method to get data for a specific frequency
    func getDataPoint(for frequency: Float, ear: AudioService.Ear) -> TestFrequencyDataPoint? {
        let data = ear == .right ? rightEarData : leftEarData
        return data.first { abs($0.frequency - frequency) < 10.0 }
    }
    
    // Helper to determine overall hearing status
    var overallHearingStatus: String {
        // Get worst classification
        let classifications = [rightEarClassification, leftEarClassification]
        let severityOrder = [
            "Normal Hearing": 0,
            "Mild Hearing Loss": 1,
            "Moderate Hearing Loss": 2,
            "Moderately Severe Hearing Loss": 3,
            "Severe Hearing Loss": 4,
            "Profound Hearing Loss": 5
        ]
        
        return classifications.max { (a, b) -> Bool in
            return (severityOrder[a] ?? 0) < (severityOrder[b] ?? 0)
        } ?? "Unknown"
    }
    
    // Determine if there's asymmetric hearing loss (significant difference between ears)
    var hasAsymmetricHearing: Bool {
        return abs(rightEarAverageLevel - leftEarAverageLevel) > 15.0
    }
}
