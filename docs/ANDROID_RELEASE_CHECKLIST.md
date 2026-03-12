# Android Release 签名与发布清单

## 目标

从当前 debug keystore 回退模式切换到正式 release 签名，并保留现有构建命令。

## 1. 准备签名材料

需要以下四项：

- keystore 文件路径
- `storePassword`
- `keyAlias`
- `keyPassword`

仓库内不会存放真实签名材料。

## 2. 提供签名配置

可选方案一：本地文件 `apps/client/android/key.properties`

参考模板：

```properties
storeFile=/absolute/path/to/release-keystore.jks
storePassword=change-me
keyAlias=overview
keyPassword=change-me
```

可选方案二：环境变量

```bash
export OVERVIEW_ANDROID_STORE_FILE=/absolute/path/to/release-keystore.jks
export OVERVIEW_ANDROID_STORE_PASSWORD=...
export OVERVIEW_ANDROID_KEY_ALIAS=overview
export OVERVIEW_ANDROID_KEY_PASSWORD=...
```

说明：

- `build.gradle.kts` 会优先读取 `key.properties`
- 若 `key.properties` 缺失，则回退读取 `OVERVIEW_ANDROID_*` 环境变量
- 若以上两类配置都缺失，release 构建会继续使用 debug keystore，仅适合安装验证

## 3. 构建命令

```bash
cd apps/client
/home/anon/sdk/flutter/bin/flutter build apk --release --no-pub
```

产物路径：

- `apps/client/build/app/outputs/flutter-apk/app-release.apk`

## 4. 发布前检查

可先运行：

```bash
npm run android:release:check
```

该脚本会统一检查：

- 正式签名材料是否齐全
- keystore 文件是否可读
- 当前 release APK 是否已存在
- 当前 APK 的 `sha256`
- `adb` 与 Android 真机是否已连接

- 已填入正式签名材料，而不是依赖 debug keystore 回退
- `flutter analyze` 通过
- `flutter test` 通过
- `flutter build apk --release --no-pub` 通过
- 记录 APK 的 `sha256`
- 至少完成一次真机安装验证
- 确认后端地址、AI 配置和发布环境说明已同步

## 5. 当前仓库已知状态

- 2026-03-12 已验证 release APK 可生成
- 2026-03-12 已验证在无正式签名材料时会自动回退 debug keystore
- 2026-03-12 已新增 `npm run android:release:check`，可自动检查签名材料与真机连接就绪度
- 2026-03-12 已再次验证 release APK 可生成，当前 `app-release.apk sha256=55cc8e46e338cb3f7c60e42ab9a19d2c84523f4a375549390c0d904ccf12c6a7`
- 正式 keystore 与发布渠道信息尚未进入仓库
