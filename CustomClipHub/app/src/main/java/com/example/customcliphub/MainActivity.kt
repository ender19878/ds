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
