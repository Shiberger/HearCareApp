//
//  LoginView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

import SwiftUI
import GoogleSignIn
import WebKit


// MARK: - Pastel Colors
private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var isAnimating = false
    
    // ไล่สีพื้นหลัง
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [pastelBlue.opacity(0.8), pastelGreen.opacity(0.6)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            // พื้นหลังไล่สี
            backgroundGradient
                .ignoresSafeArea()
            
            // พื้นหลังวงกลมตกแต่ง
            Group {
                Circle()
                    .fill(pastelYellow.opacity(0.4))
                    .frame(width: 200, height: 200)
                    .offset(x: -150, y: -250)
                
                Circle()
                    .fill(pastelBlue.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .offset(x: 150, y: 350)
                
                Circle()
                    .fill(pastelGreen.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .offset(x: 130, y: -300)
            }
            
            // เนื้อหาหลัก
            VStack(spacing: 30) {
                Spacer()
                
                // โลโก้และชื่อแอป
                VStack(spacing: 20) {
                    // โลโก้แอป
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 170, height: 170)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Image("IconGradient")
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 130, height: 130)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                    
                    // ชื่อแอป
                    Text("HearCare")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // คำอธิบาย
                    Text("Test and monitor your hearing health")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // คำแนะนำ
                VStack(spacing: 15) {
                    benefitRow(icon: "ear.fill", text: "เช็คการได้ยินด้วยการทดสอบแบบเบื้องต้น")
                    benefitRow(icon: "chart.line.uptrend.xyaxis", text: "ติดตามการเปลี่ยนแปลงการได้ยินของคุณ")
                    benefitRow(icon: "bell.fill", text: "รับคำแนะนำด้านสุขภาพการได้ยิน")
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                Spacer()
                
                // ส่วนล็อกอิน
                VStack(spacing: 20) {
                    // ปุ่มล็อกอินด้วย Google
                    Button(action: {
                        authService.signInWithGoogle()
                    }) {
                        HStack(spacing: 12) {
                            Image("google_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Text("Sign in with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .foregroundColor(.black)
                    }
                    .disabled(authService.isAuthenticating)
                    .padding(.horizontal, 30)
                    
                    // ตัวแสดงสถานะ
                    if authService.isAuthenticating {
                        ProgressView()
                            .scaleEffect(1.3)
                            .progressViewStyle(CircularProgressViewStyle(tint: pastelBlue))
                            .padding()
                    }
                    
                    // ข้อความแสดงข้อผิดพลาด
                    if let error = authService.error {
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: Color.red.opacity(0.3), radius: 3, x: 0, y: 2)
                            )
                        }
                        .padding(.horizontal, 30)
                    }
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    // แถวประโยชน์
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(pastelBlue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }

    private func resetAuthenticationState() {
        // Clear web data with the correct WKWebsiteDataType constants
        let websiteDataTypes = Set([
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache
        ])
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes,
                                              modifiedSince: Date(timeIntervalSince1970: 0)) {
            // Now try the sign-in again
            DispatchQueue.main.async {
                authService.clearError()
                authService.signInWithGoogle()
            }
        }
    }
}
