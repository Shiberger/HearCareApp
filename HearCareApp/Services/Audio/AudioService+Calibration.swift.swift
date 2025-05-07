//
//  AudioService+Calibration.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/5/2568 BE.
//

import Foundation

// Extension to AudioService to support calibration
extension AudioService {
    // Modified method to generate calibrated tones
    func generateCalibratedTone(frequency: Float, dbHL: Float, ear: Ear) {
        let calibrationService = CalibrationService.shared
        
        // Convert dB HL to device volume using calibration
        let deviceVolume = calibrationService.convertDBToDeviceVolume(dbHL: dbHL, frequency: frequency)
        
        // Use the existing method with calibrated volume
        generateTone(frequency: frequency, volume: deviceVolume, ear: ear)
        
        // Update current properties
        currentFrequency = frequency
        // Store the original dB level rather than volume
        currentVolume = dbHL
    }
    
    // Convert dB to volume based on calibration
    func calibratedVolumeFor(dbHL: Float, frequency: Float) -> Float {
        return CalibrationService.shared.convertDBToDeviceVolume(dbHL: dbHL, frequency: frequency)
    }
    
    // Check if device is calibrated
    var isCalibrated: Bool {
        return CalibrationService.shared.isCalibrated
    }
    
    // Check if calibration is still valid
    var isCalibrationValid: Bool {
        return CalibrationService.shared.isCalibrationValid()
    }
    
    // Get calibration date
    var calibrationDate: Date? {
        return CalibrationService.shared.calibrationDate
    }
}
