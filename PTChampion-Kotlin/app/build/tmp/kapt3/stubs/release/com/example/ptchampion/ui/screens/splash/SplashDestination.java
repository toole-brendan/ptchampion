package com.example.ptchampion.ui.screens.splash;

import androidx.lifecycle.ViewModel;
import com.example.ptchampion.data.repository.UserPreferencesRepository;
import retrofit2.HttpException;
import java.io.IOException;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00020\u0001:\u0003\u0003\u0004\u0005B\u0007\b\u0004\u00a2\u0006\u0002\u0010\u0002\u0082\u0001\u0003\u0006\u0007\b\u00a8\u0006\t"}, d2 = {"Lcom/example/ptchampion/ui/screens/splash/SplashDestination;", "", "()V", "Home", "Login", "Undetermined", "Lcom/example/ptchampion/ui/screens/splash/SplashDestination$Home;", "Lcom/example/ptchampion/ui/screens/splash/SplashDestination$Login;", "Lcom/example/ptchampion/ui/screens/splash/SplashDestination$Undetermined;", "app_release"})
public abstract class SplashDestination {
    
    private SplashDestination() {
        super();
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/screens/splash/SplashDestination$Home;", "Lcom/example/ptchampion/ui/screens/splash/SplashDestination;", "()V", "app_release"})
    public static final class Home extends com.example.ptchampion.ui.screens.splash.SplashDestination {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.screens.splash.SplashDestination.Home INSTANCE = null;
        
        private Home() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/screens/splash/SplashDestination$Login;", "Lcom/example/ptchampion/ui/screens/splash/SplashDestination;", "()V", "app_release"})
    public static final class Login extends com.example.ptchampion.ui.screens.splash.SplashDestination {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.screens.splash.SplashDestination.Login INSTANCE = null;
        
        private Login() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/screens/splash/SplashDestination$Undetermined;", "Lcom/example/ptchampion/ui/screens/splash/SplashDestination;", "()V", "app_release"})
    public static final class Undetermined extends com.example.ptchampion.ui.screens.splash.SplashDestination {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.screens.splash.SplashDestination.Undetermined INSTANCE = null;
        
        private Undetermined() {
        }
    }
}