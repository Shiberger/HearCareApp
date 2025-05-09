//
//  HearingTestView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//  Updated with noise level check on 22/4/2568 BE.
//  Updated with calibration integration on 4/5/2568 BE.
//

import SwiftUI

// MARK: - Pastel Colors
private let pastelBlue = Color(red: 0.75, green: 0.85, blue: 1.0)       // Bright sky blue
private let pastelGreen = Color(red: 0.75, green: 1.0, blue: 0.85)      // Bright mint green
private let pastelYellow = Color(red: 1.0, green: 0.95, blue: 0.75)     // Bright warm yellow
private let pastelPurple = Color(red: 0.9, green: 0.8, blue: 1.0)       // Bright lavender
private let pastelRed = Color(red: 1.0, green: 0.8, blue: 0.8)          // Bright coral
private let pastelOrange = Color(red: 1.0, green: 0.85, blue: 0.7)      // Bright peach

private let darkerPastelRed = Color(red: 0.7, green: 0.4, blue: 0.4)    // Darker coral
private let darkerPastelBlue = Color(red: 0.35, green: 0.45, blue: 0.6) // Darker sky blue

struct HearingTestView: View {
    @StateObject private var testManager = HearingTestManager()
    @State private var testStage: TestStage = .microphonePermission
    @State private var animating = false

    // ตั้งค่าเริ่มต้นเป็นหูขวาเท่านั้น
    @State private var selectedEar: AudioService.Ear = .right
    @State private var microphonePermissionGranted = false
    @State private var showingNoiseAlert = false
    @State private var showingDebugInfo = false
    @State private var showCalibrationView = false
    
    @State private var shouldResetAmbientNoise = false
        
    @ObservedObject private var soundService = AmbientSoundService.shared
    @ObservedObject private var calibrationService = CalibrationService.shared
    
    // เกรเดียนต์พื้นหลัง
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [pastelBlue.opacity(1.0), pastelGreen.opacity(0.9)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Debug state
    @State private var debugLogMessages: [String] = []
    
    enum TestStage {
        case microphonePermission
        case calibrationCheck
        case instructions
        case preparation
        case testing
        case results
    }
    
    var body: some View {
        ZStack {
            // พื้นหลังเกรเดียนต์
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ใช้ switch เพื่อกำหนดว่าจะแสดงเนื้อหาใด
                getMainContentForStage(testStage)
            }
        }
//        .navigationTitle("ทดสอบการได้ยิน")
        
        // .navigationTitle("ทดสอบการได้ยิน") // Title นี้จะถูกแทนที่ด้วย ToolbarItem ด้านล่าง
        .toolbar {
            ToolbarItem(placement: .principal) { // .principal สำหรับ Title ที่อยู่ตรงกลาง
                Text("ทดสอบการได้ยิน")
                    .font(.headline) // опционально: ทำให้ font คล้ายกับ title เริ่มต้น
                    .foregroundColor(AppTheme.primaryColor) // กำหนดสีที่นี่
            }
        }
        
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if testStage == .testing {
                    Menu {
                        Button("หยุดการทดสอบ") {
                            addDebugLog("User manually stopped test")
                            testManager.stopTest()
                            testStage = .instructions
                        }
                        
                        Toggle("แสดงข้อมูลดีบัก", isOn: $showingDebugInfo)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(pastelBlue)
                    }
                }
            }
        }
        .overlay(
            ZStack {
                if showingNoiseAlert {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    createNoiseAlertView(
                        isPresented: $showingNoiseAlert,
                        onTestAnyway: {
                            addDebugLog("User proceeding despite noise")
                            proceedToNextStage()
                        }
                    )
                }
            }
        )
        .sheet(isPresented: $showCalibrationView) {
            NavigationView {
                CalibrationView(shouldResetAmbientNoise: $shouldResetAmbientNoise)
            }
        }
    }
    
    // MARK: - Content Router
    
    private func getMainContentForStage(_ stage: TestStage) -> some View {
        switch stage {
        case .microphonePermission:
            return AnyView(
                MicrophonePermissionView(permissionGranted: $microphonePermissionGranted)
                    .onChange(of: microphonePermissionGranted) { granted in
                        if granted {
                            addDebugLog("Microphone permission granted")
                            soundService.startMonitoring()
                            // Check calibration status first
                            let calibrationStatus = testManager.checkCalibrationStatus()
                            if calibrationStatus == .needsCalibration {
                                testStage = .calibrationCheck
                            } else {
                                testStage = .instructions
                            }
                        }
                    }
            )
        case .calibrationCheck:
            return AnyView(
                CalibrationCheckView()
                    .onDisappear {
                        if testStage == .calibrationCheck {
                            testStage = .instructions
                        }
                    }
            )
        case .instructions:
            return AnyView(instructionsView)
        case .preparation:
            return AnyView(preparationView)
        case .testing:
            return AnyView(testingView)
        case .results:
            return AnyView(resultsView)
        }
    }
    
    // MARK: - Logging Helper
    
    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        let logMessage = "[\(timestamp)] \(message)"
        print(logMessage)
        
        // Add to our debug log array
        debugLogMessages.append(logMessage)
        
        // Keep only the most recent 100 messages
        if debugLogMessages.count > 100 {
            debugLogMessages.removeFirst(debugLogMessages.count - 100)
        }
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // ภาพประกอบการทดสอบ
                ZStack {
                    Image("PageTest")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .padding()
                }
                .frame(height: 180)
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.small)
                
                // หัวข้อ
                Text("คำแนะนำการทดสอบการได้ยิน")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .padding(.horizontal)
                
                // Calibration status card
                calibrationStatusCard
                
                // ตัวตรวจจับเสียงรบกวน
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(pastelBlue)
                        
                        Text("ระดับเสียงรบกวนในสภาพแวดล้อม")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                        
                        Spacer()
                    }
                    
                    AmbientSoundMonitorView()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                
                // ก่อนเริ่มการทดสอบ
                createBeforeYouBeginCard()
    
                // วิธีการทำงาน
                createHowItWorksCard()
                
                Spacer(minLength: AppTheme.Spacing.small)
                
                // ปุ่มเริ่มทดสอบ
                Button(action: {
                    addDebugLog("Begin Test button tapped")
                    
                    // Check if device is calibrated
                    let calibrationStatus = testManager.checkCalibrationStatus()
                    
                    if calibrationStatus == .calibrated {
                        // Proceed with test if calibrated
                        checkEnvironmentNoise()
                    } else if calibrationStatus == .recommendRecalibration {
                        // Show recalibration recommendation but allow to continue
                        showCalibrationView = true
                    } else {
                        // For other statuses, force calibration
                        showCalibrationView = true
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .padding(.trailing, 5)
                        
                        Text("ต่อไป")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(darkerPastelBlue)
                            .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.large)
            }
        }
    }
    
    // Calibration status card
    private var calibrationStatusCard: some View {
        Group {
            if calibrationService.isCalibrated {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("อุปกรณ์ได้รับการปรับเทียบแล้ว")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.green)
                        
                        if let date = calibrationService.calibrationDate {
                            Text("ปรับเทียบล่าสุด: \(date, style: .date)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showCalibrationView = true
                    }) {
                        Text("ปรับเทียบใหม่")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.primaryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .strokeBorder(AppTheme.primaryColor, lineWidth: 1)
                            )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.green.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("จำเป็นต้องทำการปรับเทียบ")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.orange)
                        
                        Text("อุปกรณ์ของคุณจำเป็นต้องปรับเทียบเพื่อผลลัพธ์ที่แม่นยำ")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showCalibrationView = true
                    }) {
                        Text("ปรับเทียบ")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.primaryColor)
                            )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.orange.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
        }
    }
    
    private func createBeforeYouBeginCard() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(pastelGreen)
                
                Text("ก่อนเริ่มทดสอบ")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: 1, text: "หาสถานที่เงียบสงบ")
                instructionRow(number: 2, text: "สวมหูฟัง (แนะนำให้ใช้)")
                instructionRow(number: 3, text: "ตั้งระดับเสียงอุปกรณ์ที่ 50-70%")
                instructionRow(number: 4, text: "การทดสอบจะใช้เวลาประมาณ 5-8 นาที")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func createHowItWorksCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "ear.fill")
                    .font(.system(size: 22))
                    .foregroundColor(pastelBlue)
                
                Text("วิธีการทดสอบ")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            
            VStack(alignment: .leading, spacing: 10) {
                instructionRow(number: 1, text: "คุณจะได้ยินเสียงที่ความถี่ต่างๆ")
                instructionRow(number: 2, text: "กด 'ได้ยิน' หากคุณได้ยินเสียง แม้จะเบามาก")
                instructionRow(number: 3, text: "กด 'ไม่ได้ยิน' หากคุณไม่ได้ยินเสียงใดๆ")
                instructionRow(number: 4, text: "การทดสอบจะสลับระหว่างหูขวาและหูซ้าย")
                instructionRow(number: 5, text: "ตอบตามความจริงเพื่อผลลัพธ์ที่ดีที่สุด")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(pastelBlue.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(pastelBlue)
            }
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
    
    // MARK: - Environment Noise Check
    
    private func checkEnvironmentNoise() {
        // ตรวจสอบว่ากำลังติดตามอยู่
        if !soundService.isMonitoring {
            soundService.startMonitoring()
            
            // รอให้บริการได้ข้อมูลที่แม่นยำ
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                evaluateNoiseLevel()
            }
        } else {
            evaluateNoiseLevel()
        }
    }
    
    private func evaluateNoiseLevel() {
        let noiseLevel = Int(soundService.currentDecibels)
        let status = soundService.ambientNoiseLevel.rawValue
        
        addDebugLog("Evaluating noise: \(noiseLevel) dB (\(status))")
        
        if soundService.ambientNoiseLevel == .excessive {
            // แสดงการแจ้งเตือนเสียงรบกวน
            showingNoiseAlert = true
        } else {
            // สภาพแวดล้อมเหมาะสม ดำเนินการต่อ
            proceedToNextStage()
        }
    }
    
    // Helper method เพื่อไปยังขั้นตอนถัดไป
    private func proceedToNextStage() {
        // กำหนดว่าจะไปขั้นตอนใดต่อไป
        if testStage == .instructions {
            addDebugLog("Moving to preparation stage")
            testStage = .preparation
        } else if testStage == .preparation {
            addDebugLog("Moving to testing stage")
            testStage = .testing
        }
    }
    
    // MARK: - Preparation View

    private var preparationView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // เว้นระยะด้านบน
                Spacer().frame(height: 20)
                
                // หัวข้อคำแนะนำ
                prepInstructionsHeader
                
                // ตรวจสอบเสียงรบกวน
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(pastelBlue)
                        
                        Text("ระดับเสียงรบกวนในสภาพแวดล้อม")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                        
                        Spacer()
                    }
                    
                    AmbientSoundMonitorView()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                
                // การเลือกหู (แต่บังคับเป็นหูขวาเท่านั้น)
                earSelectionSection
                
                // ปุ่มเริ่มทดสอบ
                Button(action: {
                    // บังคับเป็นหูขวาเท่านั้น
                    let ear = selectedEar == .right ? "Right" : "Left"
                    addDebugLog("Starting test with \(ear) ear")
                    
                    // ตรวจสอบสิ่งแวดล้อมอีกครั้งก่อนเริ่มทดสอบ
                    if soundService.ambientNoiseLevel == .excessive {
                        showingNoiseAlert = true
                    } else {
                        testStage = .testing
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .padding(.trailing, 5)
                        
                        Text("เริ่มทดสอบ")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color.black.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(pastelGreen)
                            .shadow(color: pastelGreen.opacity(0.5), radius: 5, x: 0, y: 3)
                    )
                }
                .padding(.horizontal)
                
                // เว้นระยะด้านล่าง
                Spacer().frame(height: 40)
            }
            .padding(.bottom, AppTheme.Spacing.large)
        }
    }
    
    private var prepInstructionsHeader: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "headphones")
                .font(.system(size: 60))
                .foregroundColor(pastelBlue)
                .padding(.bottom, 10)
            
            Text("เตรียมพร้อมสำหรับการทดสอบ")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .multilineTextAlignment(.center)
            
            Text("ตรวจสอบให้แน่ใจว่าคุณสวมหูฟังและอยู่ในสภาพแวดล้อมที่เงียบสงบ")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.extraLarge)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    // ส่วนเลือกหู (บังคับเป็นหูขวาเท่านั้น)
    private var earSelectionSection: some View {
        VStack {
            Text("การทดสอบจะเริ่มต้นด้วย'หูขวา'ของคุณ")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .padding(.bottom)
            
            // สร้างกรอบแสดงรูปหูที่สวยงาม
            HStack(spacing: 30) {
                // หูซ้าย (ถูกปิดใช้งาน)
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "ear.fill")
                            .font(.system(size: 40))
                            .rotation3DEffect(
                                .degrees(180),
                                axis: (x: 0, y: 1, z: 0)  // Vertical flip
                            )
                            .foregroundColor(darkerPastelBlue)
                    }
                    
                    Text("หูซ้าย")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.5))
                        .padding(.top, 5)
                }
                
                // หูขวา (เลือกไว้)
                VStack {
                    ZStack {
                        Circle()
                            .fill(pastelRed.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "ear.fill")
                            .font(.system(size: 40))
                            .foregroundColor(darkerPastelRed)
                    }
                    .overlay(
                        Circle()
                            .stroke(pastelRed, lineWidth: 3)
                            .frame(width: 88, height: 88)
                    )
                    
                    Text("หูขวา")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(pastelRed)
                        .padding(.top, 5)
                }
            }
            .padding(.vertical, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Testing View
    
    private var testingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // ส่วนแสดงความคืบหน้า
            testProgressSection
            
            // ส่วนแสดงข้อมูลดีบัก (แสดงตามเงื่อนไข)
            if showingDebugInfo {
                testDebugInfoSection
            } else {
                // ข้อมูลพื้นฐานเมื่อปิดดีบัก
                HStack {
                    Text("ระดับความดัง: \(Int(testManager.currentDBLevel)) dB")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // ข้อความสถานะปัจจุบัน
            testStatusText
            
            // การแสดงภาพคลื่นเสียง
            testAudioVisualization
            
            // ปุ่มตอบสนอง
            testResponseButtons
            
            Spacer()
            
            // ตัวบ่งชี้ความถี่
            VStack {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(pastelBlue)
                        .font(.system(size: 16))
                    
                    Text("\(Int(testManager.currentFrequency)) Hz")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.9))
                )
            }
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .padding()
        .onAppear {
            // เริ่มการทดสอบเมื่อมุมมองปรากฏ
            if testManager.testStatus != .testing {
                addDebugLog("Starting hearing test")
                
                // Use calibrated test if available
                if calibrationService.isCalibrated {
                    addDebugLog("Using calibrated tones for test")
                    // Using calibrated method would go here
                }
                
                // บังคับเริ่มที่หูขวา
                testManager.startTest(startingEar: .right)
            }
            
            // ปิดการติดตามเสียงรบกวนระหว่างการทดสอบ
            soundService.stopMonitoring()
        }
        .onChange(of: testManager.testStatus) { newStatus in
            addDebugLog("Test status changed: \(newStatus)")
            if newStatus == .complete {
                testStage = .results
            }
        }
    }
    
    private var testProgressSection: some View {
        VStack {
            // แถบความคืบหน้า
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(pastelBlue)
                    .frame(width: max(0, UIScreen.main.bounds.width * CGFloat(testManager.progress) - 40), height: 8)
                    .animation(.easeInOut, value: testManager.progress)
            }
            .padding(.horizontal)
            
            // ข้อมูลความคืบหน้า
            HStack {
                Text("ความคืบหน้า: \(Int(testManager.progress * 100))%")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                
                Spacer()
                
                // ตัวบ่งชี้หูปัจจุบัน
                let earText = testManager.currentEar == .right ? "หูขวา" : "หูซ้าย"
                let earColor = testManager.currentEar == .right ? darkerPastelRed : darkerPastelBlue
                
                HStack {
                    Image(systemName: "ear")
                        .font(.system(size: 12))
                    
                    Text("กำลังทดสอบ \(earText)")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(earColor)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(earColor.opacity(0.1))
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var testDebugInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ความถี่: \(Int(testManager.currentFrequency)) Hz")
                .font(.caption)
            Text("ระดับเสียง: \(Int(testManager.currentDBLevel)) dB")
                .font(.caption)
            Text("สถานะ: \(String(describing: testManager.testStatus))")
                .font(.caption)
            Text("หู: \(testManager.currentEar == .right ? "ขวา" : "ซ้าย")")
                .font(.caption)
            Text("กำลังเล่น: \(testManager.isPlaying ? "ใช่" : "ไม่")")
                .font(.caption)
            Text("ปรับเทียบแล้ว: \(calibrationService.isCalibrated ? "ใช่" : "ไม่")")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
        )
        .padding(.horizontal)
    }
    
    private var testStatusText: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if testManager.isPlaying {
                Text("ฟังอย่างตั้งใจ")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Text("คุณได้ยินเสียงนี้หรือไม่?")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
            } else {
                Text("เตรียมพร้อม")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Text("เสียงถัดไปกำลังจะเริ่ม...")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
    
    private var testAudioVisualization: some View {
        ZStack {
            // วงกลมด้านนอก
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                .frame(width: 200, height: 200)
            
            // วงกลมด้านใน
            let fillColor = testManager.currentEar == .right ?
                pastelRed.opacity(0.2) : pastelBlue.opacity(0.2)
            
            Circle()
                .fill(fillColor)
                .frame(width: 180, height: 180)
            
            // วงแหวนแอนิเมชันเมื่อกำลังเล่น
            if testManager.isPlaying {
                ForEach(0..<3, id: \.self) { index in
                    createAnimatedRing(index: index)
                }
            }
            
            // ไอคอนหู
            let earColor = testManager.currentEar == .right ? darkerPastelRed : darkerPastelBlue
            let earRotation = testManager.currentEar == .right ?
                Angle(degrees: 0) : Angle(degrees: 0)
            
            Image(systemName: "ear.fill")
                .font(.system(size: 60))
                .foregroundColor(earColor)
                .rotationEffect(earRotation)
                .rotation3DEffect(
                    .degrees(testManager.currentEar == .left ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)  // Vertical flip
                )
        }
    }
    
    func createAnimatedRing(index: Int) -> some View {
        let ringColor = testManager.currentEar == .right ?
            pastelRed.opacity(0.3) : pastelBlue.opacity(0.3)
        let size = CGFloat(140 + (index * 30))
        
        return Circle()
            .stroke(ringColor, lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(testManager.isPlaying ? 1.0 : 0.8)
            .opacity(testManager.isPlaying ? 0.6 : 0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.3),
                value: testManager.isPlaying
            )
    }
    
    private var testResponseButtons: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            // ปุ่มไม่ได้ยิน
            Button(action: {
                if testManager.isPlaying {
                    addDebugLog("User response: NO")
                    testManager.respondToTone(heard: false)
                }
            }) {
                Text("ไม่ได้ยิน")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.black.opacity(0.5))
                    .frame(width: 130, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(pastelRed)
                            .shadow(color: pastelRed.opacity(0.6), radius: 5, x: 0, y: 3)
                    )
            }
            .disabled(!testManager.isPlaying)
            .opacity(testManager.isPlaying ? 1.0 : 0.5)
            
            // ปุ่มได้ยิน
            Button(action: {
                if testManager.isPlaying {
                    addDebugLog("User response: YES")
                    testManager.respondToTone(heard: true)
                }
            }) {
                Text("ได้ยิน")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.black.opacity(0.5))
                    .frame(width: 130, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(pastelGreen)
                            .shadow(color: pastelGreen.opacity(0.6), radius: 5, x: 0, y: 3)
                    )
            }
            .disabled(!testManager.isPlaying)
            .opacity(testManager.isPlaying ? 1.0 : 0.5)
        }
        .padding(.top, AppTheme.Spacing.large)
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // ไอคอนเสร็จสิ้น
            ZStack {
                // วงกลมพื้นหลัง
                Circle()
                    .fill(pastelGreen.opacity(1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animating ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animating)
                
                // เอฟเฟกต์เรืองแสง
                Circle()
                    .fill(pastelGreen.opacity(0.8))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animating ? 1.2 : 0.9)
                    .opacity(animating ? 0.6 : 0.2)
                    .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animating)
                
                // ไอคอนเครื่องหมายถูก
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 29/255, green: 205/255, blue: 159/255))
                    .shadow(color: pastelGreen.opacity(0.5), radius: 3, x: 0, y: 2)
                    .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: false), value: animating)
            }
            .padding()
            .onAppear {
                animating = true
            }
            
            // ข้อความหัวข้อ
            VStack(spacing: 8) {
                Text("ทดสอบเสร็จสิ้น!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Text("ผลการทดสอบของคุณพร้อมแล้ว")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
            }
            
            // สรุปการทดสอบ
            createTestSummary()
            
            Spacer()
            
            // ปุ่มดูผลโดยละเอียด - แก้ไขแล้ว: นำ onAppear ออกเพื่อป้องกันการบันทึกอัตโนมัติ
            NavigationLink(
                destination: DetailedResultsView(testResults: testManager.getUserResponses())
            ) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18))
                        .padding(.trailing, 5)
                    
                    Text("ดูผลการทดสอบโดยละเอียด")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(pastelBlue)
                        .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
                )
                .padding(.horizontal)
            }
            
            NavigationLink(
                destination: HearingTestView()
            ) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 18))
                        .padding(.trailing, 5)
                    
                    Text("ทำการทดสอบอีกครั้ง")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(pastelBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.white)
                        .shadow(color: pastelGreen.opacity(0.5), radius: 5, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(pastelBlue, lineWidth: 1)
                )
                .padding(.horizontal)
            }
            .padding(.bottom, AppTheme.Spacing.medium)
        }
        .padding()
        .onAppear {
            // REMOVED: saveTestResults() call to prevent auto-saving
            // บันทึกการเสร็จสิ้นเท่านั้น ไม่บันทึกผล
            addDebugLog("Results view appeared")
            
            // เริ่มการติดตามเสียงรบกวนสำหรับการทดสอบในอนาคต
            soundService.startMonitoring()
        }
    }
    
    private func createTestSummary() -> some View {
        let responses = testManager.getUserResponses()
        let rightEarCount = responses.filter { $0.ear == .right }.count
        let leftEarCount = responses.filter { $0.ear == .left }.count
        let heardCount = responses.filter { $0.volumeHeard != Float.infinity }.count
        
        return VStack(alignment: .leading, spacing: 15) {
            Text("สรุปผลการทดสอบ:")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                summaryRow(icon: "checkmark.circle.fill", text: "บันทึก \(responses.count) การตอบสนอง")
                summaryRow(icon: "ear.fill", text: "วัด \(rightEarCount) ครั้งสำหรับหูขวา")
                summaryRow(icon: "ear.fill", text: "วัด \(leftEarCount) ครั้งสำหรับหูซ้าย")
                summaryRow(icon: "speaker.wave.2.fill", text: "ตอบ \"ได้ยิน\" \(heardCount) ครั้ง")
                
                if calibrationService.isCalibrated {
                    summaryRow(icon: "checkmark.seal.fill", text: "ทดสอบโดยใช้ระดับเสียงที่ปรับเทียบแล้ว")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(pastelGreen)
                .font(.system(size: 16))
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            
            Spacer()
        }
    }
    
    // MARK: - Data Saving
    
    private func saveTestResults() {
        addDebugLog("Processing test results for potential saving...")
        addDebugLog("Processing and saving test results...")
        let responses = testManager.getUserResponses()
        addDebugLog("Total responses: \(responses.count)")
        
        // สร้างอินสแตนซ์ FirestoreService
        let firestoreService = FirestoreService()
        
        // ประมวลผลการตอบสนองการทดสอบ
        let resultsProcessor = ResultsProcessor()
        let processedResults = resultsProcessor.processResults(from: responses)
        
        // บันทึกผลลัพธ์
        addDebugLog("Right ear: \(processedResults.rightEarClassification.displayName)")
        addDebugLog("Left ear: \(processedResults.leftEarClassification.displayName)")
        
        // สร้างข้อมูลสำหรับ Firestore
        let rightEarData = processedResults.rightEarHearingLevel.map {
            ["frequency": $0.key, "hearingLevel": $0.value]
        }
        
        let leftEarData = processedResults.leftEarHearingLevel.map {
            ["frequency": $0.key, "hearingLevel": $0.value]
        }
        
        // สร้างเอกสารผลการทดสอบ
        var testResult: [String: Any] = [
            "testDate": Date(),
            "rightEarClassification": processedResults.rightEarClassification.displayName,
            "leftEarClassification": processedResults.leftEarClassification.displayName,
            "recommendations": processedResults.recommendations,
            "rightEarData": rightEarData,
            "leftEarData": leftEarData
        ]
        
        // Add calibration information
        testResult["wasCalibrated"] = calibrationService.isCalibrated
        if let calibrationDate = calibrationService.calibrationDate {
            testResult["calibrationDate"] = calibrationDate
        }
        
        // บันทึกผลการทดสอบไปยัง Firestore
        firestoreService.saveTestResultForCurrentUser(testResult) { result in
            switch result {
            case .success:
                addDebugLog("Test results saved successfully to Firestore")
            case .failure(let error):
                addDebugLog("Failed to save: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Noise Alert View
    
    // ใช้ฟังก์ชันแทนการประกาศ struct ใหม่ เพื่อหลีกเลี่ยงการประกาศซ้ำ
    func createNoiseAlertView(isPresented: Binding<Bool>, onTestAnyway: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            // หัวข้อ
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(pastelRed)
                
                Text("คำเตือนเสียงรบกวน")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            
            // ข้อความคำเตือน
            Text("ตรวจพบระดับเสียงรบกวนสูงในสภาพแวดล้อมของคุณ ซึ่งอาจส่งผลต่อความแม่นยำของการทดสอบการได้ยิน")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // ภาพประกอบ
            Image(systemName: "waveform.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(pastelRed)
                .padding()
            
            // คำแนะนำ
            Text("แนะนำให้ย้ายไปยังสถานที่ที่เงียบกว่า หรือลดแหล่งกำเนิดเสียงรบกวนก่อนดำเนินการต่อ")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // ปุ่มดำเนินการ
            VStack(spacing: 12) {
                Button(action: {
                    isPresented.wrappedValue = false
                }) {
                    Text("กลับไปและลองอีกครั้ง")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(pastelBlue)
                                .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
                        )
                }
                
                Button(action: {
                    onTestAnyway()
                    isPresented.wrappedValue = false
                }) {
                    Text("ทดสอบต่อไป")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(pastelBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(pastelBlue, lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(30)
    }
}
