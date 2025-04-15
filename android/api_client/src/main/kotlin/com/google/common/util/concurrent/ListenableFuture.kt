package com.google.common.util.concurrent

import java.util.concurrent.Future
import java.util.concurrent.Executor

/**
 * Stub implementation of Google's ListenableFuture interface for compatibility.
 */
interface ListenableFuture<V> : Future<V> {
    // Add the necessary method to avoid compiler error
    fun addListener(listener: Runnable, executor: Executor)
} 