package com.smartnaamjap.smrt_counter

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.view.View
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Smart Naam Jap Home Screen Widget
 * Displays today's counts, malas, streak, and goal progress
 */
class SmartNaamWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Called when first widget is created
    }

    override fun onDisabled(context: Context) {
        // Called when last widget is removed
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                // Get data from SharedPreferences using HomeWidgetPlugin
                val prefs = HomeWidgetPlugin.getData(context)
                
                val todayCount = prefs.getInt("todayCount", 0)
                val todayMalas = prefs.getInt("todayMalas", 0)
                val currentStreak = prefs.getInt("currentStreak", 0)
                val dailyGoal = prefs.getInt("dailyGoal", 0)
                
                // Create RemoteViews
                val views = RemoteViews(context.packageName, R.layout.smart_naam_widget)
                
                // Update counts
                views.setTextViewText(R.id.widget_counts, formatNumber(todayCount))
                views.setTextViewText(R.id.widget_malas, todayMalas.toString())
                
                // Update streak
                val streakText = if (currentStreak > 0) "🔥 $currentStreak" else "📿"
                views.setTextViewText(R.id.widget_streak, streakText)
                
                // Update goal progress
                if (dailyGoal > 0) {
                    views.setViewVisibility(R.id.widget_goal_container, View.VISIBLE)
                    val progress = ((todayMalas.toFloat() / dailyGoal) * 100).toInt().coerceIn(0, 100)
                    views.setProgressBar(R.id.widget_progress, 100, progress, false)
                    views.setTextViewText(R.id.widget_goal_text, "$todayMalas / $dailyGoal malas")
                } else {
                    views.setViewVisibility(R.id.widget_goal_container, View.GONE)
                }
                
                // Set click action to open app
                val intent = Intent(context, MainActivity::class.java)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                
                // Update the widget
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                // If there's an error, show a simple fallback widget
                val views = RemoteViews(context.packageName, R.layout.smart_naam_widget)
                views.setTextViewText(R.id.widget_counts, "0")
                views.setTextViewText(R.id.widget_malas, "0")
                views.setTextViewText(R.id.widget_streak, "📿")
                views.setViewVisibility(R.id.widget_goal_container, View.GONE)
                
                // Set click action to open app
                val intent = Intent(context, MainActivity::class.java)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
        
        private fun formatNumber(number: Int): String {
            return when {
                number >= 1000000 -> String.format("%.1fM", number / 1000000.0)
                number >= 10000 -> String.format("%.0fK", number / 1000.0)
                number >= 1000 -> String.format("%.1fK", number / 1000.0)
                else -> number.toString()
            }
        }
    }
}
