# Flutter骨格推定・座標記録アプリ 実装計画

## 1. 目的

AndroidおよびiPhoneで動作するFlutterアプリを実装する。

スマホカメラ映像から人体骨格をリアルタイム推定し、関節座標を取得・画面表示・CSV保存できるようにする。主な対象は、リハビリ動作、起立着座、上肢挙上、歩行、および姿勢評価における骨格時系列データ収集である。

## 2. MVPのスコープ

### 実装する機能

- カメラプレビュー
- 前面／背面カメラ切替
- リアルタイム姿勢推定
- ML Kitの姿勢ランドマーク取得
- 骨格オーバーレイ描画
- 計測開始・停止
- フレーム単位の時刻記録
- CSVおよびセッションメタデータJSONの保存
- 保存ファイルの共有
- Android／iOS実機での動作確認

### MVPでは実装しない機能

- 複数人物の同時記録
- 動作分類・FIM推定
- ST-GCNの端末内推論
- WebSocket／FastAPI送信
- クラウド同期・アカウント機能
- 医療診断を目的とする評価
- バックグラウンド状態での連続計測

## 3. 技術スタック

- Flutter / Dart
- VS Code
- Android Studio（Android SDK・実機デバッグ）
- Xcode（iOS署名・実機デバッグ）
- Git

### 依存パッケージ

```yaml
dependencies:
  flutter:
    sdk: flutter

  camera: ^0.11.0+2
  google_mlkit_pose_detection: ^0.14.1
  path_provider: ^2.1.5
  csv: ^6.0.0
  permission_handler: ^12.0.0
  share_plus: ^10.1.4
  wakelock_plus: ^1.2.8
```

> 実装開始時に `flutter pub outdated` を実行し、Flutter SDKおよびiOS/Androidの互換性を満たす版へ調整すること。`^latest` は使用しない。

### パッケージの役割

| パッケージ | 用途 |
|---|---|
| `camera` | 利用可能カメラ取得、プレビュー、画像ストリーム |
| `google_mlkit_pose_detection` | 端末上での姿勢推定 |
| `path_provider` | アプリ専用保存先の取得 |
| `csv` | CSVデータの生成 |
| `permission_handler` | カメラ権限状態の確認 |
| `share_plus` | CSV／JSONの共有 |
| `wakelock_plus` | 計測中のスリープ抑止 |

## 4. 処理アーキテクチャ

```text
スマホカメラ
  ↓
CameraController.startImageStream()
  ↓
CameraImage
  ↓
InputImageへ変換（回転・フォーマット情報を保持）
  ↓
PoseDetector.processImage()
  ↓
Pose / PoseLandmark
  ↓
PoseFrameへ変換
  ├─ 骨格オーバーレイ表示
  ├─ 計測統計更新
  └─ CSV書き込みバッファへ蓄積
       ↓
     定期flush
       ↓
   CSV + metadata.json
```

### 設計原則

- 推論実行中は次フレームを破棄し、推論要求を積み上げない。
- カメラ入力、推論、描画、保存を別責務にする。
- CSVへの同期書き込みを毎フレーム行わない。
- 保存座標と画面描画用座標を分離する。
- 前面カメラの左右反転は描画のみに適用し、保存値はカメラ画像基準に統一する。
- 単眼姿勢推定の `z` は絶対距離ではなく、相対的な奥行き情報として扱う。

## 5. ディレクトリ構成

```text
lib/
  main.dart

  app/
    app.dart
    theme.dart

  features/
    capture/
      capture_page.dart
      capture_controller.dart
      capture_state.dart

    camera/
      camera_service.dart
      camera_config.dart
      input_image_converter.dart

    pose/
      pose_detector_service.dart
      pose_frame.dart
      pose_joint.dart
      pose_coordinate_converter.dart
      pose_overlay_painter.dart
      pose_connections.dart

    recording/
      recording_controller.dart
      recording_session.dart
      csv_writer.dart
      recording_paths.dart

    settings/
      settings_page.dart
      settings_state.dart

  shared/
    constants/
      pose_landmark_names.dart
    utils/
      session_id.dart
      timestamp_utils.dart
      logger.dart
    widgets/
      capture_control_bar.dart
      status_panel.dart
      pose_overlay.dart

test/
  pose_coordinate_converter_test.dart
  csv_writer_test.dart
  recording_controller_test.dart
```

## 6. データモデル

### `PoseJoint`

```dart
class PoseJoint {
  final String name;
  final double x;
  final double y;
  final double z;
  final double confidence;

  const PoseJoint({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });
}
```

### `PoseFrame`

```dart
class PoseFrame {
  final String sessionId;
  final int frameIndex;
  final int timestampMs;
  final int imageWidth;
  final int imageHeight;
  final bool isFrontCamera;
  final int rotationDegrees;
  final List<PoseJoint> joints;

  const PoseFrame({
    required this.sessionId,
    required this.frameIndex,
    required this.timestampMs,
    required this.imageWidth,
    required this.imageHeight,
    required this.isFrontCamera,
    required this.rotationDegrees,
    required this.joints,
  });
}
```

### `RecordingSession`

```dart
class RecordingSession {
  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String cameraLensDirection;
  final int imageWidth;
  final int imageHeight;
  final int totalFrames;
  final int detectedPoseFrames;
  final int savedRows;

  const RecordingSession({
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.cameraLensDirection,
    required this.imageWidth,
    required this.imageHeight,
    required this.totalFrames,
    required this.detectedPoseFrames,
    required this.savedRows,
  });
}
```

## 7. CSVおよびJSON仕様

### CSV形式（縦持ち）

```csv
session_id,timestamp_ms,frame_index,joint,x,y,z,confidence,image_width,image_height,camera_lens,rotation_deg
20260624_103015,1710000000000,0,leftShoulder,252.4,184.7,-32.1,0.95,1280,720,back,90
20260624_103015,1710000000000,0,leftElbow,278.9,251.3,-18.4,0.91,1280,720,back,90
```

### 保存ルール

- `timestamp_ms`: UNIX epoch milliseconds
- `frame_index`: カメラフレームの連番
- `x`, `y`: 元画像のピクセル座標
- `z`: 相対深度値。実距離として扱わない
- `confidence`: ランドマーク信頼度
- 欠損関節: 行を出力しない、または空欄／`NaN` とする。実装内で方式を統一する
- 描画時の反転座標を保存しない
- CSVのヘッダはセッションごとに必ず出力する

### メタデータJSON

```json
{
  "session_id": "20260624_103015",
  "started_at": "2026-06-24T10:30:15.000+09:00",
  "camera_lens": "back",
  "image_width": 1280,
  "image_height": 720,
  "pose_model": "base",
  "confidence_threshold": 0.5,
  "app_version": "0.1.0"
}
```

## 8. 実装フェーズ

### Phase 0: 環境構築

#### 作業

- Flutter SDK、Android SDK、Xcodeを確認する。
- VS CodeにFlutter/Dart拡張を導入する。
- Android実機とiPhone実機を認識させる。
- Gitリポジトリを初期化する。

#### コマンド

```bash
flutter doctor -v
flutter devices
flutter create pose_capture_app
cd pose_capture_app
code .
```

#### 完了条件

- `flutter doctor -v` に重大エラーがない。
- AndroidおよびiOSの少なくとも一方で標準Flutterアプリが起動する。
- 実機確認ができないプラットフォームはREADMEの制約へ記載する。

---

### Phase 1: プロジェクト初期化

#### 作業

- ディレクトリ構成を作成する。
- 依存パッケージを追加する。
- `analysis_options.yaml` を整備する。
- READMEにセットアップ、ビルド、実機実行手順を記載する。

#### 完了条件

```bash
flutter pub get
flutter analyze
flutter test
```

が成功する。

---

### Phase 2: カメラプレビュー

#### 作業

- 利用可能カメラを取得する。
- 背面カメラをデフォルトにする。
- `CameraController` を初期化する。
- `CameraPreview` を表示する。
- 前面／背面カメラ切替を実装する。
- ライフサイクル変更でカメラを安全に停止・再初期化する。
- カメラ利用不可・権限拒否を画面表示する。

#### 完了条件

- Android/iOSでカメラプレビューが表示される。
- カメラ切替後にクラッシュしない。
- バックグラウンド遷移後の復帰で状態が破綻しない。

---

### Phase 3: ML Kit姿勢推定

#### 作業

- `PoseDetector` をストリームモードで初期化する。
- Camera image streamから `InputImage` を作成する。
- 画像回転・プラットフォーム別フォーマットを正しく扱う。
- `processImage()` を実行し、姿勢ランドマークを `PoseFrame` に変換する。
- Detectorは画面破棄時に必ず `close()` する。
- 推論中フラグにより、未完了の推論がある場合は新規フレームを破棄する。

#### 擬似コード

```dart
if (_isProcessing) return;

_isProcessing = true;
try {
  final inputImage = inputImageConverter.convert(cameraImage);
  final poses = await poseDetector.processImage(inputImage);
  final poseFrame = poseMapper.toPoseFrame(poses, cameraMetadata);
  controller.onPoseFrame(poseFrame);
} finally {
  _isProcessing = false;
}
```

#### 完了条件

- 主要関節（肩、肘、手首、股、膝、足首）の座標を取得できる。
- 数分の連続処理でメモリが増え続けない。
- 人物未検出のフレームを例外ではなく通常ケースとして扱う。

---

### Phase 4: 骨格オーバーレイ

#### 作業

- `CustomPainter` で関節点・骨格リンクを描画する。
- 入力画像座標からプレビュー座標への変換を実装する。
- アスペクト比、回転、前面カメラの表示反転を正しく扱う。
- 推論FPS、検出状態、フレーム番号を表示する。

#### 最低限の骨格リンク

```text
leftShoulder - leftElbow - leftWrist
rightShoulder - rightElbow - rightWrist
leftShoulder - rightShoulder
leftShoulder - leftHip
rightShoulder - rightHip
leftHip - rightHip
leftHip - leftKnee - leftAnkle
rightHip - rightKnee - rightAnkle
```

#### 完了条件

- 関節点と骨格が人物に追従する。
- 前面カメラでは視覚的に自然な鏡像表示となる。
- 保存される座標には鏡像変換が混入しない。
- 端末回転で著しい描画ずれが起きない。

---

### Phase 5: 計測制御

#### 作業

- 開始・停止ボタンを実装する。
- `yyyyMMdd_HHmmss` 形式のセッションIDを生成する。
- 計測時間、フレーム数、検出成功率を表示する。
- 計測中は画面スリープを抑止する。
- 停止時、保留中の書き込みデータをflushする。

#### 完了条件

- 連続して複数セッションを記録できる。
- 停止後にセッションが確実に閉じられる。
- 途中でアプリが中断された場合でも、可能な範囲でバッファを保存する。

---

### Phase 6: CSV保存

#### 作業

- CSVヘッダを出力する。
- `PoseFrame` をCSV行へ展開する。
- メモリバッファへ蓄積する。
- 1秒ごと、または30〜120フレームごとに非同期flushする。
- 停止時に最終flushする。
- メタデータJSONも同時に保存する。
- 保存完了後に共有機能を提供する。

#### 完了条件

- 10秒の計測でCSVとJSONが生成される。
- Python/PandasでCSVを読める。
- 欠損関節があってもCSV構造が壊れない。
- 保存失敗時にユーザー向けのエラーを表示する。

---

### Phase 7: 座標正規化（MVP後の優先拡張）

#### 作業

以下を生座標とは別に算出できるようにする。

```text
raw_x, raw_y, raw_z
norm_x, norm_y, norm_z
body_x, body_y, body_z
```

#### 前処理案

1. `x`, `y` を画像幅・高さで `[0, 1]` に正規化する。
2. 左右Hipの中点を骨盤中心として求める。
3. 骨盤中心を原点化する。
4. 肩幅または胴体長でスケール正規化する。
5. 低信頼度関節をフラグ付けする。
6. 欠損補間・平滑化はモバイル側ではなく、まずPythonの後処理で再現可能にする。

#### 完了条件

- 正規化ロジックにユニットテストがある。
- 同一姿勢を異なる撮影距離で撮影した際、スケール差が低減される。
- 単眼推定の相対深度をKinectの絶対3D座標として扱わない。

---

### Phase 8: 実機性能評価

#### 評価指標

| 指標 | 内容 |
|---|---|
| Pose FPS | 姿勢推定成功回数/秒 |
| Camera FPS | CameraImage受信回数/秒 |
| 検出成功率 | Pose検出フレーム数/総フレーム数 |
| 関節有効率 | 信頼度閾値以上の関節比率 |
| 推論遅延 | 入力から表示までの概算時間 |
| 保存欠損 | CSVへ保存されなかったフレーム数 |
| 電池消費 | 10分、30分計測時の低下量 |
| 発熱 | 長時間動作に伴うFPS低下 |

#### テスト条件

- Android端末 1台以上
- iPhone端末 1台以上
- 前面カメラ／背面カメラ
- 明るい室内／逆光
- 着座、起立、上肢挙上、足踏みまたは歩行
- 10秒、1分、10分の連続計測

#### MVP受入基準

- 15 FPS以上の姿勢推定を安定して維持できる。
- 10秒以上のCSV記録を完了できる。
- 肩、肘、手首、股、膝、足首を概ね追跡できる。
- Android/iOSでクラッシュしない。
- CSVをPython/Pandasで読み込める。

## 9. プラットフォーム設定

### Android

`android/app/src/main/AndroidManifest.xml` にカメラ権限を追加する。

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

保存先はアプリ専用領域を採用し、不要なストレージ権限を要求しない。

### iOS

`ios/Runner/Info.plist` に追加する。

```xml
<key>NSCameraUsageDescription</key>
<string>骨格推定および動作計測のためにカメラを使用します。</string>
```

## 10. エラーハンドリング

以下を明示的に扱う。

- カメラ権限拒否
- カメラ未搭載・使用中
- カメラ初期化失敗
- ML Kit初期化・推論失敗
- 人物未検出
- 保存ディレクトリ取得失敗
- CSV／JSON書き込み失敗
- アプリ中断・ライフサイクル変更
- 低メモリ・長時間計測時の処理低下
- 端末回転・カメラ切替に伴う座標変換不整合

ユーザー表示は簡潔なメッセージとし、詳細は開発ログに残す。

## 11. テスト方針

### ユニットテスト

- セッションID生成
- CSVヘッダ・行生成
- 座標正規化
- 骨盤中心・肩幅算出
- 信頼度閾値判定
- バッファflush条件
- 入力画像から描画座標への変換

### Widgetテスト

- 開始／停止ボタン状態
- 計測時間表示
- エラー表示
- カメラ切替ボタン
- 記録中ステータス

### 実機テスト

- カメラプレビュー
- 姿勢推定
- 骨格表示
- CSV保存
- CSV共有
- 長時間計測
- Android/iOS差異

## 12. Codexへの実装指示

1. 既存リポジトリの構成、依存関係、コード規約を確認する。
2. 既存コードを破壊せず、必要な機能を小さなコミット単位で実装する。
3. Phase 2から順に進め、各Phaseの完了条件を満たしてから次へ進む。
4. 新規依存パッケージは、追加前に既存Flutter SDKとの互換性を確認する。
5. `^latest` を追加しない。解決済みの具体的なバージョンを利用する。
6. UIの状態管理は、既存方式がなければ最初は `ChangeNotifier` または `ValueNotifier` を優先し、必要性が明確になってからRiverpod等を導入する。
7. 推論処理中のフレーム投入を防ぎ、フレームキューが無制限に増えないことを保証する。
8. Detector、CameraController、StreamSubscription、ファイルハンドルは必ず解放する。
9. 実機依存のため自動検証できない箇所は、READMEに検証手順とTODOを記載する。
10. 実装後は必ず以下を実行し、結果を報告する。

```bash
flutter format .
flutter analyze
flutter test
```

## 13. Definition of Done

以下をすべて満たした時点でMVP完了とする。

- Androidでカメラプレビューが動作する。
- iPhoneでカメラプレビューが動作する。
- リアルタイム姿勢推定が動作する。
- 骨格オーバーレイが人物に追従する。
- 計測開始・停止が動作する。
- CSVおよびメタデータJSONがアプリ領域に保存される。
- CSVにセッションID、時刻、フレーム番号、関節名、座標、信頼度が含まれる。
- CSVをPython/Pandasで読み込める。
- `flutter analyze` と `flutter test` が成功する。
- 10秒以上の連続計測でクラッシュしない。
- READMEにセットアップ手順、実行方法、既知制約が記載されている。

## 14. 既知の制約

- 単眼カメラの姿勢推定座標はKinectの絶対3D座標と異なる。
- `z` は実距離・深度センサ値ではなく、相対的な奥行きの推定値である。
- 照明、遮蔽、服装、カメラ位置、端末性能、画角により推定品質が変化する。
- リハビリ評価や医療診断に利用する場合は、別途妥当性評価・倫理・安全設計が必要である。
- ML Kitの実効FPSは端末性能およびモデル選択に依存するため、各実機で測定する。
