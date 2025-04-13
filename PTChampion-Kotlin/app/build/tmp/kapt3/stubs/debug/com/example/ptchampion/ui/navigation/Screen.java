package com.example.ptchampion.ui.navigation;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000<\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0002\b\r\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00020\u0001:\n\u0007\b\t\n\u000b\f\r\u000e\u000f\u0010B\u000f\b\u0004\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u0082\u0001\n\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u00a8\u0006\u001b"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen;", "", "route", "", "(Ljava/lang/String;)V", "getRoute", "()Ljava/lang/String;", "Camera", "ExerciseDetail", "ExerciseList", "History", "Home", "Leaderboard", "Login", "Profile", "SignUp", "Splash", "Lcom/example/ptchampion/ui/navigation/Screen$Camera;", "Lcom/example/ptchampion/ui/navigation/Screen$ExerciseDetail;", "Lcom/example/ptchampion/ui/navigation/Screen$ExerciseList;", "Lcom/example/ptchampion/ui/navigation/Screen$History;", "Lcom/example/ptchampion/ui/navigation/Screen$Home;", "Lcom/example/ptchampion/ui/navigation/Screen$Leaderboard;", "Lcom/example/ptchampion/ui/navigation/Screen$Login;", "Lcom/example/ptchampion/ui/navigation/Screen$Profile;", "Lcom/example/ptchampion/ui/navigation/Screen$SignUp;", "Lcom/example/ptchampion/ui/navigation/Screen$Splash;", "app_debug"})
public abstract class Screen {
    @org.jetbrains.annotations.NotNull
    private final java.lang.String route = null;
    
    private Screen(java.lang.String route) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getRoute() {
        return null;
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0016\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u0004\u00a8\u0006\b"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$Camera;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "createRoute", "", "exerciseId", "", "exerciseType", "app_debug"})
    public static final class Camera extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.Camera INSTANCE = null;
        
        private Camera() {
        }
        
        @org.jetbrains.annotations.NotNull
        public final java.lang.String createRoute(int exerciseId, @org.jetbrains.annotations.NotNull
        java.lang.String exerciseType) {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0004\u00a8\u0006\u0006"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$ExerciseDetail;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "createRoute", "", "exerciseId", "app_debug"})
    public static final class ExerciseDetail extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.ExerciseDetail INSTANCE = null;
        
        private ExerciseDetail() {
        }
        
        @org.jetbrains.annotations.NotNull
        public final java.lang.String createRoute(@org.jetbrains.annotations.NotNull
        java.lang.String exerciseId) {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$ExerciseList;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class ExerciseList extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.ExerciseList INSTANCE = null;
        
        private ExerciseList() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$History;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class History extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.History INSTANCE = null;
        
        private History() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$Home;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class Home extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.Home INSTANCE = null;
        
        private Home() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$Leaderboard;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class Leaderboard extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.Leaderboard INSTANCE = null;
        
        private Leaderboard() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$Login;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class Login extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.Login INSTANCE = null;
        
        private Login() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$Profile;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class Profile extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.Profile INSTANCE = null;
        
        private Profile() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$SignUp;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class SignUp extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.SignUp INSTANCE = null;
        
        private SignUp() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/example/ptchampion/ui/navigation/Screen$Splash;", "Lcom/example/ptchampion/ui/navigation/Screen;", "()V", "app_debug"})
    public static final class Splash extends com.example.ptchampion.ui.navigation.Screen {
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.ui.navigation.Screen.Splash INSTANCE = null;
        
        private Splash() {
        }
    }
}