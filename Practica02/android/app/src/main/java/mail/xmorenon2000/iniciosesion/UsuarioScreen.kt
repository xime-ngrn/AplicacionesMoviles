package mail.xmorenon2000.iniciosesion

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Composable
fun UsuariosScreen() {
    var usuarios by remember { mutableStateOf<List<Usuario>>(emptyList()) }
    var cargando by remember { mutableStateOf(true) }
    var mensaje by remember { mutableStateOf("") }
    var esError by remember { mutableStateOf(false) }

    var mostrarDialogo by remember { mutableStateOf(false) }
    var modoDialogo by remember { mutableStateOf("crear") }
    var usuarioEditando by remember { mutableStateOf<Usuario?>(null) }

    val scope = rememberCoroutineScope()

    suspend fun cargar() {
        try {
            usuarios = RetrofitClient.api.listarUsuarios(Sesion.autorizacion()).users
        } catch (e: Exception) {
            esError = true
            mensaje = "Error al cargar: ${e.message}"
        } finally {
            cargando = false
        }
    }

    LaunchedEffect(Unit) { cargar() }

    fun guardarUsuario(body: UsuarioRequest, id: Int?) {
        scope.launch {
            try {
                if (id == null) {
                    RetrofitClient.api.crearUsuario(Sesion.autorizacion(), body)
                    mensaje = "Usuario creado."
                } else {
                    RetrofitClient.api.actualizarUsuario(Sesion.autorizacion(), id, body)
                    mensaje = "Usuario actualizado."
                }
                esError = false
                mostrarDialogo = false
                cargar()
            } catch (e: Exception) {
                esError = true
                mensaje = "Error al guardar: ${e.message}"
            }
        }
    }

    fun eliminar(u: Usuario) {
        scope.launch {
            try {
                RetrofitClient.api.eliminarUsuario(Sesion.autorizacion(), u.id)
                mensaje = "Usuario eliminado."
                esError = false
                cargar()
            } catch (e: Exception) {
                esError = true
                mensaje = "Error al eliminar: ${e.message}"
            }
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Gestion de usuarios", style = MaterialTheme.typography.titleLarge)
            Button(onClick = {
                modoDialogo = "crear"
                usuarioEditando = null
                mostrarDialogo = true
            }) {
                Text("+ Agregar")
            }
        }

        if (mensaje.isNotEmpty()) {
            Spacer(Modifier.height(8.dp))
            Text(
                mensaje,
                color = if (esError) MaterialTheme.colorScheme.error
                else MaterialTheme.colorScheme.primary
            )
        }
        Spacer(Modifier.height(12.dp))

        if (cargando) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items(usuarios) { u ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp)) {
                            Text(
                                u.username + if (u.id == Sesion.usuario?.id) " (tu)" else "",
                                style = MaterialTheme.typography.titleMedium
                            )
                            Text(u.email, style = MaterialTheme.typography.bodySmall)
                            Spacer(Modifier.height(4.dp))
                            AssistChip(onClick = {}, label = { Text(u.role) })
                            Spacer(Modifier.height(8.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                OutlinedButton(onClick = {
                                    modoDialogo = "editar"
                                    usuarioEditando = u
                                    mostrarDialogo = true
                                }) { Text("Editar") }

                                if (u.id != Sesion.usuario?.id) {
                                    OutlinedButton(onClick = { eliminar(u) }) {
                                        Text("Eliminar")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (mostrarDialogo) {
        UsuarioDialog(
            modo = modoDialogo,
            usuarioInicial = usuarioEditando,
            onCancelar = { mostrarDialogo = false },
            onGuardar = { body, id -> guardarUsuario(body, id) }
        )
    }
}