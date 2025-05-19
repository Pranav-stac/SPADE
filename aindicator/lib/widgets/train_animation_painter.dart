import 'package:flutter/material.dart';
import 'dart:math' as math;

// TrainPathPainter is a custom painter that renders a train path with animated markers
class TrainPathPainter extends CustomPainter {
  final List<Offset> pathPoints;
  final Color pathColor;
  final Color trainColor;
  final double trainPosition; // 0.0 to 1.0
  final double pathThickness;
  final double trainSize;
  final Animation<double> pulseAnimation;

  TrainPathPainter({
    required this.pathPoints,
    required this.pathColor,
    required this.trainColor,
    required this.trainPosition,
    required this.pulseAnimation,
    this.pathThickness = 5.0,
    this.trainSize = 12.0,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.length < 2) return;

    // Scale the path to the canvas size
    List<Offset> scaledPoints = pathPoints.map((point) {
      return Offset(
        point.dx * size.width,
        point.dy * size.height,
      );
    }).toList();

    // Paint for the path
    final pathPaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathThickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the path
    final path = Path();
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    
    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }
    
    canvas.drawPath(path, pathPaint);

    // Calculate the position of the train along the path
    Offset trainPos = _getPositionAlongPath(scaledPoints, trainPosition);
    Offset direction = _getDirectionAlongPath(scaledPoints, trainPosition);
    
    // Calculate angle for rotation
    double angle = math.atan2(direction.dy, direction.dx);

    // Add a subtle glow effect using the pulse animation
    final glowSize = trainSize * (1.0 + 0.3 * pulseAnimation.value);
    
    // Draw the train glow
    final glowPaint = Paint()
      ..color = trainColor.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    
    canvas.drawCircle(trainPos, glowSize, glowPaint);

    // Save the canvas state before rotation
    canvas.save();
    
    // Translate to the train position
    canvas.translate(trainPos.dx, trainPos.dy);
    
    // Rotate the canvas according to the angle
    canvas.rotate(angle);
    
    // Draw the train
    final trainPaint = Paint()
      ..color = trainColor
      ..style = PaintingStyle.fill;
    
    // Draw a train shape as a rounded rectangle
    final trainRect = RRect.fromLTRBR(
      -trainSize * 1.5, -trainSize * 0.6,
      trainSize * 1.5, trainSize * 0.6,
      Radius.circular(trainSize * 0.6),
    );
    canvas.drawRRect(trainRect, trainPaint);
    
    // Add windows to the train
    final windowPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final window1 = RRect.fromLTRBR(
      -trainSize * 1.0, -trainSize * 0.3,
      -trainSize * 0.4, trainSize * 0.3,
      Radius.circular(trainSize * 0.2),
    );
    
    final window2 = RRect.fromLTRBR(
      trainSize * 0.4, -trainSize * 0.3,
      trainSize * 1.0, trainSize * 0.3,
      Radius.circular(trainSize * 0.2),
    );
    
    canvas.drawRRect(window1, windowPaint);
    canvas.drawRRect(window2, windowPaint);
    
    // Restore the canvas to its original state
    canvas.restore();
  }

  // Calculate the position along the path based on trainPosition (0.0 to 1.0)
  Offset _getPositionAlongPath(List<Offset> points, double position) {
    if (position <= 0) return points.first;
    if (position >= 1) return points.last;
    
    // Calculate the total path length
    double totalLength = 0;
    List<double> segmentLengths = [];
    
    for (int i = 0; i < points.length - 1; i++) {
      double length = (points[i + 1] - points[i]).distance;
      segmentLengths.add(length);
      totalLength += length;
    }
    
    // Find the position along the path
    double targetDistance = position * totalLength;
    double currentDistance = 0;
    
    for (int i = 0; i < segmentLengths.length; i++) {
      double segmentLength = segmentLengths[i];
      
      if (currentDistance + segmentLength >= targetDistance) {
        // This is the segment containing our position
        double segmentPosition = (targetDistance - currentDistance) / segmentLength;
        return Offset(
          points[i].dx + segmentPosition * (points[i + 1].dx - points[i].dx),
          points[i].dy + segmentPosition * (points[i + 1].dy - points[i].dy),
        );
      }
      
      currentDistance += segmentLength;
    }
    
    return points.last;
  }
  
  // Calculate the direction along the path at the given position
  Offset _getDirectionAlongPath(List<Offset> points, double position) {
    if (position <= 0) {
      return points.length > 1 ? (points[1] - points[0]) : const Offset(1, 0);
    }
    if (position >= 1) {
      return points.length > 1 ? (points.last - points[points.length - 2]) : const Offset(1, 0);
    }
    
    // Calculate the total path length and find the segment containing our position
    double totalLength = 0;
    List<double> segmentLengths = [];
    
    for (int i = 0; i < points.length - 1; i++) {
      double length = (points[i + 1] - points[i]).distance;
      segmentLengths.add(length);
      totalLength += length;
    }
    
    double targetDistance = position * totalLength;
    double currentDistance = 0;
    
    for (int i = 0; i < segmentLengths.length; i++) {
      double segmentLength = segmentLengths[i];
      
      if (currentDistance + segmentLength >= targetDistance) {
        // Return the direction of this segment
        Offset direction = points[i + 1] - points[i];
        return direction.distance > 0 ? direction / direction.distance : const Offset(1, 0);
      }
      
      currentDistance += segmentLength;
    }
    
    // Default to rightward direction if we couldn't find a segment
    return const Offset(1, 0);
  }

  @override
  bool shouldRepaint(covariant TrainPathPainter oldDelegate) {
    return pathPoints != oldDelegate.pathPoints ||
           pathColor != oldDelegate.pathColor ||
           trainColor != oldDelegate.trainColor ||
           trainPosition != oldDelegate.trainPosition ||
           pathThickness != oldDelegate.pathThickness ||
           trainSize != oldDelegate.trainSize;
  }
}

// StationMarker widget for showing stations on the metro map
class StationMarker extends StatelessWidget {
  final String stationName;
  final Color lineColor;
  final bool isSelected;
  final bool isTransfer;
  final VoidCallback onTap;
  final double zoomLevel;

  const StationMarker({
    super.key,
    required this.stationName,
    required this.lineColor,
    required this.onTap,
    this.isSelected = false,
    this.isTransfer = false,
    this.zoomLevel = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Station dot
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSelected ? 24 : (isTransfer ? 16 : 12),
            height: isSelected ? 24 : (isTransfer ? 16 : 12),
            decoration: BoxDecoration(
              color: isTransfer ? Colors.white : lineColor,
              shape: isTransfer ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isTransfer ? BorderRadius.circular(4) : null,
              border: Border.all(
                color: isTransfer ? lineColor : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: lineColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        
        // Station name (show if selected or zoomed in)
        if (isSelected || zoomLevel > 1.5)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? lineColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stationName,
              style: TextStyle(
                fontSize: isSelected ? 10 : 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? lineColor : Colors.black54,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// Animation widgets for the metro map
class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;
  final Animation<double> animation;

  const PulsingDot({
    super.key,
    required this.color,
    required this.size,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: size + (size * 0.5 * animation.value),
          height: size + (size * 0.5 * animation.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(1 - animation.value),
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
} 