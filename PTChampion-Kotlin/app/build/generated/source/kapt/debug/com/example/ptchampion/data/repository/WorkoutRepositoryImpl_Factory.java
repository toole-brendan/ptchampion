package com.example.ptchampion.data.repository;

import com.example.ptchampion.data.network.WorkoutApiService;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata
@DaggerGenerated
@Generated(
    value = "dagger.internal.codegen.ComponentProcessor",
    comments = "https://dagger.dev"
)
@SuppressWarnings({
    "unchecked",
    "rawtypes",
    "KotlinInternal",
    "KotlinInternalInJava"
})
public final class WorkoutRepositoryImpl_Factory implements Factory<WorkoutRepositoryImpl> {
  private final Provider<WorkoutApiService> workoutApiServiceProvider;

  public WorkoutRepositoryImpl_Factory(Provider<WorkoutApiService> workoutApiServiceProvider) {
    this.workoutApiServiceProvider = workoutApiServiceProvider;
  }

  @Override
  public WorkoutRepositoryImpl get() {
    return newInstance(workoutApiServiceProvider.get());
  }

  public static WorkoutRepositoryImpl_Factory create(
      Provider<WorkoutApiService> workoutApiServiceProvider) {
    return new WorkoutRepositoryImpl_Factory(workoutApiServiceProvider);
  }

  public static WorkoutRepositoryImpl newInstance(WorkoutApiService workoutApiService) {
    return new WorkoutRepositoryImpl(workoutApiService);
  }
}
