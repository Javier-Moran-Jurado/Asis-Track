-- Datos de ejemplo para la tabla asistencias
INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117001', 1, NOW() - INTERVAL '2 hours', 'PRESENTE', '{"lat": 4.628692, "lng": -74.065396, "precision": 10}', '{"dispositivo": "Android", "appVersion": "1.0.0"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117002', 1, NOW() - INTERVAL '2 hours', 'PRESENTE', '{"lat": 4.628700, "lng": -74.065400, "precision": 8}', '{"dispositivo": "iOS", "appVersion": "1.0.0"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117003', 1, NOW() - INTERVAL '2 hours', 'AUSENTE', NULL, '{"justificacion": "Enfermedad"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117004', 1, NOW() - INTERVAL '2 hours', 'TARDANZA', '{"lat": 4.628800, "lng": -74.065500, "precision": 15}', '{"dispositivo": "Android", "appVersion": "1.0.0", "motivo": "Tráfico"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117005', 2, NOW() - INTERVAL '1 hour', 'PRESENTE', '{"lat": 4.628900, "lng": -74.065600, "precision": 12}', '{"dispositivo": "iPhone", "appVersion": "1.0.1"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117006', 2, NOW() - INTERVAL '1 hour', 'PRESENTE', '{"lat": 4.629000, "lng": -74.065700, "precision": 9}', '{"dispositivo": "Samsung", "appVersion": "1.0.0"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117007', 2, NOW() - INTERVAL '1 hour', 'AUSENTE', NULL, '{"justificacion": "Cita médica"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117008', 3, NOW(), 'PRESENTE', '{"lat": 4.629100, "lng": -74.065800, "precision": 5}', '{"dispositivo": "Xiaomi", "appVersion": "1.0.2"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117009', 3, NOW(), 'JUSTIFICADO', NULL, '{"justificacion": "Participación en evento académico"}');

INSERT INTO asistencias(codigo_estudiante, planilla_id, fecha_hora_registro, estado, geolocalizacion, datos_adicionales) VALUES
    ('2024117010', 3, NOW(), 'PRESENTE', '{"lat": 4.629200, "lng": -74.065900, "precision": 7}', '{"dispositivo": "Motorola", "appVersion": "1.0.1"}');