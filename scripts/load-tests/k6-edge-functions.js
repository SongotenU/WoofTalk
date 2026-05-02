// k6 load test for WoofTalk Supabase Edge Functions
// Run: k6 run scripts/load-tests/k6-edge-functions.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up to 10 users
    { duration: '1m', target: 50 },    // Ramp up to 50 users
    { duration: '1m', target: 100 },   // Spike to 100 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95th percentile < 2s
    http_req_failed: ['rate<0.01'],    // Error rate < 1%
    errors: ['rate<0.05'],             // Custom error rate < 5%
  },
};

const BASE = __ENV.SUPABASE_FUNCTIONS_URL || ''; // No default - requires explicit URL for UAT
const API_KEY = __ENV.SUPABASE_ANON_KEY || 'test-key';
const AUTH_TOKEN = __ENV.SUPABASE_USER_TOKEN || '';

// Skip all tests if no BASE URL provided (local development without Supabase)
const SKIP_TESTS = !BASE;

export default function () {
  // Skip all tests if no BASE URL is configured
  if (SKIP_TESTS) {
    return;
  }

  // Test translate function
  const translateHeaders = {
    'Content-Type': 'application/json',
    'apikey': API_KEY,
  };
  if (AUTH_TOKEN) {
    translateHeaders['Authorization'] = `Bearer ${AUTH_TOKEN}`;
  }
  const translateRes = http.post(
    `${BASE}/translate`,
    JSON.stringify({
      input: 'hello',
      direction: 'humanToDog',
    }),
    { headers: translateHeaders },
  );

  check(translateRes, {
    'translate: status is 200': (r) => r.status === 200,
    'translate: response < 2s': (r) => r.timings.duration < 2000,
    'translate: has body': (r) => r.body && r.body.length > 0,
  }) || errorRate.add(1);

  sleep(1);

  // Test search function
  const searchHeaders = {
    'Content-Type': 'application/json',
    'apikey': API_KEY,
  };
  if (AUTH_TOKEN) {
    searchHeaders['Authorization'] = `Bearer ${AUTH_TOKEN}`;
  }
  const searchRes = http.post(
    `${BASE}/phrases-search`,
    JSON.stringify({ query: 'hello', limit: 10 }),
    {
      headers: searchHeaders,
      timeout: '5s',
    },
  );

  check(searchRes, {
    'search: status is 200': (r) => r.status === 200,
    'search: response < 1s': (r) => r.timings.duration < 1000,
  }) || errorRate.add(1);

  sleep(1);
}
