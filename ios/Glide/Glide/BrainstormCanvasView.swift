import SwiftUI

struct BrainstormCanvasView: View {
    var tripId: UUID
    @State private var vm: BrainstormViewModel
    @State private var showAddIdea = false
    @State private var newIdeaText = ""
    @State private var dragOffsets: [UUID: CGSize] = [:]
    @State private var overDeleteZone: Set<UUID> = []
    @State private var canvasSize: CGSize = .zero
    @State private var ideaToDelete: BrainstormIdea?
    @State private var showIdeaError = false
    @State private var ideaErrorMessage = ""

    private let deleteZoneHeight: CGFloat = 80
    private let maxIdeaLength = 120

    init(tripId: UUID) {
        self.tripId = tripId
        _vm = State(initialValue: BrainstormViewModel(tripId: tripId))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    deleteZone
                }
                .zIndex(0)

                ForEach(vm.ideas) { idea in
                    ideaCard(idea, canvasHeight: geo.size.height)
                        .zIndex(dragOffsets[idea.id] != nil ? 2 : 1)
                }

                if !vm.isLoading && vm.ideas.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "lightbulb")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No ideas yet")
                            .foregroundStyle(.secondary)
                        Text("Tap + to add one")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
        }
        .navigationTitle("Brainstorm")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newIdeaText = ""
                    showAddIdea = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Idea", isPresented: $showAddIdea) {
            TextField("What's on your mind?", text: $newIdeaText)
            Button("Add") {
                validateAndAddIdea()
            }
            Button("Cancel", role: .cancel) {
                newIdeaText = ""
            }
        }
        .alert(ideaErrorMessage, isPresented: $showIdeaError) {
            Button("Try Again") {
                showAddIdea = true
            }
            Button("Cancel", role: .cancel) {
                newIdeaText = ""
            }
        }
        .alert("Delete idea?", isPresented: Binding(
            get: { ideaToDelete != nil },
            set: { if !$0 { ideaToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let idea = ideaToDelete {
                    Task { await vm.deleteIdea(idea) }
                }
                ideaToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                ideaToDelete = nil
            }
        } message: {
            if let idea = ideaToDelete {
                Text("\"\(idea.text)\"")
            }
        }
        .task {
            await vm.fetchIdeas()
        }
    }

    // MARK: - Idea Card

    private func ideaCard(_ idea: BrainstormIdea, canvasHeight: CGFloat) -> some View {
        let offset = dragOffsets[idea.id] ?? .zero
        let isOverDelete = overDeleteZone.contains(idea.id)

        let creatorName = idea.createdBy.flatMap { vm.creatorNames[$0] } ?? "Unknown"

        return VStack(alignment: .leading, spacing: 4) {
            Text(idea.text)
            Text(creatorName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
            .padding(12)
            .frame(minWidth: 80, maxWidth: 160)
            .background(isOverDelete ? Color.red : Color.blue.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.15), radius: isOverDelete ? 6 : 3, y: 2)
            .scaleEffect(isOverDelete ? 0.9 : 1.0)
            .position(
                x: idea.xPos + offset.width,
                y: idea.yPos + offset.height
            )
            .animation(.easeInOut(duration: 0.15), value: isOverDelete)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffsets[idea.id] = value.translation
                        let rawY = idea.yPos + value.translation.height
                        let inZone = rawY > canvasHeight - deleteZoneHeight
                        let wasInZone = overDeleteZone.contains(idea.id)
                        if inZone && !wasInZone {
                            overDeleteZone.insert(idea.id)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        } else if !inZone && wasInZone {
                            overDeleteZone.remove(idea.id)
                        }
                    }
                    .onEnded { value in
                        dragOffsets[idea.id] = nil
                        let inZone = overDeleteZone.contains(idea.id)
                        overDeleteZone.remove(idea.id)
                        if inZone {
                            ideaToDelete = idea
                        } else {
                            let newX = idea.xPos + value.translation.width
                            let newY = idea.yPos + value.translation.height
                            // Prevent saving position inside delete zone
                            let safeY = min(newY, canvasHeight - deleteZoneHeight - 40)
                            Task { await vm.moveIdea(idea, to: newX, y: safeY) }
                        }
                    }
            )
    }

    // MARK: - Delete Zone

    private var deleteZone: some View {
        let active = !overDeleteZone.isEmpty
        return HStack {
            Image(systemName: "trash")
            Text("Drag here to delete")
                .font(.subheadline)
        }
        .foregroundStyle(active ? .white : .red)
        .frame(maxWidth: .infinity)
        .frame(height: deleteZoneHeight)
        .background(active ? Color.red : Color.clear)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.15), value: active)
    }

    // MARK: - Helpers

    private func validateAndAddIdea() {
        let text = newIdeaText.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            ideaErrorMessage = "You can't add an empty idea!"
            showIdeaError = true
            return
        }
        if text.count < 3 {
            ideaErrorMessage = "Come on, keep typing... be creative!"
            showIdeaError = true
            return
        }
        if text.count > maxIdeaLength {
            ideaErrorMessage = "That's a novel, not an idea! Keep it under \(maxIdeaLength) characters."
            showIdeaError = true
            return
        }
        let x = Double.random(in: 60...300)
        let y = Double.random(in: 100...400)
        Task {
            await vm.createIdea(text: text, x: x, y: y, color: "blue")
        }
        newIdeaText = ""
    }
}
