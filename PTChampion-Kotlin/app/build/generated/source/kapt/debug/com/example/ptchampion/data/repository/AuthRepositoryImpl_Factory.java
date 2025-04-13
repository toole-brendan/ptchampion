package com.example.ptchampion.data.repository;

import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import org.openapitools.client.apis.AuthApi;

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
public final class AuthRepositoryImpl_Factory implements Factory<AuthRepositoryImpl> {
  private final Provider<AuthApi> apiProvider;

  public AuthRepositoryImpl_Factory(Provider<AuthApi> apiProvider) {
    this.apiProvider = apiProvider;
  }

  @Override
  public AuthRepositoryImpl get() {
    return newInstance(apiProvider.get());
  }

  public static AuthRepositoryImpl_Factory create(Provider<AuthApi> apiProvider) {
    return new AuthRepositoryImpl_Factory(apiProvider);
  }

  public static AuthRepositoryImpl newInstance(AuthApi api) {
    return new AuthRepositoryImpl(api);
  }
}
