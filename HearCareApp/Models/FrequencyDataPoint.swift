//
//  FrequencyDataPoint.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 5/3/2568 BE.
//

import Foundation

struct FrequencyDataPoint: Identifiable {
    let id: Float  // Use frequency as the unique identifier
    let frequency: Float
    let hearingLevel: Float
    
    // Initialize id with frequency since they’re the same in this context
    init(frequency: Float, hearingLevel: Float) {
        self.id = frequency
        self.frequency = frequency
        self.hearingLevel = hearingLevel
    }
    
    var frequencyLabel: String {
        frequency >= 1000 ? "\(Int(frequency/1000))k" : "\(Int(frequency))"
    }
}
