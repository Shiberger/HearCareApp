import SwiftUI

// MARK: - Pastel Colors
private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)
private let pastelRed = Color(red: 255/255, green: 180/255, blue: 180/255)
private let pastelOrange = Color(red: 255/255, green: 210/255, blue: 170/255)

struct DetailedResultsView: View {
    @StateObject private var viewModel: ResultsViewModel
    @State private var selectedTab = 0 // เริ่มต้นที่ Summary แทน
    @State private var isSaving = false
    @State private var showingSaveConfirmation = false
    @State private var resultsSaved = false
    
    // เปลี่ยนลำดับแท็บให้ Summary อยู่ก่อน
    private let tabs = ["Summary", "Audiogram", "Suggestion"]
    
    // เกรเดียนต์พื้นหลัง
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [pastelBlue.opacity(0.6), pastelGreen.opacity(0.4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Original initializer for new test results
    init(testResults: [AudioService.TestResponse]) {
        self._viewModel = StateObject(wrappedValue: ResultsViewModel(testResponses: testResults))
    }
    
    // New initializer for historical test results
    init(testResult: TestResult) {
        self._viewModel = StateObject(wrappedValue: ResultsViewModel(testResult: testResult))
        // If viewing historical results, mark as already saved
        self._resultsSaved = State(initialValue: true)
    }
    
    // Additional initializer that accepts a view model directly
    init(viewModel: ResultsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // พื้นหลังเกรเดียนต์
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // แถบแท็บที่ปรับปรุงแล้ว
                HStack {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(tabs[index])
                                    .font(.system(size: 15, weight: selectedTab == index ? .semibold : .regular))
                                    .foregroundColor(selectedTab == index ? pastelBlue : Color.gray)
                                
                                ZStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 3)
                                    
                                    if selectedTab == index {
                                        Rectangle()
                                            .fill(pastelBlue)
                                            .frame(height: 3)
                                            .matchedGeometryEffect(id: "TAB", in: namespace)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .background(Color.white.opacity(0.9))
                
                // เนื้อหาแท็บ
                TabView(selection: $selectedTab) {
                    // เปลี่ยนลำดับให้ตรงกับแท็บที่แสดง (Summary ก่อน)
                    summaryView
                        .tag(0)
                    
                    audiogramView
                        .tag(1)
                    
                    recommendationsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationTitle("ผลการทดสอบโดยละเอียด")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shareResults()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.up")
                        Text("แชร์")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(pastelBlue)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(pastelBlue, lineWidth: 1)
                    )
                }
            }
        }
        // แสดงการแจ้งเตือนเมื่อบันทึกสำเร็จ
        .alert(isPresented: $showingSaveConfirmation) {
            Alert(
                title: Text("สำเร็จ"),
                message: Text("บันทึกผลการทดสอบเรียบร้อยแล้ว"),
                dismissButton: .default(Text("ตกลง"))
            )
        }
        .onAppear {
            // ตรวจสอบว่าเป็นผลจากประวัติหรือไม่
            if viewModel.isHistoricalResult {
                resultsSaved = true
            }
        }
    }
    
    @Namespace private var namespace
    
    // MARK: - Summary View (อยู่ก่อนเป็นอันดับแรก)
    private var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ผลสรุปการทดสอบ
                Text("ผลสรุปการทดสอบ")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .padding(.horizontal)
                    .padding(.top, 15)
                
                // การ์ดแสดงผลการจำแนก
                VStack(spacing: 16) {
                    // การ์ดหูขวา
                    classificationCard(
                        title: "หูขวา",
                        classification: viewModel.rightEarClassification,
                        color: pastelRed
                    )
                    
                    // การ์ดหูซ้าย
                    classificationCard(
                        title: "หูซ้าย",
                        classification: viewModel.leftEarClassification,
                        color: pastelBlue
                    )
                }
                .padding(.horizontal)
                
                // ผลแบ่งตามความถี่
                Text("ผลตามความถี่")
                    .font(.headline)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // ตารางแสดงผลความถี่
                frequencyBreakdownGrid
                    .padding(.horizontal)
                
                // ข้อมูลการทดสอบ
                VStack(alignment: .leading, spacing: 10) {
                    Text("ข้อมูลการทดสอบ")
                        .font(.headline)
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    
                    HStack {
                        Text("วันที่ทดสอบ:")
                            .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                        Spacer()
                        Text(viewModel.testDate, style: .date)
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    }
                    
                    HStack {
                        Text("ระยะเวลาทดสอบ:")
                            .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                        Spacer()
                        Text(viewModel.testDuration)
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .padding(.bottom, 20)
            saveResultsButton
            .padding(.bottom, 30)
        }

    }
    
    // MARK: - Audiogram View
    private var audiogramView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("กราฟออดิโอแกรมการได้ยิน")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .padding(.horizontal)
                    .padding(.top, 15)
                
                // OPTION 1: Use PlotlyAudiogramView (WebView-based)
                PlotlyAudiogramView(
                    rightEarData: viewModel.rightEarDataPoints,
                    leftEarData: viewModel.leftEarDataPoints
                )
                .frame(height: 400)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // คำอธิบายออดิโอแกรม
                VStack(alignment: .leading, spacing: 10) {
                    Text("เกี่ยวกับออดิโอแกรม")
                        .font(.headline)
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    
                    Text("ออดิโอแกรมแสดงความสามารถในการได้ยินของคุณตามความถี่ต่างๆ ค่าที่ต่ำบนกราฟ (แสดงที่ด้านบน) บ่งบอกถึงการได้ยินที่ดีกว่า กราฟแสดงผลของหูทั้งสองข้าง ช่วยในการระบุรูปแบบการสูญเสียการได้ยิน")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // คำอธิบายสัญลักษณ์
                HStack(spacing: 20) {
                    legendItem(color: pastelRed, text: "หูขวา")
                    legendItem(color: pastelBlue, text: "หูซ้าย")
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // ปุ่มบันทึกผล
//                saveResultsButton
//                    .padding()
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Recommendations View
    private var recommendationsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("คำแนะนำที่เหมาะสม")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .padding(.horizontal)
                    .padding(.top, 15)
                
                // คำแนะนำ
                ForEach(viewModel.recommendations.indices, id: \.self) { index in
                    recommendationCard(
                        number: index + 1,
                        recommendation: viewModel.recommendations[index]
                    )
                }
                
                // ปุ่มนัดหมาย
                Button(action: {
                    viewModel.scheduleFollowUp()
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16))
                        
                        Text("นัดหมายผู้เชี่ยวชาญ")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(pastelBlue)
                            .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
                    )
                }
                .padding()
                
                // ข้อความปฏิเสธความรับผิดชอบ
                disclaimerBox
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - UI Components
    
    // การ์ดการจำแนกการได้ยิน
    private func classificationCard(title: String, classification: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Spacer()
            }
            
            Text(classification)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            
            Text(viewModel.descriptionFor(classification: classification))
                .font(.subheadline)
                .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
        )
    }
    
    // ตารางแสดงผลการทดสอบรายความถี่
    private var frequencyBreakdownGrid: some View {
        VStack(spacing: 0) {
            // ส่วนหัวตาราง
            HStack {
                Text("ความถี่")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 80, alignment: .leading)
                
                Text("หูขวา")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                
                Text("หูซ้าย")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(pastelBlue.opacity(0.15))
            
            // แถวข้อมูลความถี่
            ForEach(viewModel.frequencyBreakdown, id: \.frequency) { item in
                HStack {
                    Text(item.frequencyLabel)
                        .font(.caption)
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                        .frame(width: 80, alignment: .leading)
                    
                    HStack {
                        Text("\(Int(item.rightLevel)) dB")
                            .font(.caption)
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                        
                        Circle()
                            .fill(colorFor(level: item.rightLevel))
                            .frame(width: 8, height: 8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("\(Int(item.leftLevel)) dB")
                            .font(.caption)
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                        
                        Circle()
                            .fill(colorFor(level: item.leftLevel))
                            .frame(width: 8, height: 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(
                    Rectangle()
                        .fill(item.frequency.truncatingRemainder(dividingBy: 2) == 0 ?
                              Color.white.opacity(0.7) : Color.white.opacity(0.9))
                )
                
                if item.frequency != viewModel.frequencyBreakdown.last?.frequency {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // การ์ดคำแนะนำ
    private func recommendationCard(number: Int, recommendation: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(pastelGreen)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(recommendation)
                .font(.body)
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: pastelGreen.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // ปุ่มบันทึกผล
    private var saveResultsButton: some View {
        Button(action: {
            // ป้องกันการบันทึกซ้ำหรือขณะกำลังบันทึก
            guard !resultsSaved && !isSaving else { return }
            
            // แสดงสถานะกำลังบันทึก
            isSaving = true
            
            // บันทึกผล
            viewModel.saveResults()
            
            // กำหนดว่าบันทึกแล้ว
            resultsSaved = true
            
            // แสดงการแจ้งเตือนยืนยันการบันทึก
            showingSaveConfirmation = true
            
            // รีเซ็ตสถานะการบันทึกหลังจากหน่วงเวลาสักครู่
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSaving = false
            }
        }) {
            HStack {
                if isSaving {
                    // แสดงตัวหมุนขณะกำลังบันทึก
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 10)
                }
                
                Text(resultsSaved ? "บันทึกผลแล้ว" : "บันทึกผลการทดสอบ")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(resultsSaved ? Color.gray : pastelBlue)
                    .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
            )
            .opacity(isSaving ? 0.7 : 1.0) // แสดงผลเชิงภาพขณะกำลังบันทึก
        }
        .disabled(resultsSaved || isSaving)
        .padding(.horizontal)
    }
    
    // คำอธิบายสัญลักษณ์
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
        }
    }
    
    // ข้อความปฏิเสธความรับผิดชอบ
    private var disclaimerBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(pastelYellow)
                
                Text("ข้อควรทราบ")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            
            Text("แอปพลิเคชันนี้เป็นเพียงเครื่องมือคัดกรองเบื้องต้นและไม่ใช่สิ่งทดแทนคำแนะนำทางการแพทย์จากผู้เชี่ยวชาญ โปรดปรึกษานักแก้ไขการได้ยินเพื่อรับการประเมินที่ครอบคลุม")
                .font(.caption)
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(pastelYellow.opacity(0.2))
                .shadow(color: pastelYellow.opacity(0.2), radius: 3, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Functions
    
    // สีตามระดับการได้ยิน
    private func colorFor(level: Float) -> Color {
        switch level {
        case 0..<25:
            return pastelGreen
        case 25..<40:
            return pastelYellow
        case 40..<60:
            return pastelOrange
        case 60..<80:
            return pastelRed
        default:
            return Color.purple
        }
    }
}
