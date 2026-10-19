package com.luiszapata.tvcontrol.tv_launcher.core

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.LruCache
import com.luiszapata.tvcontrol.tv_launcher.companion.AppInfo
import java.io.ByteArrayOutputStream

/** Installed apps that can be opened, with their TV banners or icons. */
class AppRepository(private val context: Context) {
    private val pm: PackageManager = context.packageManager
    private val icons = object : LruCache<String, ByteArray>(8 * 1024 * 1024) {
        override fun sizeOf(key: String, value: ByteArray) = value.size
    }

    fun apps(): List<AppInfo> {
        val seen = LinkedHashMap<String, AppInfo>()
        for (category in listOf(Intent.CATEGORY_LEANBACK_LAUNCHER, Intent.CATEGORY_LAUNCHER)) {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(category)
            for (ri in pm.queryIntentActivities(intent, 0)) {
                val pkg = ri.activityInfo.packageName
                if (pkg == context.packageName || seen.containsKey(pkg)) continue
                val app = ri.activityInfo.applicationInfo
                seen[pkg] = AppInfo(
                    packageName = pkg,
                    label = ri.loadLabel(pm).toString(),
                    versionCode = versionCode(pkg),
                    isSystem = app.flags and ApplicationInfo.FLAG_SYSTEM != 0 &&
                        app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP == 0,
                )
            }
        }
        return seen.values.sortedBy { it.label.lowercase() }
    }

    private fun versionCode(pkg: String): Long = try {
        val info = pm.getPackageInfo(pkg, 0)
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else @Suppress("DEPRECATION") info.versionCode.toLong()
    } catch (e: PackageManager.NameNotFoundException) {
        0L
    }

    fun launchIntent(pkg: String): Intent? =
        (pm.getLeanbackLaunchIntentForPackage(pkg) ?: pm.getLaunchIntentForPackage(pkg))
            ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)

    fun launch(pkg: String): Boolean {
        val intent = launchIntent(pkg) ?: return false
        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** PNG of the TV banner (16:9) if the app has one, else its icon. Max 320 px wide. */
    fun iconPng(pkg: String): ByteArray? {
        icons.get(pkg)?.let { return it }
        val drawable: Drawable = try {
            pm.getApplicationBanner(pkg) ?: pm.getApplicationIcon(pkg)
        } catch (e: PackageManager.NameNotFoundException) {
            return null
        }
        val png = render(drawable, 320)
        icons.put(pkg, png)
        return png
    }

    fun clearIcons() = icons.evictAll()

    private fun render(d: Drawable, maxWidth: Int): ByteArray {
        val bitmap = if (d is BitmapDrawable && d.bitmap != null && d.bitmap.width <= maxWidth) {
            d.bitmap
        } else {
            val w0 = d.intrinsicWidth.takeIf { it > 0 } ?: maxWidth
            val h0 = d.intrinsicHeight.takeIf { it > 0 } ?: maxWidth
            val scale = minOf(1f, maxWidth.toFloat() / w0)
            val w = (w0 * scale).toInt().coerceAtLeast(1)
            val h = (h0 * scale).toInt().coerceAtLeast(1)
            Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
                val c = Canvas(it)
                d.setBounds(0, 0, w, h)
                d.draw(c)
            }
        }
        return ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.toByteArray()
        }
    }
}
