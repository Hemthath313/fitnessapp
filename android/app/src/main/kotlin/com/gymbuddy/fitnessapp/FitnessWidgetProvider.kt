package com.gymbuddy.fitnessapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FitnessWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data saved from Dart via HomeWidget
                val streak = widgetData.getInt("streak", 0)
                val water = (widgetData.all["water"] as? Number)?.toFloat() ?: 0f
                
                // Let's use getString just in case, HomeWidget often serializes.
                val streakStr = streak.toString() + " Days"
                
                // For water it might be Double, but let's safely retrieve string or double
                val waterStr = "${water.toInt()} ml"

                setTextViewText(R.id.widget_streak, streakStr)
                setTextViewText(R.id.widget_water, waterStr)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
