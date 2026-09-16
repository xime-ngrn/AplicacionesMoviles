<script setup>
import { ref, onMounted } from 'vue'
import api from '../api.js'
import { auth } from '../auth.js'

const usuarios = ref([])
const error = ref('')
const ok = ref('')
const cargando = ref(true)

const modalOpen = ref(false)
const modo = ref('crear') // 'crear' o 'editar'
const guardando = ref(false)
const form = ref({ id: null, username: '', email: '', rol: 'user', password: '' })

async function cargar() {
  cargando.value = true
  error.value = ''
  try {
    const { data } = await api.get('/users')
    usuarios.value = data.users
  } catch (e) {
    error.value = e.response?.data?.message || 'Error al cargar los usuarios.'
  } finally {
    cargando.value = false
  }
}
onMounted(cargar)

function abrirCrear() {
  modo.value = 'crear'
  form.value = { id: null, username: '', email: '', rol: 'user', password: '' }
  modalOpen.value = true
}

function abrirEditar(u) {
  modo.value = 'editar'
  // el backend devuelve 'role'; en el formulario lo llamamos 'rol'
  form.value = { id: u.id, username: u.username, email: u.email, rol: u.role, password: '' }
  modalOpen.value = true
}

async function guardar() {
  guardando.value = true
  error.value = ''
  ok.value = ''
  try {
    if (modo.value === 'crear') {
      await api.post('/users', {
        username: form.value.username,
        email: form.value.email,
        role: form.value.rol, // mapeo rol -> role al enviar
        password: form.value.password,
      })
      ok.value = 'Usuario creado.'
    } else {
      const payload = {
        username: form.value.username,
        email: form.value.email,
        role: form.value.rol,
      }
      if (form.value.password) payload.password = form.value.password
      await api.put(`/users/${form.value.id}`, payload)
      ok.value = 'Usuario actualizado.'
    }
    modalOpen.value = false
    await cargar()
  } catch (e) {
    error.value = e.response?.data?.message || 'Error al guardar.'
  } finally {
    guardando.value = false
  }
}

async function eliminar(u) {
  if (!confirm(`Eliminar al usuario "${u.username}"?`)) return
  error.value = ''
  ok.value = ''
  try {
    await api.delete(`/users/${u.id}`)
    ok.value = 'Usuario eliminado.'
    await cargar()
  } catch (e) {
    error.value = e.response?.data?.message || 'Error al eliminar el usuario.'
  }
}

const badge = (role) =>
  role === 'admin' ? 'bg-indigo-100 text-indigo-700' : 'bg-slate-100 text-slate-600'
</script>

<template>
  <div>
    <div class="mb-4 flex items-center justify-between">
      <h1 class="text-2xl font-bold">Gestion de usuarios</h1>
      <button @click="abrirCrear"
        class="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700">
        + Agregar usuario
      </button>
    </div>

    <div v-if="error" class="mb-4 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">{{ error }}</div>
    <div v-if="ok" class="mb-4 rounded-lg bg-green-50 px-4 py-3 text-sm text-green-700">{{ ok }}</div>

    <p v-if="cargando" class="text-sm text-slate-500">Cargando...</p>

    <template v-else>
      <!-- Tabla (escritorio) -->
      <div class="hidden overflow-hidden rounded-2xl bg-white shadow-sm md:block">
        <table class="w-full text-left text-sm">
          <thead class="bg-slate-50 text-xs uppercase text-slate-500">
            <tr>
              <th class="px-4 py-3">ID</th>
              <th class="px-4 py-3">Usuario</th>
              <th class="px-4 py-3">Correo</th>
              <th class="px-4 py-3">Rol</th>
              <th class="px-4 py-3 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="u in usuarios" :key="u.id" class="hover:bg-slate-50">
              <td class="px-4 py-3 text-slate-400">{{ u.id }}</td>
              <td class="px-4 py-3 font-medium">
                {{ u.username }}
                <span v-if="u.id === auth.id" class="ml-1 text-xs text-slate-400">(tu)</span>
              </td>
              <td class="px-4 py-3 text-slate-600">{{ u.email }}</td>
              <td class="px-4 py-3">
                <span class="rounded-full px-2 py-0.5 text-xs font-medium" :class="badge(u.role)">{{ u.role }}</span>
              </td>
              <td class="px-4 py-3">
                <div class="flex justify-end gap-2">
                  <button @click="abrirEditar(u)" class="rounded-md bg-indigo-50 px-3 py-1.5 text-xs font-medium text-indigo-700 hover:bg-indigo-100">Editar</button>
                  <button @click="eliminar(u)" :disabled="u.id === auth.id"
                    class="rounded-md bg-red-50 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-40">
                    Eliminar
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Tarjetas (movil) -->
      <div class="space-y-3 md:hidden">
        <div v-for="u in usuarios" :key="u.id" class="rounded-2xl bg-white p-4 shadow-sm">
          <div class="flex items-start justify-between">
            <div>
              <p class="font-semibold">
                {{ u.username }}
                <span v-if="u.id === auth.id" class="text-xs text-slate-400">(tu)</span>
              </p>
              <p class="text-sm text-slate-500">{{ u.email }}</p>
            </div>
            <span class="rounded-full px-2 py-0.5 text-xs font-medium" :class="badge(u.role)">{{ u.role }}</span>
          </div>
          <div class="mt-3 flex gap-2">
            <button @click="abrirEditar(u)" class="flex-1 rounded-md bg-indigo-50 py-2 text-xs font-medium text-indigo-700 hover:bg-indigo-100">Editar</button>
            <button @click="eliminar(u)" :disabled="u.id === auth.id"
              class="flex-1 rounded-md bg-red-50 py-2 text-xs font-medium text-red-700 hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-40">
              Eliminar
            </button>
          </div>
        </div>
      </div>
    </template>

    <!-- Modal crear / editar -->
    <div v-if="modalOpen" class="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-0 sm:items-center sm:p-4"
      @click.self="modalOpen = false">
      <div class="w-full max-w-md rounded-t-2xl bg-white p-6 shadow-xl sm:rounded-2xl">
        <h2 class="mb-4 text-lg font-bold">
          {{ modo === 'crear' ? 'Agregar usuario' : 'Editar usuario' }}
        </h2>
        <div class="space-y-4">
          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Usuario</label>
            <input v-model="form.username" type="text"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
          </div>
          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Correo</label>
            <input v-model="form.email" type="email"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
          </div>
          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">Rol</label>
            <select v-model="form.rol"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100">
              <option value="user">user</option>
              <option value="admin">admin</option>
            </select>
          </div>
          <div>
            <label class="mb-1 block text-sm font-medium text-slate-700">
              Contrasena
              <span class="text-slate-400">{{ modo === 'editar' ? '(opcional)' : '' }}</span>
            </label>
            <input v-model="form.password" type="password"
              :placeholder="modo === 'editar' ? 'Dejar en blanco para no cambiarla' : ''"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
          </div>
        </div>
        <div class="mt-6 flex justify-end gap-2">
          <button @click="modalOpen = false" class="rounded-lg border border-slate-300 px-4 py-2 text-sm hover:bg-slate-50">Cancelar</button>
          <button @click="guardar" :disabled="guardando"
            class="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:opacity-60">
            {{ guardando ? 'Guardando...' : 'Guardar' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>