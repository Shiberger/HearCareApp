//
//  PlotlyAudiogramView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
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
        let rightEarX = rightEarData.map { String(Int($0.frequency)) }
        let rightEarY = rightEarData.map { $0.hearingLevel }
        
        let leftEarX = leftEarData.map { String(Int($0.frequency)) }
        let leftEarY = leftEarData.map { $0.hearingLevel }
        
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
                
                const layout = {
                    xaxis: {
                        title: 'Frequency (Hz)',
                        type: 'category',
                        categoryorder: 'array',
                        categoryarray: ['500', '1000', '2000', '4000', '8000'],
                    },
                    yaxis: {
                        title: 'Hearing Level (dB HL)',
                        range: [-10, 120],
                        // The critical fix is here - this ensures better hearing is at the top
                        autorange: 'reversed',
                    },
                    shapes: [
                        // Normal hearing zone (-10-25 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: -10,
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
                        // Moderate hearing loss zone (40-55 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 40,
                            x1: 1,
                            y1: 55,
                            fillcolor: 'rgba(255, 165, 0, 0.1)',
                            line: { width: 0 }
                        },
                        // Moderately severe loss zone (55-70 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 55,
                            x1: 1,
                            y1: 70,
                            fillcolor: 'rgba(255, 100, 0, 0.1)',
                            line: { width: 0 }
                        },
                        // Severe hearing loss zone (70-90 dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 70,
                            x1: 1,
                            y1: 90,
                            fillcolor: 'rgba(255, 0, 0, 0.1)',
                            line: { width: 0 }
                        },
                        // Profound hearing loss zone (90+ dB)
                        {
                            type: 'rect',
                            xref: 'paper',
                            yref: 'y',
                            x0: 0,
                            y0: 90,
                            x1: 1,
                            y1: 120,
                            fillcolor: 'rgba(128, 0, 128, 0.1)',
                            line: { width: 0 }
                        }
                    ],
                    annotations: [
                        // Add annotations for hearing loss zones
                        {
                            x: 1.05,
                            y: 10,
                            xref: 'paper',
                            yref: 'y',
                            text: 'Normal',
                            showarrow: false,
                            font: {
                                family: 'Arial',
                                size: 10,
                                color: 'green'
                            }
                        },
                        {
                            x: 1.05,
                            y: 32.5,
                            xref: 'paper',
                            yref: 'y',
                            text: 'Mild',
                            showarrow: false,
                            font: {
                                family: 'Arial',
                                size: 10,
                                color: 'olive'
                            }
                        },
                        {
                            x: 1.05,
                            y: 47.5,
                            xref: 'paper',
                            yref: 'y',
                            text: 'Moderate',
                            showarrow: false,
                            font: {
                                family: 'Arial',
                                size: 10,
                                color: 'orange'
                            }
                        },
                        {
                            x: 1.05,
                            y: 62.5,
                            xref: 'paper',
                            yref: 'y',
                            text: 'Mod-Severe',
                            showarrow: false,
                            font: {
                                family: 'Arial',
                                size: 10,
                                color: 'darkorange'
                            }
                        },
                        {
                            x: 1.05,
                            y: 80,
                            xref: 'paper',
                            yref: 'y',
                            text: 'Severe',
                            showarrow: false,
                            font: {
                                family: 'Arial',
                                size: 10,
                                color: 'red'
                            }
                        },
                        {
                            x: 1.05,
                            y: 105,
                            xref: 'paper',
                            yref: 'y',
                            text: 'Profound',
                            showarrow: false,
                            font: {
                                family: 'Arial',
                                size: 10,
                                color: 'purple'
                            }
                        }
                    ],
                    legend: {
                        x: 0.01,
                        y: 1.15,
                        orientation: 'h',
                        font: {
                            family: 'SF Pro Display, -apple-system, sans-serif',
                            size: 12
                        }
                    },
                    margin: {
                        l: 60,
                        r: 80, // Increased right margin for annotations
                        b: 80,
                        t: 60,
                    },
                    paper_bgcolor: 'rgba(0,0,0,0)',
                    plot_bgcolor: 'rgba(0,0,0,0)',
                    font: {
                        family: 'SF Pro Display, -apple-system, sans-serif'
                    }
                };
                
                const rightEarTrace = {
                    x: rightEarX,
                    y: rightEarY,
                    mode: 'lines+markers',
                    name: 'Right Ear (O)',
                    line: { color: 'red', width: 2 }, // Changed to red to match clinical standards
                    marker: { 
                        symbol: 'circle',
                        size: 12,
                        color: 'red',
                        line: {
                            color: 'white',
                            width: 1
                        }
                    }
                };
                
                const leftEarTrace = {
                    x: leftEarX,
                    y: leftEarY,
                    mode: 'lines+markers',
                    name: 'Left Ear (X)',
                    line: { color: 'blue', width: 2 }, // Changed to blue
                    marker: { 
                        symbol: 'x',
                        size: 12,
                        color: 'blue',
                        line: {
                            color: 'blue',
                            width: 2
                        }
                    }
                };
                
                // Setup the grid for better visualization
                layout.yaxis.gridcolor = 'rgba(200,200,200,0.2)';
                layout.xaxis.gridcolor = 'rgba(200,200,200,0.2)';
                layout.yaxis.gridwidth = 1;
                layout.xaxis.gridwidth = 1;
                
                // Setup axis tick values
                layout.yaxis.tickvals = [-10, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120];
                
                Plotly.newPlot('chart', [rightEarTrace, leftEarTrace], layout, {
                    responsive: true,
                    displayModeBar: false
                });
                
                window.addEventListener('resize', function() {
                    Plotly.relayout('chart', {
                        'width': window.innerWidth,
                        'height': window.innerHeight
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
