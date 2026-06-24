# Web Pose Capture App

ブラウザだけで動く骨格推定・CSV記録アプリです。Flutter版とは別実装で、Webでは MediaPipe Pose Landmarker を使います。

## 方針

- カメラ入力: `navigator.mediaDevices.getUserMedia`
- 姿勢推定: MediaPipe `@mediapipe/tasks-vision`
- 描画: `<canvas>`
- 保存: ブラウザ上でCSV/JSONを生成してダウンロード
- Webでは前面カメラの鏡像は表示だけに適用し、CSV座標は元動画基準で保存

## 起動

カメラ利用には `localhost` か HTTPS が必要です。ローカルファイルを直接開くのではなく、簡易サーバーで起動します。

```bash
cd web_pose_capture_app
python3 -m http.server 5173
```

ブラウザで開きます。

```text
http://localhost:5173
```

## 出力

停止後にダウンロードボタンから以下を保存します。

- `pose_<session_id>.csv`
- `pose_<session_id>.json`

CSV列:

```text
session_id,timestamp_ms,frame_index,joint,x,y,z,confidence,image_width,image_height,camera_lens,rotation_deg
```

## 注意

- 初回ロード時にMediaPipeのJS/WASMとモデルをCDNから取得します。
- Safari/iOSではカメラ許可、HTTPS/localhost、端末性能の影響が大きいです。
- Web版の `z` はMediaPipe Pose Landmarkerの相対的な奥行き値として扱います。
- 複数人物、クラウド同期、医療診断用途の評価は含めていません。
