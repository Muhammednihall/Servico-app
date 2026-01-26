import 'package:flutter/material.dart';

class AbstractMapWidget extends StatelessWidget {
  final double height;
  final bool showWorker;
  final bool showLiveTag;

  const AbstractMapWidget({
    super.key,
    this.height = 200,
    this.showWorker = true,
    this.showLiveTag = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFf1f5f9),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [const Color(0xFFf8fafc), const Color(0xFFe2e8f0)],
          ),
        ),
        child: Stack(
          children: [
            // Abstract Grid Pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(painter: GridPainter()),
              ),
            ),

            // Abstract Street Lines
            Positioned.fill(child: CustomPaint(painter: MapPathPainter())),

            // Route Line (Dotted/Glow)
            Positioned.fill(child: CustomPaint(painter: RoutePainter())),

            // Destination (User Location)
            Positioned(
              top: height * 0.2,
              right: 60,
              child: _buildMapPin(
                color: const Color(0xFF10b981),
                icon: Icons.person_pin_circle_rounded,
                isUser: true,
              ),
            ),

            // Worker (Moving/Pulsing)
            if (showWorker) const Center(child: WorkerMapMarker()),

            // Map Controls (Floating Glassmorphism)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                children: [
                  _buildMapControl(Icons.add),
                  const SizedBox(height: 8),
                  _buildMapControl(Icons.remove),
                ],
              ),
            ),

            // LIVE tag
            if (showLiveTag)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF1e293b)),
    );
  }

  Widget _buildMapPin({
    required Color color,
    required IconData icon,
    required bool isUser,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (isUser)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 2),
              ],
            ),
            child: const Text(
              'You',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

class WorkerMapMarker extends StatefulWidget {
  const WorkerMapMarker({super.key});

  @override
  State<WorkerMapMarker> createState() => _WorkerMapMarkerState();
}

class _WorkerMapMarkerState extends State<WorkerMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60 * _controller.value,
              height: 60 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF2463eb,
                ).withOpacity(1 - _controller.value),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2463eb),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2463eb).withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MapPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width * 0.4, size.height * 0.2)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7);

    canvas.drawPath(path, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width * 0.7, size.height);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2463eb).withOpacity(0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.3,
        size.width * 0.8,
        size.height * 0.3,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
