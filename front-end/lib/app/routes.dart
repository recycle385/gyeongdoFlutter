import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/auth/nickname_view.dart';
import '../views/lobby/lobby_view.dart';
import '../views/lobby/join_room_view.dart';
import '../views/waiting/waiting_room_view.dart';
import '../views/game/police_game_view.dart';
import '../views/game/thief_game_view.dart';
import '../views/result/result_view.dart';
import '../app/constants.dart';
import 'bindings.dart';

/// 라우트 이름 정의
abstract class Routes {
  static const HOME = '/';
  static const LOBBY = '/lobby';
  static const CREATE_ROOM = '/create-room';
  static const JOIN_ROOM = '/join-room';
  static const WAITING_ROOM = '/waiting-room';
  static const GAME = '/game';
  static const RESULT = '/result';
}

/// 페이지 목록
class AppPages {
  static const INITIAL = Routes.HOME;

  static final routes = [
    // 닉네임 설정 (홈)
    GetPage(
      name: Routes.HOME,
      page: () => const NicknameView(),
      binding: AuthBinding(),
    ),

    // 로비 (방 만들기/참여하기 선택)
    GetPage(
      name: Routes.LOBBY,
      page: () => const LobbyView(),
      binding: LobbyBinding(),
    ),

    // 방 생성 (지도 설정) - 임시로 플레이스홀더
    GetPage(
      name: Routes.CREATE_ROOM,
      page: () => const _PlaceholderView(title: '방 만들기\n(지도 설정)'),
      binding: MapEditorBinding(),
    ),

    // 방 참여 (OTP 입력)
    GetPage(
      name: Routes.JOIN_ROOM,
      page: () => const JoinRoomView(),
      binding: RoomBinding(),
    ),

    // 대기실
    GetPage(
      name: Routes.WAITING_ROOM,
      page: () => const WaitingRoomView(),
      binding: WaitingRoomBinding(),
    ),

    // 게임 진행
    GetPage(
      name: Routes.GAME,
      page: () {
        // arguments에서 team 정보를 받아서 경찰/도둑 화면 분기
        final args = Get.arguments as Map<String, dynamic>?;
        final team = args?['team'] as TeamType? ?? TeamType.unassigned;

        if (team == TeamType.police) {
          return const PoliceGameView();
        } else if (team == TeamType.thief) {
          return const ThiefGameView();
        } else {
          return const _PlaceholderView(title: '역할이 배정되지 않았습니다');
        }
      },
      binding: GameBinding(),
    ),

    // 결과 화면
    GetPage(
      name: Routes.RESULT,
      page: () => const ResultView(),
    ),
  ];
}

/// 임시 플레이스홀더 화면
class _PlaceholderView extends StatelessWidget {
  final String title;
  const _PlaceholderView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '(개발 예정)',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
