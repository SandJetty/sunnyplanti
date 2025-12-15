import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const String _boxName = "game_data";

  // 1. 초기화 (앱 켜질 때 한 번 실행)
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  // 박스 가져오기 (도구함 열기)
  static Box get _box => Hive.box(_boxName);

  // --- [데이터 읽기] ---

  // 현재 포인트 가져오기 (없으면 0)
  static int getPoints() {
    return _box.get('points', defaultValue: 0);
  }

  // 오늘 퀘스트 완료 횟수 가져오기 (날짜 체크 기능 추가) ---
  // 리셋할 때 꽃도 새로 뽑기 (기존 getQuestCount 수정)
  static int getQuestCount() {
    final now = DateTime.now();
    String todayKey = "${now.year}-${now.month}-${now.day}";
    String? savedDate = _box.get('lastQuestDate');

    if (savedDate != todayKey) {
      // 날짜가 바뀌었으면? -> 초기화하면서 ★꽃도 새로 뽑기!★
      _box.put('questCount', 0);
      _box.put('lastQuestDate', todayKey);

      // 새로운 운명의 꽃 지정
      String newFlower = _generateRandomFlower();
      _box.put('todayFlowerType', newFlower);

      return 0;
    }
    return _box.get('questCount', defaultValue: 0);
  }

  // --- 랜덤 꽃 시스템 ---

  // 1. 오늘의 꽃 종류 가져오기 (저장된 게 없으면 새로 뽑음)
  static String getTodayFlowerType() {
    // 저장된 꽃 ID 가져오기
    String? savedType = _box.get('todayFlowerType');

    // 만약 저장된 게 없다면? (첫 실행이거나 리셋 직후) -> 랜덤으로 뽑아서 저장!
    if (savedType == null) {
      savedType = _generateRandomFlower();
      _box.put('todayFlowerType', savedType);
    }

    return savedType;
  }

  // 2. 랜덤 뽑기 함수 (내부용)
  static String _generateRandomFlower() {
    // 준비한 이미지 파일명 뒤의 숫자나 이름들
    List<String> flowerList = ['red_rose', 'yellow_rose', 'pink_rose'];

    // 랜덤으로 하나 뽑기
    int randomIndex = Random().nextInt(flowerList.length);
    return flowerList[randomIndex];
  }

  // --- [데이터 쓰기] ---
  // 누적 횟수 가져오기
  static int getTotalQuests() {
    return _box.get('totalQuests', defaultValue: 0);
  }

  // 퀘스트 성공 시 처리 (횟수+1, 포인트+500)
  static Future<void> completeQuest() async {
    int currentCount = getQuestCount(); // 오늘의 횟수
    int currentPoints = getPoints();
    int totalQuests = getTotalQuests(); // 누적 횟수

    // 오늘 날짜 도장 준비
    final now = DateTime.now();
    String todayKey = "${now.year}-${now.month}-${now.day}";

    if (currentCount < 3) {
      await _box.put('questCount', currentCount + 1);
      await _box.put('lastQuestDate', todayKey); // ★ 날짜

      await _box.put('points', currentPoints + 500); // 1회당 500포인트
      await _box.put('totalQuests', totalQuests + 1); // 누적 횟수 +1
    }
  }

  // 1. 타이머 끝나는 시간 저장 (예: 지금부터 10분 뒤)
  static Future<void> setTimerEndTime(DateTime endTime) async {
    await _box.put('timerEndTime', endTime.toIso8601String());
  }

  // 2. 저장된 끝나는 시간 가져오기
  static DateTime? getTimerEndTime() {
    String? timeStr = _box.get('timerEndTime');
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  // 3. 타이머 정보 삭제 (완료 시)
  static Future<void> clearTimer() async {
    await _box.delete('timerEndTime');
  }

  // 4. 개발자용 리셋 함수 수정 (resetData)
  static Future<void> resetData() async {
    await _box.clear();
    // 리셋 후에도 새로운 꽃 하나는 뽑아놔야 에러가 안 남
    String newFlower = _generateRandomFlower();
    await _box.put('todayFlowerType', newFlower);
  }
  // --- 상점 & 아이템 시스템 ---

  // 1. 내가 가진 아이템 목록 가져오기 (기본값: 기본 화분 하나)
  static List<String> getOwnedItems() {
    List<dynamic> rawList = _box.get('ownedItems', defaultValue: ['default']);
    return rawList.cast<String>(); // 문자열 리스트로 변환
  }

  // 2. 현재 장착 중인 화분 ID 가져오기
  static String getEquippedPot() {
    return _box.get('equippedPot', defaultValue: 'default');
  }

  // 3. 아이템 구매하기 (성공하면 true 리턴)
  static Future<bool> buyItem(String itemId, int price) async {
    int myPoints = getPoints();

    // 돈이 부족하면? 실패!
    if (myPoints < price) return false;

    // 돈 차감
    await _box.put('points', myPoints - price);

    // 아이템 창고에 추가
    List<String> inventory = getOwnedItems();
    inventory.add(itemId);
    await _box.put('ownedItems', inventory);

    return true; // 구매 성공
  }

  // 4. 아이템 장착하기
  static Future<void> equipItem(String itemId) async {
    await _box.put('equippedPot', itemId);
  }

  // --- [추가] 도감(Collection) 시스템 ---

  // 1. 내가 모은 꽃 리스트 가져오기
  static List<String> getCollectedFlowers() {
    List<dynamic> rawList = _box.get('collectedFlowers', defaultValue: []);
    return rawList.cast<String>();
  }

  // 2. 꽃 도감에 추가하기 (중복 체크 포함)
  static Future<void> unlockFlower(String flowerId) async {
    List<String> collection = getCollectedFlowers();

    // 이미 있는 꽃이면 저장 안 함 (중복 방지)
    if (!collection.contains(flowerId)) {
      collection.add(flowerId);
      await _box.put('collectedFlowers', collection);
      print("🎉 도감 등록 완료: $flowerId");
    }
  }
}
