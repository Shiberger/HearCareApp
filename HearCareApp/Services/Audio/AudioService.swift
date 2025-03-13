//
//  AudioService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import Foundation
import AVFoundation

class AudioService: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var tonePlayer: AVAudioPlayerNode?
    private var mixer: AVAudioMixerNode?
    
    @Published var isPlaying = false
    @Published var currentFrequency: Float = 0
    @Published var currentVolume: Float = 0.5
    let maxVolume: Float = 0.9
    @Published var userResponses: [TestResponse] = []
    
    private let testFrequencies: [Float] = [250, 500, 1000, 2000, 4000, 8000]
    private let volumeLevels: [Float] = [0.9, 0.7, 0.5, 0.3, 0.2, 0.1, 0.05, 0.025, 0.0125, 0.00625]
    
    struct TestResponse {
        let frequency: Float
        let volumeHeard: Float
        let ear: Ear
        let timestamp: Date
    }
    
    enum Ear {
        case left
        case right
    }
    
    init() {
        setupAudioSession()
        setupAudioEngine()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        tonePlayer = AVAudioPlayerNode()
        mixer = audioEngine?.mainMixerNode
        
        guard let audioEngine = audioEngine,
              let tonePlayer = tonePlayer,
              let mixer = mixer else { return }
        
        audioEngine.attach(tonePlayer)
        audioEngine.connect(tonePlayer, to: mixer, format: mixer.outputFormat(forBus: 0))
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    func generateTone(frequency: Float, volume: Float, ear: Ear) {
        stop()
        
        guard let tonePlayer = tonePlayer else { return }
        
        let sampleRate = Float(AVAudioSession.sharedInstance().sampleRate)
        let duration: Float = 2.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!,
                                       frameCapacity: frameCount)!
        
        let leftValue = ear == .left ? volume : 0
        let rightValue = ear == .right ? volume : 0
        
        for frame in 0..<Int(frameCount) {
            let sampleTime = Float(frame) / sampleRate
            let value = sin(2.0 * Float.pi * frequency * sampleTime)
            
            buffer.floatChannelData?[0][frame] = leftValue * value
            buffer.floatChannelData?[1][frame] = rightValue * value
        }
        
        buffer.frameLength = frameCount
        
        self.currentFrequency = frequency
        self.currentVolume = volume
        self.isPlaying = true
        
        tonePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: {
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        })
        
        tonePlayer.play()
    }
    
    func stop() {
        tonePlayer?.stop()
        isPlaying = false
    }
    
    // Make sure your recordResponse method can handle "not heard" responses:
    func recordResponse(heard: Bool, ear: Ear) {
        if heard {
            let response = TestResponse(
                frequency: currentFrequency,
                volumeHeard: currentVolume,
                ear: ear,
                timestamp: Date()
            )
            userResponses.append(response)
        } else {
            // Record that the frequency wasn't heard even at max volume
            let response = TestResponse(
                frequency: currentFrequency,
                volumeHeard: Float.infinity, // Use infinity to indicate "not heard"
                ear: ear,
                timestamp: Date()
            )
            userResponses.append(response)
        }
    }
    
    func runAutomatedTest(for ear: Ear, completion: @escaping () -> Void) {
        var currentFrequencyIndex = 0
        var currentVolumeIndex = 0
        var heardAtVolumes: [Float: Float] = [:]  // Frequency: Volume
        
        func playNextTone() {
            if currentFrequencyIndex >= testFrequencies.count {
                // Test complete
                completion()
                return
            }
            
            if currentVolumeIndex >= volumeLevels.count {
                // Move to next frequency
                currentFrequencyIndex += 1
                currentVolumeIndex = 0
                playNextTone()
                return
            }
            
            let frequency = testFrequencies[currentFrequencyIndex]
            let volume = volumeLevels[currentVolumeIndex]
            
            generateTone(frequency: frequency, volume: volume, ear: ear)
            
            // Wait for user response or timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.stop()
                
                // Present UI for user to indicate if they heard the tone
                // This would be handled by your SwiftUI view
                // For this example, we'll simulate a response
                let heard = Bool.random()  // In real app, get actual user response
                
                if heard {
                    heardAtVolumes[frequency] = volume
                    currentFrequencyIndex += 1
                    currentVolumeIndex = 0
                } else {
                    currentVolumeIndex += 1
                }
                
                // Wait a moment before playing the next tone
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    playNextTone()
                }
            }
        }
        
        playNextTone()
    }
}
