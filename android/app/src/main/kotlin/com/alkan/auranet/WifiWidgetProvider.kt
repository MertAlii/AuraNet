package com.alkan.auranet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WifiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.wifi_widget).apply {
                
                // Flutter'dan gelen verileri al
                val ssid = widgetData.getString("wifi_ssid", "Bağlı Değil") ?: "Bağlı Değil"
                val ip = widgetData.getString("wifi_ip", "0.0.0.0") ?: "0.0.0.0"
                val signal = widgetData.getInt("wifi_signal", 0)
                val score = widgetData.getInt("security_score", 0)

                // View'ları güncelle
                setTextViewText(R.id.wifi_ssid, ssid)
                setTextViewText(R.id.wifi_ip, ip)
                setTextViewText(R.id.security_score, if (score > 0) score.toString() else "--")
                
                setProgressBar(R.id.signal_progress, 100, signal, false)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
