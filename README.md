# PoseEstimation

スマホまたはブラウザのカメラ映像から人体骨格を推定し、関節座標をCSV/JSONとして保存するための実装です。

現在は2つの実装があります。

- `web_pose_capture_app/`: ブラウザで動くWeb版。すぐ試すならこちら。
- `pose_capture_app/`: FlutterでAndroid/iOS向けに作るモバイル版。

## Web版の動かし方

Web版はFlutterやNode.jsなしで起動できます。Pythonの簡易HTTPサーバーを使います。

```bash
cd /Users/nyoryorn/develop/PoseEstimation/web_pose_capture_app
python3 -m http.server 5173
```

ブラウザで開きます。

```text
http://127.0.0.1:5173
```

画面が開いたら、ブラウザのカメラ許可を承認してください。

操作:

- `Start`: 記録開始
- `Stop`: 記録停止
- `⇆`: 前面/背面カメラ切替
- `⤓`: 最後に記録したCSV/JSONをダウンロード

Web版は初回ロード時にMediaPipeのJS/WASMと姿勢推定モデルをCDNから取得します。インターネット接続が必要です。

## Flutter版の動かし方

Flutter版はAndroid/iOS実機向けです。この環境ではFlutter SDKが未インストールだったため、ネイティブ雛形の生成と実機検証は未実行です。

Flutterをインストールした環境で以下を実行してください。

```bash
cd /Users/nyoryorn/develop/PoseEstimation/pose_capture_app
flutter create --platforms=android,ios .
flutter pub get
flutter format .
flutter analyze
flutter test
```

Android/iOS端末で実行します。

```bash
flutter devices
flutter run
```

### Android設定

`android/app/src/main/AndroidManifest.xml` にカメラ権限が無い場合は追加します。

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS設定

`ios/Runner/Info.plist` にカメラ利用目的を追加します。

```xml
<key>NSCameraUsageDescription</key>
<string>骨格推定および動作計測のためにカメラを使用します。</string>
```

## 出力ファイル

記録停止後、以下の形式で保存・ダウンロードします。

- `pose_<session_id>.csv`
- `pose_<session_id>.json`

CSV列:

```text
session_id,timestamp_ms,frame_index,joint,x,y,z,confidence,image_width,image_height,camera_lens,rotation_deg
```

座標はカメラ画像基準で保存します。前面カメラの鏡像表示は画面描画だけに適用し、保存座標には混ぜません。

## 既知の制約

- 単眼カメラの `z` は相対的な奥行き推定値で、実距離ではありません。
- 照明、遮蔽、服装、カメラ位置、端末性能で推定品質が変わります。
- 医療診断用途ではなく、研究・検証用の座標記録アプリです。
- Web版はブラウザ、OS、カメラ権限設定の影響を受けます。
