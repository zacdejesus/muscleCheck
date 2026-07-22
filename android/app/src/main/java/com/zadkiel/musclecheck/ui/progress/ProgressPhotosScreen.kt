package com.zadkiel.musclecheck.ui.progress

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Compare
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.zadkiel.musclecheck.R
import com.zadkiel.musclecheck.domain.model.ProgressPhoto
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProgressPhotosScreen(
    onBack: () -> Unit,
    viewModel: ProgressPhotosViewModel = hiltViewModel(),
) {
    val photos by viewModel.photos.collectAsStateWithLifecycle()
    var viewing by remember { mutableStateOf<ProgressPhoto?>(null) }
    var comparing by remember { mutableStateOf(false) }

    val picker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri -> uri?.let(viewModel::add) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.progress_photos_title)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
                    }
                },
                actions = {
                    if (photos.size >= 2) {
                        IconButton(onClick = { comparing = true }) {
                            Icon(Icons.Filled.Compare, contentDescription = stringResource(R.string.progress_compare))
                        }
                    }
                },
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = {
                picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
            }) {
                Icon(Icons.Filled.Add, contentDescription = stringResource(R.string.progress_add_photo))
            }
        },
    ) { padding ->
        if (photos.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text(
                    stringResource(R.string.progress_empty),
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(32.dp),
                )
            }
        } else {
            val byMonth = photos.groupBy { YearMonth.from(it.date) }
                .toSortedMap(compareByDescending { it })
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                modifier = Modifier.fillMaxSize().padding(padding).padding(horizontal = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                byMonth.forEach { (month, monthPhotos) ->
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Text(
                            month.format(DateTimeFormatter.ofPattern("LLLL yyyy", Locale.getDefault()))
                                .replaceFirstChar { it.titlecase(Locale.getDefault()) },
                            style = MaterialTheme.typography.titleSmall,
                            modifier = Modifier.padding(top = 12.dp, bottom = 2.dp),
                        )
                    }
                    items(monthPhotos.size, key = { monthPhotos[it].id }) { i ->
                        val photo = monthPhotos[i]
                        AsyncImage(
                            model = viewModel.file(photo),
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .aspectRatio(1f)
                                .clipToBounds()
                                .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(8.dp))
                                .clickable { viewing = photo },
                        )
                    }
                }
            }
        }
    }

    viewing?.let { photo ->
        PhotoViewerDialog(
            file = viewModel.file(photo),
            onDelete = { viewModel.delete(photo); viewing = null },
            onClose = { viewing = null },
        )
    }

    if (comparing && photos.size >= 2) {
        // Oldest vs newest — the before/after the user cares about.
        val sorted = photos.sortedBy { it.date }
        CompareDialog(
            before = viewModel.file(sorted.first()),
            after = viewModel.file(sorted.last()),
            onClose = { comparing = false },
        )
    }
}

@Composable
private fun PhotoViewerDialog(file: java.io.File, onDelete: () -> Unit, onClose: () -> Unit) {
    Dialog(onDismissRequest = onClose) {
        Box(Modifier.fillMaxWidth().background(Color.Black, RoundedCornerShape(16.dp))) {
            AsyncImage(
                model = file,
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = Modifier.fillMaxWidth().padding(4.dp),
            )
            IconButton(onClick = onClose, modifier = Modifier.align(Alignment.TopStart)) {
                Icon(Icons.Filled.Close, contentDescription = null, tint = Color.White)
            }
            IconButton(onClick = onDelete, modifier = Modifier.align(Alignment.TopEnd)) {
                Icon(Icons.Filled.Delete, contentDescription = stringResource(R.string.progress_delete), tint = Color.White)
            }
        }
    }
}

/** Before/after slider: the "before" image is drawn clipped to the left of a
 *  draggable handle, revealing the "after" underneath on the right. */
@Composable
private fun CompareDialog(before: java.io.File, after: java.io.File, onClose: () -> Unit) {
    Dialog(onDismissRequest = onClose) {
        Box(Modifier.fillMaxWidth().background(Color.Black, RoundedCornerShape(16.dp))) {
            var width by remember { mutableFloatStateOf(1f) }
            var handleX by remember { mutableFloatStateOf(-1f) }
            val density = LocalDensity.current

            Box(
                Modifier
                    .fillMaxWidth()
                    .aspectRatio(0.75f)
                    .onSizeChanged {
                        width = it.width.toFloat()
                        if (handleX < 0f) handleX = width / 2f
                    }
                    .pointerInput(Unit) {
                        detectDragGestures { change, _ ->
                            handleX = change.position.x.coerceIn(0f, width)
                        }
                    },
            ) {
                AsyncImage(after, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                AsyncImage(
                    before, null,
                    Modifier.fillMaxSize().drawWithContent {
                        clipRect(right = handleX) { this@drawWithContent.drawContent() }
                    },
                    contentScale = ContentScale.Crop,
                )
                // Handle line + knob.
                Box(
                    Modifier
                        .offset { androidx.compose.ui.unit.IntOffset(handleX.roundToInt(), 0) }
                        .fillMaxHeight()
                        .width(2.dp)
                        .background(Color.White),
                )
                Box(
                    Modifier
                        .offset { androidx.compose.ui.unit.IntOffset((handleX - with(density) { 16.dp.toPx() }).roundToInt(), 0) }
                        .align(Alignment.CenterStart)
                        .size(32.dp)
                        .background(Color.White, CircleShape),
                )
            }
            IconButton(onClick = onClose, modifier = Modifier.align(Alignment.TopEnd)) {
                Icon(Icons.Filled.Close, contentDescription = null, tint = Color.White)
            }
        }
    }
}
