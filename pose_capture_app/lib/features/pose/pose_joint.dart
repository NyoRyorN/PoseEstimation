class PoseJoint {
  final String name;
  final double x;
  final double y;
  final double z;
  final double confidence;

  const PoseJoint({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });
}
