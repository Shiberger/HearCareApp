//
//  AmbientSoundService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 22/4/2568 BE.
//

import Foundation
import AVFoundation

class AmbientSoundService: NSObject, ObservableObject {
    // Published properties for UI
    @Published var isMonitoring = false
    @Published var currentDecibels: Float = 0
    @Published var ambientNoiseLevel: NoiseLevel = .acceptable
    @Published var permissionStatus: MicrophonePermissionStatus = .undetermined
    
    // Audio capture properties
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var updateInterval: TimeInterval = 0.5 // Update every half second
    
    // Noise level thresholds in decibels
    private let acceptableThreshold: Float = 35.0  // Quiet room: 30-40 dB
    private let moderateThreshold: Float = 50.0    // Normal conversation: 50-60 dB
    private let excessiveThreshold: Float = 65.0   // Busy street or loud environment: >65 dB
    
    // Singleton instance
    static let shared = AmbientSoundService()
    
    // Noise level enum
    enum NoiseLevel: String {
        case acceptable = "Acceptable"
        case moderate = "Moderate"
        case excessive = "Excessive"
        
        var description: String {
            switch self {
            case .acceptable:
                return "The environment is quiet and suitable for hearing tests."
            case .moderate:
                return "The environment has some background noise that might affect test accuracy."
            case .excessive:
                return "The environment is too noisy for accurate hearing testing."
            }
        }
        
        var icon: String {
            switch self {
            case .acceptable: return "checkmark.circle.fill"
            case .moderate: return "exclamationmark.triangle.fill"
            case .excessive: return "xmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .acceptable: return "green"
            case .moderate: return "yellow"
            case .excessive: return "red"
            }
        }
    }
    
    // Permission status enum
    enum MicrophonePermissionStatus {
        case undetermined
        case granted
        case denied
    }
    
    override init() {
        super.init()
        
        // Check current authorization status
        checkPermissionStatus()
    }
    
    // Check the current microphone permission status
    func checkPermissionStatus() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            self.permissionStatus = .granted
        case .denied:
            self.permissionStatus = .denied
        case .undetermined:
            self.permissionStatus = .undetermined
        @unknown default:
            self.permissionStatus = .undetermined
        }
    }
    
    // Request microphone permissions
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionStatus = granted ? .granted : .denied
                completion(granted)
            }
        }
    }
    
    // Start monitoring ambient noise levels
    func startMonitoring() {
        // Check if already monitoring
        guard !isMonitoring else { return }
        
        // Check and request permission if needed
        if permissionStatus != .granted {
            requestMicrophonePermission { [weak self] granted in
                if granted {
                    self?.setupAudioRecording()
                } else {
                    print("Microphone permission denied")
                }
            }
        } else {
            setupAudioRecording()
        }
    }
    
    // Stop monitoring ambient noise
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        isMonitoring = false
    }
    
    // Setup audio session and recorder
    private func setupAudioRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            // Configure audio recorder
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Use temporary URL since we don't need to save the recording
            let temporaryDirectory = NSTemporaryDirectory()
            let temporaryURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent("ambient_sound_level.m4a")
            
            // Create and configure recorder
            audioRecorder = try AVAudioRecorder(url: temporaryURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            // Start recording
            if audioRecorder?.record() == true {
                isMonitoring = true
                
                // Schedule timer to update sound level
                timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
                    self?.updateSoundLevel()
                }
            } else {
                print("Failed to start audio recording")
            }
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
        }
    }
    
    // Update current sound level
    private func updateSoundLevel() {
        guard let recorder = audioRecorder, isMonitoring else { return }
        
        recorder.updateMeters()
        
        // Get the average power from the recorder in decibels
        let averagePower = recorder.averagePower(forChannel: 0)
        
        // Converting to a more usable decibel range (from negative dB to positive)
        // Typical values range from -160 (silence) to 0 (max volume)
        // We're adjusting to make it more intuitive (0-100 range)
        let adjustedDecibels = max(0, 100 + averagePower)
        currentDecibels = adjustedDecibels
        
        // Update the noise level classification
        updateNoiseLevel(decibels: adjustedDecibels)
    }
    
    // Determine noise level classification
    private func updateNoiseLevel(decibels: Float) {
        if decibels <= acceptableThreshold {
            ambientNoiseLevel = .acceptable
        } else if decibels <= moderateThreshold {
            ambientNoiseLevel = .moderate
        } else {
            ambientNoiseLevel = .excessive
        }
    }
    
    // Check if the current environment is suitable for testing
    func isEnvironmentSuitableForTesting() -> Bool {
        // Consider both acceptable and moderate levels as suitable
        return ambientNoiseLevel != .excessive
    }
}
