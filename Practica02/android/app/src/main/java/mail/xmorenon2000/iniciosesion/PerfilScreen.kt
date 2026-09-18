package mail.xmorenon2000.iniciosesion

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Composable
fun PerfilScreen() {
    var username by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var role by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var userId by remember { mutableStateOf(0) }

    var mensaje by remember { mutableStateOf("") }
    var esError by remember { mutableStateOf(false) }
    var cargando by remember { mutableStateOf(false) }
    var guardando by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        try {
            val resp = RetrofitClient.api.me(Sesion.autorizacion())
            val u = resp.user
            userId = u.id
            username = u.username
            email = u.email
            role = u.role
        } catch (e: Exception) {
            esError = true
            mensaje = "Error al cargar el perfil: ${e.message}"
        } finally {
            cargando = false
        }
    }

    fun guardar() {
        mensaje = ""
        guardando = true
        scope.launch {
            try {
                val body = UsuarioRequest(
                    username = username,
                    email = email,
                    role = role,
                    password = if(password.isNotBlank()) password else null
                )

                val resp = RetrofitClient.api.actualizarUsuario(Sesion.autorizacion(), userId, body)

                resp.user?.let { Sesion.usuario = it }
                password = ""
                esError = false
                mensaje = "Perfil actualizado correctamente"
            } catch (e: Exception) {
                esError = true
                mensaje = "Error al guardar: ${e.message}"
            } finally {
                guardando = false
            }
        }
    }

    if(cargando) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp)
    ) {
        Text("Mi perfil", style = MaterialTheme.typography.headlineMedium)
        Spacer(Modifier.height(4.dp))

        AssistChip(onClick = {}, label = { Text("Rol: $role")})
        Spacer(Modifier.height(20.dp))

        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            label = { Text("Usuario") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(12.dp))

        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Correo") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(12.dp))

        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Nueva contraseña (opcional)") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(20.dp))

        Button(
            onClick = { guardar() },
            enabled = !guardando,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if (guardando) "Guardando..." else "Guardar cambios")
        }

        if(mensaje.isNotEmpty()) {
            Spacer(Modifier.height(12.dp))
            Text(
                mensaje,
                color = if (esError) MaterialTheme.colorScheme.error
                        else MaterialTheme.colorScheme.primary
            )
        }

    }

}