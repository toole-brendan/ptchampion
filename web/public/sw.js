"use strict";
(() => {
  // src/serviceWorker.ts
  var STATIC_CACHE_NAME = "pt-champion-static-v4";
  var DYNAMIC_CACHE_NAME = "pt-champion-dynamic-v4";
  var API_CACHE_NAME = "pt-champion-api-v4";
  var APP_SHELL_ASSETS = [
    "/",
    "/manifest.json",
    "/offline.html"
  ];
  self.addEventListener("install", (event) => {
    console.log("[Service Worker] Installing");
    self.skipWaiting();
    event.waitUntil(
      caches.open(STATIC_CACHE_NAME).then((cache) => {
        console.log("[Service Worker] Caching app shell");
        return cache.addAll(APP_SHELL_ASSETS);
      })
    );
  });
  self.addEventListener("activate", (event) => {
    console.log("[Service Worker] Activating");
    event.waitUntil(
      caches.keys().then((keyList) => {
        return Promise.all(
          keyList.map((key) => {
            if (key !== STATIC_CACHE_NAME && key !== DYNAMIC_CACHE_NAME && key !== API_CACHE_NAME) {
              console.log("[Service Worker] Removing old cache", key);
              return caches.delete(key);
            }
            return Promise.resolve();
          })
        );
      }).then(() => self.clients.claim())
    );
  });
  self.addEventListener("fetch", (event) => {
    const request = event.request;
    const url = new URL(request.url);
    if (request.method !== "GET" || url.origin.includes("chrome-extension")) {
      return;
    }
    if (url.pathname.includes("/api/")) {
      event.respondWith(networkFirstStrategy(request));
      return;
    }
    if (APP_SHELL_ASSETS.includes(url.pathname) || url.pathname.includes("/assets/")) {
      event.respondWith(cacheFirstStrategy(request));
      return;
    }
    if (request.mode === "navigate" || request.headers.get("accept")?.includes("text/html")) {
      event.respondWith(
        // FIX: Ensure we always return a Response by handling undefined case
        fetch(request).catch(() => {
          console.log("[Service Worker] Serving offline page for navigation");
          return caches.match("/offline.html").then((response) => {
            return response || new Response("Offline page not found", {
              status: 503,
              headers: { "Content-Type": "text/plain" }
            });
          });
        })
      );
      return;
    }
    event.respondWith(staleWhileRevalidateStrategy(request));
  });
  async function networkFirstStrategy(request) {
    try {
      const networkResponse = await fetch(request);
      const cache = await caches.open(API_CACHE_NAME);
      cache.put(request, networkResponse.clone());
      return networkResponse;
    } catch (_error) {
      console.log("[Service Worker] Network request failed, trying cache", request.url);
      const cachedResponse = await caches.match(request);
      if (cachedResponse) {
        return cachedResponse;
      }
      return new Response(JSON.stringify({
        error: "Network request failed and no cached version available"
      }), {
        status: 503,
        headers: { "Content-Type": "application/json" }
      });
    }
  }
  async function cacheFirstStrategy(request) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    try {
      const networkResponse = await fetch(request);
      const cache = await caches.open(DYNAMIC_CACHE_NAME);
      cache.put(request, networkResponse.clone());
      return networkResponse;
    } catch (_error) {
      console.log("[Service Worker] Both cache and network failed", request.url);
      if (request.url.includes(".png") || request.url.includes(".jpg") || request.url.includes(".svg")) {
        return new Response("", { status: 404 });
      }
      return new Response("Resource not available offline", { status: 404 });
    }
  }
  async function staleWhileRevalidateStrategy(request) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      fetch(request).then((networkResponse) => {
        caches.open(DYNAMIC_CACHE_NAME).then((cache) => {
          cache.put(request, networkResponse);
        }).catch(
          // eslint-disable-next-line @typescript-eslint/no-unused-vars
          (_error) => console.log("[Service Worker] Failed to update cache")
        );
      }).catch(() => console.log("[Service Worker] Background refresh failed"));
      return cachedResponse;
    }
    try {
      const networkResponse = await fetch(request);
      const cache = await caches.open(DYNAMIC_CACHE_NAME);
      cache.put(request, networkResponse.clone());
      return networkResponse;
    } catch (_error) {
      console.log("[Service Worker] Network request failed with no cache entry", request.url);
      return new Response("Not available offline", { status: 404 });
    }
  }
  self.addEventListener("sync", (event) => {
    if (event.tag === "sync-workouts" || event.tag === "pt-champion-sync") {
      notifyClients({ type: "SYNC_STATUS", status: "syncing" });
      event.waitUntil(
        syncWorkouts().then((syncedCount) => {
          notifyClients({
            type: "SYNC_STATUS",
            status: "success",
            data: { count: syncedCount }
          });
        }).catch((error) => {
          console.error("[Service Worker] Sync failed:", error);
          notifyClients({ type: "SYNC_STATUS", status: "error" });
        })
      );
    }
  });
  function notifyClients(message) {
    self.clients.matchAll().then((clients) => {
      clients.forEach((client) => {
        client.postMessage(message);
      });
    });
  }
  self.addEventListener(
    "message",
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    (event) => {
      if (event.data && event.data.type === "SYNC_STATUS_UPDATE") {
        notifyClients({
          type: "SYNC_STATUS",
          status: event.data.status
        });
      }
      if (event.data && event.data.type === "SKIP_WAITING") {
        self.skipWaiting();
      }
    }
  );
  async function syncWorkouts() {
    try {
      console.log("[Service Worker] Syncing pending workouts");
      const db = await openDatabase();
      if (!db) {
        console.error("[Service Worker] Failed to open database");
        return 0;
      }
      const pendingExercises = await getAllPendingExercises(db);
      if (pendingExercises.length === 0) {
        console.log("[Service Worker] No pending workouts to sync");
        return 0;
      }
      let syncedCount = 0;
      for (const exercise of pendingExercises) {
        try {
          await incrementSyncAttempt(db, exercise.id);
          if (exercise.syncAttempts > 5) {
            console.warn(`[Service Worker] Skipping exercise ${exercise.id} after ${exercise.syncAttempts} failed attempts`);
            continue;
          }
          const requestData = {
            exercise_id: exercise.exerciseId,
            reps: exercise.reps,
            duration: exercise.duration,
            distance: exercise.distance,
            notes: exercise.notes
          };
          const response = await fetch("/api/v1/exercises", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${await getAuthToken()}`
            },
            body: JSON.stringify(requestData)
          });
          if (!response.ok) {
            throw new Error(`Server returned ${response.status}: ${response.statusText}`);
          }
          await deletePendingExercise(db, exercise.id);
          syncedCount++;
        } catch (error) {
          console.error(`[Service Worker] Failed to sync exercise ${exercise.id}:`, error);
        }
      }
      console.log(`[Service Worker] Successfully synced ${syncedCount} workouts`);
      return syncedCount;
    } catch (error) {
      console.error("[Service Worker] Workout sync failed:", error);
      throw error;
    }
  }
  async function getAuthToken() {
    try {
      const tokenCache = await caches.open("auth-token-cache");
      const tokenResponse = await tokenCache.match("/auth-token");
      if (tokenResponse) {
        const tokenData = await tokenResponse.json();
        return tokenData.token;
      }
      return null;
    } catch (error) {
      console.error("[Service Worker] Failed to get auth token:", error);
      return null;
    }
  }
  async function openDatabase() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open("pt-champion-db", 2);
      request.onerror = () => {
        console.error("[Service Worker] IndexedDB error");
        reject(request.error);
      };
      request.onsuccess = () => {
        resolve(request.result);
      };
      request.onupgradeneeded = (event) => {
        const db = request.result;
        if (!db.objectStoreNames.contains("pendingExercises")) {
          const pendingStore = db.createObjectStore("pendingExercises", { keyPath: "id" });
          pendingStore.createIndex("by-created", "createdAt");
          pendingStore.createIndex("by-sync-attempts", "syncAttempts");
        }
      };
    });
  }
  async function getAllPendingExercises(db) {
    return new Promise((resolve, reject) => {
      const transaction = db.transaction("pendingExercises", "readonly");
      const store = transaction.objectStore("pendingExercises");
      const request = store.getAll();
      request.onerror = () => {
        reject(request.error);
      };
      request.onsuccess = () => {
        resolve(request.result);
      };
    });
  }
  async function incrementSyncAttempt(db, id) {
    return new Promise((resolve, reject) => {
      const transaction = db.transaction("pendingExercises", "readwrite");
      const store = transaction.objectStore("pendingExercises");
      const getRequest = store.get(id);
      getRequest.onerror = () => {
        reject(getRequest.error);
      };
      getRequest.onsuccess = () => {
        const exercise = getRequest.result;
        if (exercise) {
          exercise.syncAttempts += 1;
          const updateRequest = store.put(exercise);
          updateRequest.onerror = () => {
            reject(updateRequest.error);
          };
          updateRequest.onsuccess = () => {
            resolve();
          };
        } else {
          resolve();
        }
      };
    });
  }
  async function deletePendingExercise(db, id) {
    return new Promise((resolve, reject) => {
      const transaction = db.transaction("pendingExercises", "readwrite");
      const store = transaction.objectStore("pendingExercises");
      const request = store.delete(id);
      request.onerror = () => {
        reject(request.error);
      };
      request.onsuccess = () => {
        resolve();
      };
    });
  }
})();
