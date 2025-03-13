//
//  HearingModelService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// Services/CoreML/HearingModelService.swift
import Foundation
import CoreML

class HearingModelService {
    private let model: HearingClassifier?
    
    enum HearingClassification: String, CaseIterable {
        case normal = "normal"
        case mild = "mild"
        case moderate = "moderate"
        case moderatelySevere = "moderatelySevere"
        case severe = "severe"
        case profound = "profound"
        
        var displayName: String {
            switch self {
            case .normal: return "Normal Hearing"
            case .mild: return "Mild Hearing Loss"
            case .moderate: return "Moderate Hearing Loss"
            case .moderatelySevere: return "Moderately Severe Hearing Loss"
            case .severe: return "Severe Hearing Loss"
            case .profound: return "Profound Hearing Loss"
            }
        }
        
        var description: String {
            switch self {
            case .normal:
                return "You can hear soft sounds across most frequencies."
            case .mild:
                return "You may have difficulty hearing soft sounds and understanding speech in noisy environments."
            case .moderate:
                return "You likely have difficulty following conversations without hearing aids."
            case .moderatelySevere:
                return "You have difficulty with normal conversations and may miss significant speech elements without amplification."
            case .severe:
                return "You may hear almost no speech when a person talks at a normal level."
            case .profound:
                return "You may not hear loud speech or sounds without powerful hearing aids or a cochlear implant."
            }
        }

        var recommendations: [String] {
            switch self {
            case .normal:
                return [
                    "Your hearing appears to be within normal range.",
                    "Continue to protect your hearing by avoiding prolonged exposure to loud noises.",
                    "Get your hearing checked annually as part of your health routine."
                ]
            case .mild:
                return [
                    "You have mild hearing loss in one or both ears.",
                    "Consider scheduling a follow-up appointment with an audiologist.",
                    "Avoid noisy environments when possible.",
                    "Consider using assistive listening devices in challenging situations."
                ]
            case .moderate:
                return [
                    "You have moderate hearing loss that may impact your daily communication.",
                    "We recommend consulting with an audiologist to discuss hearing aid options.",
                    "Consider strategies for better communication in noisy environments.",
                    "Look into hearing assistive technologies for phones and other devices."
                ]
            case .moderatelySevere:
                return [
                    "You have moderately severe hearing loss that significantly impacts daily communication.",
                    "Hearing aids are strongly recommended for this level of hearing loss.",
                    "Consider additional assistive listening devices for specific situations.",
                    "Learn communication strategies to maximize understanding in conversations."
                ]
            case .severe, .profound:
                return [
                    "You have significant hearing loss that requires professional attention.",
                    "Please consult with an audiologist as soon as possible.",
                    "Hearing aids or other assistive devices may significantly improve your quality of life.",
                    "Consider learning about additional communication strategies like speech reading."
                ]
            }
        }
    }
    
    init() {
        do {
            self.model = try HearingClassifier()
        } catch {
            print("Failed to initialize Core ML model: \(error.localizedDescription)")
            self.model = nil
        }
    }
    
    func classifyHearing(rightEarLevels: [Float: Float], leftEarLevels: [Float: Float]) -> (right: HearingClassification, left: HearingClassification)? {
        guard let model = model else {
            print("Model not available")
            return nil
        }
        
        // Create a dictionary of input values with proper types
        var inputDict: [String: Double] = [:]
        
        // Add right ear data
        for (frequency, level) in rightEarLevels {
            let key = "\(Int(frequency))Hz_right"
            inputDict[key] = Double(level)
        }
        
        // Add left ear data
        for (frequency, level) in leftEarLevels {
            let key = "\(Int(frequency))Hz_left"
            inputDict[key] = Double(level)
        }
        
        // Fill in any missing values with defaults
        for ear in ["right", "left"] {
            for freq in [250, 500, 1000, 2000, 4000, 8000] {
                let key = "\(freq)Hz_\(ear)"
                if inputDict[key] == nil {
                    inputDict[key] = 0.0  // Default to 0 dB (perfect hearing) if no data
                }
            }
        }
        
        do {
            // Use a more generic approach by accessing the model as an MLModel
            let genericModel = model.model
            
            // Create a feature provider from our dictionary
            let provider = try MLDictionaryFeatureProvider(dictionary: inputDict.mapValues { NSNumber(value: $0) })
            
            // Make prediction using the generic model interface
            let prediction = try genericModel.prediction(from: provider)
            
            // Extract the output from the prediction - fix for the conditional binding error
            let outputFeatureValue = prediction.featureValue(for: "hearingClassification")
            
            // Make sure we have a string value
            if let outputString = outputFeatureValue?.stringValue,
               let classification = HearingClassification(rawValue: outputString) {
                // For now, return the same classification for both ears
                return (right: classification, left: classification)
            } else {
                // Handle the case where we don't get a proper classification
                print("Invalid or missing classification value")
                
                // Use manual classification as fallback
                let rightClassification = classifyHearingManually(levels: rightEarLevels)
                let leftClassification = classifyHearingManually(levels: leftEarLevels)
                return (right: rightClassification, left: leftClassification)
            }
        } catch {
            print("Error making prediction: \(error.localizedDescription)")
            
            // Use manual classification as fallback
            let rightClassification = classifyHearingManually(levels: rightEarLevels)
            let leftClassification = classifyHearingManually(levels: leftEarLevels)
            return (right: rightClassification, left: leftClassification)
        }
    }
    
    // Fallback method for when ML model fails or isn't available
    func classifyHearingManually(levels: [Float: Float]) -> HearingClassification {
        // Calculate average hearing level
        let avgHearingLevel = levels.values.reduce(0, +) / Float(levels.count)
        
        // Classify based on standard audiometric ranges
        switch avgHearingLevel {
        case -10..<25:
            return .normal           // Normal hearing: -10 to 25 dB
        case 25..<40:
            return .mild             // Mild loss: 25-40 dB
        case 40..<55:
            return .moderate         // Moderate loss: 40-55 dB
        case 55..<70:
            return .moderatelySevere // Moderately severe loss: 55-70 dB
        case 70..<90:
            return .severe           // Severe loss: 70-90 dB
        default:
            return .profound         // Profound loss: 90+ dB
        }
    }
}
