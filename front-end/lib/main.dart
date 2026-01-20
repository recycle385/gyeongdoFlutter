import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';

import 'app/routes.dart';
import 'app/bindings.dart';
import 'app/theme.dart';
import 'services/storage_service.dart';

void main() async {
  // 1. Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. .env 파일 로드
  await dotenv.load(fileName: ".env");

  // 3. 네이버 지도 SDK 초기화
  await FlutterNaverMap().init(
    clientId: dotenv.env['NAVER_MAP_CLIENT_ID']!,
    onAuthFailed: (ex) {
      debugPrint("********* 네이버 지도 인증 실패: $ex *********");
    },
  );

  // 4. StorageService 초기화 (동기적으로 필요)
  final storage = StorageService();
  await storage.init();
  Get.put(storage, permanent: true);

  // 5. 상단바 투명 처리
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 6. 전체화면 모드
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: '당근 술래잡기',

      // 테마 설정
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // 라우트 연결
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,

      // 전역 바인딩
      initialBinding: InitialBinding(),

      // 기본 트랜지션
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}