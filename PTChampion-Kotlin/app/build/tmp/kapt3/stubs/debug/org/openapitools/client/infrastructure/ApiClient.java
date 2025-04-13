package org.openapitools.client.infrastructure;

import org.openapitools.client.auth.HttpBearerAuth;
import okhttp3.Call;
import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import retrofit2.Retrofit;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Converter;
import retrofit2.CallAdapter;
import retrofit2.converter.scalars.ScalarsConverterFactory;
import com.squareup.moshi.Moshi;
import retrofit2.converter.moshi.MoshiConverterFactory;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000r\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010%\n\u0002\u0018\u0002\n\u0002\b\t\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010\u001c\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u0000 <2\u00020\u0001:\u0001<B5\b\u0016\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0007\u0012\f\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00030\t\u00a2\u0006\u0002\u0010\nB7\b\u0016\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0007\u0012\u0006\u0010\u000b\u001a\u00020\u0003\u0012\u0006\u0010\f\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\rBQ\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0007\u0012\n\b\u0002\u0010\u000e\u001a\u0004\u0018\u00010\u000f\u0012\u000e\b\u0002\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00120\u0011\u0012\u000e\b\u0002\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\u00140\u0011\u00a2\u0006\u0002\u0010\u0015J\u0016\u0010-\u001a\u00020\u00002\u0006\u0010\u000b\u001a\u00020\u00032\u0006\u0010.\u001a\u00020\u0018J\u001f\u0010/\u001a\u0002H0\"\u0004\b\u0000\u001002\f\u00101\u001a\b\u0012\u0004\u0012\u0002H002\u00a2\u0006\u0002\u00103J\b\u00104\u001a\u00020#H\u0002J\u000e\u00105\u001a\u00020\u00002\u0006\u0010\f\u001a\u00020\u0003J\u001a\u0010&\u001a\u00020\u00002\u0012\u0010!\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020#0\"J:\u00106\u001a\u00020#\"\u0004\b\u0000\u00107\"\u0006\b\u0001\u00108\u0018\u0001*\b\u0012\u0004\u0012\u0002H7092\u0017\u0010:\u001a\u0013\u0012\u0004\u0012\u0002H8\u0012\u0004\u0012\u00020#0\"\u00a2\u0006\u0002\b;H\u0082\bR\u001a\u0010\u0016\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00180\u0017X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00120\u0011X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u000e\u001a\u0004\u0018\u00010\u000fX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010\u0019\u001a\u00020\u00058BX\u0082\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001c\u0010\u001d\u001a\u0004\b\u001a\u0010\u001bR\u0014\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\u00140\u0011X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010\u001e\u001a\u00020\u00058BX\u0082\u0084\u0002\u00a2\u0006\f\n\u0004\b \u0010\u001d\u001a\u0004\b\u001f\u0010\u001bR(\u0010!\u001a\u0010\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020#\u0018\u00010\"X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b$\u0010%\"\u0004\b&\u0010\'R\u0010\u0010\u0004\u001a\u0004\u0018\u00010\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010(\u001a\u00020)8BX\u0082\u0084\u0002\u00a2\u0006\f\n\u0004\b,\u0010\u001d\u001a\u0004\b*\u0010+R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006="}, d2 = {"Lorg/openapitools/client/infrastructure/ApiClient;", "", "baseUrl", "", "okHttpClientBuilder", "Lokhttp3/OkHttpClient$Builder;", "serializerBuilder", "Lcom/squareup/moshi/Moshi$Builder;", "authNames", "", "(Ljava/lang/String;Lokhttp3/OkHttpClient$Builder;Lcom/squareup/moshi/Moshi$Builder;[Ljava/lang/String;)V", "authName", "bearerToken", "(Ljava/lang/String;Lokhttp3/OkHttpClient$Builder;Lcom/squareup/moshi/Moshi$Builder;Ljava/lang/String;Ljava/lang/String;)V", "callFactory", "Lokhttp3/Call$Factory;", "callAdapterFactories", "", "Lretrofit2/CallAdapter$Factory;", "converterFactories", "Lretrofit2/Converter$Factory;", "(Ljava/lang/String;Lokhttp3/OkHttpClient$Builder;Lcom/squareup/moshi/Moshi$Builder;Lokhttp3/Call$Factory;Ljava/util/List;Ljava/util/List;)V", "apiAuthorizations", "", "Lokhttp3/Interceptor;", "clientBuilder", "getClientBuilder", "()Lokhttp3/OkHttpClient$Builder;", "clientBuilder$delegate", "Lkotlin/Lazy;", "defaultClientBuilder", "getDefaultClientBuilder", "defaultClientBuilder$delegate", "logger", "Lkotlin/Function1;", "", "getLogger", "()Lkotlin/jvm/functions/Function1;", "setLogger", "(Lkotlin/jvm/functions/Function1;)V", "retrofitBuilder", "Lretrofit2/Retrofit$Builder;", "getRetrofitBuilder", "()Lretrofit2/Retrofit$Builder;", "retrofitBuilder$delegate", "addAuthorization", "authorization", "createService", "S", "serviceClass", "Ljava/lang/Class;", "(Ljava/lang/Class;)Ljava/lang/Object;", "normalizeBaseUrl", "setBearerToken", "runOnFirst", "T", "U", "", "callback", "Lkotlin/ExtensionFunctionType;", "Companion", "app_debug"})
public final class ApiClient {
    @org.jetbrains.annotations.NotNull
    private java.lang.String baseUrl;
    @org.jetbrains.annotations.Nullable
    private final okhttp3.OkHttpClient.Builder okHttpClientBuilder = null;
    @org.jetbrains.annotations.NotNull
    private final com.squareup.moshi.Moshi.Builder serializerBuilder = null;
    @org.jetbrains.annotations.Nullable
    private final okhttp3.Call.Factory callFactory = null;
    @org.jetbrains.annotations.NotNull
    private final java.util.List<retrofit2.CallAdapter.Factory> callAdapterFactories = null;
    @org.jetbrains.annotations.NotNull
    private final java.util.List<retrofit2.Converter.Factory> converterFactories = null;
    @org.jetbrains.annotations.NotNull
    private final java.util.Map<java.lang.String, okhttp3.Interceptor> apiAuthorizations = null;
    @org.jetbrains.annotations.Nullable
    private kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> logger;
    @org.jetbrains.annotations.NotNull
    private final kotlin.Lazy retrofitBuilder$delegate = null;
    @org.jetbrains.annotations.NotNull
    private final kotlin.Lazy clientBuilder$delegate = null;
    @org.jetbrains.annotations.NotNull
    private final kotlin.Lazy defaultClientBuilder$delegate = null;
    @org.jetbrains.annotations.NotNull
    private static final java.lang.String baseUrlKey = "org.openapitools.client.baseUrl";
    @org.jetbrains.annotations.NotNull
    private static final kotlin.Lazy<?> defaultBasePath$delegate = null;
    @org.jetbrains.annotations.NotNull
    public static final org.openapitools.client.infrastructure.ApiClient.Companion Companion = null;
    
    public ApiClient(@org.jetbrains.annotations.NotNull
    java.lang.String baseUrl, @org.jetbrains.annotations.Nullable
    okhttp3.OkHttpClient.Builder okHttpClientBuilder, @org.jetbrains.annotations.NotNull
    com.squareup.moshi.Moshi.Builder serializerBuilder, @org.jetbrains.annotations.Nullable
    okhttp3.Call.Factory callFactory, @org.jetbrains.annotations.NotNull
    java.util.List<? extends retrofit2.CallAdapter.Factory> callAdapterFactories, @org.jetbrains.annotations.NotNull
    java.util.List<? extends retrofit2.Converter.Factory> converterFactories) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable
    public final kotlin.jvm.functions.Function1<java.lang.String, kotlin.Unit> getLogger() {
        return null;
    }
    
    public final void setLogger(@org.jetbrains.annotations.Nullable
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> p0) {
    }
    
    private final retrofit2.Retrofit.Builder getRetrofitBuilder() {
        return null;
    }
    
    private final okhttp3.OkHttpClient.Builder getClientBuilder() {
        return null;
    }
    
    private final okhttp3.OkHttpClient.Builder getDefaultClientBuilder() {
        return null;
    }
    
    public ApiClient(@org.jetbrains.annotations.NotNull
    java.lang.String baseUrl, @org.jetbrains.annotations.Nullable
    okhttp3.OkHttpClient.Builder okHttpClientBuilder, @org.jetbrains.annotations.NotNull
    com.squareup.moshi.Moshi.Builder serializerBuilder, @org.jetbrains.annotations.NotNull
    java.lang.String[] authNames) {
        super();
    }
    
    public ApiClient(@org.jetbrains.annotations.NotNull
    java.lang.String baseUrl, @org.jetbrains.annotations.Nullable
    okhttp3.OkHttpClient.Builder okHttpClientBuilder, @org.jetbrains.annotations.NotNull
    com.squareup.moshi.Moshi.Builder serializerBuilder, @org.jetbrains.annotations.NotNull
    java.lang.String authName, @org.jetbrains.annotations.NotNull
    java.lang.String bearerToken) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.infrastructure.ApiClient setBearerToken(@org.jetbrains.annotations.NotNull
    java.lang.String bearerToken) {
        return null;
    }
    
    /**
     * Adds an authorization to be used by the client
     * @param authName Authentication name
     * @param authorization Authorization interceptor
     * @return ApiClient
     */
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.infrastructure.ApiClient addAuthorization(@org.jetbrains.annotations.NotNull
    java.lang.String authName, @org.jetbrains.annotations.NotNull
    okhttp3.Interceptor authorization) {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.infrastructure.ApiClient setLogger(@org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> logger) {
        return null;
    }
    
    public final <S extends java.lang.Object>S createService(@org.jetbrains.annotations.NotNull
    java.lang.Class<S> serviceClass) {
        return null;
    }
    
    private final void normalizeBaseUrl() {
    }
    
    public ApiClient() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    protected static final java.lang.String getBaseUrlKey() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public static final java.lang.String getDefaultBasePath() {
        return null;
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\t\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u001c\u0010\u0003\u001a\u00020\u00048\u0004X\u0085D\u00a2\u0006\u000e\n\u0000\u0012\u0004\b\u0005\u0010\u0002\u001a\u0004\b\u0006\u0010\u0007R!\u0010\b\u001a\u00020\u00048FX\u0087\u0084\u0002\u00a2\u0006\u0012\n\u0004\b\u000b\u0010\f\u0012\u0004\b\t\u0010\u0002\u001a\u0004\b\n\u0010\u0007\u00a8\u0006\r"}, d2 = {"Lorg/openapitools/client/infrastructure/ApiClient$Companion;", "", "()V", "baseUrlKey", "", "getBaseUrlKey$annotations", "getBaseUrlKey", "()Ljava/lang/String;", "defaultBasePath", "getDefaultBasePath$annotations", "getDefaultBasePath", "defaultBasePath$delegate", "Lkotlin/Lazy;", "app_debug"})
    public static final class Companion {
        
        private Companion() {
            super();
        }
        
        @org.jetbrains.annotations.NotNull
        protected final java.lang.String getBaseUrlKey() {
            return null;
        }
        
        @kotlin.jvm.JvmStatic
        @java.lang.Deprecated
        protected static void getBaseUrlKey$annotations() {
        }
        
        @org.jetbrains.annotations.NotNull
        public final java.lang.String getDefaultBasePath() {
            return null;
        }
        
        @kotlin.jvm.JvmStatic
        @java.lang.Deprecated
        public static void getDefaultBasePath$annotations() {
        }
    }
}