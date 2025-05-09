//
//  CalibrationService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/5/2568 BE.
//

import Foundation
import AVFoundation
import UIKit
import AudioToolbox

class CalibrationService: ObservableObject {
    // Singleton instance
    static let shared = CalibrationService()
    
    // Published properties for UI
    @Published var isCalibrated: Bool = false
    @Published var calibrationLevel: Float = 0.5  // Default volume level (0-1 scale)
    @Published var calibrationDate: Date?
    @Published var calibrationStatus: CalibrationStatus = .notCalibrated
    
    // Reference values in dB SPL for calibration tones
    private let referenceLevels: [Float: Float] = [
        1000: 40.0,  // 1000 Hz at 40 dB SPL for calibration
        2000: 40.0   // 2000 Hz backup frequency
    ]
    
    // Audio service
    var audioService: AudioService?
    
    // Calibration adjustments per frequency
    private(set) var frequencyAdjustments: [Float: Float] = [:]
    
    // User device and headphone model
    private(set) var deviceModel: String = ""
    private(set) var headphoneModel: String = "Unknown"
    
    // Debug properties
    private(set) var lastError: String? = nil
    private(set) var lastPlayAttemptTime: Date? = nil
    private(set) var audioRouteHistory: [String] = []
    
    enum CalibrationStatus {
        case notCalibrated
        case inProgress
        case completed
        case failed
        
        var description: String {
            switch self {
            case .notCalibrated:
                return "Device not calibrated"
            case .inProgress:
                return "Calibration in progress"
            case .completed:
                return "Calibration completed"
            case .failed:
                return "Calibration failed"
            }
        }
    }
    
    private init() {
        // Load saved calibration if available
        loadCalibration()
        
        // Get device model
        deviceModel = UIDevice.current.model
        
        // Try to detect connected headphones
        detectHeadphones()
        
        // Set up audio route change notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    deinit {
        // Remove observer when instance is deallocated
        NotificationCenter.default.removeObserver(self)
    }
    
    // Handle audio route changes
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        var reasonString = "unknown"
        switch reason {
        case .newDeviceAvailable:
            reasonString = "new device available"
        case .oldDeviceUnavailable:
            reasonString = "old device unavailable"
        case .categoryChange:
            reasonString = "category change"
        case .override:
            reasonString = "override"
        case .wakeFromSleep:
            reasonString = "wake from sleep"
        case .noSuitableRouteForCategory:
            reasonString = "no suitable route"
        case .routeConfigurationChange:
            reasonString = "route config change"
        case .unknown:
            reasonString = "unknown reason"
        @unknown default:
            reasonString = "unknown default"
        }
        
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let routeInfo = "[\(timestamp)] Route change: \(reasonString)"
        
        // Update history and detect headphones
        audioRouteHistory.insert(routeInfo, at: 0)
        if audioRouteHistory.count > 20 {
            audioRouteHistory.removeLast()
        }
        
        // Update headphone detection
        detectHeadphones()
    }
    
    // Start calibration process with an audio service instance
    func startCalibration(with audioService: AudioService) {
        self.audioService = audioService
        calibrationStatus = .inProgress
        
        // Reset current calibration
        frequencyAdjustments = [:]
        
        // Clear any previous errors
        lastError = nil
    }
    
    // Play calibration tone at 1000 Hz and reference level with error handling
    func playCalibrationTone(volume: Float, ear: AudioService.Ear) -> String? {
        guard let audioService = audioService else {
            let error = "Audio service not initialized"
            lastError = error
            return error
        }
        
        // Record attempt time
        lastPlayAttemptTime = Date()
        
        // Use 1000 Hz as standard calibration tone
        let frequency: Float = 1000.0
        
        // First, try to ensure audio session is properly configured
        do {
            try setupAudioSession()
        } catch {
            let errorMsg = "Failed to setup audio session: \(error.localizedDescription)"
            lastError = errorMsg
            return errorMsg
        }
        
        // Try system sound first to "wake up" the audio system
        AudioServicesPlaySystemSound(1103) // Quiet system sound
        
        // Then try to play our calibration tone with enhanced diagnostics
        return generateToneWithDiagnostics(frequency: frequency, volume: volume, ear: ear)
    }
    
    // Enhanced tone generation with error reporting
    private func generateToneWithDiagnostics(frequency: Float, volume: Float, ear: AudioService.Ear) -> String? {
        guard let audioService = self.audioService else {
            return "Audio service not available"
        }
        
        do {
            // Check if audio engine exists and is initialized
            if let engineStatus = getAudioEngineStatus() {
                // If engine isn't running, try to start it
                if engineStatus["Running"] as? Bool == false {
                    // Try to restart engine
                    try restartAudioEngine()
                }
            }
            
            // Play the tone with the provided parameters
            audioService.generateTone(frequency: frequency, volume: volume, ear: ear)
            
            // No errors occurred
            lastError = nil
            return nil
            
        } catch {
            let errorMsg = "Error generating tone: \(error.localizedDescription)"
            lastError = errorMsg
            return errorMsg
        }
    }
    
    // Method to restart audio engine if needed
    private func restartAudioEngine() throws {
        guard let audioService = audioService else {
            throw NSError(domain: "CalibrationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No audio service available"])
        }
        
        // Access audio engine through reflection if needed
        // This might be needed depending on how AudioService is implemented
        // Alternatively, add a dedicated restart method to AudioService
        
        // For now, we'll try to recreate the tone player
        try audioService.resetAudioEngine()
    }
    
    // Setup audio session with proper configuration
    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        
        // Configure session for playback
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Update headphone detection after session setup
        detectHeadphones()
    }
    
    // Stop playing tone
    func stopTone() {
        audioService?.stop()
    }
    
    // Set calibration level for the current device/headphones
    func setCalibrationLevel(_ level: Float) {
        calibrationLevel = level
        
        // For now, we use a single adjustment for all frequencies
        let referenceFrequency: Float = 1000.0
        frequencyAdjustments[referenceFrequency] = level
        
        // Mark as calibrated
        isCalibrated = true
        calibrationDate = Date()
        calibrationStatus = .completed
        
        // Save calibration
        saveCalibration()
    }
    
    // Save calibration to UserDefaults
    private func saveCalibration() {
        let defaults = UserDefaults.standard
        
        defaults.set(isCalibrated, forKey: "isCalibrated")
        defaults.set(calibrationLevel, forKey: "calibrationLevel")
        defaults.set(calibrationDate, forKey: "calibrationDate")
        defaults.set(deviceModel, forKey: "calibrationDeviceModel")
        defaults.set(headphoneModel, forKey: "calibrationHeadphoneModel")
        
        // Convert frequency adjustments to use string keys
        var adjustmentsWithStringKeys: [String: Float] = [:]
        for (frequency, value) in frequencyAdjustments {
            adjustmentsWithStringKeys["\(frequency)"] = value
        }
        
        // Save the converted dictionary
        defaults.set(adjustmentsWithStringKeys, forKey: "frequencyAdjustments")
    }
    
    // Load calibration from UserDefaults
    private func loadCalibration() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "isCalibrated") != nil {
            isCalibrated = defaults.bool(forKey: "isCalibrated")
            calibrationLevel = defaults.float(forKey: "calibrationLevel")
            calibrationDate = defaults.object(forKey: "calibrationDate") as? Date
            deviceModel = defaults.string(forKey: "calibrationDeviceModel") ?? UIDevice.current.model
            headphoneModel = defaults.string(forKey: "calibrationHeadphoneModel") ?? "Unknown"
            
            // Load frequency adjustments with string key conversion
            if let savedAdjustments = defaults.dictionary(forKey: "frequencyAdjustments") as? [String: Float] {
                frequencyAdjustments = [:]
                for (frequencyString, value) in savedAdjustments {
                    if let frequency = Float(frequencyString) {
                        frequencyAdjustments[frequency] = value
                    }
                }
            }
            
            // Update status
            calibrationStatus = isCalibrated ? .completed : .notCalibrated
        }
    }
    
    // Reset calibration
    func resetCalibration() {
        isCalibrated = false
        calibrationLevel = 0.5
        calibrationDate = nil
        calibrationStatus = .notCalibrated
        frequencyAdjustments = [:]
        
        // Save the reset state
        saveCalibration()
    }
    
    // Get adjusted volume for a specific frequency based on calibration
    func getAdjustedVolume(for frequency: Float, volume: Float) -> Float {
        guard isCalibrated else {
            return volume // Return unadjusted if not calibrated
        }
        
        // If we have a specific adjustment for this frequency, use it
        if let adjustment = frequencyAdjustments[frequency] {
            // Calculate the adjustment ratio
            let ratio = adjustment / 0.5 // Ratio relative to default level (0.5)
            
            // Apply ratio to requested volume
            return min(max(volume * ratio, 0.0), 1.0)
        }
        
        // If we don't have a specific adjustment for this frequency,
        // use the adjustment for 1000 Hz as a fallback
        if let baseAdjustment = frequencyAdjustments[1000.0] {
            let ratio = baseAdjustment / 0.5
            return min(max(volume * ratio, 0.0), 1.0)
        }
        
        // If no calibration data is available, return the original volume
        return volume
    }
    
    // Convert dB HL to calibrated device volume (0-1 scale)
    func convertDBToDeviceVolume(dbHL: Float, frequency: Float) -> Float {
        // Base conversion table (approximate)
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
        
        // Find closest match in the map
        let sortedKeys = dbToVolumeMap.keys.sorted()
        
        // Handle values below or above our map
        if dbHL <= sortedKeys.first! {
            return getAdjustedVolume(for: frequency, volume: dbToVolumeMap[sortedKeys.first!]!)
        }
        
        if dbHL >= sortedKeys.last! {
            return getAdjustedVolume(for: frequency, volume: dbToVolumeMap[sortedKeys.last!]!)
        }
        
        // Linear interpolation for values in between
        for i in 0..<(sortedKeys.count - 1) {
            let db1 = sortedKeys[i]
            let db2 = sortedKeys[i + 1]
            
            if dbHL >= db1 && dbHL <= db2 {
                let v1 = dbToVolumeMap[db1]!
                let v2 = dbToVolumeMap[db2]!
                
                let interpolatedVolume = v1 + (v2 - v1) * (dbHL - db1) / (db2 - db1)
                return getAdjustedVolume(for: frequency, volume: interpolatedVolume)
            }
        }
        
        // Fallback
        return getAdjustedVolume(for: frequency, volume: min(max(dbHL / 80.0, 0.05), 1.0))
    }
    
    // Public method to detect connected headphones
    func detectHeadphones() {
        let audioSession = AVAudioSession.sharedInstance()
        
        // Check current audio route
        if let outputs = audioSession.currentRoute.outputs as? [AVAudioSessionPortDescription], !outputs.isEmpty {
            for output in outputs {
                if output.portType == .headphones ||
                   output.portType == .bluetoothA2DP ||
                   output.portType == .bluetoothHFP ||
                   output.portType == .bluetoothLE {
                    headphoneModel = output.portName
                    
                    // Log headphone detection
                    let timestamp = Date().formatted(date: .omitted, time: .standard)
                    audioRouteHistory.insert("[\(timestamp)] Headphones detected: \(output.portName) (\(output.portType))", at: 0)
                    
                    return
                }
            }
        }
        
        // No headphones detected
        headphoneModel = "No headphones detected"
        
        // Log no headphones
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        audioRouteHistory.insert("[\(timestamp)] No headphones detected", at: 0)
    }
    
    // Check if the current device and headphones match the calibrated ones
    func isCalibrationValid() -> Bool {
        guard isCalibrated else { return false }
        
        // Check if device model matches
        let currentDevice = UIDevice.current.model
        if currentDevice != deviceModel {
            return false
        }
        
        // Optionally check if headphones match
        detectHeadphones()
        
        // If headphones have changed and we previously had headphones,
        // we might want to recalibrate
        if headphoneModel != "No headphones detected" &&
           headphoneModel != "Unknown" &&
           defaults.string(forKey: "calibrationHeadphoneModel") != headphoneModel {
            return false
        }
        
        return true
    }
    
    // Get audio engine status for debugging
    func getAudioEngineStatus() -> [String: Any]? {
        return audioService?.getAudioEngineStatus()
    }
    
    // Get current audio route description
    func getCurrentAudioRouteDescription() -> String {
        let session = AVAudioSession.sharedInstance()
        var description = "Audio Route:\n"
        
        // Outputs
        if session.currentRoute.outputs.isEmpty {
            description += "- No outputs\n"
        } else {
            description += "- Outputs:\n"
            for (index, output) in session.currentRoute.outputs.enumerated() {
                description += "  \(index+1). \(output.portName) (\(output.portType))\n"
            }
        }
        
        // Inputs
        if session.currentRoute.inputs.isEmpty {
            description += "- No inputs\n"
        } else {
            description += "- Inputs:\n"
            for (index, input) in session.currentRoute.inputs.enumerated() {
                description += "  \(index+1). \(input.portName) (\(input.portType))\n"
            }
        }
        
        return description
    }
    
    // Get route change history
    func getRouteChangeHistory() -> [String] {
        return audioRouteHistory
    }
    
    // Computed property for easier access to UserDefaults
    private var defaults: UserDefaults {
        return UserDefaults.standard
    }
    
    func resetAudioEnvironment() {
        // Example implementation - modify based on your actual service structure
        
        // 1. Reset any ambient noise level tracking
        // ambientNoiseLevel = 0.0
        
        // 2. Tell the audio service to reset if needed
        audioService?.stop()
        
        // 3. Reset any cached audio data or temporary files
        // clearAudioCache()
        
        // 4. Setup fresh session if needed
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false)
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            print("Error resetting audio session: \(error)")
        }
        
        // 5. Notify any observers that audio environment has been reset
        objectWillChange.send()
        
        print("Audio environment reset completed")
    }
}
