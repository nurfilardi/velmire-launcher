package id.samp.samp_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "id.samp.launcher/native"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasStorageAccess" -> result.success(hasStorageAccess())
                    "requestStorageAccess" -> requestStorageAccess(result)
                    "isInstalled" -> result.success(isInstalled(call.argument<String>("package") ?: ""))
                    "launchGame" -> result.success(
                        launchGame(
                            call.argument<String>("package") ?: "",
                            call.argument<String>("activity") ?: ""
                        )
                    )
                    "installApk" -> result.success(installApk(call.argument<String>("path") ?: ""))
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasStorageAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStorageAccess(result: MethodChannel.Result) {
        if (hasStorageAccess()) {
            result.success(true)
            return
        }
        pendingResult = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
            intent.data = Uri.parse("package:$packageName")
            startActivityForResult(intent, REQ_STORAGE_SETTINGS)
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
                ),
                REQ_STORAGE_PERMISSION
            )
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_STORAGE_SETTINGS) {
            pendingResult?.success(hasStorageAccess())
            pendingResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_STORAGE_PERMISSION) {
            pendingResult?.success(hasStorageAccess())
            pendingResult = null
        }
    }

    private fun isInstalled(name: String): Boolean {
        if (name.isEmpty()) return false
        return try {
            packageManager.getPackageInfo(name, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun launchGame(name: String, activity: String): Boolean {
        if (name.isEmpty()) return false
        val intent = if (activity.isNotEmpty()) {
            Intent(Intent.ACTION_MAIN).setComponent(ComponentName(name, activity))
        } else {
            packageManager.getLaunchIntentForPackage(name)
        } ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            val fallback = packageManager.getLaunchIntentForPackage(name) ?: return false
            fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(fallback)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun installApk(path: String): Boolean {
        if (path.isEmpty()) return false
        return try {
            val source = File(path)
            val dir = File(cacheDir, "apk").apply { mkdirs() }
            val copy = File(dir, source.name)
            source.copyTo(copy, overwrite = true)
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", copy)
            val intent = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        private const val REQ_STORAGE_SETTINGS = 5001
        private const val REQ_STORAGE_PERMISSION = 5002
    }
}
