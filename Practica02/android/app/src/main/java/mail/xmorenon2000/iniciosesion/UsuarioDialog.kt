package mail.xmorenon2000.iniciosesion

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UsuarioDialog(
    modo: String,
    usuarioInicial: Usuario?,
    onCancelar: () -> Unit,
    onGuardar: (UsuarioRequest, Int?) -> Unit
) {
    var username by remember { mutableStateOf(usuarioInicial?.username ?: "") }
    var email by remember { mutableStateOf(usuarioInicial?.email ?: "") }
    var role by remember { mutableStateOf(usuarioInicial?.role ?: "user") }
    var password by remember { mutableStateOf("") }
    var rolMenuAbierto by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = onCancelar,
        title = { Text(if (modo == "crear") "Agregar usuario" else "Editar usuario") },
        text = {
            Column {
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it },
                    label = { Text("Usuario") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(10.dp))

                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Correo") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(10.dp))

                ExposedDropdownMenuBox(
                    expanded = rolMenuAbierto,
                    onExpandedChange = { rolMenuAbierto = it }
                ) {
                    OutlinedTextField(
                        value = role,
                        onValueChange = { },
                        label = { Text("Rol") },
                        readOnly = true,
                        trailingIcon = {
                            ExposedDropdownMenuDefaults.TrailingIcon(expanded = rolMenuAbierto)
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = rolMenuAbierto,
                        onDismissRequest = { rolMenuAbierto = false }
                    ) {
                        listOf("user", "admin").forEach { opcion ->
                            DropdownMenuItem(
                                text = { Text(opcion) },
                                onClick = {
                                    role = opcion
                                    rolMenuAbierto = false
                                }
                            )
                        }
                    }
                }
                Spacer(Modifier.height(10.dp))

                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text(if (modo == "editar") "Contraseña (opcional)" else "Contraseña") },
                    singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    modifier = Modifier.fillMaxWidth()
                )

            }

        },
        confirmButton = {
            TextButton(onClick = {
                val body = UsuarioRequest(
                    username = username,
                    email = email,
                    role = role,
                    password = if (password.isNotBlank()) password else null
                )
                onGuardar(body, usuarioInicial?.id)
            }) {
                Text("Guardar")
            }
        },
        dismissButton = {
            TextButton(onClick = onCancelar) { Text("Cancelar") }
        }
    )
}