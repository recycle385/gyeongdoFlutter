import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';

// ✅ 방금 만든 라우트 파일 import
import 'routes.dart';

void main() async {
  // 1. 플러터 엔진 초기화
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

  // 4. 상단바 투명 처리
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 5. 전체화면 모드
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), // 당근색
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),

      // ✅ 라우트 연결 (여기가 핵심!)
      initialRoute: AppPages.INITIAL, // '/' 경로로 시작
      getPages: AppPages.routes,      // routes.dart에 정의된 리스트 사용

      // 전역 바인딩 (컨트롤러 주입)
      initialBinding: BindingsBuilder(() {
        // 추후 SocketService 등을 여기서 put 합니다.
        // Get.put(SocketService());
      }),
    );
  }
}