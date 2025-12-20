import 'package:flutter/material.dart';
import 'package:sunnyplanti/services/database_service.dart';

class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  // 도감 목록 정의
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

  List<String> myCollection = [];

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  void _loadCollection() {
    setState(() {
      myCollection = DatabaseService.getCollectedFlowers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight + 20;

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text(
          "식물 도감",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Stack(
        children: [
          // 배경 이미지
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_shop_codex.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 리스트 뷰
          ListView.builder(
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
            itemCount: allFlowers.length,
            itemBuilder: (context, index) {
              final flower = allFlowers[index];
              final String id = flower['id']!;
              final String name = flower['name']!;

              bool isUnlocked = myCollection.contains(id);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  border: isUnlocked
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: isUnlocked ? Colors.white : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                      ),
                      child: Center(
                        child: isUnlocked
                            ? Image.asset(
                                'assets/images/$id.png',
                                fit: BoxFit.contain,
                                width: 50,
                              )
                            : const Icon(
                                Icons.lock,
                                color: Colors.grey,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

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
