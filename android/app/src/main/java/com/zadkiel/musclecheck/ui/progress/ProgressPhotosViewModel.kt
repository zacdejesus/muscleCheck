package com.zadkiel.musclecheck.ui.progress

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.zadkiel.musclecheck.data.pro.ProAccessManager
import com.zadkiel.musclecheck.data.repository.ProgressPhotoRepository
import com.zadkiel.musclecheck.domain.model.ProgressPhoto
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

@HiltViewModel
class ProgressPhotosViewModel @Inject constructor(
    private val repository: ProgressPhotoRepository,
    proAccess: ProAccessManager,
) : ViewModel() {

    val photos: StateFlow<List<ProgressPhoto>> = repository.photos
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val isPro: StateFlow<Boolean> = proAccess.isPro
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    fun file(photo: ProgressPhoto): File = repository.file(photo)

    fun add(uri: Uri) {
        viewModelScope.launch { repository.add(uri) }
    }

    fun delete(photo: ProgressPhoto) {
        viewModelScope.launch { repository.delete(photo) }
    }
}
