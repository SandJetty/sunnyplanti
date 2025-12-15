import 'package:flutter/material.dart';
import 'package:sunnyplanti/services/database_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // 판매할 아이템 목록
  final List<Map<String, dynamic>> items = [
    // --- 기존 판매중인 화분 4개 ---
    {
      'id': 'default',
      'name': '기본 화분',
      'price': 0,
      'image': 'assets/images/pot_basic.png',
      'isComingSoon': false, // 판매중
    },
    {
      'id': 'white',
      'name': '하얀 화분',
      'price': 500,
      'image': 'assets/images/pot_white.png',
      'isComingSoon': false,
    },
    {
      'id': 'blue',
      'name': '파랑 화분',
      'price': 1000,
      'image': 'assets/images/pot_blue.png',
      'isComingSoon': false,
    },
    {
      'id': 'round',
      'name': '둥근 화분',
      'price': 1500,
      'image': 'assets/images/pot_round.png',
      'isComingSoon': false,
    },
    {
      'id': 'locked1',
      'name': 'Coming Soon',
      'price': '????',
      'isComingSoon': true, // 미공개 표시
    },
    {
      'id': 'locked2',
      'name': 'Coming Soon',
      'price': '????',
      'isComingSoon': true,
    },
    {
      'id': 'locked3',
      'name': 'Coming Soon',
      'price': '????',
      'isComingSoon': true,
    },
    {
      'id': 'locked4',
      'name': 'Coming Soon',
      'price': '????',
      'isComingSoon': true,
    },
  ];

  List<String> ownedItems = [];
  String equippedItem = 'default';
  int myPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      ownedItems = DatabaseService.getOwnedItems();
      equippedItem = DatabaseService.getEquippedPot();
      myPoints = DatabaseService.getPoints();
    });
  }

  void _buyItem(String id, int price) async {
    bool success = await DatabaseService.buyItem(id, price);
    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("구매 성공! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("포인트가 부족해요 😭"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _equipItem(String id) async {
    await DatabaseService.equipItem(id);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("화분을 바꿨어요!"),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상단 패딩 (상태바 + 앱바 + 여유)
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight + 20;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "아이템 상점",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "$myPoints P",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 배경 이미지
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_shop_codex.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. 아이템 그리드
          GridView.builder(
            padding: EdgeInsets.only(
              top: topPadding,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              // 상태 확인
              bool isOwned = ownedItems.contains(item['id']);
              bool isEquipped = equippedItem == item['id'];
              // [추가] 미공개 여부 확인 (null safety를 위해 기본값 false)
              bool isComingSoon = item['isComingSoon'] ?? false;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: isEquipped
                      ? Border.all(color: Colors.green, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // [변경] 미공개면 아이콘, 아니면 이미지
                    if (isComingSoon)
                      const Icon(
                        Icons.lock_outline_rounded, // 자물쇠 아이콘
                        size: 60,
                        color: Colors.grey,
                      )
                    else
                      Image.asset(
                        item['image'],
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                      ),

                    const SizedBox(height: 10),

                    // 이름 (Coming Soon)
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isComingSoon
                            ? Colors.grey
                            : Colors.black, // 미공개는 회색 글씨
                      ),
                    ),
                    const SizedBox(height: 5),

                    // 버튼 분기 처리
                    if (isComingSoon)
                      // [추가] 미공개용 비활성화 버튼
                      ElevatedButton(
                        onPressed: null, // null을 주면 버튼이 비활성화(회색)됨
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey[300], // 비활성화 배경색
                          disabledForegroundColor: Colors.grey[600], // 비활성화 글자색
                        ),
                        child: Text("${item['price']} P"), // 가격은 보여줌
                      )
                    else if (isEquipped)
                      const Text(
                        "장착 중 ✅",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isOwned)
                      ElevatedButton(
                        onPressed: () => _equipItem(item['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue,
                        ),
                        child: const Text("장착하기"),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _buyItem(item['id'], item['price']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[50],
                          foregroundColor: Colors.amber[900],
                        ),
                        child: Text("${item['price']} P"),
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
