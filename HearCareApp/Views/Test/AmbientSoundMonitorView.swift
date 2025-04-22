//
//  AmbientSoundMonitorView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 22/4/2568 BE.
//

import SwiftUI

struct AmbientSoundMonitorView: View {
    @ObservedObject var soundService = AmbientSoundService.shared
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: soundService.ambientNoiseLevel.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(soundService.ambientNoiseLevel.color))
                
                Text("Ambient Noise Level")
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                Text(soundService.ambientNoiseLevel.rawValue)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(Color(soundService.ambientNoiseLevel.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(Color(soundService.ambientNoiseLevel.color).opacity(0.2))
                    )
            }
            
            // Sound level meter
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Fill based on current decibel level
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(levelColor())
                    .frame(width: calculateWidth(), height: 8)
            }
            
            HStack {
                Text("\(Int(soundService.currentDecibels)) dB")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text(soundService.ambientNoiseLevel.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            soundService.startMonitoring()
        }
        .onDisappear {
            soundService.stopMonitoring()
        }
    }
    
    // Calculate the width of the filled portion of the progress bar
    private func calculateWidth() -> CGFloat {
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 40 // Adjust for padding
        let progress = CGFloat(min(soundService.currentDecibels / 100.0, 1.0))
        return maxWidth * progress
    }
    
    // Determine the color based on the current noise level
    private func levelColor() -> Color {
        switch soundService.ambientNoiseLevel {
        case .acceptable:
            return Color.green
        case .moderate:
            return Color.yellow
        case .excessive:
            return Color.red
        }
    }
}

struct AmbientSoundMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        AmbientSoundMonitorView()
            .padding()
            .background(Color.gray.opacity(0.1))
            .previewLayout(.sizeThatFits)
    }
}
