/// Gacha baseline stats — frozen at birth for Base vs Added display.
class StatBaselines {
  int baseHp;
  int baseSan;
  int baseSmarts;
  int baseNetwork;
  int baseWealth;
  int baseReputation;
  int baseLuck;
  int baseDiscipline;

  StatBaselines({
    this.baseHp = 80,
    this.baseSan = 70,
    this.baseSmarts = 50,
    this.baseNetwork = 30,
    this.baseWealth = 0,
    this.baseReputation = 50,
    this.baseLuck = 50,
    this.baseDiscipline = 50,
  });

  Map<String, dynamic> toJson() => {
        'baseHp': baseHp,
        'baseSan': baseSan,
        'baseSmarts': baseSmarts,
        'baseNetwork': baseNetwork,
        'baseWealth': baseWealth,
        'baseReputation': baseReputation,
        'baseLuck': baseLuck,
        'baseDiscipline': baseDiscipline,
      };

  factory StatBaselines.fromJson(Map<String, dynamic> json) => StatBaselines(
        baseHp: json['baseHp'] as int? ?? 80,
        baseSan: json['baseSan'] as int? ?? 70,
        baseSmarts: json['baseSmarts'] as int? ?? 50,
        baseNetwork: json['baseNetwork'] as int? ?? 30,
        baseWealth: json['baseWealth'] as int? ?? 0,
        baseReputation: json['baseReputation'] as int? ?? 50,
        baseLuck: json['baseLuck'] as int? ?? 50,
        baseDiscipline: json['baseDiscipline'] as int? ?? 50,
      );

  static StatBaselines fromPlayer({
    required int hp,
    required int san,
    required int smarts,
    required int network,
    required int wealth,
    required int reputation,
    required int luck,
    required int discipline,
  }) =>
      StatBaselines(
        baseHp: hp,
        baseSan: san,
        baseSmarts: smarts,
        baseNetwork: network,
        baseWealth: wealth,
        baseReputation: reputation,
        baseLuck: luck,
        baseDiscipline: discipline,
      );
}
