//
//  FirestoreService.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/3/2568 BE.
//

// FirestoreService.swift
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    private let db = Firestore.firestore()
    
    // Save test result to Firestore
    func saveTestResult(_ testResult: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = testResult["userId"] as? String else {
            completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
            return
        }
        
        // Create a reference to the user's test results collection
        let userTestsRef = db.collection("users").document(userId).collection("testResults")
        
        // Add the test result with an auto-generated ID
        userTestsRef.addDocument(data: testResult) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Save test result using the current authenticated user
    func saveTestResultForCurrentUser(_ testResult: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
            return
        }
        
        // Add the user ID to the test result data
        var updatedTestResult = testResult
        updatedTestResult["userId"] = user.uid
        
        // Call the standard save method
        saveTestResult(updatedTestResult, completion: completion)
    }
    
    // Get user's test history
    func getTestHistory(for userId: String, completion: @escaping (Result<[TestResult], Error>) -> Void) {
        let userTestsRef = db.collection("users").document(userId).collection("testResults")
        
        userTestsRef.order(by: "testDate", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let testResults = documents.compactMap { document -> TestResult? in
                do {
                    let data = document.data()
                    
                    // Create test result model from document data
                    let testDate = (data["testDate"] as? Timestamp)?.dateValue() ?? Date()
                    let rightEarClassification = data["rightEarClassification"] as? String ?? "Unknown"
                    let leftEarClassification = data["leftEarClassification"] as? String ?? "Unknown"
                    
                    // Parse frequency data
                    let rightEarData = data["rightEarData"] as? [[String: Any]] ?? []
                    let leftEarData = data["leftEarData"] as? [[String: Any]] ?? []
                    
                    var rightEarFrequencies: [TestFrequencyDataPoint] = []
                    var leftEarFrequencies: [TestFrequencyDataPoint] = []
                    
                    for point in rightEarData {
                        if let frequency = point["frequency"] as? Float,
                           let hearingLevel = point["hearingLevel"] as? Float {
                            rightEarFrequencies.append(TestFrequencyDataPoint(frequency: frequency, hearingLevel: hearingLevel))
                        }
                    }
                    
                    for point in leftEarData {
                        if let frequency = point["frequency"] as? Float,
                           let hearingLevel = point["hearingLevel"] as? Float {
                            leftEarFrequencies.append(TestFrequencyDataPoint(frequency: frequency, hearingLevel: hearingLevel))
                        }
                    }
                    
                    return TestResult(
                        id: document.documentID,
                        testDate: testDate,
                        rightEarClassification: rightEarClassification,
                        leftEarClassification: leftEarClassification,
                        rightEarData: rightEarFrequencies,
                        leftEarData: leftEarFrequencies
                    )
                } catch {
                    print("Error parsing document: \(error)")
                    return nil
                }
            }
            
            completion(.success(testResults))
        }
    }
    
    // Get test history for current user
    func getTestHistoryForCurrentUser(completion: @escaping (Result<[TestResult], Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
            return
        }
        
        getTestHistory(for: user.uid, completion: completion)
    }
    
    // Get user profile data
    func getUserProfile(for userId: String, completion: @escaping (Result<UserProfile?, Error>) -> Void) {
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.success(nil))
                return
            }
            
            do {
                let name = data["name"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let dateOfBirth = (data["dateOfBirth"] as? Timestamp)?.dateValue()
                let hearingConditions = data["hearingConditions"] as? [String] ?? []
                
                let userProfile = UserProfile(
                    id: userId,
                    name: name,
                    email: email,
                    dateOfBirth: dateOfBirth,
                    hearingConditions: hearingConditions
                )
                
                completion(.success(userProfile))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Get profile for current user
    func getCurrentUserProfile(completion: @escaping (Result<UserProfile?, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
            return
        }
        
        getUserProfile(for: user.uid, completion: completion)
    }
    
    // Update user profile
    func updateUserProfile(_ profile: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.collection("users").document(profile.id)
        
        var data: [String: Any] = [
            "name": profile.name,
            "email": profile.email
        ]
        
        if let dateOfBirth = profile.dateOfBirth {
            data["dateOfBirth"] = Timestamp(date: dateOfBirth)
        }
        
        data["hearingConditions"] = profile.hearingConditions
        
        userRef.setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

// Data Models - Renamed to avoid ambiguity
struct TestFrequencyDataPoint {
    let frequency: Float
    let hearingLevel: Float
}

struct TestResult: Identifiable {
    let id: String
    let testDate: Date
    let rightEarClassification: String
    let leftEarClassification: String
    let rightEarData: [TestFrequencyDataPoint]
    let leftEarData: [TestFrequencyDataPoint]
}

struct UserProfile {
    let id: String
    var name: String
    var email: String
    var dateOfBirth: Date?
    var hearingConditions: [String]
}
