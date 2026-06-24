# Audio Signal Plot App

スマホブラウザでマイク音声をリアルタイム表示するWebアプリです。音声入力をWeb Audio APIで取得し、Canvasに波形と周波数スペクトラムを描画します。

## 起動

初回は `uv` で仮想環境を作成します。

```bash
cd audio_signal_plot_app
uv venv .venv --python python3
uv sync
```

マイク利用には `localhost` か HTTPS が必要です。ローカルファイルを直接開くのではなく、簡易サーバーで起動します。

```bash
cd audio_signal_plot_app
uv run python -m http.server 5174
```

ブラウザで開きます。

```text
http://localhost:5174
```

## スマホで試す場合

- 画面確認だけなら、同じWi-Fiのスマホで `http://PCのIPアドレス:5174` を開けます。
- スマホ実機でマイクを使う場合はHTTPS配信が必要です。
- ホーム画面に追加すると、PWA風に単独画面で起動できます。

PCのIPアドレスはMacなら以下のどちらかで確認できます。

```bash
ipconfig getifaddr en0
ifconfig en0
```

同じWi-Fiのスマホから画面だけ確認する場合:

```bash
cd audio_signal_plot_app
uv run python -m http.server 5174 --bind 0.0.0.0
```

スマホで以下を開きます。

```text
http://PCのIPアドレス:5174
```

マイク入力まで使う場合は、証明書を用意してHTTPSで配信します。例:

```bash
cd audio_signal_plot_app
mkcert -key-file localhost-key.pem -cert-file localhost-cert.pem localhost 127.0.0.1 ::1 PCのIPアドレス
uv run python serve_https.py --host 0.0.0.0 --port 5174
```

スマホで以下を開きます。

```text
https://PCのIPアドレス:5174
```

`mkcert` のルート証明書をスマホ側でも信頼させる必要があります。iPhoneでは構成プロファイルとしてインストール後、証明書信頼設定を有効にします。Androidではユーザー証明書としてインストールします。

## 機能

- リアルタイム波形プロット
- リアルタイム周波数スペクトラム
- RMS/Peakメーター
- 表示ゲイン調整
- FFTサイズ切り替え
- 一時停止と停止

## 注意

- 端末やブラウザによって、マイク入力にはノイズ抑制や自動ゲインが残る場合があります。
- このアプリは音声の可視化用です。録音ファイルの保存や音声解析の診断機能は含めていません。
