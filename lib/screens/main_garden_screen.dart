import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sunnyplanti/services/database_service.dart';
import 'package:sunnyplanti/services/notification_service.dart';
import 'package:sunnyplanti/screens/shop_screen.dart';
import 'package:sunnyplanti/screens/camera_auth_screen.dart';
import 'package:sunnyplanti/screens/codex_screen.dart';

class MainGardenScreen extends StatefulWidget {
  const MainGardenScreen({super.key});

  @override
  State<MainGardenScreen> createState() => _MainGardenScreenState();
}

class _MainGardenScreenState extends State<MainGardenScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;

  bool _isRewardReady = false;

  @override
  void initState() {
    super.initState();
    _checkSavedTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();

    // 화면이 다 그려진 뒤에 초기화 메시지 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyGreeting();
    });
  }

  // 매일 처음 켰을 때 독려 메시지 띄우기
  void _checkDailyGreeting() {
    int questCount = DatabaseService.getQuestCount();
    if (questCount == 0 && _remainingSeconds == 0 && !_isRewardReady) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("☀️ 새로운 하루!"),
          content: const Text("오늘도 식물과 함께 힘찬 하루를 시작해보세요!\n산책으로 식물을 키워볼까요? 🌱"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("좋아요", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    }
  }

  void _checkSavedTimer() {
    dynamic savedTime = DatabaseService.getTimerEndTime();

    if (savedTime != null) {
      DateTime endTime;
      if (savedTime is DateTime) {
        endTime = savedTime;
      } else if (savedTime is int) {
        endTime = DateTime.fromMillisecondsSinceEpoch(savedTime);
      } else {
        return;
      }

      final now = DateTime.now();
      final diff = endTime.difference(now).inSeconds;

      if (diff > 0) {
        setState(() {
          _remainingSeconds = diff;
          _isRewardReady = false;
        });
        _runTimerLogic();
      } else {
        _handleQuestCompletion();
        // 앱이 꺼진 사이에 시간이 다됨 -> 보상 대기 상태
        _remainingSeconds = 0;
        _isRewardReady = true; // 보상 버튼 활성화
      }
    }
  }

  // 보상 지급 로직
  Future<void> _handleQuestCompletion() async {
    if (DatabaseService.getTimerEndTime() == null) return;

    await DatabaseService.completeQuest();
    await DatabaseService.clearTimer();
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 0;
    });

    if (_getPlantLevel() == 3) {
      String todayFlower = DatabaseService.getTodayFlowerType();
      await DatabaseService.unlockFlower(todayFlower);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 축하합니다! '$todayFlower'가 도감에 등록됐어요!"),
            backgroundColor: Colors.purpleAccent,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("성장 완료! 식물이 자랐어요 🌱")));
      }
    }
  }

  void _runTimerLogic() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRewardReady = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ 산책 완료! '보상 받기' 버튼을 눌러주세요! 🎁"),
              backgroundColor: Colors.blueAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  // 사용자가 '보상 받기' 버튼을 눌렀을 때 실행되는 보상 지급 함수
  Future<void> _claimReward() async {
    // DB 업데이트
    await DatabaseService.completeQuest();
    await DatabaseService.clearTimer(); // 타이머 정보 삭제

    setState(() {
      _isRewardReady = false;
      _remainingSeconds = 0;
    });

    // 도감 등록 및 레벨업 체크
    if (_getPlantLevel() == 3) {
      String todayFlower = DatabaseService.getTodayFlowerType();
      await DatabaseService.unlockFlower(todayFlower);

      if (mounted) {
        // 축하 다이얼로그
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("🎉 축하합니다!"),
            content: Text("꽃이 활짝 피었습니다!\n도감에 '$todayFlower'가 등록되었어요."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("쑥쑥! 식물이 자랐습니다! 🌱 (+포인트 획득)"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _startTimer() async {
    // 타이머
    DateTime endTime = DateTime.now().add(const Duration(minutes: 10)); // 10분
    await DatabaseService.setTimerEndTime(endTime);
    setState(() {
      _remainingSeconds = 600;
    });
    _runTimerLogic();
  }

  String _formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  int _getPlantLevel() {
    return DatabaseService.getQuestCount();
  }

  String _getFlowerName(String id) {
    switch (id) {
      case 'red_rose':
        return '정열적인 빨간 장미';
      case 'yellow_rose':
        return '수줍은 노란 장미';
      case 'pink_rose':
        return '우아한 분홍 장미';
      // case 'sunflower':
      //   return '활짝 핀 해바라기';
      default:
        return '신비한 미지의 꽃';
    }
  }

  Widget _buildPlantCharacter() {
    int level = _getPlantLevel();
    String equippedPot = DatabaseService.getEquippedPot();

    // 화분 이미지 설정
    String potImageName;
    if (equippedPot == 'default') {
      potImageName = 'pot_basic.png';
    } else {
      potImageName = equippedPot.endsWith('.png')
          ? equippedPot
          : 'pot_$equippedPot.png';
    }

    // 식물 이미지 및 높이 조절
    String? plantImageName;
    double bottomPadding = 0;

    switch (level) {
      case 1: // 새싹
        plantImageName = 'plant_LV1.png';
        bottomPadding = 95;
        break;
      case 2: // 봉오리
        plantImageName = 'plant_LV2.png';
        bottomPadding = 95;
        break;
      case 3: // 꽃
        String randomFlowerId = DatabaseService.getTodayFlowerType();
        plantImageName = '$randomFlowerId.png';
        bottomPadding = 95;
        break;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 1층: 화분
        Image.asset(
          'assets/images/$potImageName',
          width: 140,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 100, color: Colors.grey),
        ),

        // 2층: 식물
        if (plantImageName != null)
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Image.asset(
              'assets/images/$plantImageName',
              width: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_florist,
                size: 80,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int points = DatabaseService.getPoints();
    int questCount = DatabaseService.getQuestCount();
    double progress = questCount / 3.0;
    String bgImage = 'assets/images/bg_day.png';

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text(
          "Sunny Planti",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // actions: [
        //   // 개발용 리셋 버튼
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: Colors.white),
        //     onPressed: () async {
        //       await DatabaseService.resetData();
        //       if (mounted) {
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           const SnackBar(content: Text("🔄 데이터가 초기화되었습니다.")),
        //         );
        //         _checkDailyGreeting();
        //       }
        //       setState(() {});
        //     },
        //   ),
        // ],
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // 도감 & 상점 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 도감 버튼
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CodexScreen(),
                          ),
                        );
                      },
                      child: Chip(
                        avatar: const Icon(
                          Icons.menu_book,
                          color: Colors.green,
                        ),
                        label: const Text(
                          "도감",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.9),
                        elevation: 3,
                      ),
                    ),

                    // 상점 버튼
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShopScreen(),
                          ),
                        );
                        setState(() {});
                      },
                      child: Chip(
                        avatar: const Icon(Icons.store, color: Colors.brown),
                        label: Text(
                          "$points P",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.9),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),

              // 식물 이름
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getPlantLevel() == 3
                      ? _getFlowerName(
                          DatabaseService.getTodayFlowerType(),
                        ) // 3단계: 꽃
                      : _getPlantLevel() == 2
                      ? "Lv.2 쑥쑥 자란 봉오리" // 2단계
                      : _getPlantLevel() == 1
                      ? "Lv.1 파릇파릇한 새싹" // 1단계
                      : "Lv.0 잠자고 있는 씨앗", // 0단계
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const Spacer(),
              const SizedBox(height: 30),
              // 식물 캐릭터
              _buildPlantCharacter(),

              const SizedBox(height: 15),

              // 퀘스트 카드
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "오늘의 광합성",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_remainingSeconds > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: Text(
                                  "⏳ ${_formatTime(_remainingSeconds)}",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          "퀘스트 [$questCount/3]",
                          style: TextStyle(
                            fontSize: 14,
                            color: questCount >= 3 ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: Colors.green,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isRewardReady
                          ? ElevatedButton(
                              // 보상 받기 버튼
                              onPressed: _claimReward,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "🎁 보상 받기",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              // 산책 시작 버튼
                              onPressed:
                                  questCount >= 3 || _remainingSeconds > 0
                                  ? null
                                  : () async {
                                      final bool? isAuthenticated =
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CameraAuthScreen(),
                                            ),
                                          );
                                      if (isAuthenticated == true) {
                                        await NotificationService()
                                            .scheduleQuestCompletion();
                                        _startTimer();
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "🌱 10분 산책 시작! 완료하면 식물이 자라요.",
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                questCount >= 3
                                    ? "오늘의 퀘스트 완료! 🎉"
                                    : "☀️ 광합성 시작",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
