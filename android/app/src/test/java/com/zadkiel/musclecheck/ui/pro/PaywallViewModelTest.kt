package com.zadkiel.musclecheck.ui.pro

import com.zadkiel.musclecheck.data.pro.ProAccessManager
import com.zadkiel.musclecheck.data.pro.ProPackage
import com.zadkiel.musclecheck.data.pro.ProPurchaseException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class PaywallViewModelTest {

    /** Records the purchase call and lets a test force a failure. */
    private class FakeProAccessManager(private val failWith: String? = null) : ProAccessManager {
        val proFlag = MutableStateFlow(false)
        var lastPurchased: ProPackage? = null
        override val isPro: Flow<Boolean> = proFlag.asStateFlow()
        override val isLoading: Flow<Boolean> = MutableStateFlow(false).asStateFlow()

        override suspend fun purchase(pkg: ProPackage) {
            failWith?.let { throw ProPurchaseException(it) }
            lastPurchased = pkg
            proFlag.value = true
        }

        override suspend fun restore() {}
    }

    private val dispatcher = StandardTestDispatcher()

    @Before fun setUp() = Dispatchers.setMain(dispatcher)
    @After fun tearDown() = Dispatchers.resetMain()

    @Test
    fun `defaults to the yearly package`() {
        val vm = PaywallViewModel(FakeProAccessManager())
        assertEquals(ProPackage.YEARLY, vm.selectedPackage.value)
    }

    @Test
    fun `purchase buys the selected package and grants pro`() = runTest(dispatcher) {
        val fake = FakeProAccessManager()
        val vm = PaywallViewModel(fake)

        vm.select(ProPackage.MONTHLY)
        vm.purchase()
        advanceUntilIdle()

        assertEquals(ProPackage.MONTHLY, fake.lastPurchased)
        assertTrue(fake.proFlag.value)
        assertNull(vm.error.value)
    }

    @Test
    fun `purchase failure surfaces the error message`() = runTest(dispatcher) {
        val vm = PaywallViewModel(FakeProAccessManager(failWith = "boom"))

        vm.purchase()
        advanceUntilIdle()

        assertEquals("boom", vm.error.value)
    }

    @Test
    fun `clearError resets the error`() = runTest(dispatcher) {
        val vm = PaywallViewModel(FakeProAccessManager(failWith = "boom"))
        vm.purchase()
        advanceUntilIdle()

        vm.clearError()

        assertNull(vm.error.value)
    }
}
