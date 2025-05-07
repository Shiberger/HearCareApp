//
//  HearCareApp.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//
import SwiftUI
import Firebase
import GoogleSignIn

@main
struct HearCareApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var authService = AuthenticationService()
    @State private var showSplash = true
    
    // สีพาสเทล
    private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
    private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
    private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)
    private let pastelPurple = Color(red: 0.88, green: 0.83, blue: 0.98)
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    EnhancedSplashScreenView(pastelBlue: pastelBlue, pastelGreen: pastelGreen, pastelYellow: pastelYellow)
                        .onAppear {
                            // แสดง Splash Screen เป็นเวลา 3 วินาที
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeOut(duration: 1.0)) {
                                    self.showSplash = false
                                }
                            }
                        }
                } else {
                    if authService.user != nil {
                        HomeView()
                            .environmentObject(authService)
                            .transition(.opacity.combined(with: .scale(scale: 1.05)))
                            .animation(.easeInOut(duration: 0.5), value: !showSplash)
                    } else {
                        LoginView()
                            .environmentObject(authService)
                            .transition(.opacity.combined(with: .scale(scale: 1.05)))
                            .animation(.easeInOut(duration: 0.5), value: !showSplash)
                    }
                }
            }
        }
    }
}

// Splash Screen View ที่มีการเพิ่มแอนิเมชัน
struct EnhancedSplashScreenView: View {
    let pastelBlue: Color
    let pastelGreen: Color
    let pastelYellow: Color
    
    // State สำหรับแอนิเมชัน
    @State private var opacity = 0.0
    @State private var scale = 0.7
    @State private var rotation = -10.0
    @State private var textOpacity = 0.0
    @State private var textOffsetY = 20.0
    @State private var isShowingWave = false
    
    var body: some View {
        ZStack {
            // พื้นหลังแบบ gradient สไตล์พาสเทล
            LinearGradient(
                gradient: Gradient(colors: [pastelBlue.opacity(0.8), pastelGreen.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
            
            // เพิ่มลูกคลื่นเป็นองค์ประกอบตกแต่ง
            WaveView(isAnimating: $isShowingWave)
                .opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                ZStack {
                    // วงกลมเรืองแสงด้านหลังโลโก้
                    Circle()
                        .fill(pastelBlue.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .blur(radius: 10)
                    
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 130, height: 130)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // ไอคอนแอป
                    Image("IconGradient") // ตรวจสอบให้แน่ใจว่ามีในโปรเจคของคุณ
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                
                VStack(spacing: 10) {
                    Text("HearCare")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    
                    Text("ดูแลการได้ยินของคุณได้ทุกวัน")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .opacity(textOpacity)
                .offset(y: textOffsetY)
            }
        }
        .onAppear {
            // เริ่มแอนิเมชันทันทีที่หน้าจอปรากฏ
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
                rotation = 0
                opacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.7).delay(0.5)) {
                textOpacity = 1.0
                textOffsetY = 0
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                isShowingWave = true
            }
        }
    }
}

// คอมโพเนนต์คลื่นเคลื่อนไหว
struct WaveView: View {
    @Binding var isAnimating: Bool
    @State private var phase = 0.0
    
    var body: some View {
        ZStack {
            // คลื่นล่าง
            WaveShape(frequency: 10, amplitude: 0.03, phase: phase)
                .fill(Color.white.opacity(0.3))
                .frame(height: UIScreen.main.bounds.height)
                .offset(y: UIScreen.main.bounds.height * 0.3)
            
            // คลื่นบน
            WaveShape(frequency: 12, amplitude: 0.02, phase: phase * 1.2)
                .fill(Color.white.opacity(0.2))
                .frame(height: UIScreen.main.bounds.height)
                .offset(y: UIScreen.main.bounds.height * 0.25)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// รูปร่างคลื่น
struct WaveShape: Shape {
    var frequency: Double
    var amplitude: Double
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * frequency + phase)
            let y = midHeight + sine * midHeight * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        
        return Path(path.cgPath)
    }
}

// AppDelegate implementation for Firebase setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Initialize GIDSignIn
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Failed to restore previous Google Sign-In: \(error.localizedDescription)")
            }
        }
        
        return true
    }
    
    // Handle URL schemes for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Opening URL: \(url.absoluteString)")
        
        // Handle Google Sign-In URL
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Add handling for other URL schemes if needed
        
        return false
    }
}
