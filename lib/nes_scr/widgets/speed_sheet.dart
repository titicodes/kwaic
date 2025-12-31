import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../model/timeline_item.dart';

class SpeedSheet extends StatefulWidget {
  final TimelineItem clip;
  final Function(double speed) onNormal;
  final Function(List<SpeedPoint> points) onCurve;

  const SpeedSheet({
    super.key,
    required this.clip,
    required this.onNormal,
    required this.onCurve,
  });

  @override
  State<SpeedSheet> createState() => _SpeedSheetState();
}

class _SpeedSheetState extends State<SpeedSheet> {
  int? selectedPointIndex;

  late String tab;
  late double normalSpeed;
  late List<SpeedPoint> curvePoints;

  @override
  void initState() {
    super.initState();
    tab = 'Normal';
    normalSpeed = widget.clip.speed;
    curvePoints = widget.clip.speedPoints.isEmpty
        ? [SpeedPoint(time: 0.0, speed: 1.0), SpeedPoint(time: 1.0, speed: 1.0)]
        : List.from(widget.clip.speedPoints);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            TabBar(
              tabs: const [Tab(text: 'Normal'), Tab(text: 'Curve')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildNormalSpeed(),
                  _buildCurveSpeed(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  final tabIndex = DefaultTabController.of(context).index;

                  if (tabIndex == 0) {
                    widget.clip.speed = normalSpeed;
                    widget.clip.speedPoints = [];
                    widget.onNormal(normalSpeed);
                  } else {
                    widget.clip.speedPoints = curvePoints;
                    widget.onCurve(curvePoints);
                  }

                  Navigator.pop(context);
                },

                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
                child: const Text('Apply', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalSpeed() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${normalSpeed.toStringAsFixed(2)}x', style: const TextStyle(color: Colors.white, fontSize: 48)),
        Slider(
          value: normalSpeed,
          min: 0.25,
          max: 8.0,
          divisions: 30,
          onChanged: (v) => setState(() => normalSpeed = v),
          activeColor: const Color(0xFF00D9FF),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0.5, 1.0, 2.0, 4.0, 8.0].map((s) {
            return ElevatedButton(
              onPressed: () => setState(() => normalSpeed = s),
              child: Text('${s}x'),
            );
          }).toList(),
        ),
      ],
    );
  }
  Widget _buildCurveSpeed() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 1,
          minY: 0.25,
          maxY: 8.0,

          lineTouchData: LineTouchData(
            handleBuiltInTouches: false,
            touchCallback: (event, response) {
              if (response == null || response.lineBarSpots == null) return;

              final spot = response.lineBarSpots!.first;
              final index = spot.spotIndex;

              if (event is FlTapDownEvent) {
                setState(() => selectedPointIndex = index);
              }

              if (event is FlPanUpdateEvent && selectedPointIndex != null) {
                final localPos = event.localPosition;
                final size = context.size!;

                final newX = (localPos.dx / size.width).clamp(0.0, 1.0);
                final newY = (8.0 -
                    (localPos.dy / size.height) * (8.0 - 0.25))
                    .clamp(0.25, 8.0);

                setState(() {
                  curvePoints[selectedPointIndex!] =
                      SpeedPoint(time: newX, speed: newY);

                  curvePoints.sort((a, b) => a.time.compareTo(b.time));
                });
              }
            },
          ),

          lineBarsData: [
            LineChartBarData(
              spots: curvePoints
                  .map((p) => FlSpot(p.time, p.speed))
                  .toList(),
              isCurved: true,
              color: const Color(0xFF00D9FF),
              barWidth: 4,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) {
                  final isSelected =
                      selectedPointIndex != null &&
                          curvePoints[selectedPointIndex!].time == spot.x;

                  return FlDotCirclePainter(
                    radius: isSelected ? 6 : 4,
                    color: isSelected ? Colors.white : const Color(0xFF00D9FF),
                    strokeWidth: 2,
                    strokeColor: Colors.black,
                  );
                },
              ),
            ),
          ],

          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
    );
  }

}