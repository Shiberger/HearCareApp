//
//  HearingTestView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI

struct HearingTestView: View {
    @StateObject private var testManager = HearingTestManager()
    @State private var testStage: TestStage = .instructions
    @State private var selectedEar: AudioService.Ear = .right
    
    // สีพาสเทล
      private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
      private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
      private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)
      
    // เกรเดียนต์พื้นหลัง
       private var backgroundGradient: LinearGradient {
           LinearGradient(
               gradient: Gradient(colors: [pastelBlue.opacity(0.7), pastelGreen.opacity(0.7)]),
               startPoint: .topLeading,
               endPoint: .bottomTrailing
           )
       }
    
    enum TestStage {
        case instructions
        case preparation
        case testing
        case results
    }
    
    var body: some View {
        VStack(spacing: 0) {
            switch testStage {
            case .instructions:
                instructionsView
            case .preparation:
                preparationView
            case .testing:
                testingView
            case .results:
                resultsView
            }
        }
        .navigationTitle("Hearing Test")
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if testStage == .testing {
                    Button("Stop Test") {
                        testManager.stopTest()
                        testStage = .instructions
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Instructions View
    
    //////--------------
    // หน้าจอเริ่มต้น
    private var initialContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "ear")
                .font(.system(size: 80))
                .foregroundColor(pastelBlue)
                .padding()
            
            Text("คำแนะนำในการทดสอบ")
                .font(.headline)
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            
            VStack(alignment: .leading, spacing: 10) {
//                instructionRow(number: "1", text: "สวมหูฟังและอยู่ในที่เงียบ")
//                instructionRow(number: "2", text: "กดเล่นเสียงและปรับระดับเสียงจนได้ยินเบาๆ")
//                instructionRow(number: "3", text: "ทำซ้ำกับทุกความถี่")
//                instructionRow(number: "4", text: "ระบบจะบันทึกและวิเคราะห์ผล")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
        }
    }
    
   
//////--------------
    
    private var instructionsView: some View {
        
        
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                Image("PageTest")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .padding(.top, AppTheme.Spacing.large)
                
                InfoCard(title: "Before You Begin", icon: "checkmark.circle") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        instructionRow(number: 1, text: "Find a quiet environment")
                        instructionRow(number: 2, text: "Put on headphones (recommended)")
                        instructionRow(number: 3, text: "Set your device volume to 50-70%")
                        instructionRow(number: 4, text: "The test will take approximately 5-8 minutes")
                        instructionRow(number: 5, text: "This is just a preliminary test. For accuracy, it is recommended to consult an expert.")
                    }
                }
                
                
                
                InfoCard(title: "How It Works", icon: "ear") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        instructionRow(number: 1, text: "You will hear a series of tones at different frequencies")
                        instructionRow(number: 2, text: "Tap 'Yes' if you can hear the tone, even if it's very faint")
                        instructionRow(number: 3, text: "Tap 'No' if you don't hear anything")
                        instructionRow(number: 4, text: "The test will alternate between right and left ears")
                    }
                }
                
//                Spacer(minLength: AppTheme.Spacing.small)
                
                //ButtonAction
                PrimaryButton(title: "Begin Test", icon: "play.fill") {
                    testStage = .preparation
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.small)
            }
        }
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(pastelBlue))
                .padding(.top, 2)
            //                .font(AppTheme.Typography.callout)
            //                .fontWeight(.semibold)
            //                .foregroundColor(.white)
            //                .frame(width: 24, height: 24)
            //                .background(Circle().fill(AppTheme.primaryColor))
            
            Text(text)
                .font(.body)
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                .fixedSize(horizontal: false, vertical: true)
//                .font(AppTheme.Typography.body)
//                .foregroundColor(AppTheme.textPrimary)
            Spacer()
        }
    }

    
    // MARK: - Preparation View
    private var preparationView: some View {
           ZStack {
               backgroundGradient
               .edgesIgnoringSafeArea(.all)
               
               VStack(spacing: AppTheme.Spacing.large) {
                   // Top spacer with additional flexibility
                   Spacer().frame(height: 30)
                   
                   // Headphone Icon with refined styling
                   Circle()
                       .fill(AppTheme.primaryColor.opacity(0.1))
                       .frame(width: 120, height: 120)
                       .overlay(
                           Image(systemName: "headphones")
                               .resizable()
                               .aspectRatio(contentMode: .fit)
                               .frame(width: 60, height: 60)
                               .foregroundColor(AppTheme.primaryColor)
                       )
                       .shadow(color: AppTheme.primaryColor.opacity(0.2), radius: 10, x: 0, y: 5)
                   
                   
                   
                   // Title with enhanced typography
                   Text("Prepare for Your Hearing Test")
                       .font(AppTheme.Typography.title2)
                       .fontWeight(.bold)
                       .foregroundColor(AppTheme.textPrimary)
                   
                   // Instruction text with improved readability
                   Text("Ensure you're wearing headphones and located in a quiet environment for accurate results.")
                       .font(AppTheme.Typography.body)
                       .foregroundColor(AppTheme.textSecondary)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal, AppTheme.Spacing.extraLarge)
                       .lineSpacing(5)
                   
                   Spacer()
                   
                   // Ear Selection Section with card-like design
                   VStack(spacing: AppTheme.Spacing.medium) {
                       Text("Select Which Ear to Test First")
                           .font(AppTheme.Typography.headline)
                           .foregroundColor(AppTheme.textPrimary)
                       
                       EarSelectionView(selectedEar: $selectedEar)
                           .padding()
                           .background(
                               RoundedRectangle(cornerRadius: 15)
                                   .fill(Color.white)
                                   .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                           )
                   }
                   .padding()
                   
                   Spacer()
                   
                   // Start Test Button with modern design
                   PrimaryButton(
                       title: "Start Test",
                       icon: "play.fill"
                   ) {
                       testStage = .testing
                   }
                   .padding(.horizontal, AppTheme.Spacing.large)
                   .padding(.bottom, AppTheme.Spacing.extraLarge)
                   .transition(.scale)
               }
               .animation(.easeInOut, value: selectedEar)
           }
       }
    
    
    // MARK: - Testing View (Fixed to prevent UI flashing)
    
    private var testingView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Progress indicator
            VStack {
                ProgressView(value: CGFloat(testManager.progress))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primaryColor))
                    .padding(.horizontal)
                
                HStack {
                    Text("Progress: \(Int(testManager.progress * 100))%")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("Testing \(testManager.currentEar == .right ? "Right" : "Left") Ear")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(testManager.currentEar == .right ? .blue : .red)
                }
                .padding(.horizontal)
            }
            
            // Debug info
            Text(testManager.debugInfo)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Current dB level indicator
            HStack {
                Text("Current Level: \(Int(testManager.currentDBLevel)) dB")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Current frequency and ear indicator
            VStack(spacing: AppTheme.Spacing.medium) {
                if testManager.isPlaying {
                    Text("Listen carefully")
                        .font(AppTheme.Typography.title3)
                    
                    Text("Do you hear this tone?")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Get ready")
                        .font(AppTheme.Typography.title3)
                    
                    Text("Next tone coming soon...")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            // Audio visualization
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(testManager.currentEar == .right ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                if testManager.isPlaying {
                    // Animated rings when sound is playing
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(testManager.currentEar == .right ? Color.blue.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 2)
                            .frame(width: CGFloat(140 + (index * 30)), height: CGFloat(140 + (index * 30)))
                            .scaleEffect(testManager.isPlaying ? 1.0 : 0.8)
                            .opacity(testManager.isPlaying ? 0.6 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                value: testManager.isPlaying
                            )
                    }
                }
                
                Image(systemName: "ear.fill")
                    .font(.system(size: 60))
                    .foregroundColor(testManager.currentEar == .right ? .blue : .red)
//                    .rotationEffect(testManager.currentEar == .right ? .zero : .degrees(0))
                    .rotation3DEffect(
                        .degrees(testManager.currentEar == .left ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)  // Vertical flip
                            )

            }
            
            // Response buttons (always visible now)
            HStack(spacing: AppTheme.Spacing.large) {
                Button(action: {
                    if testManager.isPlaying {
                        testManager.respondToTone(heard: false)
                    }
                }) {
                    Text("No")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(Color.red)
                        .cornerRadius(AppTheme.Radius.medium)
                }
                .disabled(!testManager.isPlaying)
                .opacity(testManager.isPlaying ? 1.0 : 0.5)
                
                Button(action: {
                    if testManager.isPlaying {
                        testManager.respondToTone(heard: true)
                    }
                }) {
                    Text("Yes")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(Color.green)
                        .cornerRadius(AppTheme.Radius.medium)
                }
                .disabled(!testManager.isPlaying)
                .opacity(testManager.isPlaying ? 1.0 : 0.5)
            }
            .padding(.top, AppTheme.Spacing.large)
            
            Spacer()
            
            // Frequency indicator (always visible)
            VStack {
                Text("\(Int(testManager.currentFrequency)) Hz")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .padding()
        .onAppear {
            // Start the test when the view appears
            if testManager.testStatus != .testing {
                testManager.startTest(startingEar: selectedEar)
            }
        }
        .onChange(of: testManager.testStatus) { newStatus in
            if newStatus == .complete {
                testStage = .results
            }
        }
    }
    
//    // MARK: - Results View
    private var resultsView: some View {
        VStack(spacing: 0) {
            // ส่วนหัวผลลัพธ์
            VStack(spacing: AppTheme.Spacing.medium) {
                // ไอคอนและอนิเมชัน
                ZStack {
                    Circle()
                        .fill(pastelGreen.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(pastelGreen)
                        .shadow(color: pastelGreen.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .padding(.top, AppTheme.Spacing.large)
                
                // ข้อความยืนยันการทดสอบเสร็จสิ้น
                Text("การทดสอบเสร็จสิ้น!")
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Text("ผลการทดสอบของคุณพร้อมแล้ว")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.bottom, AppTheme.Spacing.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, AppTheme.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
            .padding(.horizontal)
            
            // ส่วนสรุปผลทดสอบ
            VStack(spacing: AppTheme.Spacing.medium) {
                HStack {
                    Text("สรุปผลการทดสอบ")
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    
                    Spacer()
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(pastelBlue)
                }
                .padding(.top, AppTheme.Spacing.medium)
                
                // ข้อมูลสรุป
                VStack(spacing: AppTheme.Spacing.small) {
                    resultSummaryRow(title: "การตอบสนองเฉลี่ย:", value: "ดี", icon: "ear", color: pastelGreen)
                    resultSummaryRow(title: "ช่วงความถี่ที่ได้ยินชัดเจน:", value: "500Hz - 2000Hz", icon: "waveform.path", color: pastelBlue)
                    resultSummaryRow(title: "จำนวนความถี่ที่ทดสอบ:", value: "\(testManager.getUserResponses().count)", icon: "number.circle", color: pastelYellow)
                }
                .padding(.vertical, AppTheme.Spacing.small)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            )
            .padding(.horizontal)
            .padding(.top, AppTheme.Spacing.large)
            
            Spacer()
            
            // แนะนำการดูแลการได้ยิน
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(pastelYellow)
                    
                    Text("คำแนะนำการดูแลการได้ยิน")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                }
                
                Text("การทดสอบนี้เป็นเพียงการเบื้องต้น ควรพบแพทย์เพื่อตรวจอย่างละเอียดหากพบความผิดปกติ")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(pastelYellow.opacity(0.2))
            )
            .padding(.horizontal)
            
            // ปุ่มดูผลลัพธ์โดยละเอียด
            NavigationLink(
                destination: DetailedResultsView(testResults: testManager.getUserResponses())
                    .onAppear {
                        // Save test results to Firestore when viewing results
                        saveTestResults()
                    }
            ) {
                HStack {
                    Text("ดูผลลัพธ์โดยละเอียด")
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .primaryButton()
            }
            .padding(.horizontal)
            .padding(.top, AppTheme.Spacing.large)
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .padding(.vertical)
        .onAppear {
            // Save results as soon as the results view appears
            saveTestResults()
        }
    }

    // ฟังก์ชันช่วยสร้างแถวข้อมูลสรุป
    private func resultSummaryRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
        }
        .padding(.vertical, 5)
    }

    // Extension สำหรับสไตล์ปุ่ม (ถ้าคุณยังไม่มี)
//    extension Text {
//        func primaryButton(backgroundColor: Color = Color(red: 174/255, green: 198/255, blue: 255/255)) -> some View {
//            self
//                .font(.headline)
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(
//                    RoundedRectangle(cornerRadius: 15)
//                        .fill(backgroundColor)
//                        .shadow(color: backgroundColor.opacity(0.5), radius: 5, x: 0, y: 3)
//                )
//        }
//    }
    
//MARK: OG RESULT VIEW
//    private var resultsView: some View {
//        VStack(spacing: AppTheme.Spacing.large) {
//            Image(systemName: "checkmark.circle.fill")
//                .font(.system(size: 80))
//                .foregroundColor(.green)
//                .padding()
//            
//            Text("Test Completed!")
//                .font(AppTheme.Typography.title2)
//            
//            Text("Your results are ready")
//                .font(AppTheme.Typography.body)
//                .foregroundColor(AppTheme.textSecondary)
//            
//            Spacer()
//            
//            NavigationLink(
//                destination: DetailedResultsView(testResults: testManager.getUserResponses())
//                    .onAppear {
//                        // Save test results to Firestore when viewing results
//                        saveTestResults()
//                    }
//            ) {
//                Text("View Detailed Results")
//                    .primaryButton()
//            }
//            .padding(.horizontal)
//            .padding(.bottom, AppTheme.Spacing.large)
//        }
//        .padding()
//        .onAppear {
//            // Save results as soon as the results view appears
//            saveTestResults()
//        }
//    }
    
    // MARK: - Helper Methods
    
    private func saveTestResults() {
        // Create a FirestoreService instance
        let firestoreService = FirestoreService()
        
        // Process the test responses
        let resultsProcessor = ResultsProcessor()
        let processedResults = resultsProcessor.processResults(from: testManager.getUserResponses())
        
        // Create a test result document
        let testResult: [String: Any] = [
            "testDate": Date(),
            "rightEarClassification": processedResults.rightEarClassification.displayName,
            "leftEarClassification": processedResults.leftEarClassification.displayName,
            "recommendations": processedResults.recommendations,
            "rightEarData": processedResults.rightEarHearingLevel.map { [
                "frequency": $0.key,
                "hearingLevel": $0.value
            ]},
            "leftEarData": processedResults.leftEarHearingLevel.map { [
                "frequency": $0.key,
                "hearingLevel": $0.value
            ]}
        ]
        
        // Save the test result to Firestore
        firestoreService.saveTestResultForCurrentUser(testResult) { result in
            switch result {
            case .success:
                print("Test results saved successfully to Firestore")
            case .failure(let error):
                print("Failed to save test results: \(error.localizedDescription)")
            }
        }
    }
}
