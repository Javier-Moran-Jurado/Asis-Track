import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../services/role_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_breakpoints.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_dialog.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _isLoading = true;
  String? _error;

  final List<Map<String, String>> _roles = const [
    {'id': '1', 'nombre': 'Estudiante'},
    {'id': '2', 'nombre': 'Coordinador'},
    {'id': '3', 'nombre': 'Docente'},
    {'id': '4', 'nombre': 'Administrativo'},
    {'id': '5', 'nombre': 'Decano'},
    {'id': '6', 'nombre': 'Rector'},
    {'id': '7', 'nombre': 'Administrador'},
    {'id': '8', 'nombre': 'Monitor'},
    {'id': '9', 'nombre': 'Directivo'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await UserService.listUsers();
      setState(() => _usuarios = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _rolNombre(dynamic rol) {
    if (rol == null) return 'Sin rol';
    if (rol is Map) return rol['nombre']?.toString() ?? 'Sin rol';
    return rol.toString();
  }

  void _showForm({Map<String, dynamic>? usuario}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _UsuarioForm(
        usuario: usuario,
        roles: _roles,
        onSave: () {
          Navigator.pop(context);
          _loadUsuarios();
        },
      ),
    );
  }

  Future<void> _confirmDelete(dynamic usuario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a ${usuario['nombreCompleto'] ?? usuario['codigo']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.deleteUser(usuario['codigo'].toString());
        _loadUsuarios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado'), backgroundColor: AppTheme.secondaryColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _loadUsuarios,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: AppBreakpoints.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Usuarios registrados (${_usuarios.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showForm(),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Nuevo usuario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                    const SizedBox(height: 12),
                                    Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                                  ],
                                ),
                              )
                            : _usuarios.isEmpty
                                ? const Center(child: Text('No hay usuarios registrados.'))
                                : isWide
                                    ? _buildTable()
                                    : _buildList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Código')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Correo')),
            DataColumn(label: Text('Rol')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: _usuarios.map((u) {
            return DataRow(cells: [
              DataCell(Text(u['codigo']?.toString() ?? '')),
              DataCell(Text(u['nombreCompleto']?.toString() ?? '')),
              DataCell(Text(u['correo']?.toString() ?? '')),
              DataCell(Text(_rolNombre(u['rol']))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: AppTheme.primaryColor),
                    onPressed: () => _showForm(usuario: u),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(u),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: _usuarios.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, i) {
        final u = _usuarios[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              (u['nombreCompleto']?.toString() ?? '?')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(u['nombreCompleto']?.toString() ?? ''),
          subtitle: Text('${u['correo']?.toString() ?? ''} \u2022 ${_rolNombre(u['rol'])}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                onPressed: () => _showForm(usuario: u),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(u),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UsuarioForm extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final List<Map<String, String>> roles;
  final VoidCallback onSave;

  const _UsuarioForm({this.usuario, required this.roles, required this.onSave});

  @override
  State<_UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<_UsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmCtrl;
  String? _rolId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _codigoCtrl = TextEditingController(text: u?['codigo']?.toString() ?? '');
    _nombreCtrl = TextEditingController(text: u?['nombreCompleto']?.toString() ?? '');
    _correoCtrl = TextEditingController(text: u?['correo']?.toString() ?? '');
    _cedulaCtrl = TextEditingController(text: u?['cedula']?.toString() ?? '');
    _telefonoCtrl = TextEditingController(text: u?['telefono']?.toString() ?? '');
    _passwordCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();

    if (u != null && u['rol'] != null) {
      final rol = u['rol'];
      if (rol is Map) {
        _rolId = rol['id']?.toString();
      }
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rolId == null) {
      ErrorDialog.show(context, 'Selecciona un rol');
      return;
    }
    final isEdit = widget.usuario != null;
    if (_passwordCtrl.text.isNotEmpty && _passwordCtrl.text != _confirmCtrl.text) {
      ErrorDialog.show(context, 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEdit) {
        await UserService.updateUser(
          codigo: _codigoCtrl.text.trim(),
          nombreCompleto: _nombreCtrl.text.trim(),
          correo: _correoCtrl.text.trim(),
          contrasena: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
          cedula: _cedulaCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          rolId: _rolId!,
        );
      } else {
        await UserService.createUser(
          codigo: _codigoCtrl.text.trim(),
          nombreCompleto: _nombreCtrl.text.trim(),
          correo: _correoCtrl.text.trim(),
          contrasena: _passwordCtrl.text,
          cedula: _cedulaCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          rolId: _rolId!,
        );
      }
      widget.onSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Usuario actualizado con éxito' : 'Usuario creado con éxito'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.usuario != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Editar usuario' : 'Nuevo usuario',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Código institucional',
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                readOnly: isEdit,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nombre completo',
                controller: _nombreCtrl,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Correo electrónico',
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Cédula',
                controller: _cedulaCtrl,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Teléfono',
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _rolId,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text('Selecciona un rol'),
                items: widget.roles.map((r) {
                  return DropdownMenuItem(value: r['id'], child: Text(r['nombre']!));
                }).toList(),
                onChanged: (v) => setState(() => _rolId = v),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: isEdit ? 'Nueva contraseña (dejar vacío para mantener)' : 'Contraseña',
                controller: _passwordCtrl,
                obscureText: true,
                validator: (v) {
                  if (!isEdit && (v == null || v.length < 8)) return 'Mínimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Confirmar contraseña',
                controller: _confirmCtrl,
                obscureText: true,
                validator: (v) {
                  if (_passwordCtrl.text.isEmpty) return null;
                  return v != _passwordCtrl.text ? 'Las contraseñas no coinciden' : null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: isEdit ? 'Guardar cambios' : 'Crear usuario',
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
