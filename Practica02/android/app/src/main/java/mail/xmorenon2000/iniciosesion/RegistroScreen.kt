package mail.xmorenon2000.iniciosesion

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Composable
fun RegistroScreen(onIrALogin: () -> Unit) {
    var username by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var mensaje by remember { mutableStateOf("") }
    var esError by remember { mutableStateOf(false) }
    var cargando by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()

    fun registrar() {
        mensaje = ""
        cargando = true
        scope.launch {
            try {
                RetrofitClient.api.register(RegisterRequest(username, email, password))
                esError = false
                mensaje = "Cuenta creada, inicia sesión."
            } catch (e: Exception) {
                esError = true
                mensaje = "Error: ${e.message ?: "No se pudo registrar."}"
            } finally {
                cargando = false
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center
    ) {
        Text("Crear cuenta", style = MaterialTheme.typography.headlineMedium)
        Spacer(Modifier.height(24.dp))

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
            label = { Text("Contraseña") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(20.dp))

        Button(
            onClick = { registrar() },
            enabled = !cargando,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if(cargando) "Creando..." else "Registrarme")
        }

        TextButton(onClick = onIrALogin) {
            Text("Ya tengo cuenta, iniciar sesión.")
        }

        if(mensaje.isNotEmpty()) {
            Spacer(Modifier.height(8.dp))
            Text(
                mensaje,
                color = if (esError) MaterialTheme.colorScheme.error
                        else MaterialTheme.colorScheme.primary
            )
        }

    }

}