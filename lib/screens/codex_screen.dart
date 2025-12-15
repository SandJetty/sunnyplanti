import 'package:flutter/material.dart';
import 'package:sunnyplanti/services/database_service.dart'; // DB 연결 필수

class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  // 2. 도감 목록 정의
  final List<Map<String, String>> allFlowers = [
    {'id': 'red_rose', 'name': '정열적인 빨간 장미'},
    {'id': 'yellow_rose', 'name': '수줍은 노란 장미'},
    {'id': 'pink_rose', 'name': '우아한 분홍 장미'},
    {'id': 'flower1', 'name': '꽃'},
    {'id': 'flower2', 'name': '꽃'},
    {'id': 'flower3', 'name': '꽃'},
    {'id': 'flower4', 'name': '꽃'},
    {'id': 'flower5', 'name': '꽃'},
    {'id': 'flower6', 'name': '꽃'},
    {'id': 'flower7', 'name': '꽃'},
    {'id': 'flower8', 'name': '꽃'},
    {'id': 'flower9', 'name': '꽃'},
    {'id': 'flower10', 'name': '꽃'},
    {'id': 'flower11', 'name': '꽃'},
    {'id': 'flower12', 'name': '꽃'},
    // ... (나중에 추가할 꽃들)
  ];

  List<String> myCollection = []; // 내가 모은 꽃 ID 리스트

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  // DB에서 "내가 뭘 모았나?" 확인하는 함수
  void _loadCollection() {
    setState(() {
      myCollection = DatabaseService.getCollectedFlowers();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 상단 패딩 계산 (상태바 + 앱바 높이 + 여유)
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight + 20;

    return Scaffold(
      // [핵심 1] 배경이 앱바 뒤까지 보이도록 확장
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        // [핵심 2] 앱바 투명화 및 글씨색 흰색으로 변경
        title: const Text(
          "식물 도감",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent, // 투명
        elevation: 0, // 그림자 제거
        iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 버튼 흰색
      ),

      // [핵심 3] Stack을 사용하여 배경 이미지와 리스트 겹치기
      body: Stack(
        children: [
          // 1. 배경 이미지 (가장 뒤)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // 상점과 같은 배경을 쓰려면 shop_bg.png,
                // 도감 전용 배경이 있다면 파일명을 변경해주세요.
                image: AssetImage('assets/images/bg_shop_codex.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. 리스트 뷰 (그 위)
          ListView.builder(
            // 상단 패딩을 주어 앱바에 가려지지 않게 함
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
            itemCount: allFlowers.length,
            itemBuilder: (context, index) {
              final flower = allFlowers[index];
              final String id = flower['id']!;
              final String name = flower['name']!;

              // ★ 핵심: 내가 이 꽃을 가지고 있는지 확인!
              bool isUnlocked = myCollection.contains(id);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 100,
                decoration: BoxDecoration(
                  // [핵심 4] 배경을 살짝 반투명하게 (0.9)
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  // 잠금 해제되면 초록 테두리
                  border: isUnlocked
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // 그림자 색상 약간 진하게
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 왼쪽: 이미지 영역
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        // 여기도 살짝 반투명하게 할지, 불투명하게 할지 선택 가능 (현재 불투명 유지)
                        color: isUnlocked ? Colors.white : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                      ),
                      child: Center(
                        child: isUnlocked
                            ? Image.asset(
                                'assets/images/$id.png', // 해제되면: 진짜 꽃 이미지
                                fit: BoxFit.contain,
                                width: 50, // 크기 살짝 키움
                              )
                            : const Icon(
                                Icons.lock,
                                color: Colors.grey,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 오른쪽: 텍스트 영역
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUnlocked ? name : "???",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isUnlocked ? Colors.black : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isUnlocked ? "획득 완료!" : "아직 발견하지 못했습니다.",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
