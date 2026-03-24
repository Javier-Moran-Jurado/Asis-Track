-- Datos de ejemplo para justificaciones
INSERT INTO justificaciones (registro_id, usuario_codigo, motivo, documento_url, estado, fecha_solicitud) VALUES
(1, '2024117001', 'Enfermedad', 'https://ejemplo.com/documento1.pdf', 'APROBADO', NOW() - INTERVAL '5 days'),
(2, '2024117002', 'Cita médica', 'https://ejemplo.com/documento2.pdf', 'PENDIENTE', NOW() - INTERVAL '3 days'),
(3, '2024117003', 'Tráfico', NULL, 'RECHAZADO', NOW() - INTERVAL '1 days');