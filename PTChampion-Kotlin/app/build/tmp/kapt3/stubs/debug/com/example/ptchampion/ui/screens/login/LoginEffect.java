package com.example.ptchampion.ui.screens.login;

import androidx.lifecycle.ViewModel;
import com.example.ptchampion.domain.repository.AuthRepository;
import org.openapitools.client.models.LoginRequest;
import com.example.ptchampion.util.Resource;
import com.example.ptchampion.data.repository.UserPreferencesRepository;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0016\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00020\u0001:\u0002\u0003\u0004B\u0007\b\u0004\u00a2\u0006\u0002\u0010\u0002\u0082\u0001\u0002\u0005\u0006\u00a8\u0006\u0007"}, d2 = {"Lcom/example/ptchampion/ui/screens/login/LoginEffect;", "", "()V", "NavigateToHome", "NavigateToSignUp", "Lcom/example/ptchampion/ui/screens/login/LoginEffect$NavigateToHome;", "Lcom/example/ptchampion/ui/screens/login/LoginEffect$NavigateToSignUp;", "app_debug"})
public abstract class LoginEffect {
    
    private LoginEffect() {
        super();
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/screens/login/LoginEffect$NavigateToHome;", "Lcom/example/ptchampion/ui/screens/login/LoginEffect;", "()V", "app_debug"})
    public static final class NavigateToHome extends com.example.ptchampion.ui.screens.login.LoginEffect {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.screens.login.LoginEffect.NavigateToHome INSTANCE = null;
        
        private NavigateToHome() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/screens/login/LoginEffect$NavigateToSignUp;", "Lcom/example/ptchampion/ui/screens/login/LoginEffect;", "()V", "app_debug"})
    public static final class NavigateToSignUp extends com.example.ptchampion.ui.screens.login.LoginEffect {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.screens.login.LoginEffect.NavigateToSignUp INSTANCE = null;
        
        private NavigateToSignUp() {
        }
    }
}