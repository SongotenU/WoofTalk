import SwiftUI
import RevenueCat

struct CancellationSurveyView: View {
    let onComplete: () -> Void

    @State private var selectedReason = ""
    @State private var feedback = ""
    @State private var isSubmitting = false
    @State private var showError = false

    private let reasons = [
        "Too expensive",
        "Missing features I need",
        "Not using it enough",
        "Technical issues",
        "Switching to another app",
        "Temporary break",
        "Other"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Why are you cancelling?")) {
                    ForEach(reasons, id: \.self) { reason in
                        Button(action: { selectedReason = reason }) {
                            HStack {
                                Text(reason)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Additional feedback (optional)")) {
                    TextEditor(text: $feedback)
                        .frame(height: 100)
                }

                Section {
                    Button(action: submitSurvey) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Submit & Cancel Subscription")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
                    .disabled(selectedReason.isEmpty || isSubmitting)
                }

                Section {
                    Button("Manage Subscription in Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Cancellation Survey")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to submit survey. Please try again.")
            }
        }
    }

    private func submitSurvey() {
        guard !selectedReason.isEmpty else { return }
        isSubmitting = true

        Task {
            do {
                try await submitToSupabase()
                // Note: RevenueCat doesn't provide a cancel() method
                // Subscriptions are managed through iOS Settings or App Store
                // The survey is recorded and user can manage subscription via Settings
                onComplete()
            } catch {
                showError = true
            }
            isSubmitting = false
        }
    }

    private func submitToSupabase() async throws {
        guard let userId = AuthManager.shared.currentUser?.id,
              let client = SupabaseManager.shared.client else { return }

        let surveyData: [String: Any] = [
            "user_id": userId,
            "reason": selectedReason,
            "feedback": feedback,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]

        // Insert into cancellation_surveys table
        try await client
            .from("cancellation_surveys")
            .insert(surveyData)
            .execute()

        // Update subscription_status with cancellation info
        let updateData: [String: Any] = [
            "cancellation_reason": selectedReason,
            "cancellation_feedback": feedback,
            "cancelled_at": ISO8601DateFormatter().string(from: Date())
        ]

        try await client
            .from("subscription_status")
            .update(updateData)
            .eq("user_id", value: userId)
            .execute()
    }
}

#if DEBUG
struct CancellationSurveyView_Previews: PreviewProvider {
    static var previews: some View {
        CancellationSurveyView(onComplete: {})
    }
}
#endif
