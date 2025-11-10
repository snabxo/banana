import SwiftUI

struct ReviewModerationView: View {
    @StateObject private var viewModel = ReviewViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingS) {
                        ForEach(ReviewViewModel.ReviewFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Reviews List
                if viewModel.isLoading && viewModel.pendingReviews.isEmpty {
                    VStack(spacing: AppTheme.spacingM) {
                        ProgressView()
                        Text("Loading reviews...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.filteredReviews.isEmpty {
                    ContentUnavailableView {
                        Label("No Reviews", systemImage: "star")
                    } description: {
                        Text(viewModel.selectedFilter == .pending ? "No pending reviews to moderate" : "No reviews found")
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredReviews) { review in
                            NavigationLink(destination: ReviewDetailView(review: review)) {
                                ReviewRow(review: review)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Review Moderation")
            .refreshable {
                await viewModel.loadPendingReviews(refresh: true)
            }
            .task {
                if viewModel.pendingReviews.isEmpty {
                    await viewModel.loadPendingReviews()
                }
            }
        }
    }
}

struct ReviewRow: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                // Star Rating
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(index < review.rating ? .yellow : .gray)
                    }
                }
                
                Spacer()
                
                if review.verifiedPurchase {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                        Text("Verified")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
                
                if !review.isApproved {
                    StatusBadge(status: "Pending", color: "orange")
                }
            }
            
            Text(review.title)
                .font(.subheadline.bold())
            
            Text(review.comment)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let response = review.adminResponse {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .font(.caption)
                        Text("Response")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, AppTheme.spacingS)
    }
}

struct ReviewDetailView: View {
    let review: Review
    
    @EnvironmentObject var viewModel: ReviewViewModel
    
    @State private var showingApprovalSheet = false
    @State private var showingRejectAlert = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                // Header
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < review.rating ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(index < review.rating ? .yellow : .gray)
                            }
                        }
                        
                        Spacer()
                        
                        if !review.isApproved {
                            StatusBadge(status: "Pending Review", color: "orange")
                        } else {
                            StatusBadge(status: "Approved", color: "green")
                        }
                    }
                    
                    if review.verifiedPurchase {
                        HStack(spacing: AppTheme.spacingS) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Verified Purchase")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                // Action Buttons (only for pending reviews)
                if !review.isApproved {
                    HStack(spacing: AppTheme.spacingM) {
                        Button {
                            showingApprovalSheet = true
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadiusM)
                        }
                        
                        Button {
                            showingRejectAlert = true
                        } label: {
                            Label("Reject", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadiusM)
                        }
                    }
                }
                
                // Review Content
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.blue)
                        Text("Review Title")
                            .font(.headline)
                    }
                    
                    Text(review.title)
                        .font(.title3.bold())
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.blue)
                        Text("Review Comment")
                            .font(.headline)
                    }
                    
                    Text(review.comment)
                        .font(.body)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
                
                // Admin Response
                if let response = review.adminResponse {
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        HStack {
                            Image(systemName: "bubble.left.fill")
                                .foregroundColor(.purple)
                            Text("Your Response")
                                .font(.headline)
                        }
                        
                        Text(response)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(AppTheme.cornerRadiusM)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        Text("Details")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Submitted:")
                        Spacer()
                        Text(review.createdAt.formatted(date: .long, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Text("Product ID:")
                        Spacer()
                        Text(review.productId)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(AppTheme.cornerRadiusM)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingApprovalSheet) {
            ApproveReviewSheet(review: review, onApprove: { response in
                Task {
                    let success = await viewModel.approveReview(
                        id: review.id,
                        adminResponse: response
                    )
                    if success {
                        successMessage = "Review approved successfully"
                        showingSuccessAlert = true
                    }
                }
            })
        }
        .alert("Reject Review", isPresented: $showingRejectAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reject", role: .destructive) {
                Task {
                    let success = await viewModel.rejectReview(id: review.id)
                    if success {
                        successMessage = "Review rejected and deleted"
                        showingSuccessAlert = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to reject and delete this review? This action cannot be undone.")
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
    }
}

struct ApproveReviewSheet: View {
    let review: Review
    let onApprove: (String?) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var adminResponse = ""
    @State private var includeResponse = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Preview of review
                    VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < review.rating ? "star.fill" : "star")
                                    .foregroundColor(index < review.rating ? .yellow : .gray)
                            }
                        }
                        
                        Text(review.title)
                            .font(.headline)
                        
                        Text(review.comment)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Review Preview")
                }
                
                Section {
                    Toggle("Add Response", isOn: $includeResponse)
                    
                    if includeResponse {
                        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                            Text("Your Response (Optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $adminResponse)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                        }
                    }
                } header: {
                    Text("Admin Response")
                } footer: {
                    Text("Add a public response that will be visible to customers.")
                }
            }
            .navigationTitle("Approve Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Approve") {
                        let response = includeResponse && !adminResponse.isEmpty ? adminResponse : nil
                        onApprove(response)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReviewModerationView()
    }
}
