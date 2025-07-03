import SwiftUI

/// A custom SwiftUI `GeometryEffect` that animates a view along a specified path of board positions.
///
/// This effect translates a linear animation `progress` (from 0.0 to 1.0) into a transform
/// that moves a view along a series of connected line segments defined by the `path`.
/// It is designed to be used with the `.modifier()` view modifier. The view it modifies
/// should be initially positioned at the starting point of the path.
struct FollowPathEffect: GeometryEffect {
    var path: [Position]
    var progress: CGFloat
    let cellSize: CGFloat

    /// The animatable data for the effect. SwiftUI interpolates this value from its
    /// starting to its ending value during the animation, calling `effectValue` for each frame.
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    /// Calculates the new position for the view based on the current animation progress.
    /// - Parameter size: The size of the view being animated (unused in this effect).
    /// - Returns: A `ProjectionTransform` that translates the view to its new position on the path.
    func effectValue(size: CGSize) -> ProjectionTransform {
        // Ensure there is a path to follow, otherwise do not move the view.
        guard !path.isEmpty, path.count > 1, let startPoint = path.first else {
            return ProjectionTransform(.identity)
        }

        // 1. Map the linear animation 'progress' (0-1) to the segmented path.
        let totalSegments = CGFloat(path.count - 1)
        let currentTotalProgress = totalSegments * progress
        
        // 2. Determine which segment of the path the pawn is currently on.
        // We cap the index at count - 2 to ensure we can always get a `segmentEnd`.
        let currentSegmentIndex = min(Int(floor(currentTotalProgress)), path.count - 2)
        
        // 3. Calculate how far along the pawn is within that specific segment.
        let progressInCurrentSegment = currentTotalProgress - CGFloat(currentSegmentIndex)

        let segmentStart = path[currentSegmentIndex]
        let segmentEnd = path[currentSegmentIndex + 1]

        // 4. Interpolate the (x, y) grid coordinates for the current position on the path.
        let interpolatedX = CGFloat(segmentStart.col) + (CGFloat(segmentEnd.col - segmentStart.col) * progressInCurrentSegment)
        let interpolatedY = CGFloat(segmentStart.row) + (CGFloat(segmentEnd.row - segmentStart.row) * progressInCurrentSegment)
        
        // 5. The effect calculates a translation *relative* to the view's initial position.
        // Since the view will be placed at the path's start point, we calculate the offset from there.
        let offsetX = (interpolatedX - CGFloat(startPoint.col)) * cellSize
        let offsetY = (interpolatedY - CGFloat(startPoint.row)) * cellSize
        
        // 6. Create the final transform and return it.
        let translation = CGAffineTransform(translationX: offsetX, y: offsetY)
        return ProjectionTransform(translation)
    }
} 
