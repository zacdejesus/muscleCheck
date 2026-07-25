package com.zadkiel.musclecheck.ui.pro

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Button
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.data.pro.ProPackage

/** A Free-vs-Pro feature row. */
private data class CompareRow(val labelRes: Int, val free: Boolean)

// Reflects what the app actually gates today: checklist, AI coach, history,
// stats and notifications ship free; only progress photos are Pro.
private val compareRows = listOf(
    CompareRow(R.string.paywall_compare_checklist, free = true),
    CompareRow(R.string.paywall_compare_ai, free = true),
    CompareRow(R.string.paywall_compare_history, free = true),
    CompareRow(R.string.paywall_compare_stats, free = true),
    CompareRow(R.string.paywall_compare_notifications, free = true),
    CompareRow(R.string.paywall_compare_photos, free = false),
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallScreen(
    onClose: () -> Unit,
    viewModel: PaywallViewModel = hiltViewModel(),
) {
    val isPro by viewModel.isPro.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val selected by viewModel.selectedPackage.collectAsStateWithLifecycle()

    // Close as soon as the entitlement is granted (mirrors iOS dismiss-on-success).
    LaunchedEffect(isPro) {
        if (isPro) onClose()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
                actions = {
                    IconButton(onClick = onClose) {
                        Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.action_close))
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Spacer(Modifier.height(8.dp))
            Icon(
                Icons.Filled.WorkspacePremium,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(52.dp),
            )
            Text(
                text = stringResource(R.string.paywall_title),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
            Text(
                text = stringResource(R.string.paywall_subtitle),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )

            ComparisonTable()

            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                PackageOption(
                    title = stringResource(R.string.paywall_yearly),
                    price = stringResource(R.string.paywall_price_yearly),
                    badge = stringResource(R.string.paywall_best_value),
                    selected = selected == ProPackage.YEARLY,
                    onClick = { viewModel.select(ProPackage.YEARLY) },
                )
                PackageOption(
                    title = stringResource(R.string.paywall_monthly),
                    price = stringResource(R.string.paywall_price_monthly),
                    badge = null,
                    selected = selected == ProPackage.MONTHLY,
                    onClick = { viewModel.select(ProPackage.MONTHLY) },
                )
                PackageOption(
                    title = stringResource(R.string.paywall_lifetime),
                    price = stringResource(R.string.paywall_price_lifetime),
                    badge = stringResource(R.string.paywall_one_time),
                    selected = selected == ProPackage.LIFETIME,
                    onClick = { viewModel.select(ProPackage.LIFETIME) },
                )
            }

            Button(
                onClick = viewModel::purchase,
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth().height(52.dp),
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(22.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp,
                    )
                } else {
                    Text(stringResource(R.string.paywall_subscribe), fontWeight = FontWeight.SemiBold)
                }
            }

            TextButton(onClick = viewModel::restore, enabled = !isLoading) {
                Text(
                    stringResource(R.string.paywall_restore),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.height(12.dp))
        }
    }
}

@Composable
private fun ComparisonTable() {
    Column(Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(bottom = 4.dp)) {
            Spacer(Modifier.weight(1f))
            Text(
                stringResource(R.string.paywall_compare_free),
                modifier = Modifier.width(56.dp),
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
            )
            Text(
                stringResource(R.string.paywall_compare_pro),
                modifier = Modifier.width(56.dp),
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
            )
        }
        compareRows.forEachIndexed { index, row ->
            Row(
                Modifier.fillMaxWidth().padding(vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    stringResource(row.labelRes),
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.bodyMedium,
                )
                CompareCell(on = row.free, accent = false, modifier = Modifier.width(56.dp))
                CompareCell(on = true, accent = true, modifier = Modifier.width(56.dp))
            }
            if (index < compareRows.lastIndex) HorizontalDivider()
        }
    }
}

@Composable
private fun CompareCell(on: Boolean, accent: Boolean, modifier: Modifier = Modifier) {
    val color = when {
        !on -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
        accent -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }
    Box(modifier, contentAlignment = Alignment.Center) {
        Icon(
            if (on) Icons.Filled.Check else Icons.Filled.Remove,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(18.dp),
        )
    }
}

@Composable
private fun PackageOption(
    title: String,
    price: String,
    badge: String?,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val borderColor =
        if (selected) MaterialTheme.colorScheme.primary
        else MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .border(if (selected) 2.dp else 1.dp, borderColor, RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, style = MaterialTheme.typography.titleMedium)
        badge?.let {
            Spacer(Modifier.width(8.dp))
            Box(
                Modifier
                    .background(MaterialTheme.colorScheme.primary, RoundedCornerShape(4.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp),
            ) {
                Text(
                    it,
                    color = MaterialTheme.colorScheme.onPrimary,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }
        Spacer(Modifier.weight(1f))
        Text(price, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
    }
}
