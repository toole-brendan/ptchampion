package com.example.ptchampion.data.repository;

import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import org.openapitools.client.apis.LeaderboardApi;

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
public final class LeaderboardRepositoryImpl_Factory implements Factory<LeaderboardRepositoryImpl> {
  private final Provider<LeaderboardApi> leaderboardApiProvider;

  public LeaderboardRepositoryImpl_Factory(Provider<LeaderboardApi> leaderboardApiProvider) {
    this.leaderboardApiProvider = leaderboardApiProvider;
  }

  @Override
  public LeaderboardRepositoryImpl get() {
    return newInstance(leaderboardApiProvider.get());
  }

  public static LeaderboardRepositoryImpl_Factory create(
      Provider<LeaderboardApi> leaderboardApiProvider) {
    return new LeaderboardRepositoryImpl_Factory(leaderboardApiProvider);
  }

  public static LeaderboardRepositoryImpl newInstance(LeaderboardApi leaderboardApi) {
    return new LeaderboardRepositoryImpl(leaderboardApi);
  }
}
