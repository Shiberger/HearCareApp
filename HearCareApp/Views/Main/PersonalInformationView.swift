//
//  PersonalInformationView.swift
//  HearCareApp
//
//  Created by Hannarong Kaewkiriya on 3/18/2568 BE.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PersonalInformationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var age: String = ""
    @State private var gender: Gender = .notSpecified
    @State private var isEditing: Bool = false
    @State private var isLoading: Bool = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isSaving: Bool = false
    @State private var lastSaveTime: Date? = nil
    
    private let saveDebounceInterval: TimeInterval = 2.0 // 2 seconds debounce time
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
        case notSpecified = "Prefer not to say"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Profile image
                profileImageSection
                
                // Information fields
                VStack(spacing: 0) {
                    informationField(title: "Display Name", value: $displayName, editable: isEditing)
                    
                    Divider()
                        .padding(.leading, 120)
                    
                    informationField(title: "Email", value: $email, editable: false)
                    
                    Divider()
                        .padding(.leading, 120)
                    
                    informationField(title: "Phone Number", value: $phoneNumber, editable: isEditing, keyboardType: .phonePad)
                    
                    Divider()
                        .padding(.leading, 120)
                    
                    informationField(title: "Age", value: $age, editable: isEditing, keyboardType: .numberPad)
                    
                    Divider()
                        .padding(.leading, 120)
                    
                    // Gender picker
                    HStack {
                        Text("Gender")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 120, alignment: .leading)
                        
                        if isEditing {
                            Picker("Gender", selection: $gender) {
                                ForEach(Gender.allCases) { gender in
                                    Text(gender.rawValue).tag(gender)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(gender.rawValue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(AppTheme.Radius.medium)
                .padding(.horizontal)
                
                // Action Buttons
                if isEditing {
                    Button(action: {
                        // Get current time
                        let now = Date()
                        
                        // Check if already saving or if last save was too recent
                        if isSaving || (lastSaveTime != nil && now.timeIntervalSince(lastSaveTime!) < saveDebounceInterval) {
                            return
                        }
                        
                        // Update state
                        isSaving = true
                        lastSaveTime = now
                        
                        // Save information
                        saveUserInformation()
                        
                        // Reset saving state after a delay to prevent multiple rapid taps
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isSaving = false
                        }
                    }) {
                        Text("Save")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isSaving ? Color.gray : AppTheme.primaryColor)
                            .cornerRadius(AppTheme.Radius.medium)
                            .opacity(isSaving ? 0.7 : 1.0) // Visual feedback
                    }
                    .disabled(isSaving)
                    .padding(.horizontal)
                    
                    Button(action: {
                        // Cancel editing, reload original data
                        isEditing = false
                        loadUserInformation()
                    }) {
                        Text("Cancel")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.primaryColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.primaryColor, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit Information")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.Radius.medium)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, AppTheme.Spacing.large)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Information"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay(
                Group {
                    if isLoading {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            )
        }
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit")
                    }
                }
            }
        }
        .onAppear {
            loadUserInformation()
        }
    }
    
    private var profileImageSection: some View {
        VStack {
            if let photoURL = authService.user?.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppTheme.primaryColor)
            }
            
            if isEditing {
                Button(action: {
                    // Photo selection logic would go here
                    // This would typically involve using UIImagePickerController
                    // via UIViewControllerRepresentable
                }) {
                    Text("Change Photo")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.primaryColor)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func informationField(title: String, value: Binding<String>, editable: Bool, keyboardType: UIKeyboardType = .default) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            if editable {
                TextField("", text: value)
                    .keyboardType(keyboardType)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(value.wrappedValue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
    
    private func loadUserInformation() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        // Set basic information from Auth
        displayName = user.displayName ?? ""
        email = user.email ?? ""
        phoneNumber = user.phoneNumber ?? ""
        
        // Get additional information from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Error loading information: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                
                // Update with Firestore data
                DispatchQueue.main.async {
                    self.phoneNumber = data["phoneNumber"] as? String ?? self.phoneNumber
                    self.age = data["age"] as? String ?? ""
                    
                    if let genderValue = data["gender"] as? String,
                       let userGender = Gender.allCases.first(where: { $0.rawValue == genderValue }) {
                        self.gender = userGender
                    } else {
                        self.gender = .notSpecified
                    }
                }
            } else {
                // Create user document if it doesn't exist
                let userData: [String: Any] = [
                    "displayName": self.displayName,
                    "email": self.email,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        alertMessage = "Error creating user profile: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }
        }
    }
    
    private func saveUserInformation() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "No authenticated user found"
            showAlert = true
            return
        }
        
        // Update display name in Auth
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        
        changeRequest.commitChanges { error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Error updating display name: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            
            // Update additional information in Firestore
            let userData: [String: Any] = [
                "displayName": self.displayName,
                "phoneNumber": self.phoneNumber,
                "age": self.age,
                "gender": self.gender.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).updateData(userData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        alertMessage = "Error updating information: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        alertMessage = "Information updated successfully"
                        showAlert = true
                        isEditing = false
                        
                        // Refresh auth service user data
                        self.authService.refreshUserData()
                    }
                }
            }
        }
    }
}
