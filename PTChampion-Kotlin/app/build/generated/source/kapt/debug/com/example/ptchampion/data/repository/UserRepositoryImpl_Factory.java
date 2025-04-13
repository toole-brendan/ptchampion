package com.example.ptchampion.data.repository;

import com.example.ptchampion.data.datastore.AuthDataStore;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import org.openapitools.client.apis.UsersApi;

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
public final class UserRepositoryImpl_Factory implements Factory<UserRepositoryImpl> {
  private final Provider<UsersApi> usersApiProvider;

  private final Provider<AuthDataStore> authDataStoreProvider;

  public UserRepositoryImpl_Factory(Provider<UsersApi> usersApiProvider,
      Provider<AuthDataStore> authDataStoreProvider) {
    this.usersApiProvider = usersApiProvider;
    this.authDataStoreProvider = authDataStoreProvider;
  }

  @Override
  public UserRepositoryImpl get() {
    return newInstance(usersApiProvider.get(), authDataStoreProvider.get());
  }

  public static UserRepositoryImpl_Factory create(Provider<UsersApi> usersApiProvider,
      Provider<AuthDataStore> authDataStoreProvider) {
    return new UserRepositoryImpl_Factory(usersApiProvider, authDataStoreProvider);
  }

  public static UserRepositoryImpl newInstance(UsersApi usersApi, AuthDataStore authDataStore) {
    return new UserRepositoryImpl(usersApi, authDataStore);
  }
}
