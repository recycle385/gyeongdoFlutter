import 'package:get/get.dart';

import 'package:flutter/material.dart';


import '../views/map_test_view.dart';

// 1. 라우트 이름 정의 (오타 방지용 상수)
abstract class Routes {
  static const HOME = '/';            // 로그인/메인
  static const LOBBY = '/lobby';      // 방 생성/참여 선택
  static const MAP_SETUP = '/setup';  // 방장 구역 설정 (지도)
  static const WAITING = '/waiting';  // 대기방
  static const GAME = '/game';        // 메인 게임
  static const RESULT = '/result';    // 결과 화면
}

// 2. 페이지 리스트 정의 (GetX 방식)
class AppPages {
  static const INITIAL = Routes.HOME;

  static final routes = [
    // 메인(로그인) 화면
    GetPage(
      name: Routes.HOME,
      //page: () => const _PlaceholderView(title: '로그인/홈 화면'),
      page: () => const MapTestView(),
      // binding: AuthBinding(), // 나중에 컨트롤러 연결할 때 주석 해제
    ),

    // 로비 (방 만들기/참여하기)
    GetPage(
      name: Routes.LOBBY,
      page: () => const _PlaceholderView(title: '로비 화면'),
    ),

    // 구역 설정 (지도)
    GetPage(
      name: Routes.MAP_SETUP,
      page: () => const _PlaceholderView(title: '구역 설정(지도) 화면'),
      // binding: GameBinding(), // 게임 컨트롤러 주입
    ),

    // 대기방
    GetPage(
      name: Routes.WAITING,
      page: () => const _PlaceholderView(title: '대기방'),
    ),

    // 게임 진행 화면
    GetPage(
      name: Routes.GAME,
      page: () => const _PlaceholderView(title: '게임 진행 중'),
      // transition: Transition.fadeIn, // 화면 전환 효과 (선택사항)
    ),

    // 결과 화면
    GetPage(
      name: Routes.RESULT,
      page: () => const _PlaceholderView(title: '게임 결과'),
    ),
  ];
}

// [임시] 뷰 파일이 없을 때 에러 안 나게 해주는 임시 위젯

class _PlaceholderView extends StatelessWidget {
  final String title;
  const _PlaceholderView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title\n(개발 예정)', textAlign: TextAlign.center)),
    );
  }
}