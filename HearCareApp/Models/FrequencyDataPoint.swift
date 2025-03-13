//
//  FrequencyDataPoint.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 5/3/2568 BE.
//

// Models/FrequencyDataPoint.swift
import Foundation

struct FrequencyDataPoint: Identifiable {
    let id = UUID()
    let frequency: Float
    let hearingLevel: Float
    
    var frequencyLabel: String {
        if frequency >= 1000 {
            return "\(Int(frequency/1000))k"
        }
        return "\(Int(frequency))"
    }
}
