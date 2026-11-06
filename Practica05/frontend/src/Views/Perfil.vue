<script setup>
import { ref, onMounted } from 'vue'
import api from '../api.js'
import { auth } from '../auth.js'

const user = ref(null)
const password = ref('')
const error = ref('')
const ok = ref('')
const cargando = ref(false)

async function cargar() {
    try {
        const { data } = await api.get('/me')
        user.value = data.user
    } catch (e) {
        error.value = e.response?.data?.message || 'Error al cargar el perfil'
    }
}

onMounted(() => {
    cargar()
})


async function guardar() {
    error.value = ''
    ok.value = ''
    cargando.value = true

    try {
        const payload = {username: user.value.username, email: user.value.email }
        if (password.value) {
            payload.password = password.value
        }
        const { data } = await api.put(`/users/${user.value.id}`, payload)
        user.value = data.user
        auth.username = data.user.username
        localStorage.setItem('username', data.user.username)
        password.value = ''
        ok.value = 'Perfil actualizado correctamente'
    } catch (e) {
        error.value = e.response?.data?.message || 'Error al actualizar el perfil'
    } finally {
        cargando.value = false
    }
}

</script>

<template>
  <div class="mx-auto max-w-xl">
    <h1 class="mb-4 text-2xl font-bold">Mi perfil</h1>

    <div v-if="user" class="rounded-2xl bg-white p-6 shadow-sm sm:p-8">
      <div v-if="error" class="mb-4 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">{{ error }}</div>
      <div v-if="ok" class="mb-4 rounded-lg bg-green-50 px-4 py-3 text-sm text-green-700">{{ ok }}</div>

      <div class="mb-6 flex items-center gap-4">
        <div class="grid h-14 w-14 place-items-center rounded-full bg-indigo-100 text-xl font-bold text-indigo-700">
          {{ user.username.charAt(0).toUpperCase() }}
        </div>
        <div>
          <p class="font-semibold">{{ user.username }}</p>
          <span class="inline-block rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600">
            {{ user.role }}
          </span>
        </div>
      </div>

      <form @submit.prevent="guardar" class="space-y-4">
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Usuario</label>
          <input v-model="user.username" type="text"
            class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
        </div>
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Correo</label>
          <input v-model="user.email" type="email"
            class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
        </div>
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Nueva contraseña
            <span class="text-slate-400">(opcional)</span>
          </label>
          <input v-model="password" type="password" placeholder="Dejar en blanco para no cambiarla"
            class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
        </div>
        <button type="submit" :disabled="cargando"
          class="rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:opacity-60">
          {{ cargando ? 'Guardando...' : 'Guardar cambios' }}
        </button>
      </form>
    </div>

    <p v-else class="text-sm text-slate-500">Cargando...</p>
  </div>
</template>