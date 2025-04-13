package org.openapitools.client.models;

import org.openapitools.client.models.SyncRequestDataProfile;
import org.openapitools.client.models.SyncRequestDataUserExercisesInner;
import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * @param userExercises 
 * @param profile
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\t\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B#\u0012\u0010\b\u0003\u0010\u0002\u001a\n\u0012\u0004\u0012\u00020\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u0006\u00a2\u0006\u0002\u0010\u0007J\u0011\u0010\f\u001a\n\u0012\u0004\u0012\u00020\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010\r\u001a\u0004\u0018\u00010\u0006H\u00c6\u0003J\'\u0010\u000e\u001a\u00020\u00002\u0010\b\u0003\u0010\u0002\u001a\n\u0012\u0004\u0012\u00020\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u0006H\u00c6\u0001J\u0013\u0010\u000f\u001a\u00020\u00102\b\u0010\u0011\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u0012\u001a\u00020\u0013H\u00d6\u0001J\t\u0010\u0014\u001a\u00020\u0015H\u00d6\u0001R\u0013\u0010\u0005\u001a\u0004\u0018\u00010\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\tR\u0019\u0010\u0002\u001a\n\u0012\u0004\u0012\u00020\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000b\u00a8\u0006\u0016"}, d2 = {"Lorg/openapitools/client/models/SyncRequestData;", "", "userExercises", "", "Lorg/openapitools/client/models/SyncRequestDataUserExercisesInner;", "profile", "Lorg/openapitools/client/models/SyncRequestDataProfile;", "(Ljava/util/List;Lorg/openapitools/client/models/SyncRequestDataProfile;)V", "getProfile", "()Lorg/openapitools/client/models/SyncRequestDataProfile;", "getUserExercises", "()Ljava/util/List;", "component1", "component2", "copy", "equals", "", "other", "hashCode", "", "toString", "", "app_debug"})
public final class SyncRequestData {
    @org.jetbrains.annotations.Nullable
    private final java.util.List<org.openapitools.client.models.SyncRequestDataUserExercisesInner> userExercises = null;
    @org.jetbrains.annotations.Nullable
    private final org.openapitools.client.models.SyncRequestDataProfile profile = null;
    
    public SyncRequestData(@com.squareup.moshi.Json(name = "userExercises")
    @org.jetbrains.annotations.Nullable
    java.util.List<org.openapitools.client.models.SyncRequestDataUserExercisesInner> userExercises, @com.squareup.moshi.Json(name = "profile")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.SyncRequestDataProfile profile) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.util.List<org.openapitools.client.models.SyncRequestDataUserExercisesInner> getUserExercises() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final org.openapitools.client.models.SyncRequestDataProfile getProfile() {
        return null;
    }
    
    public SyncRequestData() {
        super();
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.util.List<org.openapitools.client.models.SyncRequestDataUserExercisesInner> component1() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final org.openapitools.client.models.SyncRequestDataProfile component2() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.SyncRequestData copy(@com.squareup.moshi.Json(name = "userExercises")
    @org.jetbrains.annotations.Nullable
    java.util.List<org.openapitools.client.models.SyncRequestDataUserExercisesInner> userExercises, @com.squareup.moshi.Json(name = "profile")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.SyncRequestDataProfile profile) {
        return null;
    }
    
    @java.lang.Override
    public boolean equals(@org.jetbrains.annotations.Nullable
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public java.lang.String toString() {
        return null;
    }
}