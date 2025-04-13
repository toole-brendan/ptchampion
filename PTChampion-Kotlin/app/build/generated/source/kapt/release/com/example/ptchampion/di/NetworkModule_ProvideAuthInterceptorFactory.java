package com.example.ptchampion.di;

import com.example.ptchampion.data.network.AuthInterceptor;
import com.example.ptchampion.data.repository.UserPreferencesRepository;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
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
public final class NetworkModule_ProvideAuthInterceptorFactory implements Factory<AuthInterceptor> {
  private final Provider<UserPreferencesRepository> userPreferencesRepositoryProvider;

  public NetworkModule_ProvideAuthInterceptorFactory(
      Provider<UserPreferencesRepository> userPreferencesRepositoryProvider) {
    this.userPreferencesRepositoryProvider = userPreferencesRepositoryProvider;
  }

  @Override
  public AuthInterceptor get() {
    return provideAuthInterceptor(userPreferencesRepositoryProvider.get());
  }

  public static NetworkModule_ProvideAuthInterceptorFactory create(
      Provider<UserPreferencesRepository> userPreferencesRepositoryProvider) {
    return new NetworkModule_ProvideAuthInterceptorFactory(userPreferencesRepositoryProvider);
  }

  public static AuthInterceptor provideAuthInterceptor(
      UserPreferencesRepository userPreferencesRepository) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideAuthInterceptor(userPreferencesRepository));
  }
}
