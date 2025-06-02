<template>
  <div class="app-container">
    <Header />
    <main>
      <fade>
        <div class="router-view-container">
          <router-view></router-view>
        </div>
      </fade>
    </main>
    <m-footer />
  </div>
</template>

<script lang="ts">
import Header from "./components/header.vue";
import fade from "./components/base/fade.vue"
import mFooter from "./components/footer.vue";
import { defineComponent } from "vue";

export default defineComponent({
  components: { 
    Header, 
    fade, 
    mFooter 
  }
});
</script>

<style>
:root {
  --primary-color: #2a6af0;
  --secondary-color: #00d9ff;
  --background-color: #ffffff;
  --text-color: #333333;
  --border-color: #e8e8e8;
  --border-radius-sm: 4px;
  --border-radius-md: 8px;
  --border-radius-lg: 16px;
  --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 8px rgba(0, 0, 0, 0.1);
}

body {
  margin: 0;
  padding: 0;
  background:rgb(95, 150, 233);
}

/* 全局圆角样式 */
button, 
input, 
select, 
textarea {
  border-radius: var(--border-radius-sm);
}

.card {
  border-radius: var(--border-radius-md);
  box-shadow: var(--shadow-sm);
}

.modal {
  border-radius: var(--border-radius-lg);
}
</style>

<style scoped>
.app-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

main {
  flex: 1;
  width: 100%;
  max-width: 1200px;
  margin: 1em auto;
  background: var(--background-color);
  min-height: calc(100vh - 280px);
  padding: 2em;
  box-sizing: border-box;
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-sm);
}

.router-view-container {
  background: #fff;
  border-radius: var(--border-radius-md);
  padding: 1.5em;
  box-shadow: var(--shadow-sm);
}

/* 添加媒体查询以适应不同屏幕尺寸 */
@media screen and (max-width: 1200px) {
  main {
    margin: 1em;
    padding: 1.5em;
  }
}

@media screen and (max-width: 768px) {
  main {
    margin: 0.5em;
    padding: 1em;
  }
  
  .router-view-container {
    padding: 1em;
  }
}
</style>

