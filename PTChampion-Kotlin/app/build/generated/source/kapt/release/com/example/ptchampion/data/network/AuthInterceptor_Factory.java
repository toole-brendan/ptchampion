package com.example.ptchampion.data.network;

import com.example.ptchampion.data.repository.UserPreferencesRepository;
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
public final class AuthInterceptor_Factory implements Factory<AuthInterceptor> {
  private final Provider<UserPreferencesRepository> userPreferencesRepositoryProvider;

  public AuthInterceptor_Factory(
      Provider<UserPreferencesRepository> userPreferencesRepositoryProvider) {
    this.userPreferencesRepositoryProvider = userPreferencesRepositoryProvider;
  }

  @Override
  public AuthInterceptor get() {
    return newInstance(userPreferencesRepositoryProvider.get());
  }

  public static AuthInterceptor_Factory create(
      Provider<UserPreferencesRepository> userPreferencesRepositoryProvider) {
    return new AuthInterceptor_Factory(userPreferencesRepositoryProvider);
  }

  public static AuthInterceptor newInstance(UserPreferencesRepository userPreferencesRepository) {
    return new AuthInterceptor(userPreferencesRepository);
  }
}
