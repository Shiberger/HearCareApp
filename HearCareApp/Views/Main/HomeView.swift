import SwiftUI
import FirebaseAuth

struct HomeView: View {
    // MARK: - Properties
    @State private var user: User?
    @Environment(\.colorScheme) var colorScheme
    
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
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Welcome to HearCare")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                            
                            Text("Your personal hearing health companion")
                                .font(.headline)
                                .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        // Quick Actions Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Quick Actions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                // Hearing Test
                                NavigationLink(destination: HearingTestView()) {
                                    ActionCard(
                                        title: "Hearing Test",
                                        subtitle: "Start a quick test",
                                        icon: "ear",
                                        backgroundColor: pastelBlue
                                    )
                                }
                                
                                // Sound Environment
                                NavigationLink(destination: PersonalInformationView()) {
                                    ActionCard(
                                        title: "Sound Environment",
                                        subtitle: "Monitor noise levels",
                                        icon: "waveform",
                                        backgroundColor: pastelGreen
                                    )
                                }
                                
                                // Activities
                                NavigationLink(destination: HistoryView()) {
                                    ActionCard(
                                        title: "Activities",
                                        subtitle: "Hearing exercises",
                                        icon: "figure.walk",
                                        backgroundColor: pastelYellow
                                    )
                                }
                                
                                // Settings
                                NavigationLink(destination: Text("Settings View")) {
                                    ActionCard(
                                        title: "Settings",
                                        subtitle: "Customize app",
                                        icon: "gearshape.fill",
                                        backgroundColor: Color(red: 233/255, green: 196/255, blue: 235/255)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Health Insights
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Health Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                            
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(pastelBlue)
                                
                                VStack(alignment: .leading) {
                                    Text("Weekly Summary")
                                        .font(.headline)
                                    Text("View your hearing patterns")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(pastelBlue, lineWidth: 2)
                                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.8)))
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        // Tips and Education
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tips & Education")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(1...3, id: \.self) { index in
                                        TipCard(
                                            title: "Hearing Tip \(index)",
                                            description: "Learn about protecting your hearing health in everyday situations.",
                                            backgroundColor: [pastelBlue, pastelGreen, pastelYellow][index - 1]
                                        )
                                        .frame(width: 250)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                leading: Image(systemName: "ear")
                    .font(.system(size: 22))
                    .foregroundColor(pastelBlue),
                trailing: NavigationLink(destination: PersonalInformationView()) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22))
                        .foregroundColor(pastelBlue)
                }
            )
        }
        .onAppear {
            // Check for authenticated user
            self.user = Auth.auth().currentUser
        }
    }
}

// MARK: - Supporting Views
struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(Color.black)
                Spacer()
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(Color.black.opacity(0.8))
        }
        .padding()
        .frame(height: 150)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .shadow(color: backgroundColor.opacity(0.5), radius: 5, x: 0, y: 3)
        )
    }
}

struct TipCard: View {
    let title: String
    let description: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.9))
                .lineLimit(3)
            
            Spacer()
            
            HStack {
                Spacer()
                Text("Learn More")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(backgroundColor)
                .shadow(color: backgroundColor.opacity(0.6), radius: 5, x: 2, y: 3)
        )
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
