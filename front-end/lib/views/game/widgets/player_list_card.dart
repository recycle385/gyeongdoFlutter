import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../models/player_model.dart';

class PlayerListCard extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;
  final bool showControls; // 방장용 컨트롤 보이기 여부
  final VoidCallback? onRoleToggle; // 역할 변경 콜백
  final VoidCallback? onKick; // 강퇴 콜백 (나중에 구현)

  const PlayerListCard({
    super.key,
    required this.player,
    this.isMe = false,
    this.showControls = false,
    this.onRoleToggle,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.carrotOrange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? AppTheme.carrotOrange : Colors.grey.shade300,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아바타 / 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: player.team.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.team.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 이름 & 역할
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.nickname,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isMe ? AppTheme.carrotOrange : Colors.black87,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.carrotOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('나', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                    if (player.isHost) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  player.team.label,
                  style: TextStyle(
                    color: player.team.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 컨트롤 (방장용)
          if (showControls && !player.isHost) // 방장은 자기 역할 변경 불가
            InkWell(
              onTap: onRoleToggle,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '변경',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
