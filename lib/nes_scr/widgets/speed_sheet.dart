import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../model/timeline_item.dart'; // Add fl_chart: ^0.68.0 for graph

class SpeedSheet extends StatefulWidget {
  final TimelineItem clip;
  final Function(double speed) onNormal;
  final Function(List<SpeedPoint> points) onCurve; // Custom curve

  const SpeedSheet({super.key, required this.clip, required this.onNormal, required this.onCurve});

  @override
  State<SpeedSheet> createState() => _SpeedSheetState();
}

class _SpeedSheetState extends State<SpeedSheet> {
  String tab = 'Normal';
  double normalSpeed = 1.0;
  List<SpeedPoint> curvePoints = [SpeedPoint(time: 0.0, speed: 1.0), SpeedPoint(time: 1.0, speed: 1.0)];

  @override
  void initState() {
    super.initState();
    normalSpeed = widget.clip.speed;
    curvePoints = widget.clip.speedPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      color: Color(0xFF1A1A1A),
      child: Column(
        children: [
          TabBar(
            tabs: [Tab(text: 'Normal'), Tab(text: 'Curve'), Tab(text: 'Velocity')],
            onTap: (i) => setState(() => tab = ['Normal', 'Curve', 'Velocity'][i]),
          ),
          Expanded(
            child: tab == 'Normal'
                ? Column(
              children: [
                Slider(
                  value: normalSpeed,
                  min: 0.25,
                  max: 4.0,
                  onChanged: (v) {
                    setState(() => normalSpeed = v);
                    widget.onNormal(v);
                  },
                ),
                Text('${normalSpeed.toStringAsFixed(2)}x', style: TextStyle(color: Colors.white, fontSize: 32)),
              ],
            )
                : _buildCurveEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurveEditor() {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: 0.1,
              maxY: 4.0,
              lineTouchData: LineTouchData(enabled: false),
              titlesData: FlTitlesData(show: false),
              gridData: FlGridData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: curvePoints.map((p) => FlSpot(p.time, p.speed)).toList(),
                  isCurved: true,
                  barWidth: 4,
                  color: Color(0xFF00D9FF),
                ),
              ],
            ),
          ),
        ),
        // Add/remove points, presets (Hero, Montage, etc.)
        ElevatedButton(onPressed: () => widget.onCurve(curvePoints), child: Text('Apply Curve')),
      ],
    );
  }
}