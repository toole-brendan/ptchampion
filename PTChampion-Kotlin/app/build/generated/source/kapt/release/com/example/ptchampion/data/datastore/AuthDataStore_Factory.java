package com.example.ptchampion.data.datastore;

import androidx.datastore.core.DataStore;
import androidx.datastore.preferences.core.Preferences;
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
public final class AuthDataStore_Factory implements Factory<AuthDataStore> {
  private final Provider<DataStore<Preferences>> dataStoreProvider;

  public AuthDataStore_Factory(Provider<DataStore<Preferences>> dataStoreProvider) {
    this.dataStoreProvider = dataStoreProvider;
  }

  @Override
  public AuthDataStore get() {
    return newInstance(dataStoreProvider.get());
  }

  public static AuthDataStore_Factory create(Provider<DataStore<Preferences>> dataStoreProvider) {
    return new AuthDataStore_Factory(dataStoreProvider);
  }

  public static AuthDataStore newInstance(DataStore<Preferences> dataStore) {
    return new AuthDataStore(dataStore);
  }
}
