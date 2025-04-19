import http from 'k6/http';
import { sleep, check } from 'k6';

export let options = {
  vus: __ENV.VUS ? parseInt(__ENV.VUS) : 50, // virtual users
  duration: __ENV.DURATION || '30s',        // test duration
  thresholds: {
    http_req_duration: ['p(95)<500'],       // 95% of requests must complete < 500ms
  },
};

// Base URL can be overridden via BASE_URL env variable
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const ENDPOINT = `${BASE_URL}/api/v1/leaderboard/push_up?limit=20`;

export default function () {
  const res = http.get(ENDPOINT);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
} 