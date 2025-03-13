//
//  CustomComponents.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// CustomComponents.swift
import SwiftUI

// Custom Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let icon: String?
    var isDisabled: Bool = false
    
    init(title: String, icon: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
            }
            .primaryButton()
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

// Custom Text Field
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    
    init(_ placeholder: String, text: Binding<String>, icon: String? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 24, height: 24)
            }
            
            TextField(placeholder, text: $text)
                .font(AppTheme.Typography.body)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Custom Card
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String?
    let content: Content
    
    init(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryColor)
                }
                
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            content
        }
        .cardStyle()
    }
}

// Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(selectedTab == index ? AppTheme.Typography.headline : AppTheme.Typography.body)
                                .foregroundColor(selectedTab == index ? AppTheme.primaryColor : AppTheme.textSecondary)
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                                
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(AppTheme.primaryColor)
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
            
            Divider()
        }
    }
    
    @Namespace private var namespace
}

// Ear Selection Component
struct EarSelectionView: View {
    @Binding var selectedEar: AudioService.Ear
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            earButton(ear: .left, isSelected: selectedEar == .left)
            earButton(ear: .right, isSelected: selectedEar == .right)
        }
    }
    
    private func earButton(ear: AudioService.Ear, isSelected: Bool) -> some View {
        let label = ear == .left ? "Left Ear" : "Right Ear"
        let icon = ear == .left ? "ear.fill" : "ear.fill"
        let color = ear == .left ? Color.red : Color.blue
        
        return Button(action: {
            selectedEar = ear
        }) {
            VStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? color : AppTheme.textSecondary)
                
                Text(label)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(isSelected ? color : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected ? color.opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Fixed AudioWaveView in CustomComponents.swift
struct AudioWaveView: View {
    @State private var phase = 0.0
    let isPlaying: Bool
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                if isPlaying {
                    phase += 0.05
                    if phase > .pi * 2 {
                        phase = 0
                    }
                }
                
                let width = size.width
                let height = size.height
                let centerY = height / 2
                let amplitude = height * 0.25
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: centerY))
                
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    
                    // Fixed ambiguous multiplication by being explicit with types
                    let relativeXFloat = Float(relativeX)
                    let phaseFloat = Float(phase)
                    let amplitudeFloat = Float(amplitude)
                    
                    // Multiple sine waves for more complexity - fixed with explicit Float types
                    let y1 = sin(relativeXFloat * Float.pi * 10 + phaseFloat) * amplitudeFloat * 0.5
                    let y2 = sin(relativeXFloat * Float.pi * 5 + phaseFloat * 0.5) * amplitudeFloat * 0.3
                    let y3 = sin(relativeXFloat * Float.pi * 20 + phaseFloat * 1.5) * amplitudeFloat * 0.2
                    
                    // Envelope to fade at edges
                    let envelope = sin(relativeXFloat * Float.pi) * 0.8 + 0.2
                    
                    // Convert back to CGFloat for the path
                    let y = CGFloat((y1 + y2 + y3) * envelope) + centerY
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [AppTheme.primaryColor.opacity(0.5), AppTheme.primaryColor]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: width, y: 0)
                    ),
                    lineWidth: 3
                )
            }
        }
        .frame(height: 100)
    }
}
