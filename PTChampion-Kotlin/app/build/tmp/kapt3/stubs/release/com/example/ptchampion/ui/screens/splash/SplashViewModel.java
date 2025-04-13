package com.example.ptchampion.ui.screens.splash;

import androidx.lifecycle.ViewModel;
import com.example.ptchampion.data.repository.UserPreferencesRepository;
import retrofit2.HttpException;
import java.io.IOException;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000$\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\n\u001a\u00020\u000bH\u0002R\u0014\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00050\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\t\u00a8\u0006\f"}, d2 = {"Lcom/example/ptchampion/ui/screens/splash/SplashViewModel;", "Landroidx/lifecycle/ViewModel;", "()V", "_destination", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/example/ptchampion/ui/screens/splash/SplashDestination;", "destination", "Lkotlinx/coroutines/flow/StateFlow;", "getDestination", "()Lkotlinx/coroutines/flow/StateFlow;", "checkAuthStatus", "", "app_release"})
public final class SplashViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.MutableStateFlow<com.example.ptchampion.ui.screens.splash.SplashDestination> _destination = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.splash.SplashDestination> destination = null;
    
    public SplashViewModel() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.splash.SplashDestination> getDestination() {
        return null;
    }
    
    private final void checkAuthStatus() {
    }
}