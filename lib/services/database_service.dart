import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static const String _boxName = "game_data";

  // 초기화
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  // 현재 포인트 가져오기
  static int getPoints() {
    return _box.get('points', defaultValue: 0);
  }

  // 오늘 퀘스트 완료 횟수 가져오기
  // 리셋할 때 꽃 새로 뽑기
  static int getQuestCount() {
    final now = DateTime.now();
    String todayKey = "${now.year}-${now.month}-${now.day}";
    String? savedDate = _box.get('lastQuestDate');

    if (savedDate != todayKey) {
      // 날짜가 바뀌었으면 초기화하면서 꽃도 새로 뽑기
      _box.put('questCount', 0);
      _box.put('lastQuestDate', todayKey);

      // 새로운 꽃 지정
      String newFlower = _generateRandomFlower();
      _box.put('todayFlowerType', newFlower);

      return 0;
    }
    return _box.get('questCount', defaultValue: 0);
  }

  // 랜덤 꽃 시스템

  // 오늘의 꽃 종류 가져오기
  static String getTodayFlowerType() {
    // 꽃 ID 가져오기
    String? savedType = _box.get('todayFlowerType');

    // 만약 저장된 게 없다면 랜덤으로 뽑
    if (savedType == null) {
      savedType = _generateRandomFlower();
      _box.put('todayFlowerType', savedType);
    }

    return savedType;
  }

  // 랜덤 뽑기 함수
  static String _generateRandomFlower() {
    List<String> flowerList = ['red_rose', 'yellow_rose', 'pink_rose'];

    // 랜덤으로 하나 뽑기
    int randomIndex = Random().nextInt(flowerList.length);
    return flowerList[randomIndex];
  }

  // 누적 횟수 가져오기
  static int getTotalQuests() {
    return _box.get('totalQuests', defaultValue: 0);
  }

  // 퀘스트 성공 시 처리
  static Future<void> completeQuest() async {
    int currentCount = getQuestCount();
    int currentPoints = getPoints();
    int totalQuests = getTotalQuests();

    final now = DateTime.now();
    String todayKey = "${now.year}-${now.month}-${now.day}";

    if (currentCount < 3) {
      await _box.put('questCount', currentCount + 1);
      await _box.put('lastQuestDate', todayKey);

      await _box.put('points', currentPoints + 100);
      await _box.put('totalQuests', totalQuests + 1);
    }
  }

  // 타이머 끝나는 시간 저장
  static Future<void> setTimerEndTime(DateTime endTime) async {
    await _box.put('timerEndTime', endTime.toIso8601String());
  }

  // 저장된 끝나는 시간 가져오기
  static DateTime? getTimerEndTime() {
    String? timeStr = _box.get('timerEndTime');
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  // 완료 시 타이머 정보 삭제
  static Future<void> clearTimer() async {
    await _box.delete('timerEndTime');
  }

  // 개발자용 리셋 함수 수정 (resetData)
  // static Future<void> resetData() async {
  //   await _box.clear();
  //   // 리셋 후에도 새로운 꽃 하나는 뽑아놔야 에러가 안 남
  //   String newFlower = _generateRandomFlower();
  //   await _box.put('todayFlowerType', newFlower);
  // }
  // --- 상점 & 아이템 시스템 ---

  // 내가 가진 아이템 목록 가져오기
  static List<String> getOwnedItems() {
    List<dynamic> rawList = _box.get('ownedItems', defaultValue: ['default']);
    return rawList.cast<String>();
  }

  // 현재 장착 중인 화분 ID 가져오기
  static String getEquippedPot() {
    return _box.get('equippedPot', defaultValue: 'default');
  }

  // 아이템 구매
  static Future<bool> buyItem(String itemId, int price) async {
    int myPoints = getPoints();

    if (myPoints < price) return false;

    await _box.put('points', myPoints - price);

    List<String> inventory = getOwnedItems();
    inventory.add(itemId);
    await _box.put('ownedItems', inventory);

    return true;
  }

  // 아이템 장착
  static Future<void> equipItem(String itemId) async {
    await _box.put('equippedPot', itemId);
  }

  // 모은 꽃 리스트
  static List<String> getCollectedFlowers() {
    List<dynamic> rawList = _box.get('collectedFlowers', defaultValue: []);
    return rawList.cast<String>();
  }

  // 꽃 도감에 추가
  static Future<void> unlockFlower(String flowerId) async {
    List<String> collection = getCollectedFlowers();

    if (!collection.contains(flowerId)) {
      collection.add(flowerId);
      await _box.put('collectedFlowers', collection);
      print("🎉 도감 등록 완료: $flowerId");
    }
  }
}
