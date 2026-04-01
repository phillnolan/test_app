package com.example.sinhvien_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class TodayScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TodayScheduleWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(componentName)
            ids.forEach { updateWidget(context, manager, it) }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)

            views.setTextViewText(
                R.id.widget_title,
                prefs.getString("flutter.widget_title", "Lịch hôm nay")
            )
            views.setTextViewText(
                R.id.widget_subtitle,
                prefs.getString("flutter.widget_subtitle", "Chưa có dữ liệu")
            )
            views.setTextViewText(
                R.id.widget_line_1,
                prefs.getString("flutter.widget_line_1", "")
            )
            views.setTextViewText(
                R.id.widget_line_2,
                prefs.getString("flutter.widget_line_2", "")
            )
            views.setTextViewText(
                R.id.widget_line_3,
                prefs.getString("flutter.widget_line_3", "")
            )

            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
