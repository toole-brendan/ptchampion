package com.example.ptchampion.ui.screens.signup;

import androidx.lifecycle.ViewModel;
import com.example.ptchampion.domain.repository.AuthRepository;
import org.openapitools.client.models.InsertUser;
import com.example.ptchampion.util.Resource;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00006\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0006\u0010\u0013\u001a\u00020\u0014J\u000e\u0010\u0015\u001a\u00020\u00142\u0006\u0010\u0016\u001a\u00020\u0017J\b\u0010\u0018\u001a\u00020\u0014H\u0002R\u0014\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00050\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\tR+\u0010\f\u001a\u00020\u000b2\u0006\u0010\n\u001a\u00020\u000b8F@BX\u0086\u008e\u0002\u00a2\u0006\u0012\n\u0004\b\u0011\u0010\u0012\u001a\u0004\b\r\u0010\u000e\"\u0004\b\u000f\u0010\u0010\u00a8\u0006\u0019"}, d2 = {"Lcom/example/ptchampion/ui/screens/signup/SignUpViewModel;", "Landroidx/lifecycle/ViewModel;", "()V", "_effect", "Lkotlinx/coroutines/flow/MutableSharedFlow;", "Lcom/example/ptchampion/ui/screens/signup/SignUpEffect;", "effect", "Lkotlinx/coroutines/flow/SharedFlow;", "getEffect", "()Lkotlinx/coroutines/flow/SharedFlow;", "<set-?>", "Lcom/example/ptchampion/ui/screens/signup/SignUpState;", "state", "getState", "()Lcom/example/ptchampion/ui/screens/signup/SignUpState;", "setState", "(Lcom/example/ptchampion/ui/screens/signup/SignUpState;)V", "state$delegate", "Landroidx/compose/runtime/MutableState;", "navigateToLogin", "", "onEvent", "event", "Lcom/example/ptchampion/ui/screens/signup/SignUpEvent;", "registerUser", "app_release"})
public final class SignUpViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull
    private final androidx.compose.runtime.MutableState state$delegate = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.MutableSharedFlow<com.example.ptchampion.ui.screens.signup.SignUpEffect> _effect = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.SharedFlow<com.example.ptchampion.ui.screens.signup.SignUpEffect> effect = null;
    
    public SignUpViewModel() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.signup.SignUpState getState() {
        return null;
    }
    
    private final void setState(com.example.ptchampion.ui.screens.signup.SignUpState p0) {
    }
    
    @org.jetbrains.annotations.NotNull
    public final kotlinx.coroutines.flow.SharedFlow<com.example.ptchampion.ui.screens.signup.SignUpEffect> getEffect() {
        return null;
    }
    
    public final void onEvent(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.signup.SignUpEvent event) {
    }
    
    private final void registerUser() {
    }
    
    public final void navigateToLogin() {
    }
}