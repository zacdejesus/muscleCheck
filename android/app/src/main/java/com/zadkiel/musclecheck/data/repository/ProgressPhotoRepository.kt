package com.zadkiel.musclecheck.data.repository

import android.content.Context
import android.net.Uri
import com.zadkiel.musclecheck.data.local.ProgressPhotoDao
import com.zadkiel.musclecheck.data.local.ProgressPhotoEntity
import com.zadkiel.musclecheck.data.local.toDomain
import com.zadkiel.musclecheck.domain.model.ProgressPhoto
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.io.File
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/** Port of iOS ProgressPhotoManager: metadata in Room, image bytes on disk. */
@Singleton
class ProgressPhotoRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val dao: ProgressPhotoDao,
) {
    /** Internal-storage dir for the images — private to the app, no permission needed. */
    private val dir: File by lazy { File(context.filesDir, "progress_photos").apply { mkdirs() } }

    val photos: Flow<List<ProgressPhoto>> =
        dao.observeAll().map { list -> list.map { it.toDomain() } }

    /** Absolute file for a photo — passed to Coil for loading. */
    fun file(photo: ProgressPhoto): File = File(dir, photo.fileName)

    /** Copies the picked image into internal storage and records its metadata. */
    suspend fun add(uri: Uri, date: LocalDate = LocalDate.now()) = withContext(Dispatchers.IO) {
        val id = UUID.randomUUID().toString()
        val fileName = "$id.jpg"
        val copied = context.contentResolver.openInputStream(uri)?.use { input ->
            File(dir, fileName).outputStream().use { output -> input.copyTo(output) }
            true
        } ?: false
        if (copied) {
            dao.insert(ProgressPhotoEntity(id = id, epochDay = date.toEpochDay(), fileName = fileName))
        }
    }

    suspend fun delete(photo: ProgressPhoto) = withContext(Dispatchers.IO) {
        File(dir, photo.fileName).delete()
        dao.delete(photo.id)
    }
}
