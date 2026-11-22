#!/bin/zsh
set -e
VERSION="1.1.0"

# 1. 既存プロセスの停止と前回ビルド物の削除
pkill -f "rickroll.app/Contents/MacOS/applet" 2>/dev/null || true
killall player 2>/dev/null || true
sleep 0.3
rm -rf rickroll.app StopWatcher.app UninstallWatcher.app \
  watcher.png stop.png uninstall.png \
  watcher.iconset stop.iconset uninstall.iconset \
  watcher.icns stop.icns uninstall.icns \
  pkg_root pkg_scripts component.plist component.pkg distribution.xml RickrollInstaller-v${VERSION}.pkg \
  /tmp/rickroll.log

# 2. 本体アプリとボーダーレスプレイヤーのビルド
osacompile -s -o rickroll.app main.applescript
swiftc player.swift -o rickroll.app/Contents/Resources/player

# 3. リソース配置とInfo.plist設定（Dock非表示・固有ID付与）
# 3. 動画の自動取得（キャッシュがなければダウンロード）とリソース配置
VIDEO_URL="https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# 3. 動画の自動取得（uv環境にも対応）とリソース配置
VIDEO_URL="https://youtube.com"
export PATH="$HOME/.local/bin:$PATH"

if [ ! -f "rickroll.mp4" ]; then
  if [ -f "$HOME/Movies/rickroll.mp4" ]; then
    cp "$HOME/Movies/rickroll.mp4" rickroll.mp4
  elif command -v yt-dlp >/dev/null 2>&1; then
    yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4" --merge-output-format mp4 -o "rickroll.mp4" "$VIDEO_URL"
  elif command -v uv >/dev/null 2>&1; then
    echo "Downloading rickroll.mp4 via uv..."
    uv run yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4" --merge-output-format mp4 -o "rickroll.mp4" "$VIDEO_URL" 2>/dev/null || \
    uvx yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4" --merge-output-format mp4 -o "rickroll.mp4" "$VIDEO_URL"
  else
    echo "Error: rickroll.mp4 not found. Install yt-dlp or place rickroll.mp4 in this folder."
    exit 1
  fi
fi

cp config.json rickroll.app/Contents/Resources/
cp rickroll.mp4 rickroll.app/Contents/Resources/

plutil -replace LSUIElement -bool true rickroll.app/Contents/Info.plist
plutil -replace CFBundleIdentifier -string "local.dev.rickroll.watcher" rickroll.app/Contents/Info.plist
plutil -replace CFBundleShortVersionString -string "$VERSION" rickroll.app/Contents/Info.plist

# 4. 停止用アプリの生成
osacompile -s -o StopWatcher.app StopWacher.applescript
plutil -replace CFBundleIdentifier -string "local.dev.rickroll.stopper" StopWatcher.app/Contents/Info.plist
plutil -replace CFBundleShortVersionString -string "$VERSION" StopWatcher.app/Contents/Info.plist

# 5. アンインストール用アプリの生成
osacompile -s -o UninstallWatcher.app Uninstaller.applescript
plutil -replace CFBundleIdentifier -string "local.dev.rickroll.uninstaller" UninstallWatcher.app/Contents/Info.plist
plutil -replace CFBundleShortVersionString -string "$VERSION" UninstallWatcher.app/Contents/Info.plist

# 6. Configure.app の生成（config.json を開いて再起動で反映）
# Configure.app の生成（外部の config.json を開いて再起動で反映）
# Configure.app の生成（100% ASCII記述・外部 config.json 編集＆リロード）
osacompile -o Configure.app Configure.applescript
plutil -replace CFBundleIdentifier -string "local.dev.rickroll.configure" Configure.app/Contents/Info.plist
plutil -replace CFBundleShortVersionString -string "$VERSION" Configure.app/Contents/Info.plist

# 7. アイコンの生成と変換（.png -> .iconset -> .icns）
swift make_icon.swift
for name in watcher stop uninstall; do
  mkdir -p "${name}.iconset"
  for sz in 16 32 128 256 512; do
    sips -z $sz $sz "${name}.png" --out "${name}.iconset/icon_${sz}x${sz}.png" >/dev/null
    sz2=$((sz * 2))
    sips -z $sz2 $sz2 "${name}.png" --out "${name}.iconset/icon_${sz}x${sz}@2x.png" >/dev/null
  done
  iconutil -c icns "${name}.iconset"
done

# 8. Info.plistへのアイコン登録
cp watcher.icns rickroll.app/Contents/Resources/custom.icns
cp stop.icns StopWatcher.app/Contents/Resources/custom.icns
cp uninstall.icns UninstallWatcher.app/Contents/Resources/custom.icns
plutil -replace CFBundleIconFile -string "custom" rickroll.app/Contents/Info.plist
plutil -replace CFBundleIconFile -string "custom" StopWatcher.app/Contents/Info.plist
plutil -replace CFBundleIconFile -string "custom" UninstallWatcher.app/Contents/Info.plist
plutil -replace CFBundleIconFile -string "custom" Configure.app/Contents/Info.plist

# 9. コード署名（カスタムアイコン属性付与の前に実行）
codesign --force --deep --sign - rickroll.app
codesign --force --deep --sign - StopWatcher.app
codesign --force --deep --sign - UninstallWatcher.app
codesign --force --deep --sign - Configure.app

# 10. Finderアイコンキャッシュの強制上書きと一時ファイル削除
swift -e 'import Cocoa; NSWorkspace.shared.setIcon(NSImage(contentsOfFile: "watcher.icns"), forFile: "rickroll.app", options: []); NSWorkspace.shared.setIcon(NSImage(contentsOfFile: "stop.icns"), forFile: "StopWatcher.app", options: []); NSWorkspace.shared.setIcon(NSImage(contentsOfFile: "uninstall.icns"), forFile: "UninstallWatcher.app", options: [])'
rm -rf watcher.png stop.png uninstall.png watcher.iconset stop.iconset uninstall.iconset watcher.icns stop.icns uninstall.icns

# 11. 管理者権限不要・使い方表示付きの .pkg 生成
mkdir -p pkg_root pkg_scripts pkg_resources
cp -R rickroll.app Configure.app StopWatcher.app UninstallWatcher.app pkg_root/

# 4つのアプリすべての再配置（Relocatable）を無効化
pkgbuild --analyze --root pkg_root component.plist
for idx in 0 1 2 3; do
  /usr/libexec/PlistBuddy -c "Set :${idx}:BundleIsRelocatable false" component.plist
done

# インストーラーに表示する使い方HTMLを作成
cat << 'EOF' > pkg_resources/readme.html
<!DOCTYPE html>
<html lang="ja">
<head><meta charset="utf-8"><style>
  body { font-family: -apple-system, sans-serif; font-size: 13px; line-height: 1.6; color: #222; }
  h2 { font-size: 15px; border-bottom: 1px solid #ccc; padding-bottom: 4px; }
  code { background: #f2f2f2; padding: 2px 5px; border-radius: 4px; }
</style></head>
<body>
  <h2>インストール内容（~/Applications）</h2>
  <p>パスワード不要でユーザー専用のアプリケーションフォルダに以下が配置されます。</p>
  <ul>
    <li><b>rickroll.app</b>：バックグラウンド監視本体（インストール後に自動起動）</li>
    <li><b>Configure.app</b>：監視先フォルダや再生間隔（<code>config.json</code>）の編集・反映</li>
    <li><b>StopWatcher.app</b>：監視と再生の一時停止</li>
    <li><b>UninstallWatcher.app</b>：完全削除（アンインストール）</li>
  </ul>
  <h2>操作方法</h2>
  <ul>
    <li><b>全画面再生の解除</b>：<code>Shift + Esc</code> キーで終了します。</li>
    <li><b>初回のみ</b>：「Finderの制御を求めています」と表示されたら「OK」を押してください。</li>
  </ul>
</body>
</html>
EOF

cat << 'EOF' > pkg_scripts/postinstall
#!/bin/zsh
open "$HOME/Applications/rickroll.app"
exit 0
EOF
chmod +x pkg_scripts/postinstall

pkgbuild \
  --root pkg_root \
  --component-plist component.plist \
  --scripts pkg_scripts \
  --identifier "local.dev.rickroll.pkg" \
  --version "$VERSION" \
  --install-location "/Applications" \
  component.pkg

cat << EOF > distribution.xml
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>Rickroll Watcher v${VERSION}</title>
    <readme file="readme.html"/>
    <options customize="never" require-scripts="false"/>
    <domains enable_anywhere="false" enable_currentUserHome="true" enable_localSystem="false"/>
    <pkg-ref id="local.dev.rickroll.pkg"/>
    <options rootVolumeOnly="false"/>
    <choices-outline>
        <line choice="default">
            <line choice="local.dev.rickroll.pkg"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="local.dev.rickroll.pkg" visible="false">
        <pkg-ref id="local.dev.rickroll.pkg"/>
    </choice>
    <pkg-ref id="local.dev.rickroll.pkg" version="${VERSION}" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
EOF

productbuild \
  --distribution distribution.xml \
  --resources pkg_resources \
  --package-path . \
  "RickrollInstaller-v${VERSION}.pkg"

rm -rf pkg_root pkg_scripts pkg_resources component.plist component.pkg distribution.xml

# 12. インストーラーの署名（Apple Developer ID で署名する場合は --sign オプションを追加）
codesign --force --deep --sign - RickrollInstaller-v${VERSION}.pkg

# 13. インストーラーの圧縮 (tar)
tar -czf RickrollInstaller.tar.gz RickrollInstaller-v${VERSION}.pkg

# 14. 起動とログ確認
open rickroll.app
for i in {1..25}; do
  [ -f /tmp/rickroll.log ] && break
  sleep 0.2
done
cat /tmp/rickroll.log
echo "Done: RickrollInstaller-v${VERSION}.pkg"
