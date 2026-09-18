<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api.js'
import { auth } from '../auth.js'

const router = useRouter()
const username = ref('')
const email = ref('')
const password = ref('')
const error = ref('')
const cargando = ref(false)

async function registrarse() {
    error.value = ''
    cargando.value = true
    
    try {
        const { data } = await api.post('/register', {
            username: username.value,
            email: email.value,
            password: password.value
        })
        auth.setSession(data.access_token, data.user)
        router.push('/perfil')
    } catch (e) {
        error.value = e.response?.data?.message || 'Error al registrarse'
    } finally {
        cargando.value = false
    }
}

function iniciarSesion() {
    router.push('/login')
}

</script>

<template>
    <div class="mx-auto max-w-md">
        <div class="rounded-2x1 bg-white p-6 shadow-sm sm:p-8">
            <h1 class="mb-1 text-2x1 font-bold">Registrarse</h1>
            <p class="mb-6 text-sm text-slate-500">Ingrese sus datos para crear una cuenta.</p>

            <div v-if="error" class="mb-4 rounded-lg bg-red-100 p-4 text-sm text-red-700" role="alert">{{ error }}</div>

            <form @submit.prevent="registrarse" class="space-y-4">
                <div>
                    <label class="mb-1 block text-sm font-medium text-slate-700">Usuario</label>
                    <input v-model="username" type="text" autocomplete="username" class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium text-slate-700">Correo</label>
                    <input v-model="email" type="email" autocomplete="email" class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium text-slate-700">Contraseña</label>
                    <input v-model="password" type="password" autocomplete="current-password" class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
                </div>
                <button type="submit" :disabled="cargando" class="w-full rounded-lg bg-indigo-600 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-100 disabled:opacity-60">
                    {{ cargando ? 'Registrando...' : 'Registrarme' }}
                </button>
                <button type="button" @click="iniciarSesion" class="w-full rounded-lg bg-sky-200 py-2.5 text-sm font-semibold text-white hover:bg-sky-300 focus:outline-none focus:ring-2 focus:ring-sky-100 disabled:opacity-60">
                    Iniciar sesión
                </button>
            </form>
        </div>
    </div>
</template>