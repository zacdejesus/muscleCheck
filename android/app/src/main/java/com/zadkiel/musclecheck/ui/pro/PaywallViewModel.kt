package com.zadkiel.musclecheck.ui.pro

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.zadkiel.musclecheck.data.pro.ProAccessManager
import com.zadkiel.musclecheck.data.pro.ProPackage
import com.zadkiel.musclecheck.data.pro.ProPurchaseException
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PaywallViewModel @Inject constructor(
    private val proAccess: ProAccessManager,
) : ViewModel() {

    val isPro: StateFlow<Boolean> =
        proAccess.isPro.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    val isLoading: StateFlow<Boolean> =
        proAccess.isLoading.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    private val _selectedPackage = MutableStateFlow(ProPackage.YEARLY)
    val selectedPackage: StateFlow<ProPackage> = _selectedPackage.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun select(pkg: ProPackage) {
        _selectedPackage.value = pkg
    }

    fun purchase() {
        viewModelScope.launch {
            try {
                proAccess.purchase(_selectedPackage.value)
            } catch (e: ProPurchaseException) {
                _error.value = e.message
            }
        }
    }

    fun restore() {
        viewModelScope.launch {
            try {
                proAccess.restore()
            } catch (e: ProPurchaseException) {
                _error.value = e.message
            }
        }
    }

    fun clearError() {
        _error.value = null
    }
}
