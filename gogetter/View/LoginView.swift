import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingXL) {
                    // Logo/Header
                    VStack(spacing: AppTheme.spacingM) {
                        Image(systemName: "bag.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("Sniffle Admin")
                            .font(.largeTitle.bold())
                        
                        Text("Manage your store")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    // Login Form
                    VStack(spacing: AppTheme.spacingM) {
                        // Email Field
                        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                            Text("Email")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            
                            TextField("admin@sniffle.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(AppTheme.cornerRadiusM)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                            Text("Password")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("••••••••", text: $password)
                                    } else {
                                        SecureField("••••••••", text: $password)
                                    }
                                }
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit {
                                    login()
                                }
                                
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(AppTheme.cornerRadiusM)
                        }
                        
                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMessage)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadiusS)
                        }
                        
                        // Login Button
                        Button {
                            login()
                        } label: {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadiusM)
                        }
                        .disabled(!isFormValid || authViewModel.isLoading)
                        .padding(.top, AppTheme.spacingM)
                    }
                    .padding(.horizontal, AppTheme.spacingL)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func login() {
        focusedField = nil
        Task {
            await authViewModel.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
