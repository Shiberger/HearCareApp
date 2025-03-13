//
//  HistoryViewModel.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 4/3/2568 BE.
//

import SwiftUI
import Firebase

class HistoryViewModel: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    
    func loadTestHistory() {
        isLoading = true
        errorMessage = nil
        
        firestoreService.getTestHistoryForCurrentUser { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let testResults):
                    self.testResults = testResults
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Failed to load test history: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func refreshTestHistory() {
        loadTestHistory()
    }
}
