import SwiftUI

struct COPPAAgeVerificationView: View {
    @State private var birthDate = Date()
    @State private var showParentalConsent = false
    @State private var parentEmail = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Age Verification")) {
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                        .accessibilityLabel("Birth date picker")
                        .accessibilityHint("Select your date of birth")
                    Text("You must be 13 or older to create an account. Users under 13 require parental consent.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Age requirement notice")
                }

                if isUnder13 {
                    Section(header: Text("Parental Consent Required")) {
                        TextField("Parent/Guardian Email", text: $parentEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .accessibilityLabel("Parent or guardian email")
                            .accessibilityHint("Enter parent or guardian email for consent")
                        Button("Send Consent Request") {
                            sendConsentRequest()
                        }
                        .accessibilityLabel("Send consent request")
                        .accessibilityHint("Sends consent request to parent email")
                    }
                }

                Section {
                    Button("Continue") {
                        if isUnder13 {
                            showParentalConsent = true
                        } else {
                            proceedWithSignup()
                        }
                    }
                    .accessibilityLabel("Continue with signup")
                    .accessibilityHint(isUnder13 ? "Requires parental consent" : "Proceed with account creation")
                }
            }
            .navigationTitle("Age Verification")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showParentalConsent) {
                ParentalConsentView(parentEmail: parentEmail)
            }
        }
    }

    private var isUnder13: Bool {
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return age < 13
    }

    private func sendConsentRequest() {
        // Send consent request to parent email
        print("COPPA consent request sent to: \(parentEmail)")
    }

    private func proceedWithSignup() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct ParentalConsentView: View {
    let parentEmail: String
    @State private var consentCode = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Parental Consent")) {
                Text("A consent code has been sent to \(parentEmail). Enter it below to proceed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Consent code instructions")
                TextField("Consent Code", text: $consentCode)
                    .keyboardType(.numberPad)
                    .accessibilityLabel("Consent code")
                    .accessibilityHint("Enter the code sent to parent email")
            }

            Section {
                Button("Verify & Continue") {
                    verifyConsent()
                }
                .accessibilityLabel("Verify consent code")
                .accessibilityHint("Verifies parental consent and continues")
            }
        }
        .navigationTitle("Parental Consent")
    }

    private func verifyConsent() {
        print("Verifying COPPA consent code: \(consentCode)")
        presentationMode.wrappedValue.dismiss()
    }
}
