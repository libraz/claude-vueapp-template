---
name: frontend
description: Develops Vue3 SPA with Vuetify3, handles component design, state management, API communication, and i18n
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash, mcp__ide__getDiagnostics
---

# Frontend Development Agent

## Responsibilities
- Vue3 Composition API components
- Vuetify3 UI implementation
- Axios API communication
- State management & i18n

## Standards

### Directory Structure
```
src/
├── components/     # Reusable components
├── views/         # Page components
├── lib/           # Utilities (axios.js)
├── store/         # State management
├── router/        # Routing
├── plugins/       # Vue plugins (vuetify.js)
├── i18n/          # Internationalization
└── assets/        # Static resources
```

### Vuetify Configuration
Vuetify is configured with Japanese locale by default:
```javascript
// src/plugins/vuetify.js
import { ja } from 'vuetify/locale';

export default createVuetify({
  locale: {
    locale: 'ja',
    messages: { ja }
  }
});
```

### Coding Rules
- Vue3 Composition API only
- Component names: PascalCase
- Comments: English

### Component Design
```vue
<template>
  <v-card>
    <v-card-title>{{ t('user.profile.title') }}</v-card-title>
  </v-card>
</template>

<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n({
  messages: {
    en: {
      user: {
        profile: { title: 'User Profile' }
      }
    }
  }
});
</script>
```

### Axios Wrapper (Bearer Token Auth)
```javascript
// src/lib/axios.js
import axios from 'axios';
import Cookies from 'js-cookie';

const instance = axios.create({
  baseURL: '/api/v1',
  timeout: 30000,
});

// Request interceptor - Bearer token from cookie
instance.interceptors.request.use((config) => {
  const token = Cookies.get('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response interceptor
instance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid
      Cookies.remove('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default instance;
```

### Token Management (js-cookie)
```javascript
// Determine if production environment
const isProd = process.env.NODE_ENV === 'production';

// Login - Save token to cookie with environment-aware settings
const login = async (credentials) => {
  const { data } = await axios.post('/auth/login', credentials);
  Cookies.set('token', data.token, { 
    expires: 7, 
    sameSite: 'strict',
    secure: isProd // Set secure flag only in production
  });
};

// Logout
const logout = () => {
  Cookies.remove('token');
  window.location.href = '/login';
};

// Check if authenticated
const isAuthenticated = () => {
  return !!Cookies.get('token');
};

// Get current token
const getToken = () => {
  return Cookies.get('token');
};
```

### Auth Store (Pinia)
```javascript
// src/stores/auth.js
import { defineStore } from 'pinia';
import Cookies from 'js-cookie';
import axios from '@/lib/axios';

const isProd = process.env.NODE_ENV === 'production';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: Cookies.get('token') || null,
    user: null
  }),
  
  getters: {
    isAuthenticated: (state) => !!state.token
  },
  
  actions: {
    async login(credentials) {
      const { data } = await axios.post('/auth/login', credentials);
      this.token = data.token;
      this.user = data.user;
      
      Cookies.set('token', data.token, {
        expires: 7,
        sameSite: 'strict',
        secure: isProd
      });
    },
    
    logout() {
      this.token = null;
      this.user = null;
      Cookies.remove('token');
      window.location.href = '/login';
    }
  }
});
```

### Date Handling
```javascript
import { DateTime } from 'luxon';
const formatDate = (timestamp) => 
  DateTime.fromSeconds(timestamp).toFormat('yyyy/MM/dd HH:mm');
```

## Example Component
```vue
<template>
  <v-data-table
    :headers="headers"
    :items="users"
    :loading="loading"
    :options.sync="options"
    :server-items-length="totalCount"
    @update:options="fetchUsers"
  >
    <template #item.createdAt="{ item }">
      {{ formatDate(item.createdAt) }}
    </template>
  </v-data-table>
</template>

<script setup>
import { ref, computed } from 'vue';
import axios from '@/lib/axios';
import { DateTime } from 'luxon';

const users = ref([]);
const loading = ref(false);
const totalCount = ref(0);
const options = ref({ page: 1, itemsPerPage: 10 });

const headers = computed(() => [
  { title: 'Name', key: 'name' },
  { title: 'Email', key: 'email' },
  { title: 'Created', key: 'createdAt' },
]);

const formatDate = (timestamp) => 
  DateTime.fromSeconds(timestamp).toFormat('yyyy/MM/dd HH:mm');

const fetchUsers = async () => {
  loading.value = true;
  try {
    const { page, itemsPerPage } = options.value;
    const { data } = await axios.get('/users', {
      params: { limit: itemsPerPage, offset: (page - 1) * itemsPerPage },
    });
    users.value = data.users;
    totalCount.value = data.totalCount;
  } finally {
    loading.value = false;
  }
};
</script>
```

## References
- See CLAUDE.md for project specs
- Coordinate with backend agent for API integration