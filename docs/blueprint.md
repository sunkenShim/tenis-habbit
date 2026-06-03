두 가지 핵심 축인 **Flutter UI 컴포넌트 구조**와 **개선된 Firebase 데이터 모델 및 보안 규칙**을 동시에 구체화하여, 바로 개발에 착수할 수 있는 완벽한 설계 도면을 만들어 드리겠습니다.

이 설계도를 바탕으로 코딩을 시작하면 시행착오를 제로에 가깝게 줄일 수 있습니다.

---

## 📱 1. 앱 아키텍처 및 화면 설계 (Flutter)

### 위젯 트리 구조 및 역할

| 위젯 클래스명 | 역할 및 UX UI 특징 |
| --- | --- |
| `MainNavigationScreen` | 하단 탭바를 통한 메인 내비게이션 관장 (통계, 회고, 히스토리 등). |
| `DailyReviewScreen` | 30초 마이크로 회고 입력 화면. (세션 태그, 컨디션, 체크리스트, 피드백) |
| `StatsDashboardScreen` | `fl_chart`를 활용한 데이터 시각화 화면. 주간 점수 추이 및 태그 분포 제공. |
| `HistoryTimelineScreen` | 과거 기록을 탐색할 수 있는 타임라인 뷰 (구현 예정). |

### 핵심 UX 컴포넌트
- **Haptic Feedback**: 점수 입력 및 버튼 터치 시 미세한 진동 제공.
- **Charts**: `LineChart` (점수 변화), `PieChart` (세션 비율).

---

## 🗄️ 2. Firebase Firestore 데이터 모델 구체화

### [Collection] `/users` (사용자 프로필)
```json
{
  "uid": "USER_UNIQUE_ID",
  "displayName": "테니스의길",
  "isPremium": false,
  "equipment": {
    "racket": "Wilson Pro Staff",
    "string": "Luxilon Alu Power",
    "tension": 52
  },
  "createdAt": "2026-06-02T17:36:53Z"
}
```

### [Sub-Collection] `/users/{uid}/tennis_logs` (개인 테니스 세션 일지)
```json
// Document ID: "2026-06-02"
{
  "date": "2026-06-02T00:00:00Z",
  "sessionTags": ["lesson", "hard_court"],
  "conditionScore": 4,
  "scores": {
    "chk_001": 3, // 스플릿 스텝 잘하기: 🔥 완벽함
    "chk_002": 1  // 라켓 던지기: 😥 아쉬움
  },
  "feedbackText": "오늘 백핸드 칠 때 라켓을 끝까지 던지지 못해서 네트에 많이 걸렸다.",
  "videoClipUrl": null // Scale-up 단계
}
```

---

## 🔒 3. Firestore 보안 규칙 (Security Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      
      match /tennis_logs/{logId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```
