        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Raw 데이터 입력"
        android:gravity="top"
        android:lines="4"
        android:layout_marginBottom="12dp"/>

    <Button
        android:id="@+id/btnInjectCustom"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="지정한 포맷으로 클립보드 복사"
        android:layout_marginBottom="16dp"/>

    <View 
        android:layout_width="match_parent" 
        android:layout_height="1dp" 
        android:background="#CCCCCC" 
        android:layout_marginBottom="16dp"/>

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="2. 클립보드 종합 인스펙터"
        android:textStyle="bold"
        android:textSize="16sp"
        android:layout_marginBottom="8dp"/>

    <Button
        android:id="@+id/btnInspectAll"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="현재 클립보드 정보 실시간 파싱"
        android:layout_marginBottom="12dp"/>

    <ScrollView
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:background="#EFEFEF"
        android:padding="8dp">

        <TextView
            android:id="@+id/tvInspectorOutput"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="분석 버튼을 누르면 상세 스펙이 출력됩니다."
            android:fontFamily="monospace"
            android:textSize="13sp"/>
    </ScrollView>

</LinearLayout>
EOF

# 7. MainActivity.kt 생성 (비즈니스 로직 전체 코드)
cat << 'EOF' > $HOME/CustomClipHub/app/src/main/java/com/example/customcliphub/MainActivity.kt
package com.example.customcliphub

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private lateinit var spPresets: Spinner
    private lateinit var etMimeType: EditText
    private lateinit var etRawData: EditText
    private lateinit var btnInjectCustom: Button
    private lateinit var btnInspectAll: Button
    private lateinit var tvInspectorOutput: TextView

    private val presets = arrayOf("직접 입력 (프리셋 없음)", "Application/JSON", "Text/CSV", "Text/XML", "Text/HTML")
    private val mimeTypes = arrayOf("", "application/json", "text/csv", "text/xml", "text/html")
    private val sampleData = arrayOf(
        "",
        "{\n  \"user_id\": 12345,\n  \"platform\": \"Android\",\n  \"environment\": \"Termux\"\n}",
        "id,platform,environment\n12345,Android,Termux",
        "<clipboard>\n  <id>12345</id>\n  <platform>Android</platform>\n</clipboard>",
        "<h1>Termux Build</h1>\n<p>This is a <b>custom</b> HTML snippet.</p>"
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        spPresets = findViewById(R.id.spPresets)
        etMimeType = findViewById(R.id.etMimeType)
        etRawData = findViewById(R.id.etRawData)
        btnInjectCustom = findViewById(R.id.btnInjectCustom)
        btnInspectAll = findViewById(R.id.btnInspectAll)
        tvInspectorOutput = findViewById(R.id.tvInspectorOutput)

        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, presets)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        spPresets.adapter = adapter

        spPresets.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                if (position > 0) {
                    etMimeType.setText(mimeTypes[position])
                    etRawData.setText(sampleData[position])
                }
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }

        btnInjectCustom.setOnClickListener {
            val customMime = etMimeType.text.toString().trim()
            val rawData = etRawData.text.toString()

            if (customMime.isEmpty() || rawData.isEmpty()) {
                Toast.makeText(this, "MIME 타입과 Raw 데이터를 모두 입력해주세요.", Toast.LENGTH_SHORT).show()
            } else {
                injectCustomMimeData(customMime, rawData)
            }
        }

        btnInspectAll.setOnClickListener {
            inspectAllClipboardInfo()
        }
    }

    private fun injectCustomMimeData(mimeType: String, rawData: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val mimeTypesArray = arrayOf(mimeType)
        val description = ClipDescription("Custom_Raw_Template", mimeTypesArray)
        val item = ClipData.Item(rawData)
        val clipData = ClipData(description, item)
        clipboard.setPrimaryClip(clipData)
        Toast.makeText(this, "[$mimeType] 타입으로 Raw 데이터가 주입되었습니다.", Toast.LENGTH_SHORT).show()
    }

    private fun inspectAllClipboardInfo() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        if (!clipboard.hasPrimaryClip()) {
            tvInspectorOutput.text = "현재 클립보드가 비어 있습니다."
            return
        }

        val clip = clipboard.primaryClip
        val description = clip?.description
        val resultBuilder = StringBuilder()

        resultBuilder.append("■■■ 클립보드 메타데이터 분석 ■■■\n")
        resultBuilder.append("• 라벨(Label): ${description?.label ?: "없음"}\n")
        resultBuilder.append("• 등록된 포맷 종류 (MIME Types):\n")
        val mimeCount = description?.mimeTypeCount ?: 0
        for (i in 0 until mimeCount) {
            resultBuilder.append("  └ [$i] : ${description?.getMimeType(i)}\n")
        }

        resultBuilder.append("\n■■■ 내부 실측 Raw 데이터 분석 ■■■\n")
        val itemCount = clip?.itemCount ?: 0
        for (i in 0 until itemCount) {
            val item = clip?.getItemAt(i)
            resultBuilder.append("[Item Index: $i]\n")

            if (item != null) {
                if (item.text != null) {
                    resultBuilder.append("  • Raw Text 본문:\n")
                    resultBuilder.append("----------------------------------------\n")
                    resultBuilder.append("${item.text}\n")
                    resultBuilder.append("----------------------------------------\n")
                } else {
                    resultBuilder.append("  • Raw Text 본문: 없음\n")
                }

                if (item.htmlText != null) {
                    resultBuilder.append("  • HTML Raw Source:\n${item.htmlText}\n")
                }

                if (item.uri != null) {
                    resultBuilder.append("  • 연동된 Content URI: ${item.uri}\n")
                }
            }
        }
        tvInspectorOutput.text = resultBuilder.toString()
    }
}
EOF

# 8. AndroidManifest.xml 생성
cat << 'EOF' > $HOME/CustomClipHub/app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.customcliphub">

    <application
        android:allowBackup="true"
        android:label="CustomClipHub"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

echo "==> [성공] CustomClipHub 전량 소스코드 구축 완료!"
ls
cd
ls
cd Cus*
ls
cd ..
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk
wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
pkg install wget
wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
ls
cd ..
ls
rm -rf androi*
ls
pkg install commandlinetools
commandlinetools
apt update && apt upgrade -y
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
wget https://google.com -O cmdline-tools.zip
unzip cmdline-tools.zip
ls
unzip cmdline-tools.zip
# Delete the corrupted zip file
rm -f ~/android-sdk/cmdline-tools/cmdline-tools.zip
# Navigate to your tools directory
cd ~/android-sdk/cmdline-tools
# Re-download using the stable Google repository link
wget https://google.com -O cmdline-tools.zip
unzip cmdline-tools.zip
# 1. Delete the incorrect HTML file
rm -f cmdline-tools.zip
# 2. Download the ACTUAL Android SDK zip file (Note the full URL)
wget https://google.com -O cmdline-tools.zip
# 3. Unzip the real archive
unzip cmdline-tools.zip
pkg install git wget curl zsh vim build-essential -y
pkg install platform-tools
termuxsdk
termux-sdk
android
sdk
cd
cd and*
ls
wget https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip
ls
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk
unzip commandlinetools-linux-14742923_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/
ls
cd cmd*
ls
cd
# 1. 새 프로젝트 폴더 진입
cd $HOME/CustomClipHub
# 2. 안드로이드 SDK 경로 초기화 연결
export ANDROID_HOME=$HOME/android-sdk
# 3. 그레이들 디버그 빌드 개시!
gradle assembleDebug
pkg install gradle
gradle assembleDebug
cat << 'EOF' > $HOME/CustomClipHub/build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.2.2"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22"
    }
}

// 에러를 유발하던 allprojects { repositories { ... } } 블록을 완전 삭제함
EOF

# 1. 프로젝트 폴더로 이동
cd $HOME/CustomClipHub
# 2. 빌드 재시작
gradle assembleDebug
# 1. 안드로이드 SDK 경로 설정
export ANDROID_HOME=$HOME/android-sdk
# 2. sdkmanager 위치를 자동으로 찾아 모든 라이선스 일괄 승인
SDK_MANAGER=$(find $ANDROID_HOME -name "sdkmanager" -type f | head -n 1)
if [ -n "$SDK_MANAGER" ]; then     echo "==> sdkmanager 발견: $SDK_MANAGER";     yes | $SDK_MANAGER --licenses;     echo "==> [성공] 모든 안드로이드 SDK 라이선스 동의 완료!"; else     echo "==> [경고] sdkmanager를 찾지 못했습니다. 임시 라이선스 폴더를 강제 생성합니다.";     mkdir -p $ANDROID_HOME/licenses;     echo -e "\n8933bad161d7a78b827b11c62d7475c19a0fc46d\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license; fi
# 3. 프로젝트 폴더로 이동 후 최종 빌드 슛!
cd $HOME/CustomClipHub
gradle assembleDebug
# 1. 안드로이드 SDK 라이선스 폴더 강제 생성
export ANDROID_HOME=$HOME/android-sdk
mkdir -p $ANDROID_HOME/licenses
# 2. 구글 공식 안드로이드 SDK 라이선스 해시값 직접 주입 (검문소 프리패스)
echo -e "8933bad161d7a78b827b11c62d7475c19a0fc46d\n24333f8a63b6825ea9c5514f83c2829b004d1fee\ned0d0a5bde5169da3b10b88e991110db56412610" > $ANDROID_HOME/licenses/android-sdk-license
# 3. 혹시 모를 프리뷰 버전을 위한 라이선스 해시값 주입
echo -e "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license
# 4. 주입 결과 검증 (파일이 정상적으로 구워졌는지 확인)
echo "==> 생성된 라이선스 파일 확인:"
ls -l $ANDROID_HOME/licenses
# 5. 프로젝트 폴더로 이동 후 최종 빌드 다시 달리기!
cd $HOME/CustomClipHub
gradle assembleDebug
# 1. 프로젝트 폴더로 진입
cd $HOME/CustomClipHub
# 2. 글로벌 그레이들을 시켜서 이 프로젝트 전용 'Gradle 8.5 엔진(래퍼)'을 강제 생성
gradle wrapper --gradle-version 8.5
# 1. 방금 생성된 gradlew 파일에 실행 권한 부여
chmod +x gradlew
# 2. 안드로이드 전용 래퍼 엔진으로 최종 디버그 빌드 개시!
./gradlew assembleDebug
# 1. 의존성 충돌을 막기 위해 android.useAndroidX 설정을 추가한 전체 풀 코드 작성
cat << 'EOF' > $HOME/CustomClipHub/gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
EOF

# 2. 프로젝트 폴더인지 다시 확인하고 진짜 최종 빌드 슛!
cd $HOME/CustomClipHub
./gradlew assembleDebug
# 1. Termux 네이티브 안드로이드 빌드 도구(aapt2 포함) 설치
pkg update -y && pkg install android-tools -y
# 2. gradle.properties에 네이티브 AAPT2 우회 경로를 포함한 풀 설정 주입
cat << 'EOF' > $HOME/CustomClipHub/gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
EOF

# 3. 프로젝트 폴더로 이동 후 최종 빌드 다시 달리기!
cd $HOME/CustomClipHub
./gradlew assembleDebug
# 1. 프로젝트 폴더로 이동
cd $HOME/CustomClipHub
# 2. Termux 시스템 내부에서 실제 aapt2 바이너리 위치 찾기
REAL_AAPT2=$(which aapt2 2>/dev/null || find /data/data/com.termux/files/usr/ -name "aapt2" -type f | head -n 1)
if [ -n "$REAL_AAPT2" ]; then     echo "==> 실제 AAPT2 발견됨: $REAL_AAPT2";     
    cat << EOF > gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
android.aapt2FromMavenOverride=$REAL_AAPT2
EOF
  else     echo "==> [오류] 시스템에 aapt2가 설치되지 않았습니다. 툴체인을 재설치합니다.";     pkg install android-tools -y;     REAL_AAPT2="/data/data/com.termux/files/usr/bin/aapt2";     
    cat << EOF > gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
android.aapt2FromMavenOverride=$REAL_AAPT2
EOF
 fi
# 4. 제대로 파일이 작성되었는지 확인 검증
echo "==> [설정 완료] 작성된 gradle.properties 내용:"
cat gradle.properties
# 5. 마지막 빌드 시도!
./gradlew assembleDebug
# 1. 프로젝트 폴더로 이동
cd $HOME/CustomClipHub
# 2. Termux의 서드파티 저장소(TUR) 활성화 및 android-tools 확실하게 설치
echo "==> Termux 저장소 업데이트 및 패키지 설치 중..."
pkg update -y
pkg install x11-repo tur-repo -y
# 1. 프로젝트 폴더로 이동
cd $HOME/CustomClipHub
# 2. Termux의 서드파티 저장소(TUR) 활성화 및 android-tools 확실하게 설치
echo "==> Termux 저장소 업데이트 및 패키지 설치 중..."
pkg update -y
pkg install x11-repo tur-repo -y
pkg install android-tools -y
# 3. 설치된 aapt2의 실제 위치 강제 확인 및 심볼릭 링크 생성 보장
if [ ! -f "/data/data/com.termux/files/usr/bin/aapt2" ]; then     echo "==> 기본 경로에 aapt2가 없어 실제 위치를 찾아 링크를 연결합니다.";     FOUND_AAPT2=$(find /data/data/com.termux/files/usr/ -name "aapt2" -type f | head -n 1);     if [ -n "$FOUND_AAPT2" ]; then         ln -sf "$FOUND_AAPT2" /data/data/com.termux/files/usr/bin/aapt2;     fi; fi
# 4. 바이너리가 실제로 존재하는지 최종 검증 후 세팅
if [ -f "/data/data/com.termux/files/usr/bin/aapt2" ]; then     echo "==> [검증 성공] AAPT2 바이너리가 준비되었습니다.";     chmod +x /data/data/com.termux/files/usr/bin/aapt2;     
    cat << 'EOF' > gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
EOF
      echo "==> [설정 완료] gradle.properties 내용 확인:";     cat gradle.properties; 
    echo "==> 최종 빌드를 시작합니다...";     ./gradlew assembleDebug; else     echo "==> [오류] 시스템에 aapt2 컴파일러를 설치하지 못했습니다. 패키지 상태를 확인해 주세요."; fi
# 1. 프로젝트 폴더로 이동 및 클린 준비
cd $HOME/CustomClipHub
rm -f /data/data/com.termux/files/usr/bin/aapt2
# 2. Termux 환경에 맞는 네이티브 64비트 AAPT2 바이너리 직접 다운로드 (우회용 저장소 활용)
echo "==> 네이티브 AAPT2 바이너리 다운로드 중..."
curl -L -o /data/data/com.termux/files/usr/bin/aapt2 https://github.com/skylot/jadx/raw/master/jadx-core/src/test/resources/bin/aapt2-linux-arm64 2>/dev/null || curl -L -o /data/data/com.termux/files/usr/bin/aapt2 https://raw.githubusercontent.com/CerebroLabs/aapt2-arm64/master/aapt2
# 3. 실행 권한 부여 및 검증
chmod +x /data/data/com.termux/files/usr/bin/aapt2
if [ -f "/data/data/com.termux/files/usr/bin/aapt2" ]; then     echo "==> [검증 성공] 수동 주입된 AAPT2 바이너리가 준비되었습니다.";     
    cat << 'EOF' > gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
EOF
      echo "==> [설정 완료] gradle.properties 내용 확인:";     cat gradle.properties; 
    echo "==> 빌드를 시작합니다...";     ./gradlew clean assembleDebug; else     echo "==> [오류] 네트워크 문제로 AAPT2 바이너리를 다운로드하지 못했습니다. 인터넷 연결을 확인해 주세요."; fi
# 1. 프로젝트 폴더로 이동 및 기존 깨진 파일 제거
cd $HOME/CustomClipHub
rm -f /data/data/com.termux/files/usr/bin/aapt2
# 2. 그레이들 캐시 디렉토리 내부에서 순정 linux-x86_64용 내장 aapt2 바이너리 검색 및 복사
echo "==> 그레이들 캐시에서 순정 AAPT2 바이너리 추출 중..."
INTERNAL_AAPT2=$(find $HOME/.gradle/caches/modules-2/files-2.1/com.android.tools.build/aapt2/ -name "aapt2-*-linux.jar" 2>/dev/null | head -n 1)
if [ -n "$INTERNAL_AAPT2" ]; then
    unzip -p "$INTERNAL_AAPT2" aapt2 > /data/data/com.termux/files/usr/bin/aapt2 2>/dev/null; fi
# 3. 만약 위에서 추출이 안 되었다면 공식 구글 메이븐 저장소에서 최신 순정 아카이브를 직접 정상 다운로드
if [ ! -s "/data/data/com.termux/files/usr/bin/aapt2" ]; then     echo "==> 메이븐 저장소에서 순정 AAPT2 바이너리를 직접 가져옵니다...";     curl -L -o /tmp/aapt2.jar https://repo1.maven.org/maven2/com/android/tools/build/aapt2/8.2.2-10154469/aapt2-8.2.2-10154469-linux.jar;     unzip -p /tmp/aapt2.jar aapt2 > /data/data/com.termux/files/usr/bin/aapt2;     rm -f /tmp/aapt2.jar; fi
# 4. 실행 권한 부여 및 최종 유효성 검증
chmod +x /data/data/com.termux/files/usr/bin/aapt2
if [ -s "/data/data/com.termux/files/usr/bin/aapt2" ]; then     echo "==> [검증 성공] 완벽한 순정 AAPT2 바이너리가 준비되었습니다.";     
    cat << 'EOF' > gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
EOF
      echo "==> [설정 완료] gradle.properties 내용:";     cat gradle.properties; 
    echo "==> 빌드를 시작합니다...";     ./gradlew clean assembleDebug; else     echo "==> [오류] AAPT2 바이너리를 확보하는 데 실패했습니다. 파일 시스템 권한을 확인해 주세요."; fi
# 1. 프로젝트 폴더로 이동 및 잘못 생성된 링크/파일 초기화
cd $HOME/CustomClipHub
rm -f /data/data/com.termux/files/usr/bin/aapt2
# 2. Termux 전용 공식 android-tools 패키지 강제 재설치
echo "==> Termux 아키텍처 전용 android-tools 패키지 재설치 중..."
pkg update -y
pkg install android-tools -y
# 3. 실제 설치된 Termux 순정 aapt2 위치 확인 및 환경변수 설정 준비
# Termux에 설치된 공식 aapt2는 /data/data/com.termux/files/usr/bin/aapt2 에 바로 위치합니다.
if [ -f "/data/data/com.termux/files/usr/bin/aapt2" ]; then     echo "==> [검증 성공] Termux 전용 AAPT2 바이너리가 확인되었습니다.";     chmod +x /data/data/com.termux/files/usr/bin/aapt2;     
    cat << 'EOF' > gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1024m
android.useAndroidX=true
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
EOF
      echo "==> [설정 완료] gradle.properties 갱신 완료:";     cat gradle.properties; 
    echo "==> 빌드 캐시 청소 및 최종 컴파일을 시작합니다...";     ./gradlew clean assembleDebug; else     echo "==> [오류] Termux 패키지 인프라에서 aapt2를 찾을 수 없습니다. pkg install android-tools 결과를 확인해 주세요."; fi
pkg install android-tools
cd /sdcard
ls
cd Cust*
./gradlew assembleDebug
termux-setup-storage
./gradlew assembleDebug
termux-setup-storage
./gradlew assembleDebug
cd ~
ls
cd /sdcard/Cus*
./gradlew assembleDebug
cp -r /sdcard/Cus* ~/ss
cd ~
ls
cd ss
./gradlew assembleDebug
pkg
./gradlew assembleDebug
cd ..
cd Cu*
./gradlew assembleDebug
cd ..
cd s
cd ss
chmod +x *
./gradlew assembleDebug
gradle wrapper --gradle-version 8.5
# 1. 안드로이드 SDK 라이선스 폴더 강제 생성
export ANDROID_HOME=$HOME/android-sdk
mkdir -p $ANDROID_HOME/licenses
# 2. 구글 공식 안드로이드 SDK 라이선스 해시값 직접 주입 (검문소 프리패스)
echo -e "8933bad161d7a78b827b11c62d7475c19a0fc46d\n24333f8a63b6825ea9c5514f83c2829b004d1fee\ned0d0a5bde5169da3b10b88e991110db56412610" > $ANDROID_HOME/licenses/android-sdk-license
# 3. 혹시 모를 프리뷰 버전을 위한 라이선스 해시값 주입
echo -e "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license
# 4. 주입 결과 검증 (파일이 정상적으로 구워졌는지 확인)
echo "==> 생성된 라이선스 파일 확인:"
ls -l $ANDROID_HOME/licenses
gradle wrapper --gradle-version 8.5
