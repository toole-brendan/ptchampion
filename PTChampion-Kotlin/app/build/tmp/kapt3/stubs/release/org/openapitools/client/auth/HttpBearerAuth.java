package org.openapitools.client.auth;

import java.io.IOException;
import okhttp3.Interceptor;
import okhttp3.Interceptor.Chain;
import okhttp3.Response;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000 \n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\b\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0019\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0005J\b\u0010\n\u001a\u00020\u0003H\u0002J\u0010\u0010\u000b\u001a\u00020\f2\u0006\u0010\r\u001a\u00020\u000eH\u0016J\b\u0010\u000f\u001a\u00020\u0003H\u0002R\u001a\u0010\u0004\u001a\u00020\u0003X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0006\u0010\u0007\"\u0004\b\b\u0010\tR\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0010"}, d2 = {"Lorg/openapitools/client/auth/HttpBearerAuth;", "Lokhttp3/Interceptor;", "schema", "", "bearerToken", "(Ljava/lang/String;Ljava/lang/String;)V", "getBearerToken", "()Ljava/lang/String;", "setBearerToken", "(Ljava/lang/String;)V", "headerValue", "intercept", "Lokhttp3/Response;", "chain", "Lokhttp3/Interceptor$Chain;", "upperCaseBearer", "app_release"})
public final class HttpBearerAuth implements okhttp3.Interceptor {
    @org.jetbrains.annotations.NotNull
    private java.lang.String schema;
    @org.jetbrains.annotations.NotNull
    private java.lang.String bearerToken;
    
    public HttpBearerAuth(@org.jetbrains.annotations.NotNull
    java.lang.String schema, @org.jetbrains.annotations.NotNull
    java.lang.String bearerToken) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getBearerToken() {
        return null;
    }
    
    public final void setBearerToken(@org.jetbrains.annotations.NotNull
    java.lang.String p0) {
    }
    
    @java.lang.Override
    @kotlin.jvm.Throws(exceptionClasses = {java.io.IOException.class})
    @org.jetbrains.annotations.NotNull
    public okhttp3.Response intercept(@org.jetbrains.annotations.NotNull
    okhttp3.Interceptor.Chain chain) throws java.io.IOException {
        return null;
    }
    
    private final java.lang.String headerValue() {
        return null;
    }
    
    private final java.lang.String upperCaseBearer() {
        return null;
    }
    
    public HttpBearerAuth() {
        super();
    }
}