package com.example.ptchampion.ui.screens.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.paging.PagingData
import androidx.paging.cachedIn
import com.example.ptchampion.domain.model.WorkoutSession
import com.example.ptchampion.domain.repository.WorkoutRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val workoutRepository: WorkoutRepository
) : ViewModel() {

    val historyFlow: Flow<PagingData<WorkoutSession>> = workoutRepository.getWorkoutHistoryStream()
        .cachedIn(viewModelScope) // Cache the stream in ViewModelScope

} 