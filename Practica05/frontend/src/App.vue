<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { auth } from './auth.js'

const router = useRouter()
const menuOpen = ref(false)

const navLink = 'rounded-md px-3 py-1.5 text-sm text-slate-200 hover:bg-slate-800 hover:text-white'
const mobileLink = 'block w-full rounded-md px-2 py-2 text-left text-sm text-slate-200 hover:bg-slate-800'

function go(path) {
  menuOpen.value = false
  router.push(path)
}

function logout() {
    auth.clear()
    menuOpen.value = false
    router.push('/login')
}

</script>

<template>
  <div class="min-h-screen bg-slate-100 text-slate-900">
    <header class="bg-slate-900 text-white shadow">
      <div class="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
        <button class="flex items-center gap-2 font-bold" @click="go(auth.isAuth ? '/perfil' : '/login')">
          <span class="grid h-8 w-8 place-items-center rounded-lg bg-indigo-500 text-sm">L</span>
          Login App
        </button>

        <nav v-if="auth.isAuth" class="hidden items-center gap-1 sm:flex">
          <button :class="navLink" @click="go('/perfil')">Mi perfil</button>
          <button v-if="auth.isAdmin" :class="navLink" @click="go('/usuarios')">Usuarios</button>
          <span class="mx-2 hidden text-sm text-slate-400 md:inline">{{ auth.username }}</span>
          <button class="rounded-md bg-indigo-500 px-3 py-1.5 text-sm font-medium hover:bg-indigo-600" @click="logout">
            Salir
          </button>
        </nav>

        <button v-if="auth.isAuth" class="sm:hidden" @click="menuOpen = !menuOpen" aria-label="Menu">
          <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path v-if="!menuOpen" stroke-linecap="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            <path v-else stroke-linecap="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <nav v-if="auth.isAuth && menuOpen" class="border-t border-slate-700 px-4 py-2 sm:hidden">
        <p class="px-2 py-2 text-sm text-slate-400">Hola, {{ auth.username }}</p>
        <button :class="mobileLink" @click="go('/perfil')">Mi perfil</button>
        <button v-if="auth.isAdmin" :class="mobileLink" @click="go('/usuarios')">Usuarios</button>
        <button :class="mobileLink + ' text-indigo-300'" @click="logout">Salir</button>
      </nav>
    </header>

    <main class="mx-auto max-w-5xl px-4 py-8">
      <router-view />
    </main>
  </div>
</template>