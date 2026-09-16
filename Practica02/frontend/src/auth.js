import { reactive } from 'vue'

export const auth = reactive({
  token: localStorage.getItem('token') || '',
  role: localStorage.getItem('role') || '',
  username: localStorage.getItem('username') || '',
  id: Number(localStorage.getItem('id')) || null,

  get isAuth() { return !!this.token },
  get isAdmin() { return this.role === 'admin' },

  setSession(token, user) {
    this.token = token
    this.role = user.role
    this.username = user.username
    this.id = user.id
    localStorage.setItem('token', token)
    localStorage.setItem('role', user.role)
    localStorage.setItem('username', user.username)
    localStorage.setItem('id', user.id)
  },

  clear() {
    this.token = ''
    this.role = ''
    this.username = ''
    this.id = null
    localStorage.clear()
  },
})