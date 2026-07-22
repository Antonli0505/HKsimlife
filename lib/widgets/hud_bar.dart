import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/family_assets.dart';
import '../data/hk_school_data.dart';
import '../game_state.dart';
import '../models/enums.dart';
import 'stat_bar.dart';

class HudBar extends StatelessWidget {
  const HudBar({super.key});

  String _formatCash(int wealth) {
    if (wealth >= 1000000) {
      return '\$${(wealth / 1000000).toStringAsFixed(1)}M';
    }
    if (wealth >= 1000) {
      return '\$${(wealth / 1000).toStringAsFixed(0)}K';
    }
    return '\$$wealth';
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.player;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1419),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A3441), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '香港生存模擬器',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade400,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.age} 歲 · ${p.year} · ${p.quarterLabel}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF0F3F6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF12261A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3FB950)),
                ),
                child: Text(
                  'AP ${p.actionPoints}/${p.maxActionPoints}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3FB950),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.person, size: 26),
                color: const Color(0xFF79C0FF),
                tooltip: '個人檔（成績／選科／GER）',
                onPressed: gs.toggleProfile,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(p.birthTier.shortLabel),
              if (p.lifeStage == LifeStage.secondary &&
                  p.secondarySchoolName.isNotEmpty)
                _chip(p.secondarySchoolName)
              else if (p.lifeStage == LifeStage.secondary &&
                  p.schoolBand != SchoolBand.none)
                _chip(p.schoolBand.secondaryLabel)
              else if (p.lifeStage == LifeStage.primary &&
                  p.primarySchoolName.isNotEmpty)
                _chip(p.primarySchoolName)
              else if (p.lifeStage == LifeStage.infant &&
                  p.primaryBand != SchoolBand.none)
                _chip('${p.primaryBand.primaryLabel}（待升小）')
              else if (p.lifeStage == LifeStage.primary &&
                  p.primaryBand != SchoolBand.none)
                _chip(p.primaryBand.primaryLabel),
              if (p.ssaBandGroup != SsaBandGroup.none &&
                  (p.age >= 11 || p.lifeStage == LifeStage.secondary))
                _chip(p.ssaBandGroup.label),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  p.statusLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC9D1D9),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCash(p.wealth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF58A6FF),
                    ),
                  ),
                  if (p.livesWithFamily && p.age < 18)
                    const Text(
                      '零用：不定期',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6E7681),
                      ),
                    ),
                  if (p.livesWithFamily && p.quarter == Quarter.q1)
                    Text(
                      '利是 ${FamilyAssets.laiSeeRangeLabel(p)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6E7681),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatBar(
            label: '生命',
            value: p.hp,
            max: p.maxHp,
            color: const Color(0xFF3FB950),
            labelWidth: 36,
          ),
          const SizedBox(height: 5),
          StatBar(
            label: '神智',
            value: p.san,
            max: p.maxSan,
            color: const Color(0xFFBC8CFF),
            labelWidth: 36,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: StatBar(
                  label: '智慧',
                  value: p.smarts,
                  max: 100,
                  color: const Color(0xFF79C0FF),
                  labelWidth: 36,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBar(
                  label: '人脈',
                  value: p.network,
                  max: 100,
                  color: const Color(0xFFFFA657),
                  labelWidth: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF21262D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3D4A5C)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFC9D1D9),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
