import { createRouter, createWebHistory } from 'vue-router'
import { auth } from './auth.js'

import Login from './Views/Login.vue'
import Perfil from './Views/Perfil.vue'
import Registro from './Views/Registro.vue'
import Usuarios from './Views/Usuarios.vue'

const routes = [
    { path: '/', redirect: '/login' },
    { path: '/login', component: Login },
    { path: '/perfil', component: Perfil },
    { path: '/registrar', component: Registro },
    { path: '/usuarios', component: Usuarios, meta: { requiresAuth: true, admin: true } },

    { path: '/:pathMatch(.*)*', redirect: '/login' },
]

const router = createRouter({
    history: createWebHistory(),
    routes,
})

router.beforeEach((to) => {
    if (to.meta.requiresAuth && !auth.isAuth) return '/login'
    if (to.path === '/login' && auth.isAuth) return '/perfil'
    if (to.path === '/login' && auth.isAuth) return auth.isAdmin ? '/usuarios' : '/perfil'
    return true
})

export default router