//
//  CountryMapPreviewBubble.swift
//  WorldTrackerIOS
//
//  Created by seren on 26.03.2026.
//

import SwiftUI
import MapKit

// MARK: - Map Annotation Bubble (Always Visible)

/// Compact bubble that appears as an annotation on the map for visited countries
struct CountryMapAnnotationBubble: View {
    let country: Country
    let visit: Visit
    
    var body: some View {
        VStack(spacing: 4) {
            // Main bubble content
            HStack(spacing: 8) {
                // Preview indicator
                if let firstPhoto = visit.photos.first,
                   let uiImage = UIImage(data: firstPhoto.imageData) {
                    // Photo thumbnail
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                } else if !visit.notes.isEmpty {
                    // Note indicator
                    ZStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "note.text")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                } else {
                    // Just visited indicator
                    ZStack {
                        Circle()
                            .fill(Color.green.gradient)
                            .frame(width: 40, height: 40)
                        
                        Text(country.flagEmoji)
                            .font(.system(size: 20))
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                
                // Country name label (optional - can be hidden at far zoom)
                Text(country.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
            
            // Pointer/tail
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 6)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

/// Triangle shape for bubble pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Full Preview Bubble (Modal/Sheet)

struct CountryMapPreviewBubble: View {
    let country: Country
    let visit: Visit
    let onDismiss: () -> Void
    let onViewDetails: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with country info
            HStack(spacing: 12) {
                Text(country.flagEmoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let visitDate = visit.visitedDate {
                        Text(visitDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            
            // Content preview
            if hasContent {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Photo preview (if available)
                    if let firstPhoto = visit.photos.first,
                       let uiImage = UIImage(data: firstPhoto.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(6)
                        
                        if visit.photos.count > 1 {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.stack")
                                    .font(.caption2)
                                Text("\(visit.photos.count) photos")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Notes preview (if available)
                    if !visit.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            Text(visit.notes)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            
            // View Details button
            Divider()
            
            Button {
                onViewDetails()
            } label: {
                HStack {
                    Text("View Details")
                        .font(.subheadline.weight(.medium))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 340)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
    
    private var hasContent: Bool {
        !visit.photos.isEmpty || !visit.notes.isEmpty
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            appeared = false
        }
        
        // Delay actual dismissal to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Preview Container

/// Wrapper to hold country and visit data for preview
struct CountryPreviewData: Identifiable {
    let id: String
    let country: Country
    let visit: Visit
    
    init(country: Country, visit: Visit) {
        self.id = country.id
        self.country = country
        self.visit = visit
    }
}
