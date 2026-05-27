package com.miztmutzuki.calculaya

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TasaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val rate = widgetData.getString("bcv_rate", "—") ?: "—"
        val p2p = widgetData.getString("p2p_rate", "—") ?: "—"
        val spread = widgetData.getString("spread_pct", "—") ?: "—"
        val updated = widgetData.getString("updated_at", "") ?: ""

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.tasa_widget)
            views.setTextViewText(R.id.widget_rate, "$rate Bs/\$")
            views.setTextViewText(R.id.widget_sub, "P2P: $p2p · +$spread%")
            views.setTextViewText(R.id.widget_updated, updated)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
