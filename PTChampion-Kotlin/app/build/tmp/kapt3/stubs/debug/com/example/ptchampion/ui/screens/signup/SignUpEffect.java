package com.example.ptchampion.ui.screens.signup;

import androidx.lifecycle.ViewModel;
import com.example.ptchampion.domain.repository.AuthRepository;
import org.openapitools.client.models.InsertUser;
import com.example.ptchampion.util.Resource;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00020\u0001:\u0001\u0003B\u0007\b\u0004\u00a2\u0006\u0002\u0010\u0002\u0082\u0001\u0001\u0004\u00a8\u0006\u0005"}, d2 = {"Lcom/example/ptchampion/ui/screens/signup/SignUpEffect;", "", "()V", "NavigateToLogin", "Lcom/example/ptchampion/ui/screens/signup/SignUpEffect$NavigateToLogin;", "app_debug"})
public abstract class SignUpEffect {
    
    private SignUpEffect() {
        super();
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/screens/signup/SignUpEffect$NavigateToLogin;", "Lcom/example/ptchampion/ui/screens/signup/SignUpEffect;", "()V", "app_debug"})
    public static final class NavigateToLogin extends com.example.ptchampion.ui.screens.signup.SignUpEffect {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.screens.signup.SignUpEffect.NavigateToLogin INSTANCE = null;
        
        private NavigateToLogin() {
        }
    }
}