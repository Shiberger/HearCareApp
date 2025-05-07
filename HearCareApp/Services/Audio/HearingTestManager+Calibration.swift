//
//  HearingTestManager+Calibration.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/5/2568 BE.
//

import Foundation

// Extension to add calibration support to the HearingTestManager
extension HearingTestManager {
    // Check if device is calibrated and calibration is still valid
    var isReadyForTesting: Bool {
        // Use the shared CalibrationService instead of trying to access the private audioService
        return CalibrationService.shared.isCalibrated &&
               CalibrationService.shared.isCalibrationValid()
    }
    
    // Get days since last calibration
    var daysSinceCalibration: Int? {
        guard let calibrationDate = CalibrationService.shared.calibrationDate else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calibrationDate, to: Date())
        return components.day
    }
    
    // Method to check calibration status and prompt if needed
    func checkCalibrationStatus() -> CalibrationStatus {
        let calibrationService = CalibrationService.shared
        
        if !calibrationService.isCalibrated {
            return .needsCalibration
        }
        
        if !calibrationService.isCalibrationValid() {
            return .needsRecalibration
        }
        
        // If it's been more than 90 days since last calibration
        if let days = daysSinceCalibration, days > 90 {
            return .recommendRecalibration
        }
        
        return .calibrated
    }
    
    // Calibration status enum
    enum CalibrationStatus {
        case calibrated
        case needsCalibration
        case needsRecalibration
        case recommendRecalibration
        
        var message: String {
            switch self {
            case .calibrated:
                return "Device is calibrated and ready for testing."
            case .needsCalibration:
                return "Your device needs to be calibrated before testing."
            case .needsRecalibration:
                return "Your device or headphones have changed and need recalibration."
            case .recommendRecalibration:
                return "It's been over 3 months since your last calibration."
            }
        }
    }
}
