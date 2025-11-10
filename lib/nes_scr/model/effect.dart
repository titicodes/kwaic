class Effect {
  String id;
  String name;
  String type; // e.g., "filter", "transition"
  Map<String, dynamic> parameters;

  Effect({
    required this.id,
    required this.name,
    required this.type,
    required this.parameters,
  });
}
