//
//  TESTSwiftUIView.swift
//  HearCareApp
//
//  Created by Kornchanok Subsin on 9/4/2568 BE.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


// MARK: - Pastel Colors
private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)

// MARK: - Gradient
private var backgroundGradient: LinearGradient {
    LinearGradient(
        gradient: Gradient(colors: [pastelBlue, pastelGreen]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}


struct TESTPersonalInformationView: View {
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
    @State private var showPhotoOptions: Bool = false
    
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
                    Group {
                        informationField(
                            icon: "person.fill",
                            title: "Display Name",
                            value: $displayName,
                            editable: isEditing
                        )
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        informationField(
                            icon: "envelope.fill",
                            title: "Email",
                            value: $email,
                            editable: false
                        )
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        informationField(
                            icon: "phone.fill",
                            title: "Phone Number",
                            value: $phoneNumber,
                            editable: isEditing,
                            keyboardType: .phonePad
                        )
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        informationField(
                            icon: "calendar",
                            title: "Age",
                            value: $age,
                            editable: isEditing,
                            keyboardType: .numberPad
                        )
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        // Gender picker
                        HStack(spacing: 16) {
                            Image(systemName: "person.text.rectangle.fill")
                                .foregroundColor(AppTheme.primaryColor)
                                .frame(width: 24)
                            
                            Text("Gender")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 100, alignment: .leading)
                            
                            if isEditing {
                                Picker("Gender", selection: $gender) {
                                    ForEach(Gender.allCases) { gender in
                                        Text(gender.rawValue).tag(gender)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .tint(AppTheme.primaryColor)
                            } else {
                                Text(gender.rawValue)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.vertical, AppTheme.Spacing.large)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Information"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showPhotoOptions) {
                TESTPhotoPickerSheet { image in
                    // Handle selected image
                    // This would be where you upload to storage
                    showPhotoOptions = false
                }
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
        .background(AppTheme.backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit")
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.primaryColor)
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
            ZStack(alignment: .bottomTrailing) {
                if let photoURL = authService.user?.photoURL {
                    AsyncImage(url: photoURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 120, height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(AppTheme.primaryColor)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(AppTheme.primaryColor)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
                
                if isEditing {
                    Button(action: {
                        showPhotoOptions = true
                    }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(AppTheme.primaryColor)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
            }
            
            if isEditing {
                Button(action: {
                    showPhotoOptions = true
                }) {
                    Text("Change Photo")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.primaryColor)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
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
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text("Save Changes")
                            .font(AppTheme.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isSaving ? Color.gray : AppTheme.primaryColor)
                    .cornerRadius(AppTheme.Radius.medium)
                    .opacity(isSaving ? 0.7 : 1.0) // Visual feedback
                    .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
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
                        .fontWeight(.medium)
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
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primaryColor)
                        .cornerRadius(AppTheme.Radius.medium)
                        .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func informationField(icon: String, title: String, value: Binding<String>, editable: Bool, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primaryColor)
                .frame(width: 24)
            
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            if editable {
                TextField(title, text: value)
                    .keyboardType(keyboardType)
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(value.wrappedValue.isEmpty ? "Not provided" : value.wrappedValue)
                    .foregroundColor(value.wrappedValue.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
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

// Helper view for photo picking options
struct TESTPhotoPickerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    var onImageSelected: (UIImage) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Change Profile Photo")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Divider()
            
            Button(action: {
                // This would open camera
                // For simplicity, we'll just dismiss
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(AppTheme.primaryColor)
                    Text("Take Photo")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(AppTheme.Radius.medium)
            }
            
            Button(action: {
                // This would open photo library
                // For simplicity, we'll just dismiss
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(AppTheme.primaryColor)
                    Text("Choose from Library")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(AppTheme.Radius.medium)
            }
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(AppTheme.Radius.medium)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}

