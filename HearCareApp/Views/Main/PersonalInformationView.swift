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
    @State private var showPhotoOptions: Bool = false
    
    private let saveDebounceInterval: TimeInterval = 2.0 // 2 seconds debounce time
    
    // สีพาสเทล
    private let pastelBlue = Color(red: 174/255, green: 198/255, blue: 255/255)
    private let pastelGreen = Color(red: 181/255, green: 234/255, blue: 215/255)
    private let pastelYellow = Color(red: 255/255, green: 240/255, blue: 179/255)
    
    // เกรเดียนต์พื้นหลัง
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [pastelBlue.opacity(0.5), pastelGreen.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
        case notSpecified = "Prefer not to say"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            // พื้นหลังเกรเดียนต์
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Profile image
                    profileImageSection
                    
                    // Information fields
                    VStack(spacing: 0) {
                        // หัวข้อส่วนข้อมูลส่วนตัว
                        HStack {
                            Text("Personal Information")
                                .font(.headline)
                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        // ข้อมูลส่วนตัว
                        informationField(icon: "person.fill", title: "Display Name", value: $displayName, editable: isEditing, backgroundColor: Color.white)
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        informationField(icon: "envelope.fill", title: "Email", value: $email, editable: false, backgroundColor: Color.white.opacity(0.7))
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        informationField(icon: "phone.fill", title: "Phone Number", value: $phoneNumber, editable: isEditing, keyboardType: .phonePad, backgroundColor: Color.white)
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        informationField(icon: "calendar", title: "Age", value: $age, editable: isEditing, keyboardType: .numberPad, backgroundColor: Color.white.opacity(0.7))
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        // Gender picker
                        HStack {
                            // ไอคอนเพศ
                            ZStack {
                                Circle()
                                    .fill(pastelBlue.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "person.text.rectangle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(pastelBlue)
                            }
                            .padding(.trailing, 8)
                            
                            Text("Gender")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            if isEditing {
                                Picker("Gender", selection: $gender) {
                                    ForEach(Gender.allCases) { gender in
                                        Text(gender.rawValue).tag(gender)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(pastelBlue)
                            } else {
                                Text(gender.rawValue)
                                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                            }
                        }
                        .padding()
                        .background(Color.white)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
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
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .padding(.trailing, 5)
                                }
                                
                                Text("Save")
                                    .font(AppTheme.Typography.headline)
                            }
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(isSaving ? Color.gray : pastelBlue)
                                    .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
                            )
                            .opacity(isSaving ? 0.7 : 1.0)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal)
                        
                        Button(action: {
                            // Cancel editing, reload original data
                            withAnimation {
                                isEditing = false
                                loadUserInformation()
                            }
                        }) {
                            Text("Cancel")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(pastelBlue)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(pastelBlue, lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.horizontal)
                    } else {
                        Button(action: {
                            withAnimation {
                                isEditing = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.trailing, 5)
                                
                                Text("Edit Information")
                                    .font(AppTheme.Typography.headline)
                            }
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(pastelBlue)
                                    .shadow(color: pastelBlue.opacity(0.5), radius: 5, x: 0, y: 3)
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                .sheet(isPresented: $showPhotoOptions) {
                    PhotoPickerSheet { image in
                        // Handle selected image
                        // This would be where you upload to storage
                        showPhotoOptions = false
                    }
                    .interactiveDismissDisabled(true)
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
                .padding(.vertical, AppTheme.Spacing.large)
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Information"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            
            // Loading overlay
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Loading data...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.7))
                    )
                }
            }
        }
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            isEditing = true
                        }
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(pastelBlue)
                    }
                }
            }
        }
        .onAppear {
            loadUserInformation()
        }
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(pastelBlue.opacity(0.2))
                    .frame(width: 110, height: 110)
                
                if let photoURL = authService.user?.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: pastelBlue))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(pastelBlue)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
                
                if isEditing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showPhotoOptions = true
                                // Photo selection logic would go here
                            }) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(pastelBlue)
                                            .shadow(color: pastelBlue.opacity(0.5), radius: 3, x: 0, y: 2)
                                    )
                            }
                            .offset(x: 5, y: 5)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            
            if isEditing {
            
                Button(action: {
                    showPhotoOptions = true
                }) {
                    Text("Change Photo")
                        .font(.caption)
                        .foregroundColor(pastelBlue)
                        .fontWeight(.medium)
                }
                .padding(.top, 6)
        
            } else if !displayName.isEmpty {
                Text(displayName)
                    .font(.headline)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                if !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(Color.gray)
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Information Field
    private func informationField(
        icon: String,
        title: String,
        value: Binding<String>,
        editable: Bool,
        keyboardType: UIKeyboardType = .default,
        backgroundColor: Color = Color.white
    ) -> some View {
        HStack {
            // ไอคอน
            ZStack {
                Circle()
                    .fill(pastelBlue.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(pastelBlue)
            }
            .padding(.trailing, 8)
            
            // หัวข้อ
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            Spacer()
            
            // ช่องข้อมูล
            if editable {
                TextField("", text: value)
                    .keyboardType(keyboardType)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width / 2.2)
            } else {
                Text(value.wrappedValue.isEmpty ? "Not specified" : value.wrappedValue)
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding()
        .background(backgroundColor)
    }
    
    // MARK: - Data Loading & Saving Functions
    // ฟังก์ชันเดิมคงไว้ทั้งหมด
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
struct PhotoPickerSheet: View {
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

