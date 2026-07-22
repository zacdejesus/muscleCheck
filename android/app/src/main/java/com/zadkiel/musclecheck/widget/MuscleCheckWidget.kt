package com.zadkiel.musclecheck.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalContext
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.zadkiel.musclecheck.MainActivity
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.repository.MuscleRepository
import com.zadkiel.musclecheck.domain.AppWeek
import com.zadkiel.musclecheck.domain.StreakCalculator
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.flow.first
import java.time.LocalDate

class MuscleCheckWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MuscleCheckWidget()
}

/** Home-screen port of the iOS widget: weekly streak header + this week's checklist. */
class MuscleCheckWidget : GlanceAppWidget() {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface WidgetEntryPoint {
        fun repository(): MuscleRepository
    }

    private data class WidgetRow(val name: String, val isChecked: Boolean)

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val repository = EntryPointAccessors
            .fromApplication(context.applicationContext, WidgetEntryPoint::class.java)
            .repository()

        val entries = repository.entries.first()
        val today = LocalDate.now()
        val rows = entries
            .filter { it.weekOfYear == AppWeek.weekOfYear(today) && it.year == AppWeek.weekBasedYear(today) }
            .map { WidgetRow(it.name, it.isChecked) }
        val currentStreak = StreakCalculator.currentStreak(entries)
        val maxStreak = StreakCalculator.maxStreak(entries)

        provideContent {
            GlanceTheme {
                WidgetContent(rows, currentStreak, maxStreak)
            }
        }
    }

    @Composable
    private fun WidgetContent(rows: List<WidgetRow>, currentStreak: Int, maxStreak: Int) {
        val secondary = GlanceTheme.colors.onSurfaceVariant
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(GlanceTheme.colors.widgetBackground)
                .padding(12.dp)
                .clickable(actionStartActivity<MainActivity>()),
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = if (currentStreak > 0) "🔥 $currentStreak" else "💤 0",
                    style = TextStyle(
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (currentStreak > 0) {
                            ColorProvider(Color(0xFFFF9500))
                        } else {
                            secondary
                        },
                    ),
                )
                Spacer(GlanceModifier.defaultWeight())
                Text(
                    text = "🏆 $maxStreak",
                    style = TextStyle(fontSize = 12.sp, color = secondary),
                )
            }
            Spacer(GlanceModifier.height(6.dp))

            if (rows.isEmpty()) {
                Text(
                    text = LocalContext.current.getString(R.string.widget_empty),
                    style = TextStyle(fontSize = 12.sp, color = secondary),
                )
            } else {
                rows.take(5).forEach { row ->
                    Row(
                        modifier = GlanceModifier.fillMaxWidth().padding(vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = if (row.isChecked) "✓ " else "○ ",
                            style = TextStyle(
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (row.isChecked) {
                                    ColorProvider(Color(0xFF34C759))
                                } else {
                                    secondary
                                },
                            ),
                        )
                        Text(
                            text = row.name,
                            maxLines = 1,
                            style = TextStyle(fontSize = 13.sp, color = GlanceTheme.colors.onSurface),
                        )
                    }
                }
            }
        }
    }
}
