import 'player.dart';

/// Blind choice — label only, no stat preview.
class EventChoice {
  final String label;
  final void Function(Player player) apply;
  final bool enabled;

  const EventChoice({
    required this.label,
    required this.apply,
    this.enabled = true,
  });
}

class StoryEvent {
  final String id;
  final String title;
  final String body;
  final List<EventChoice> choices;
  final bool isSystem;

  const StoryEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.choices,
    this.isSystem = false,
  });
}

class ActionButton {
  final String label;
  final int apCost;
  final void Function(Player player) onExecute;
  final bool isConditional;
  final String? opensChecklistId;
  /// false＝灰顯不可用（例如未開放功能）
  final bool enabled;

  const ActionButton({
    required this.label,
    this.apCost = 1,
    required this.onExecute,
    this.isConditional = false,
    this.opensChecklistId,
    this.enabled = true,
  });
}

class RequirementItem {
  final String label;
  final bool Function(Player player) check;

  const RequirementItem({required this.label, required this.check});
}

class ChecklistExam {
  final String id;
  final String title;
  final String description;
  final List<RequirementItem> requirements;
  final void Function(Player player) onPass;
  final void Function(Player player)? onFail;

  const ChecklistExam({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
    required this.onPass,
    this.onFail,
  });

  List<bool> evaluate(Player player) =>
      requirements.map((r) => r.check(player)).toList();
}
