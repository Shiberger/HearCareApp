//
//  HistoryView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/3/2568 BE.
//
import SwiftUI
import Firebase

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    // สีพาสเทล
    private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
    private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
    private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)
    private let pastelPurple = Color(red: 233/255, green: 196/255, blue: 235/255)
    
    // เกรเดียนต์พื้นหลัง
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [pastelBlue.opacity(0.6), pastelGreen.opacity(0.5)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // พื้นหลังเกรเดียนต์
                backgroundGradient
                    .ignoresSafeArea()
                
                // เนื้อหาหลัก
                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.testResults.isEmpty {
                        emptyStateView
                    } else {
                        testHistoryList
                    }
                }
            }
            .navigationTitle("ประวัติการทดสอบ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshTestHistory()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(pastelBlue)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                }
            }
        }
        .onAppear {
            viewModel.loadTestHistory()
        }
    }
    
    // หน้าจอกำลังโหลด
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: pastelBlue))
                .padding()
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                )
            
            Text("กำลังโหลดประวัติการทดสอบ...")
                .font(AppTheme.Typography.headline)
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // หน้าจอไม่มีข้อมูล
    private var emptyStateView: some View {
        VStack(spacing: 25) {
            ZStack {
                Circle()
                    .fill(pastelYellow.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(pastelYellow)
                    .shadow(color: pastelYellow.opacity(0.5), radius: 2, x: 0, y: 2)
            }
            .padding(.top, 40)
            
            Text("ไม่พบประวัติการทดสอบ")
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            
            Text("ทำการทดสอบการได้ยินเพื่อบันทึกประวัติและดูผลลัพธ์ที่นี่")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 20)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("ข้อดีของการทดสอบเป็นประจำ:")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .padding(.bottom, 5)
                
                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "ติดตามการเปลี่ยนแปลงของการได้ยินตลอดเวลา")
                benefitRow(icon: "exclamationmark.triangle", text: "ตรวจพบปัญหาการได้ยินตั้งแต่ระยะเริ่มแรก")
                benefitRow(icon: "brain.head.profile", text: "เข้าใจรูปแบบการได้ยินของคุณดีขึ้น")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .padding(.horizontal, 30)
            
            Spacer().frame(height: 20)
            
            NavigationLink(destination: HearingTestView()) {
                HStack {
                    Image(systemName: "ear")
                        .font(.system(size: 18))
                    
                    Text("เริ่มการทดสอบการได้ยิน")
                        .font(AppTheme.Typography.headline)
                }
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(pastelBlue)
                        .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
                )
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // แถวข้อดีการทดสอบเป็นประจำ
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(pastelBlue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
    
    // รายการประวัติการทดสอบ
    private var testHistoryList: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ส่วนหัวรายการประวัติ
                VStack(alignment: .leading, spacing: 10) {
                    Text("ผลการทดสอบทั้งหมด")
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    
                    Text("ประวัติการทดสอบการได้ยินทั้งหมดของคุณ")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // รายการประวัติการทดสอบ
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(viewModel.testResults) { result in
                        testHistoryCard(result: result)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // การ์ดประวัติการทดสอบ
    private func testHistoryCard(result: TestResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // ส่วนหัวแสดงวันที่และเวลา
            HStack {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(pastelBlue)
                        .font(.system(size: 14))
                    
                    Text(dateFormatter.string(from: result.testDate))
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(pastelPurple)
                        .font(.system(size: 14))
                    
                    Text(timeFormatter.string(from: result.testDate))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Divider()
                .background(Color(red: 230/255, green: 230/255, blue: 230/255))
            
            // ส่วนแสดงผลการทดสอบ
            HStack(alignment: .top) {
                // ผลหูขวา
                VStack(alignment: .leading, spacing: 5) {
                    Text("หูขวา")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(colorForClassification(result.rightEarClassification))
                            .frame(width: 12, height: 12)
                        
                        Text(result.rightEarClassification)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // ผลหูซ้าย
                VStack(alignment: .leading, spacing: 5) {
                    Text("หูซ้าย")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: 5) {
                        Circle()
                            .fill(colorForClassification(result.leftEarClassification))
                            .frame(width: 12, height: 12)
                        
                        Text(result.leftEarClassification)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // ปุ่มดูรายละเอียด
                NavigationLink(
                    destination: TestResultDetailView(testResult: result)
                ) {
                    HStack {
                        Text("ดูรายละเอียด")
                            .font(AppTheme.Typography.subheadline)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(pastelBlue)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 3)
        )
    }
    
    // สีตามการจำแนกการได้ยิน
    private func colorForClassification(_ classification: String) -> Color {
        switch classification {
        case "Normal Hearing":
            return pastelGreen
        case "Mild Hearing Loss":
            return pastelYellow
        case "Moderate Hearing Loss":
            return Color(red: 255/255, green: 180/255, blue: 120/255) // สีส้มพาสเทล
        case "Severe Hearing Loss", "Profound Hearing Loss":
            return Color(red: 255/255, green: 150/255, blue: 150/255) // สีแดงพาสเทล
        default:
            return Color(red: 200/255, green: 200/255, blue: 200/255) // สีเทาพาสเทล
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// ส่วนนี้คงไว้ตามเดิม
struct TestResultDetailView: View {
    let testResult: TestResult
    @StateObject private var viewModel: ResultsViewModel
    
    init(testResult: TestResult) {
        self.testResult = testResult
        self._viewModel = StateObject(wrappedValue: ResultsViewModel(testResult: testResult))
    }
    
    var body: some View {
        // You can reuse the UI from DetailedResultsView or create a custom layout
        // This is just a placeholder that redirects to the actual implementation
        DetailedResultsView(viewModel: viewModel)
    }
}

// Extension สำหรับเรียกใช้ง่ายๆ (ถ้ายังไม่มี)
extension Text {
    func primaryButton() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(red: 174/255, green: 198/255, blue: 255/255))
                    .shadow(color: Color(red: 174/255, green: 198/255, blue: 255/255).opacity(0.5), radius: 5, x: 0, y: 3)
            )
    }
}
