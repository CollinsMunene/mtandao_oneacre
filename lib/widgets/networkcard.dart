import 'dart:math';
import 'package:flutter/material.dart';

class NetworkCard extends StatelessWidget {
  final String? carrierName;
  final String? displayName;
  final int? mobileSignal;
  final String? signalStrength;

  const NetworkCard(
    this.carrierName,
    this.displayName,
    this.mobileSignal,
    this.signalStrength, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Define the shape of the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      // Define how the card's content should be clipped
      clipBehavior: Clip.antiAliasWithSaveLayer,
      // Define the child widget of the card
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Add padding around the row widget

          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              displayName ?? '',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Add an image widget to display an image
                // Image.asset(
                //   'assets/small-logo.png',
                //   height: 100,
                //   width: 100,
                //   fit: BoxFit.cover,
                // ),

                StrengthCurveCircle(
                    strengthInDBM: mobileSignal,
                    strengthInType: signalStrength),
                // Add some spacing between the image and the text
                Container(width: 20),
                // Add an expanded widget to take up the remaining horizontal space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Add some spacing between the top of the card and the title
                      Container(height: 5),
                      const Text(
                        "Network Type",
                        style: TextStyle(color: Colors.white),
                      ),
                      // Add a title widget

                      // Add a subtitle widget

                      // Add some spacing between the subtitle and the text
                      Container(height: 10),
                      Text(
                        "Voice: $carrierName",
                      ),

                      Text(
                        "Data: $carrierName",
                      ),

                      // Add some spacing between the subtitle and the text
                      Container(height: 10),
                      // Add a text widget to display some text
                      const Text(
                        'Signal Strength',
                        maxLines: 2,
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        signalStrength ?? '',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StrengthCurveCircle extends StatelessWidget {
  final int? strengthInDBM; // Strength value in dBm
  final String? strengthInType;

  StrengthCurveCircle(
      {required this.strengthInDBM, required this.strengthInType});

  @override
  Widget build(BuildContext context) {
    // Normalize the strength value to a range between 0 and 1
    final double normalizedStrength =
        (strengthInDBM! + 200) / 200; // Range is -102 dBm to -41 dBm
    return CustomPaint(
        size: const Size(150, 150), // Adjust size according to your preference
        painter: CurveCirclePainter(
            normalizedStrength: normalizedStrength,
            strengthInType: strengthInType));
  }
}

class CurveCirclePainter extends CustomPainter {
  final double normalizedStrength;
  final String? strengthInType;

  CurveCirclePainter(
      {required this.normalizedStrength, required this.strengthInType});

  @override
  void paint(Canvas canvas, Size size) {
    final double circleRadius = min(size.width, size.height) / 2;
    final double strokeWidth = 10;

    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Paint curvePaint = Paint()
      ..color = _getColorForStrength(normalizedStrength)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double angle =
        pi * normalizedStrength; // Normalize angle between 0 and pi

    final Rect rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2), radius: circleRadius);

    canvas.drawArc(rect, pi, pi, false, backgroundPaint);
    canvas.drawArc(rect, pi, angle, false, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Color _getColorForStrength(double normalizedStrength) {
    if (strengthInType == 'Low') {
      return Colors.yellow; // Low to moderate signal strength
    } else if (strengthInType == 'Moderate') {
      return Colors.blue; // Moderate to good signal strength
    } else {
      return Colors.green; // Good to excellent signal strength
    }
  }
}
