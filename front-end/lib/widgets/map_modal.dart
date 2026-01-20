import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import '../app/theme.dart';

class MapModal extends StatelessWidget {
  final double myLat;
  final double myLng;
  final double? jailLat;
  final double? jailLng;
  final bool isPolice;
  // TODO: Polygon points 전달 필요

  const MapModal({
    super.key,
    required this.myLat,
    required this.myLng,
    this.jailLat,
    this.jailLng,
    required this.isPolice,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '작전 지도',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // 지도
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(myLat, myLng),
                      zoom: 15,
                    ),
                    locationButtonEnable: true,
                  ),
                  onMapReady: (controller) async {
                    // 내 위치 마커
                    final myMarker = NMarker(
                      id: 'me',
                      position: NLatLng(myLat, myLng),
                      iconTintColor: isPolice ? AppTheme.policeBlue : AppTheme.thiefRed,
                      caption: NOverlayCaption(text: '나'),
                    );
                    await controller.addOverlay(myMarker);
                    
                    // 감옥 위치 마커
                    if (jailLat != null && jailLng != null) {
                      final jailMarker = NMarker(
                        id: 'jail',
                        position: NLatLng(jailLat!, jailLng!),
                        iconTintColor: Colors.black,
                        caption: const NOverlayCaption(text: '감옥'),
                      );
                      await controller.addOverlay(jailMarker);
                      
                      // 감옥 반경 (15m)
                      final jailCircle = NCircleOverlay(
                        id: 'jail_radius',
                        center: NLatLng(jailLat!, jailLng!),
                        radius: 15,
                        color: Colors.black.withOpacity(0.1),
                        outlineColor: Colors.black,
                        outlineWidth: 1,
                      );
                      await controller.addOverlay(jailCircle);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
