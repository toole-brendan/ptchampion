package org.openapitools.client.infrastructure;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0007\u0018\u00002\u00020\u0001:\u0005\u0003\u0004\u0005\u0006\u0007B\u0005\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\b"}, d2 = {"Lorg/openapitools/client/infrastructure/CollectionFormats;", "", "()V", "CSVParams", "PIPESParams", "SPACEParams", "SSVParams", "TSVParams", "app_release"})
public final class CollectionFormats {
    
    public CollectionFormats() {
        super();
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0006\b\u0016\u0018\u00002\u00020\u0001B\u0015\b\u0016\u0012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\u0002\u0010\u0005B\u001b\b\u0016\u0012\u0012\u0010\u0002\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00040\u0006\"\u00020\u0004\u00a2\u0006\u0002\u0010\u0007J\b\u0010\u000b\u001a\u00020\u0004H\u0016R \u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\b\u0010\t\"\u0004\b\n\u0010\u0005\u00a8\u0006\f"}, d2 = {"Lorg/openapitools/client/infrastructure/CollectionFormats$CSVParams;", "", "params", "", "", "(Ljava/util/List;)V", "", "([Ljava/lang/String;)V", "getParams", "()Ljava/util/List;", "setParams", "toString", "app_release"})
    public static class CSVParams {
        @org.jetbrains.annotations.NotNull
        private java.util.List<java.lang.String> params;
        
        @org.jetbrains.annotations.NotNull
        public final java.util.List<java.lang.String> getParams() {
            return null;
        }
        
        public final void setParams(@org.jetbrains.annotations.NotNull
        java.util.List<java.lang.String> p0) {
        }
        
        public CSVParams(@org.jetbrains.annotations.NotNull
        java.util.List<java.lang.String> params) {
            super();
        }
        
        public CSVParams(@org.jetbrains.annotations.NotNull
        java.lang.String... params) {
            super();
        }
        
        @java.lang.Override
        @org.jetbrains.annotations.NotNull
        public java.lang.String toString() {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0015\b\u0016\u0012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\u0002\u0010\u0005B\u001b\b\u0016\u0012\u0012\u0010\u0002\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00040\u0006\"\u00020\u0004\u00a2\u0006\u0002\u0010\u0007J\b\u0010\b\u001a\u00020\u0004H\u0016\u00a8\u0006\t"}, d2 = {"Lorg/openapitools/client/infrastructure/CollectionFormats$PIPESParams;", "Lorg/openapitools/client/infrastructure/CollectionFormats$CSVParams;", "params", "", "", "(Ljava/util/List;)V", "", "([Ljava/lang/String;)V", "toString", "app_release"})
    public static final class PIPESParams extends org.openapitools.client.infrastructure.CollectionFormats.CSVParams {
        
        public PIPESParams(@org.jetbrains.annotations.NotNull
        java.util.List<java.lang.String> params) {
            super(null);
        }
        
        public PIPESParams(@org.jetbrains.annotations.NotNull
        java.lang.String... params) {
            super(null);
        }
        
        @java.lang.Override
        @org.jetbrains.annotations.NotNull
        public java.lang.String toString() {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lorg/openapitools/client/infrastructure/CollectionFormats$SPACEParams;", "Lorg/openapitools/client/infrastructure/CollectionFormats$SSVParams;", "()V", "app_release"})
    public static final class SPACEParams extends org.openapitools.client.infrastructure.CollectionFormats.SSVParams {
        
        public SPACEParams() {
            super(null);
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0003\b\u0016\u0018\u00002\u00020\u0001B\u0015\b\u0016\u0012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\u0002\u0010\u0005B\u001b\b\u0016\u0012\u0012\u0010\u0002\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00040\u0006\"\u00020\u0004\u00a2\u0006\u0002\u0010\u0007J\b\u0010\b\u001a\u00020\u0004H\u0016\u00a8\u0006\t"}, d2 = {"Lorg/openapitools/client/infrastructure/CollectionFormats$SSVParams;", "Lorg/openapitools/client/infrastructure/CollectionFormats$CSVParams;", "params", "", "", "(Ljava/util/List;)V", "", "([Ljava/lang/String;)V", "toString", "app_release"})
    public static class SSVParams extends org.openapitools.client.infrastructure.CollectionFormats.CSVParams {
        
        public SSVParams(@org.jetbrains.annotations.NotNull
        java.util.List<java.lang.String> params) {
            super(null);
        }
        
        public SSVParams(@org.jetbrains.annotations.NotNull
        java.lang.String... params) {
            super(null);
        }
        
        @java.lang.Override
        @org.jetbrains.annotations.NotNull
        public java.lang.String toString() {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0015\b\u0016\u0012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\u0002\u0010\u0005B\u001b\b\u0016\u0012\u0012\u0010\u0002\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00040\u0006\"\u00020\u0004\u00a2\u0006\u0002\u0010\u0007J\b\u0010\b\u001a\u00020\u0004H\u0016\u00a8\u0006\t"}, d2 = {"Lorg/openapitools/client/infrastructure/CollectionFormats$TSVParams;", "Lorg/openapitools/client/infrastructure/CollectionFormats$CSVParams;", "params", "", "", "(Ljava/util/List;)V", "", "([Ljava/lang/String;)V", "toString", "app_release"})
    public static final class TSVParams extends org.openapitools.client.infrastructure.CollectionFormats.CSVParams {
        
        public TSVParams(@org.jetbrains.annotations.NotNull
        java.util.List<java.lang.String> params) {
            super(null);
        }
        
        public TSVParams(@org.jetbrains.annotations.NotNull
        java.lang.String... params) {
            super(null);
        }
        
        @java.lang.Override
        @org.jetbrains.annotations.NotNull
        public java.lang.String toString() {
            return null;
        }
    }
}