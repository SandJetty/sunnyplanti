import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ★ 화면 회전 잠금을 위해 필요

class CameraAuthScreen extends StatefulWidget {
  const CameraAuthScreen({super.key});

  @override
  State<CameraAuthScreen> createState() => _CameraAuthScreenState();
}

class _CameraAuthScreenState extends State<CameraAuthScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // ★ 부드러운 게이지 로직을 위한 변수들
  Timer? _uiTimer; // 게이지 애니메이션용 타이머
  bool _isConditionMet = false; // 현재 빛이 충분한지 여부 (분석 결과)
  double _progress = 0.0; // 진행률 (0.0 ~ 1.0)
  bool _isSuccess = false; // 성공 여부

  // 상태 메시지 UI 변수
  String _statusMessage = "밝은 빛을 비춰주세요! ☀️";
  Color _statusColor = Colors.white;
  IconData _statusIcon = Icons.wb_sunny_outlined;

  @override
  void initState() {
    super.initState();
    // 1. 화면 세로 모드 고정
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 2. 카메라 초기화
    _initCamera();

    // 3. 게이지 애니메이션 타이머 시작
    _startProgressTimer();
  }

  @override
  void dispose() {
    // 화면 회전 잠금 해제 (앱의 다른 화면을 위해)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller?.dispose();
    _uiTimer?.cancel();
    super.dispose();
  }

  // ★ 게이지를 부드럽게 올리고 내리는 타이머
  void _startProgressTimer() {
    // 0.05초(50ms)마다 실행
    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _isSuccess) return;

      setState(() {
        // 3초 동안 채우려면: 0.05초 / 3.0초 = 약 0.0167씩 증감
        const double step = 0.05 / 3.0;

        if (_isConditionMet) {
          // 조건 충족 시: 게이지 상승
          _progress += step;

          // UI 업데이트
          _statusMessage = "빛 에너지를 모으는 중... 🔥";
          _statusColor = Colors.yellowAccent;
          _statusIcon = Icons.bolt;

          if (_progress >= 1.0) {
            _progress = 1.0;
            _handleSuccess(); // 성공 처리
          }
        } else {
          // 조건 미달 시: 게이지 하락 (똑같은 속도로)
          _progress -= step;

          if (_progress <= 0.0) {
            _progress = 0.0;
            // 완전히 바닥나면 메시지 변경
            _statusMessage = "더 밝은 자연광을 비춰주세요. ☁️";
            _statusColor = Colors.white;
            _statusIcon = Icons.wb_sunny_outlined;
          } else {
            // 줄어드는 중일 때 메시지
            _statusMessage = "빛이 약해지고 있어요! 😱";
            _statusColor = Colors.orangeAccent;
          }
        }
      });
    });
  }

  void _handleSuccess() {
    _isSuccess = true;
    _uiTimer?.cancel(); // 타이머 중지

    setState(() {
      _statusMessage = "🌿 광합성 충전 완료! 성공!";
      _statusColor = Colors.greenAccent;
      _statusIcon = Icons.check_circle;
    });

    // 1초 뒤에 닫기
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      setState(() => _isCameraInitialized = true);

      _controller!.startImageStream((CameraImage image) {
        if (!_isProcessing && !_isSuccess) {
          _isProcessing = true;
          _analyzeRealtimeImage(image).then((_) => _isProcessing = false);
        }
      });
    } catch (e) {
      setState(() => _statusMessage = "카메라 오류: $e");
    }
  }

  Future<void> _analyzeRealtimeImage(CameraImage image) async {
    final Plane yPlane = image.planes[0];
    final Uint8List yBytes = yPlane.bytes;

    int totalBrightness = 0;
    int brightPixelCount = 0;
    int pixelCount = yBytes.length;

    const int step = 10;
    int sampledCount = 0;

    for (int i = 0; i < pixelCount; i += step) {
      int brightness = yBytes[i];
      totalBrightness += brightness;
      if (brightness > 200) brightPixelCount++;
      sampledCount++;
    }

    double avgBrightness = totalBrightness / sampledCount;
    double brightRatio = brightPixelCount / sampledCount;

    // 분석 결과만 업데이트 (게이지 조절은 타이머가 담당)
    bool isGoodLight = (avgBrightness > 110 && brightRatio > 0.05);

    // 상태 변수만 갱신 (화면 갱신은 타이머에서 하므로 setState 최소화 가능)
    // 하지만 반응성을 위해 여기서 변수값 변경
    _isConditionMet = isGoodLight;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 카메라 프리뷰 (세로 모드 고정됨)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                // 카메라 센서 방향에 따라 가로세로를 바꿔줘야 꽉 찹니다.
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. 어두운 오버레이 & 구멍
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      // 성공하면 초록, 아니면 투명도 조절
                      color: _isSuccess
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.3),
                      width: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. 진행률 게이지 (원형)
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: _progress, // 0.0 ~ 1.0 부드럽게 변함
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.yellowAccent,
              ),
            ),
          ),

          // 4. 상태 메시지
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _statusIcon,
                color: _statusColor.withOpacity(0.8), // 아이콘 투명도 살짝
                size: 60,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          // 5. 닫기 버튼
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
        ],
      ),
    );
  }
}
