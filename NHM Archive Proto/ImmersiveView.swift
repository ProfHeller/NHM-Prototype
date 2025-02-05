import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @State private var originalPositions: [Entity: SIMD3<Float>] = [:]
    @State private var angle = Angle(degrees: 0.0)

    var body: some View {
        RealityView { content in
            // Create occlusion floor
            let floor = ModelEntity(
                mesh: .generatePlane(width: 50, depth: 50),
                materials: [OcclusionMaterial()]
            )
            floor.generateCollisionShapes(recursive: false)
            floor.components[PhysicsBodyComponent.self] = .init(massProperties: .default, mode: .static)
            content.add(floor)
            
            // Create the table
            let table = ModelEntity(
                mesh: .generateBox(width: 0.5, height: 1, depth: 0.5), // Adjust dimensions as needed
                materials: [SimpleMaterial(color: .brown, isMetallic: false)] // Wooden material
            )
            table.position = SIMD3(0, 0, -1) // Position the table
            table.generateCollisionShapes(recursive: false)
            table.components[PhysicsBodyComponent.self] = .init(massProperties: .default, mode: .static)
            content.add(table)
            
            // Load the mask model
            if let potModel = try? await Entity(named: "pot"),
               let pot = potModel.children.first?.children.first {
                
                pot.scale = [1, 1, 1] // Lock scale to 10
                pot.position = SIMD3(-0.1, 0.5, -1) // Position on top of the table
                pot.generateCollisionShapes(recursive: false)

                // Enable interaction
                pot.components.set(InputTargetComponent())
                pot.components[PhysicsBodyComponent.self] = .init(
                    massProperties: .default,
                    material: .generate(staticFriction: 0.8, dynamicFriction: 0.5, restitution: 0), // No bouncing
                    mode: .kinematic // Start in kinematic mode to prevent physics interactions
                )

                originalPositions[pot] = pot.position
                content.add(pot)
            }
            
            // Load the bird model
            if let birdModel = try? await Entity(named: "bird"),
               let bird = birdModel.children.first?.children.first {
                
                bird.scale = [1, 1, 1] // Lock scale to 5
                bird.position = SIMD3(0.1, 0.5, -1) // Position on top of the table
                bird.generateCollisionShapes(recursive: false)

                // Enable interaction
                bird.components.set(InputTargetComponent())
                bird.components[PhysicsBodyComponent.self] = .init(
                    massProperties: .default,
                    material: .generate(staticFriction: 0.8, dynamicFriction: 0.5, restitution: 0), // No bouncing
                    mode: .kinematic // Start in kinematic mode to prevent physics interactions
                )

                originalPositions[bird] = bird.position
                content.add(bird)
            }
        }
        .gesture(dragGesture)
        .rotationEffect(angle)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                // Update position based on drag
                value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
                value.entity.components[PhysicsBodyComponent.self]?.mode = .kinematic // Ensure kinematic mode during drag
            }
            .onEnded { value in
                // Restore original position
                if let originalPosition = originalPositions[value.entity] {
                    value.entity.position = originalPosition
                }

                // Ensure the entity remains in kinematic mode to prevent any physics interactions
                value.entity.components[PhysicsBodyComponent.self]?.mode = .kinematic
            }
    }
}
