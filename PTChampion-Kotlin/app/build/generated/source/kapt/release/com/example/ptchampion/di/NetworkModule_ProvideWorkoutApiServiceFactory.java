package com.example.ptchampion.di;

import com.example.ptchampion.data.network.WorkoutApiService;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import retrofit2.Retrofit;

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
public final class NetworkModule_ProvideWorkoutApiServiceFactory implements Factory<WorkoutApiService> {
  private final Provider<Retrofit> retrofitProvider;

  public NetworkModule_ProvideWorkoutApiServiceFactory(Provider<Retrofit> retrofitProvider) {
    this.retrofitProvider = retrofitProvider;
  }

  @Override
  public WorkoutApiService get() {
    return provideWorkoutApiService(retrofitProvider.get());
  }

  public static NetworkModule_ProvideWorkoutApiServiceFactory create(
      Provider<Retrofit> retrofitProvider) {
    return new NetworkModule_ProvideWorkoutApiServiceFactory(retrofitProvider);
  }

  public static WorkoutApiService provideWorkoutApiService(Retrofit retrofit) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideWorkoutApiService(retrofit));
  }
}
