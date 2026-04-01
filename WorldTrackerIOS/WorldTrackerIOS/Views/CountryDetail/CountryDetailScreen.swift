//
//  CountryDetailScreen.swift
//  WorldTrackerIOS
//
//  Created by seren on 26.02.2026.
//

import SwiftUI
import PhotosUI

struct CountryDetailScreen: View {
    @EnvironmentObject private var appState: AppState
    let country: Country
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editingCaptionPhotoId: UUID?
    @State private var editingCaption: String = ""
    
    // Force view to update when visits change by observing appState directly
    @State private var refreshID = UUID()

    // MARK: - Clean bindings

    private var isVisited: Binding<Bool> {
        Binding(
            get: { appState.visit(for: country.id).isVisited },
            set: { newValue in
                if newValue {
                    // turning ON: keep existing date if present, otherwise default to today
                    let existing = appState.visit(for: country.id).visitedDate
                    appState.setVisited(country.id, isVisited: true, visitedDate: existing ?? Date())
                } else {
                    appState.setVisited(country.id, isVisited: false)
                }
            }
        )
    }

    private var visitDate: Binding<Date> {
        Binding(
            get: { appState.visit(for: country.id).visitedDate ?? Date() },
            set: { newDate in
                appState.setVisited(country.id, isVisited: true, visitedDate: newDate)
            }
        )
    }

    private var notes: Binding<String> {
        Binding(
            get: { appState.visit(for: country.id).notes },
            set: { appState.updateNotes(country.id, notes: $0) }
        )
    }
    
    private var wantToVisitBinding: Binding<Bool> {
        Binding(
            get: { appState.wantToVisit(country.id) },
            set: { appState.setWantToVisit(country.id, wantToVisit: $0) }
        )
    }
    
    private var photos: [VisitPhoto] {
        appState.visits[country.id]?.photos ?? []
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Text(country.flagEmoji)
                        .font(.system(size: 44))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(country.name)
                            .font(.title2).bold()
                        Text(country.continent.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Travel Status") {
                Toggle("Visited", isOn: isVisited)

                if isVisited.wrappedValue {
                    DatePicker(
                        "Visit date",
                        selection: visitDate,
                        displayedComponents: [.date]
                    )
                }
                
                Toggle("Want to Visit", isOn: wantToVisitBinding)
            }

            Section("Notes") {
                TextEditor(text: notes)
                    .frame(minHeight: 120)
            }

            Section {
                if photos.isEmpty {
                    Text("No photos yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(photos) { photo in
                        photoRow(for: photo)
                    }
                }
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Add Photo", systemImage: "photo.badge.plus")
                }
            } header: {
                Text("Photos")
            }
        }
        .id(appState.visits[country.id]?.updatedAt ?? Date()) // Force refresh when visit updates
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                await loadPhoto(from: newValue)
            }
        }
    }
    
    @ViewBuilder
    private func photoRow(for photo: VisitPhoto) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
            }
            
            if editingCaptionPhotoId == photo.id {
                HStack {
                    TextField("Caption", text: $editingCaption)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Save") {
                        appState.updatePhotoCaption(country.id, photoId: photo.id, caption: editingCaption)
                        editingCaptionPhotoId = nil
                        editingCaption = ""
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Cancel") {
                        editingCaptionPhotoId = nil
                        editingCaption = ""
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                HStack {
                    if photo.caption.isEmpty {
                        Text("Add caption...")
                            .foregroundStyle(.secondary)
                            .onTapGesture {
                                editingCaptionPhotoId = photo.id
                                editingCaption = photo.caption
                            }
                    } else {
                        Text(photo.caption)
                            .onTapGesture {
                                editingCaptionPhotoId = photo.id
                                editingCaption = photo.caption
                            }
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        appState.removePhoto(country.id, photoId: photo.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return
            }
            
            let compressedData = compressImage(data)
            let photo = VisitPhoto(imageData: compressedData)
            appState.addPhoto(country.id, photo: photo)
            
            selectedPhotoItem = nil
        } catch {
            print("⚠️ Error loading photo: \(error)")
        }
    }
    
    private func compressImage(_ data: Data) -> Data {
        guard var image = UIImage(data: data) else { return data }
        
        let maxSize: Int = 300_000 // ~400KB after Base64 encoding
        let maxDimension: CGFloat = 1200
        
        // Resize if too large
        let size = image.size
        if size.width > maxDimension || size.height > maxDimension {
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = resizedImage
            }
            UIGraphicsEndImageContext()
        }
        
        // Compress with JPEG quality
        var compression: CGFloat = 0.8
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return data
        }
        
        // Reduce quality if still too large
        var attempts = 0
        while imageData.count > maxSize && compression > 0.1 && attempts < 10 {
            compression -= 0.1
            if let compressedData = image.jpegData(compressionQuality: compression) {
                imageData = compressedData
            }
            attempts += 1
        }
        
        return imageData
    }
}
