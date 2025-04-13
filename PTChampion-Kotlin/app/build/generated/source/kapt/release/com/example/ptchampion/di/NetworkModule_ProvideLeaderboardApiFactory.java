package com.example.ptchampion.di;

import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import org.openapitools.client.apis.LeaderboardApi;
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
public final class NetworkModule_ProvideLeaderboardApiFactory implements Factory<LeaderboardApi> {
  private final Provider<Retrofit> retrofitProvider;

  public NetworkModule_ProvideLeaderboardApiFactory(Provider<Retrofit> retrofitProvider) {
    this.retrofitProvider = retrofitProvider;
  }

  @Override
  public LeaderboardApi get() {
    return provideLeaderboardApi(retrofitProvider.get());
  }

  public static NetworkModule_ProvideLeaderboardApiFactory create(
      Provider<Retrofit> retrofitProvider) {
    return new NetworkModule_ProvideLeaderboardApiFactory(retrofitProvider);
  }

  public static LeaderboardApi provideLeaderboardApi(Retrofit retrofit) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideLeaderboardApi(retrofit));
  }
}
