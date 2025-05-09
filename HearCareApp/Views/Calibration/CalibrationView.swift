//
//  CalibrationView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/5/2568 BE.
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct CalibrationView: View {
    @ObservedObject private var calibrationService = CalibrationService.shared
    @StateObject private var audioService = AudioService()
    @State private var currentStep = 0
    @State private var sliderValue: Float = 0.5
    @State private var isPlaying = false
    @State private var selectedEar: AudioService.Ear = .right
    @State private var showingHeadphoneWarning = false
    @State private var showingCompletionAlert = false
    
    // Direct audio generation properties
    @State private var directAudioEngine: AVAudioEngine?
    @State private var directPlayer: AVAudioPlayerNode?
    
    // AVAudioPlayer approach
    @State private var audioPlayer: AVAudioPlayer?
    @State private var systemSoundID: SystemSoundID = 0
    
    // Debug panel states
    @State private var showDebugPanel = false
    @State private var audioSessionInfo = "No information"
    @State private var routeChangeHistory: [String] = []
    @State private var audioSessionCategory = ""
    @State private var audioSessionMode = ""
    @State private var audioSessionProperties: [String: String] = [:]
    @State private var playingError: String? = nil
    @State private var debugTimer: Timer? = nil
    
    @Environment(\.presentationMode) private var presentationMode
    @Binding var shouldResetAmbientNoise: Bool
    
    // Steps for calibration process
    private let steps = [
        "Introduction",
        "Headphone Check",
        "Level Adjustment",
        "Confirmation",
        "Completion"
    ]
    
    // Add a state to track which alert to show
    @State private var activeAlert: ActiveAlert? = nil
    
    enum ActiveAlert: Identifiable {
        case headphoneWarning
        case completionSuccess
        
        var id: Int {
            switch self {
            case .headphoneWarning:
                return 0
            case .completionSuccess:
                return 1
            }
        }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Header
            Text("Device Calibration")
                .font(AppTheme.Typography.title2)
                .padding(.top)
            
            // Progress indicators
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? AppTheme.primaryColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom, AppTheme.Spacing.small)
            
            // Current step label
            Text(steps[currentStep])
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.primaryColor)
                .padding(.bottom)
            
            // Content area
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Step-specific content
                    getContentForStep(currentStep)
                }
                .padding()
            }
            
            Spacer()
            
            // Navigation buttons
            getNavigationButtons()
        }
        .padding()
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Calibration")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            Group {
                if showDebugPanel {
                    debugPanelView
                        .transition(.move(edge: .bottom))
                }
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        showDebugPanel.toggle()
                        
                        // Start or stop the debug timer
                        if showDebugPanel {
                            startDebugTimer()
                            refreshAudioSessionInfo()
                        } else {
                            debugTimer?.invalidate()
                            debugTimer = nil
                        }
                    }
                }) {
                    Image(systemName: "ant")
                        .foregroundColor(showDebugPanel ? .red : .blue)
                }
            }
        }
        .onAppear {
            // Start calibration process
            calibrationService.startCalibration(with: audioService)
            
            // Set up route change notification
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [self] notification in
                guard let userInfo = notification.userInfo,
                      let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                    return
                }
                
                let session = AVAudioSession.sharedInstance()
                let timestamp = Date().formatted(date: .omitted, time: .standard)
                
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
                
                // Get output description
                let outputDesc = session.currentRoute.outputs.first?.portName ?? "none"
                
                routeChangeHistory.insert("[\(timestamp)] Route changed: \(reasonString) - Output: \(outputDesc)", at: 0)
                
                // Refresh all audio session info
                refreshAudioSessionInfo()
                
                // Detect headphones - update calibration service
                calibrationService.detectHeadphones()
            }
            
            // Initial refresh
            refreshAudioSessionInfo()
        }
        .onDisappear {
            // Stop any playing tones
            stopAllAudio()
            
            // Remove the notification observer
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
            
            // Stop timer
            debugTimer?.invalidate()
            debugTimer = nil
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .headphoneWarning:
                return Alert(
                    title: Text("Headphones Recommended"),
                    message: Text("เพื่อการ Calibration และการทดสอบที่แม่นยำ โปรดใช้หูฟัง คุณต้องการดำเนินการต่อโดยไม่ใช้หูฟังหรือไม่?"),
                    primaryButton: .default(Text("Continue Anyway")) {
                        currentStep += 1
                    },
                    secondaryButton: .cancel(Text("I'll Get Headphones"))
                )
            case .completionSuccess:
                return Alert(
                    title: Text("Calibration Successful"),
                    message: Text("อุปกรณ์ของคุณได้รับการ Calibration สำหรับการทดสอบการได้ยินที่แม่นยำเรียบร้อยแล้ว"),
                    dismissButton: .default(Text("OK")) {
                        // Trigger ambient noise level reset
                        shouldResetAmbientNoise = true
                        
                        // Dismiss this view and return to the home screen
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Debug Panel
    
    private var debugPanelView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Audio Debug Panel")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Group {
                    Text("Device: \(UIDevice.current.model)")
                    Text("iOS Version: \(UIDevice.current.systemVersion)")
                    
                    Divider()
                    
                    Text("Audio Session Category: \(audioSessionCategory)")
                    Text("Audio Session Mode: \(audioSessionMode)")
                    
                    Divider()
                    
                    Text("Current Route:")
                        .font(.subheadline)
                        .bold()
                    
                    ForEach(audioSessionProperties.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        Text("\(key): \(value)")
                            .font(.caption)
                    }
                    
                    if let error = playingError {
                        Text("Last Error: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    Text("Route Change History:")
                        .font(.subheadline)
                        .bold()
                    
                    ForEach(routeChangeHistory.indices.prefix(10), id: \.self) { index in
                        Text(routeChangeHistory[index])
                            .font(.caption)
                            .foregroundColor(index == 0 ? .primary : .secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Button(action: {
                        refreshAudioSessionInfo()
                    }) {
                        Text("Refresh Info")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    
                    Button(action: {
                        testAudioWithSystemSound()
                    }) {
                        Text("Test System Sound")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    
                    Button(action: {
                        routeChangeHistory.removeAll()
                    }) {
                        Text("Clear History")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .padding()
        }
        .frame(height: 400)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Debug Functions
    
    private func startDebugTimer() {
        debugTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshAudioSessionInfo()
        }
    }
    
    private func refreshAudioSessionInfo() {
        let session = AVAudioSession.sharedInstance()
        
        // Get category and mode
        audioSessionCategory = String(describing: session.category)
        audioSessionMode = String(describing: session.mode)
        
        // Get current route info
        var properties: [String: String] = [:]
        
        // Current Output Route
        if let currentRoute = session.currentRoute.outputs.first {
            properties["Output Port"] = currentRoute.portName
            properties["Output Type"] = String(describing: currentRoute.portType)
            properties["Output UID"] = currentRoute.uid
        } else {
            properties["Output"] = "No output route"
        }
        
        // Current Input Route
        if let currentInput = session.currentRoute.inputs.first {
            properties["Input Port"] = currentInput.portName
            properties["Input Type"] = String(describing: currentInput.portType)
            properties["Input UID"] = currentInput.uid
        } else {
            properties["Input"] = "No input route"
        }
        
        // Additional session properties
        properties["Sample Rate"] = "\(session.sampleRate) Hz"
        properties["Buffer Duration"] = "\(session.ioBufferDuration) sec"
        properties["Preferred IO Buffer"] = "\(session.preferredIOBufferDuration) sec"
        properties["OutputVolume"] = "\(session.outputVolume)"
        properties["OutputLatency"] = "\(session.outputLatency) sec"
        properties["InputLatency"] = "\(session.inputLatency) sec"
        properties["Is Other Audio Playing"] = "\(session.isOtherAudioPlaying)"
        
        // Headphone detection specific checks
        let isHeadsetPluggedIn = isHeadsetConnected()
        properties["Headphones Detected"] = "\(isHeadsetPluggedIn)"
        properties["Headphone Model"] = calibrationService.headphoneModel
        
        // Audio engine status - use properly exposed method
        if let engineStatus = calibrationService.getAudioEngineStatus() {
            for (key, value) in engineStatus {
                properties["Engine: \(key)"] = "\(value)"
            }
        }
        
        // Direct engine status
        if let directAudioEngine = directAudioEngine {
            properties["Direct Engine Running"] = "\(directAudioEngine.isRunning)"
        }
        
        // AVAudioPlayer status
        if let player = audioPlayer {
            properties["AVAudioPlayer"] = "Active"
            properties["AVAudioPlayer Volume"] = "\(player.volume)"
        }
        
        self.audioSessionProperties = properties
    }
    
    // Method to check if headset is connected
    private func isHeadsetConnected() -> Bool {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        
        for output in outputs {
            if output.portType == .headphones ||
                output.portType == .bluetoothA2DP ||
                output.portType == .bluetoothHFP ||
                output.portType == .bluetoothLE {
                return true
            }
        }
        return false
    }
    
    // Test system sound to bypass our custom audio implementation
    private func testAudioWithSystemSound() {
        // Play a simple system sound to test if audio works at all
        AudioServicesPlaySystemSound(1104) // Standard system sound
        
        // Add to history
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        routeChangeHistory.insert("[\(timestamp)] System sound test triggered", at: 0)
    }
    
    // MARK: - Step-specific content
    
    @ViewBuilder
    private func getContentForStep(_ step: Int) -> some View {
        switch step {
        case 0:
            introductionStepContent
        case 1:
            headphoneCheckStepContent
        case 2:
            levelAdjustmentStepContent
        case 3:
            confirmationStepContent
        case 4:
            completionStepContent
        default:
            EmptyView()
        }
    }
    
    private var introductionStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "tuningfork")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            Text("Welcome to Calibration")
                .font(AppTheme.Typography.title3)
            
            Text("การ Calibration ช่วยให้มั่นใจได้ว่าผลการทดสอบการได้ยินของคุณแม่นยำโดยปรับให้เหมาะกับอุปกรณ์และหูฟังเฉพาะของคุณ")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                calibrationInfoRow(number: 1, text: "อยู่ในห้องที่มีสภาพแวดล้อมที่เงียบสงบ")
                calibrationInfoRow(number: 2, text: "ใช้หูฟังเพื่อผลลัพธ์ที่ดีที่สุด")
                calibrationInfoRow(number: 3, text: "ตั้งระดับเสียงอุปกรณ์ของเป็นประมาณ 50%")
                calibrationInfoRow(number: 4, text: "กระบวนการนี้ใช้เวลาประมาณ 2 นาที")
            }
            .padding(.vertical)
            
            Text("Your device: \(UIDevice.current.model)")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
    
    private var headphoneCheckStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            Text("Headphone Check")
                .font(AppTheme.Typography.title3)
            
            Text("โปรดเชื่อมต่อหูฟังกับอุปกรณ์ของคุณเพื่อการ Calibration และการทดสอบที่แม่นยำ")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            HStack {
                Image(systemName: calibrationService.headphoneModel == "No headphones detected" ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(calibrationService.headphoneModel == "No headphones detected" ? .red : .green)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading) {
                    Text(calibrationService.headphoneModel == "No headphones detected" ? "No Headphones Detected" : "Headphones Connected")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.primaryColor)
                    
                    if calibrationService.headphoneModel != "No headphones detected" {
                        Text(calibrationService.headphoneModel)
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // Add manual detection refresh button
            Button(action: {
                calibrationService.detectHeadphones()
                refreshAudioSessionInfo()
                let timestamp = Date().formatted(date: .omitted, time: .standard)
                routeChangeHistory.insert("[\(timestamp)] Manual headphone detection check", at: 0)
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Check Again")
                }
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.primaryColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .stroke(AppTheme.primaryColor, lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical)
            
            Text("หูฟังช่วยให้มั่นใจได้ว่าเสียงจะส่งตรงถึงหูของคุณในระดับที่สม่ำเสมอ การใช้ลำโพงของอุปกรณ์อาจทำให้ผลการทดสอบมีความแม่นยำน้อยลง")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top)
        }
    }
    
    private var levelAdjustmentStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Adjust Reference Level")
                .font(AppTheme.Typography.title3)
            
            Text("คุณจะได้ยินเสียงอ้างอิงที่ความถี่ 1,000Hz โดยปรับแถบเลื่อนจนได้ยินเสียงเบาที่สุดจนได้ยินชัดเจน")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            // Ear selection
            earSelectionView
                .padding(.vertical)
            
            // Tone controls
            VStack(spacing: AppTheme.Spacing.medium) {
                Button(action: toggleTone) {
                    HStack {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                        Text(isPlaying ? "Stop Tone" : "Play Reference Tone")
                            .font(AppTheme.Typography.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isPlaying ? Color.red : AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.Radius.medium)
                }
                
                // If there's an error, show it
                if let error = playingError {
                    Text("Issue detected: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Add system sound test button here too
                Button(action: testAudioWithSystemSound) {
                    Text("Test Device Sound")
                        .font(AppTheme.Typography.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(AppTheme.Radius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .stroke(Color.green, lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Volume adjustment slider
                Text("Adjust the level")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                VStack {
                    Slider(value: $sliderValue, in: 0.01...1.0) { editing in
                        if !editing && isPlaying {
                            // Update the playing tone when slider is released
                            updateToneVolume()
                        }
                    }
                    
                    HStack {
                        Text("Softer")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        Text("Louder")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
            
            Text("เสียงที่ใช้ในการ Calibration ตั้งไว้ที่ระดับอ้างอิง 40 เดซิเบล การปรับให้พอได้ยินจะช่วยให้เรากำหนดค่าระดับเสียงที่ถูกต้องสำหรับอุปกรณ์ของคุณ")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top)
        }
    }
    
    private var confirmationStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Confirm Calibration Level")
                .font(AppTheme.Typography.title3)
            
            Text("มาตรวจสอบการตั้งค่าการ Calibration ของคุณกัน เราจะเล่นเสียงอ้างอิงที่ระดับที่คุณเลือก คุณควรจะได้ยินมันอย่างชัดเจน แต่เสียงนั้นควรจะยังเบาอยู่")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
            
            // Ear selection
            earSelectionView
                .padding(.vertical)
            
            // Confirmation controls
            VStack(spacing: AppTheme.Spacing.medium) {
                Button(action: toggleTone) {
                    HStack {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                        Text(isPlaying ? "Stop Tone" : "Play Calibration Tone")
                            .font(AppTheme.Typography.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isPlaying ? Color.red : AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.Radius.medium)
                }
                
                // If there's an error, show it
                if let error = playingError {
                    Text("Issue detected: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Add system sound test button
                Button(action: testAudioWithSystemSound) {
                    Text("Test Device Sound")
                        .font(AppTheme.Typography.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(AppTheme.Radius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .stroke(Color.green, lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Display selected level
                HStack {
                    Text("Selected Level:")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.primaryColor)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", sliderValue))
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.primaryColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
            
            // Confirmation questions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("คุณสามารถตอบคำถามเหล่านี้ได้ไหม")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.primaryColor)
                
                Text("1. เสียงสามารถได้ยินชัดเจนแต่ยังคงนุ่มนวลอยู่หรือไม่?")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.primaryColor)
                
                Text("2. คุณจะสามารถรับรู้เสียงนี้ได้ในห้องที่เงียบสงบหรือไม่?")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.primaryColor)
                
                Text("หากคุณตอบว่า ใช่ ทั้งสองคำถาม แสดงว่าการ Calibration ของคุณดีแล้วแต่ถ้าหากไม่เป็นเช่นนั้น ให้กลับไปและปรับระดับอีกครั้ง")
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var completionStepContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            Text("Calibration Complete!")
                .font(AppTheme.Typography.title3)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Device:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(UIDevice.current.model)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.primaryColor)
                }
                
                Divider()
                
                HStack {
                    Text("Headphones:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(calibrationService.headphoneModel)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.primaryColor)
                }
                
                Divider()
                
                HStack {
                    Text("Calibration Level:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", sliderValue))
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.primaryColor)
                }
                
                Divider()
                
                HStack {
                    Text("Date:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(Date(), style: .date)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.primaryColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            Text("ตอนนี้อุปกรณ์ของคุณได้รับการ Calibration สำหรับการทดสอบการได้ยินที่แม่นยำแล้ว อย่าลืมปรับเทียบใหม่หากคุณเปลี่ยนหูฟังหรือผ่านไปแล้วมากกว่า 3 เดือนนับจากการ Calibration ครั้งสุดท้าย")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top)
            
            Text("การ Calibration จะช่วยเพิ่มความแม่นยำของการทดสอบการได้ยินของคุณ โดยช่วยให้แน่ใจว่าเสียงจะเล่นในระดับที่ถูกต้องสำหรับอุปกรณ์และหูฟังเฉพาะของคุณ")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, AppTheme.Spacing.small)
        }
    }
    
    // MARK: - Helper Views
    
    private var earSelectionView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Select Ear")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.large) {
                Button(action: {
                    selectedEar = .left
                    if isPlaying {
                        // Update the playing tone with new ear selection
                        updateEarSelection()
                    }
                }) {
                    VStack {
                        Image(systemName: "ear.fill")
                            .font(.system(size: 28))
                            .foregroundColor(selectedEar == .left ? .blue : .gray)
                        
                        Text("Left Ear")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(selectedEar == .left ? .blue : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(selectedEar == .left ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(selectedEar == .left ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                Button(action: {
                    selectedEar = .right
                    if isPlaying {
                        // Update the playing tone with new ear selection
                        updateEarSelection()
                    }
                }) {
                    VStack {
                        Image(systemName: "ear.fill")
                            .font(.system(size: 28))
                            .foregroundColor(selectedEar == .right ? .red : .gray)
                        
                        Text("Right Ear")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(selectedEar == .right ? .red : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(selectedEar == .right ? Color.red.opacity(0.1) : Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(selectedEar == .right ? Color.red : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    private func calibrationInfoRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(number)")
                .font(AppTheme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.primaryColor))
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Buttons
    
    @ViewBuilder
    private func getNavigationButtons() -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Back button
            if currentStep > 0 {
                Button(action: {
                    if isPlaying {
                        toggleTone()
                    }
                    currentStep -= 1
                }) {
                    Text("Back")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.primaryColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(AppTheme.Radius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(AppTheme.primaryColor, lineWidth: 1)
                        )
                }
            } else {
                // Empty spacer for consistent layout
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            
            // Next/Finish button
            Button(action: {
                handleNextButtonTap()
            }) {
                Text(currentStep == steps.count - 1 ? "Finish" : "Next")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor)
                    .cornerRadius(AppTheme.Radius.medium)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, AppTheme.Spacing.large)
    }
    
    // MARK: - Actions
    
    private func handleNextButtonTap() {
        // Stop any playing tone
        if isPlaying {
            toggleTone()
        }
        
        switch currentStep {
        case 0:
            // Intro -> Headphone Check
            currentStep += 1
            
        case 1:
            // Headphone Check -> Level Adjustment
            // Check if headphones are connected, warn if not
            if calibrationService.headphoneModel == "No headphones detected" {
                activeAlert = .headphoneWarning
            } else {
                currentStep += 1
            }
            
        case 2:
            // Level Adjustment -> Confirmation
            currentStep += 1
            
        case 3:
            // Confirmation -> Completion
            // Save calibration settings
            calibrationService.setCalibrationLevel(sliderValue)
            currentStep += 1
            
        case 4:
            // Completion -> Finish
            activeAlert = .completionSuccess
            
            // The navigation action would typically happen after the alert is dismissed
            // but we're not adding that code here since you didn't specify navigation behavior
            
        default:
            break
        }
    }
    
    // MARK: - Audio Functions
    
    // Stop all audio from any source
    private func stopAllAudio() {
        // Stop any existing calibration service audio
        calibrationService.stopTone()
        
        // Stop audio player
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Stop direct engine
        directAudioEngine?.stop()
        directAudioEngine = nil
        directPlayer = nil
        
        // Dispose system sound if any
        if systemSoundID != 0 {
            AudioServicesDisposeSystemSoundID(systemSoundID)
            systemSoundID = 0
        }
        
        isPlaying = false
        
        // Add to history
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        routeChangeHistory.insert("[\(timestamp)] 🔴 Stopped all audio", at: 0)
    }
    
    // Toggle tone on/off
    private func toggleTone() {
        if isPlaying {
            stopAllAudio()
        } else {
            // Try the AVAudioPlayer approach
            playWithAVAudioPlayer()
        }
    }
    
    // Update ear selection while playing
    private func updateEarSelection() {
        if isPlaying {
            // For AVAudioPlayer, we can just update the pan
            if let player = audioPlayer {
                if selectedEar == .left {
                    player.pan = -1.0  // Full left
                } else if selectedEar == .right {
                    player.pan = 1.0   // Full right
                }
                
                // Log
                let timestamp = Date().formatted(date: .omitted, time: .standard)
                routeChangeHistory.insert("[\(timestamp)] 🔄 Updated ear selection to \(selectedEar == .left ? "Left" : "Right")", at: 0)
            } else {
                // For other approaches, restart
                stopAllAudio()
                playWithAVAudioPlayer()
            }
        }
    }
    
    // Update tone volume if it's already playing
    private func updateToneVolume() {
        if isPlaying {
            if let player = audioPlayer {
                // For AVAudioPlayer, we can just update the volume directly
                player.volume = sliderValue
                
                // Log
                let timestamp = Date().formatted(date: .omitted, time: .standard)
                routeChangeHistory.insert("[\(timestamp)] 🔄 Volume updated to \(sliderValue)", at: 0)
            } else {
                // For other approaches, restart
                stopAllAudio()
                playWithAVAudioPlayer()
            }
        }
    }
    
    // Simple audio session setup focused on reliability
    private func simplestAudioSessionSetup() throws {
        let session = AVAudioSession.sharedInstance()
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        
        // Close any existing session first with very conservative delay
        try? session.setActive(false)
        Thread.sleep(forTimeInterval: 0.3)
        
        // Set the most basic category without any options
        try session.setCategory(.playback)
        
        // Activate without options
        try session.setActive(true)
        
        // Log
        routeChangeHistory.insert("[\(timestamp)] ✓ Simple audio session established", at: 0)
    }
    
    // Play with AVAudioPlayer approach
    private func playWithAVAudioPlayer() {
        // Clean up any existing audio
        stopAllAudio()
        
        // Use AVAudioPlayer instead of engine for more reliability
        do {
            // Create a simple audio session that's less likely to fail
            try simplestAudioSessionSetup()
            
            // Generate a sine wave file
            let url = generateToneFile()
            
            // Create and configure the player
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1  // Loop continuously
            player.volume = sliderValue
            
            // Route to the appropriate channel
            if selectedEar == .left {
                player.pan = -1.0  // Full left
            } else if selectedEar == .right {
                player.pan = 1.0   // Full right
            } else {
                player.pan = 0.0   // Center (should never happen but just in case)
            }
            
            // Start playing
            player.prepareToPlay()
            player.play()
            
            // Store the player and update state
            self.audioPlayer = player
            self.isPlaying = true
            self.playingError = nil
            
            // Log success
            let timestamp = Date().formatted(date: .omitted, time: .standard)
            routeChangeHistory.insert("[\(timestamp)] 🟢 AVAudioPlayer started (1000Hz)", at: 0)
            
            // Refresh audio session info
            refreshAudioSessionInfo()
            
        } catch {
            // Handle failure
            self.playingError = "AVAudioPlayer failed: \(error.localizedDescription)"
            
            // Log failure
            let timestamp = Date().formatted(date: .omitted, time: .standard)
            routeChangeHistory.insert("[\(timestamp)] ❌ AVAudioPlayer failed: \(error.localizedDescription)", at: 0)
            
            // Try system sound as fallback
            playWithSystemSound()
        }
    }
    
    // Play with System Sound - more reliable but fewer features
    private func playWithSystemSound() {
        do {
            // Clean up first
            stopAllAudio()
            
            // Generate tone file suitable for system sound
            let url = generateToneFile()
            
            // Create system sound
            var soundID: SystemSoundID = 0
            let status = AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
            
            if status != kAudioServicesNoError {
                playWithAudioServicesPlaySystemSound() // Resort to built-in sound
                return
            }
            
            // Store for later cleanup
            self.systemSoundID = soundID
            
            // Play the sound
            AudioServicesPlaySystemSound(soundID)
            
            // Update state
            self.isPlaying = true
            self.playingError = "Using system sound (limited control)"
            
            // Log
            let timestamp = Date().formatted(date: .omitted, time: .standard)
            routeChangeHistory.insert("[\(timestamp)] 🟡 System sound started", at: 0)
            
            // Refresh audio session info
            refreshAudioSessionInfo()
            
        } catch {
            // If this fails too, use built-in sounds
            playWithAudioServicesPlaySystemSound()
        }
    }
    
    // Fallback to built-in system sounds
    private func playWithAudioServicesPlaySystemSound() {
        // Clean up first
        stopAllAudio()
        
        // Use a standard system sound
        AudioServicesPlaySystemSound(1013) // Standard alert sound
        
        // Show error that we're using a fallback
        self.playingError = "Using standard system sound as fallback"
        self.isPlaying = true
        
        // Log
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        routeChangeHistory.insert("[\(timestamp)] ⚠️ Using system sound fallback", at: 0)
        
        // Refresh audio session info
        refreshAudioSessionInfo()
    }
    
    // Helper to create a wave file
    private func generateToneFile() -> URL {
        // Create a 1-second sine wave at 1000Hz
        let sampleRate = 44100
        let duration = 1.0
        let frequency = 1000.0
        let amplitude = Double(sliderValue) * 0.8  // Slightly reduce to prevent clipping
        
        // Create audio format for WAV file
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        
        // Create buffer
        let frameCount = AVAudioFrameCount(duration * Double(sampleRate))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        // Fill with sine wave
        let channels = buffer.floatChannelData!
        for frame in 0..<Int(frameCount) {
            let value = Float(sin(2.0 * .pi * frequency * Double(frame) / Double(sampleRate)) * amplitude)
            
            // Apply to appropriate channels
            if selectedEar == .left {
                channels[0][frame] = value  // Left channel
                channels[1][frame] = 0.0    // Right channel silent
            } else if selectedEar == .right {
                channels[0][frame] = 0.0    // Left channel silent
                channels[1][frame] = value  // Right channel
            } else {
                channels[0][frame] = value  // Left channel
                channels[1][frame] = value  // Right channel
            }
        }
        
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("tone-\(UUID().uuidString).wav")
        
        // Write the buffer to file
        let audioFile = try! AVAudioFile(forWriting: fileURL, settings: format.settings)
        try! audioFile.write(from: buffer)
        
        return fileURL
    }
}

// MARK: - CalibrationService Extension
// Renamed method to avoid conflict with the existing method in CalibrationService
extension CalibrationService {
    // Use this new method name to avoid conflict
    func playDiagnosticCalibrationTone(volume: Float, ear: AudioService.Ear) -> String? {
        // Just call the original method - this is a wrapper
        return playCalibrationTone(volume: volume, ear: ear)
    }
}
