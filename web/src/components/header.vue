<template>
  <header>
    <div class="header-overlay"></div>
    <nav :class="['nav', {'nav-active': scrollTop > 0}]">
      <div class="logo-container">
        <img src="/logo.png" alt="logo" class="logo-img">
      </div>
      <div class="nav-links">
        <router-link to="/" class="nav-item">
          <span class="nav-icon">📊</span>
          所有众筹
        </router-link>
        <router-link to="/myself" class="nav-item">
          <span class="nav-icon">👤</span>
          我的众筹
        </router-link>
        <router-link to="/balance" class="nav-item">
          <span class="nav-icon">💰</span>
          我的资金
        </router-link>
      </div>
      <span class="flex-spacer"></span>
      <a @click="handleClick" class="auth-button">
        <span class="auth-icon">🔐</span>
        {{account}}
      </a>
    </nav>
    <div class="title-container">
      <h1 class="title">YLY众筹平台</h1>
      <p class="subtitle">区块链驱动的众筹平台</p>
    </div>
  </header>
</template>

<script lang="ts">
import {ref, onMounted, toRefs, defineComponent} from 'vue'
import {useRouter} from 'vue-router'
import {message} from 'ant-design-vue'
import { authenticate, getAccount, addListener } from '../api/contract'

export default defineComponent({
  setup() {
    const scrollTop = ref(0)
    onMounted(() => {
      window.addEventListener('scroll', () => {
        scrollTop.value = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop
      })
    })
    const account = ref('认证');
    async function handleClick() {
      await authenticate();
      account.value = await getAccount();
    }

    handleClick();
    addListener(handleClick)

    return {scrollTop, handleClick, account}
  }
})
</script>

<style scoped>
header {
  height: 280px;
  position: relative;
  background: linear-gradient(135deg, #1a237e, #0277bd);
  overflow: hidden;
}

.header-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url("/header.png") no-repeat center/cover;
  opacity: 0.7;
}

.nav {
  display: flex;
  align-items: center;
  padding: 0 4em;
  position: fixed;
  left: 0;
  right: 0;
  height: 64px;
  transition: all 0.3s ease;
  z-index: 10;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.logo-container {
  height: 50px;
  width: 50px;
  display: flex;
  align-items: center;
  margin-right: 2em;
}

.logo-img {
  height: 100%;
  width: 100%;
  object-fit: contain;
}

.nav-links {
  display: flex;
  gap: 1.5em;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.5em;
  padding: 0.5em 1em;
  color: white;
  text-decoration: none;
  border-radius: 8px;
  transition: all 0.3s ease;
  position: relative;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-2px);
}

.nav-item.router-link-active {
  background: rgba(255, 255, 255, 0.2);
}

.nav-icon {
  font-size: 1.2em;
}

.flex-spacer {
  flex: 1;
}

.auth-button {
  display: flex;
  align-items: center;
  gap: 0.5em;
  padding: 0.5em 1.5em;
  background: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 20px;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
}

.auth-button:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: translateY(-2px);
}

.title-container {
  position: relative;
  padding: 6em 4em 2em;
  z-index: 1;
}

.title {
  font-size: 2.5em;
  color: white;
  margin: 0;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.subtitle {
  color: rgba(255, 255, 255, 0.9);
  margin-top: 1em;
  font-size: 1.2em;
}

.nav.nav-active {
  background: rgba(255, 255, 255, 0.95);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.nav.nav-active .nav-item {
  color: #333;
}

.nav.nav-active .auth-button {
  background: linear-gradient(135deg, #1a237e, #0277bd);
  border: none;
  color: white;
}

@media screen and (max-width: 800px) {
  .nav {
    padding: 0 1em;
  }
  
  .nav-links {
    gap: 0.5em;
  }
  
  .title-container {
    padding: 4em 1em 2em;
  }
  
  .title {
    font-size: 2em;
  }
  
  .nav-item {
    padding: 0.5em;
  }
  
  .nav-icon {
    font-size: 1em;
  }
}
</style>