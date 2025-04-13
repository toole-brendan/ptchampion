package com.example.ptchampion.domain.exercise;

/**
 * Represents the current state of an exercise during analysis.
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\b\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005j\u0002\b\u0006j\u0002\b\u0007j\u0002\b\b\u00a8\u0006\t"}, d2 = {"Lcom/example/ptchampion/domain/exercise/ExerciseState;", "", "(Ljava/lang/String;I)V", "IDLE", "STARTING", "DOWN", "UP", "FINISHED", "INVALID", "app_debug"})
public enum ExerciseState {
    /*public static final*/ IDLE /* = new IDLE() */,
    /*public static final*/ STARTING /* = new STARTING() */,
    /*public static final*/ DOWN /* = new DOWN() */,
    /*public static final*/ UP /* = new UP() */,
    /*public static final*/ FINISHED /* = new FINISHED() */,
    /*public static final*/ INVALID /* = new INVALID() */;
    
    ExerciseState() {
    }
    
    @org.jetbrains.annotations.NotNull
    public static kotlin.enums.EnumEntries<com.example.ptchampion.domain.exercise.ExerciseState> getEntries() {
        return null;
    }
}