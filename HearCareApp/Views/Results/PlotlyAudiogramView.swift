//
//  PlotlyAudiogramView.swift
//  HearCareApp
//

import SwiftUI
import WebKit

struct PlotlyAudiogramView: UIViewRepresentable {
    let rightEarData: [FrequencyDataPoint]
    let leftEarData: [FrequencyDataPoint]
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Convert data to JSON format for Plotly
        // UPDATED: Filter out any points that are at maximum threshold (90+)
        let rightEarX = rightEarData
            .filter { $0.hearingLevel <= 90 }
            .map { String(Int($0.frequency)) }
        
        let rightEarY = rightEarData
            .filter { $0.hearingLevel <= 90 }
            .map { $0.hearingLevel }
        
        let leftEarX = leftEarData
            .filter { $0.hearingLevel <= 90 }
            .map { String(Int($0.frequency)) }
        
        let leftEarY = leftEarData
            .filter { $0.hearingLevel <= 90 }
            .map { $0.hearingLevel }
        
        // NEW: Create separate arrays for "no response" points
        let rightNoResponseX = rightEarData
            .filter { $0.hearingLevel > 90 }
            .map { String(Int($0.frequency)) }
        
        let leftNoResponseX = leftEarData
            .filter { $0.hearingLevel > 90 }
            .map { String(Int($0.frequency)) }
        
        // Create HTML with Plotly
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
            <style>
                body { margin: 0; padding: 0; font-family: -apple-system, 'SF Pro Display'; }
                #chart { width: 100%; height: 100vh; }
            </style>
        </head>
        <body>
            <div id="chart"></div>
            <script>
                const rightEarX = \(rightEarX);
                const rightEarY = \(rightEarY);
                const leftEarX = \(leftEarX);
                const leftEarY = \(leftEarY);
                const rightNoResponseX = \(rightNoResponseX);
                const leftNoResponseX = \(leftNoResponseX);
                
                const layout = {
                    title: 'Audiogram',
                    xaxis: {
                        title: 'Frequency (Hz)',
                        type: 'category',
                        categoryorder: 'array',
                        categoryarray: ['500', '1000', '2000', '4000', '8000'],
                    },
                    yaxis: {
                        title: 'Hearing Level (dB)',
                        range: [0, 95],
                        autorange: 'reversed',
                    },
                    shapes: [
                        // Normal hearing zone (0-25 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 0,
                            x1: 1,
                            y1: 25,
                            fillcolor: 'rgba(0, 255, 0, 0.1)',
                            line: { width: 0 }
                        },
                        // Mild hearing loss zone (25-40 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 25,
                            x1: 1,
                            y1: 40,
                            fillcolor: 'rgba(255, 255, 0, 0.1)',
                            line: { width: 0 }
                        },
                        // Moderate hearing loss zone (40-60 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 40,
                            x1: 1,
                            y1: 60,
                            fillcolor: 'rgba(255, 165, 0, 0.1)',
                            line: { width: 0 }
                        },
                        // Severe hearing loss zone (60-80 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 60,
                            x1: 1,
                            y1: 80,
                            fillcolor: 'rgba(255, 0, 0, 0.1)',
                            line: { width: 0 }
                        },
                        // Profound hearing loss zone (80+ dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 80,
                            x1: 1,
                            y1: 95,
                            fillcolor: 'rgba(128, 0, 128, 0.1)',
                            line: { width: 0 }
                        }
                    ],
                    legend: {
                        x: 0.1,
                        y: 1.1,
                        orientation: 'h'
                    },
                    margin: {
                        l: 50,
                        r: 50,
                        b: 80,
                        t: 100,
                    }
                };
                
                const traces = [];
                
                // Right ear trace
                if (rightEarX.length > 0) {
                    traces.push({
                        x: rightEarX,
                        y: rightEarY,
                        mode: 'lines+markers',
                        name: 'Right Ear',
                        line: { color: 'blue' },
                        marker: { 
                            symbol: 'circle',
                            size: 10,
                            color: 'blue'
                        }
                    });
                }
                
                // Left ear trace
                if (leftEarX.length > 0) {
                    traces.push({
                        x: leftEarX,
                        y: leftEarY,
                        mode: 'lines+markers',
                        name: 'Left Ear',
                        line: { color: 'red' },
                        marker: { 
                            symbol: 'square',
                            size: 10,
                            color: 'red'
                        }
                    });
                }
                
                // Right ear "no response" points
                if (rightNoResponseX.length > 0) {
                    traces.push({
                        x: rightNoResponseX,
                        y: Array(rightNoResponseX.length).fill(90), // Fixed at 90 dB
                        mode: 'markers',
                        name: 'Right Ear (No Response)',
                        marker: { 
                            symbol: 'triangle-down',
                            size: 12,
                            color: 'blue'
                        },
                        showlegend: true
                    });
                }
                
                // Left ear "no response" points
                if (leftNoResponseX.length > 0) {
                    traces.push({
                        x: leftNoResponseX,
                        y: Array(leftNoResponseX.length).fill(90), // Fixed at 90 dB
                        mode: 'markers',
                        name: 'Left Ear (No Response)',
                        marker: { 
                            symbol: 'triangle-down',
                            size: 12,
                            color: 'red'
                        },
                        showlegend: true
                    });
                }
                
                Plotly.newPlot('chart', traces, layout, {responsive: true});
                
                window.addEventListener('resize', function() {
                    Plotly.relayout('chart', {
                        'xaxis.autorange': true,
                        'yaxis.autorange': true
                    });
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PlotlyAudiogramView
        
        init(_ parent: PlotlyAudiogramView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Handle any post-load actions if needed
        }
    }
}
