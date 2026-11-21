-- =====================================================================
-- Proyecto: Aplicación móvil para la gestión del inventario de
--           repuestos críticos del área de insertado - Virutex Ilko
-- Archivo : 01_esquema.sql  (Sprint 1 - diseño y base de datos)
-- Motor   : MariaDB 10.4+ (XAMPP) / MySQL 8.0+
-- Objeto  : crea la base de datos, tablas, relaciones, restricciones
--           e índices.
-- Autores : Johan Velasco, Dailer Silva
-- =====================================================================

DROP DATABASE IF EXISTS virutex_inventario;
CREATE DATABASE virutex_inventario
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE virutex_inventario;

-- ---------------------------------------------------------------------
-- Seguridad y usuarios (HU-01, HU-16, RNF-02)
-- ---------------------------------------------------------------------
CREATE TABLE rol (
  id_rol      TINYINT UNSIGNED NOT NULL,
  nombre      VARCHAR(20)      NOT NULL,
  descripcion VARCHAR(150)     NOT NULL,
  CONSTRAINT pk_rol PRIMARY KEY (id_rol),
  CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuario (
  id_usuario        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nombre_completo   VARCHAR(100)     NOT NULL,
  nombre_usuario    VARCHAR(30)      NOT NULL,
  contrasena_hash   VARCHAR(255)     NOT NULL,
  id_rol            TINYINT UNSIGNED NOT NULL,
  activo            TINYINT(1)       NOT NULL DEFAULT 1,
  intentos_fallidos TINYINT UNSIGNED NOT NULL DEFAULT 0,
  bloqueado_hasta   DATETIME         NULL,
  fecha_creacion    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_creado_por     INT UNSIGNED     NULL,
  CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
  CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES rol (id_rol),
  CONSTRAINT fk_usuario_creador FOREIGN KEY (id_creado_por) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_usuario_activo CHECK (activo IN (0, 1)),
  CONSTRAINT ck_usuario_hash CHECK (CHAR_LENGTH(contrasena_hash) >= 60)
) ENGINE=InnoDB;

CREATE TABLE sesion (
  id_sesion        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario       INT UNSIGNED    NOT NULL,
  token_hash       CHAR(64)        NOT NULL,
  fecha_inicio     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion DATETIME        NOT NULL,
  revocada         TINYINT(1)      NOT NULL DEFAULT 0,
  CONSTRAINT pk_sesion PRIMARY KEY (id_sesion),
  CONSTRAINT uq_sesion_token UNIQUE (token_hash),
  CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_sesion_fechas CHECK (fecha_expiracion > fecha_inicio)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Catálogos (HU-02, HU-04, H-13, V-03)
-- ---------------------------------------------------------------------
CREATE TABLE unidad_medida (
  id_unidad         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo            VARCHAR(5)       NOT NULL,
  nombre            VARCHAR(30)      NOT NULL,
  permite_decimales TINYINT(1)       NOT NULL DEFAULT 0,
  CONSTRAINT pk_unidad_medida PRIMARY KEY (id_unidad),
  CONSTRAINT uq_unidad_codigo UNIQUE (codigo),
  CONSTRAINT uq_unidad_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE maquina (
  id_maquina SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo     VARCHAR(10)       NOT NULL,
  nombre     VARCHAR(60)       NOT NULL,
  activa     TINYINT(1)        NOT NULL DEFAULT 1,
  CONSTRAINT pk_maquina PRIMARY KEY (id_maquina),
  CONSTRAINT uq_maquina_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE ubicacion (
  id_ubicacion SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  estanteria   VARCHAR(10)       NOT NULL,
  cajon        VARCHAR(10)       NOT NULL,
  CONSTRAINT pk_ubicacion PRIMARY KEY (id_ubicacion),
  CONSTRAINT uq_ubicacion UNIQUE (estanteria, cajon)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Repuestos (HU-02, HU-03, HU-04, HU-08)
-- ---------------------------------------------------------------------
CREATE TABLE repuesto (
  id_repuesto         INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  codigo              VARCHAR(20)       NOT NULL,
  nombre              VARCHAR(100)      NOT NULL,
  descripcion         VARCHAR(255)      NULL,
  id_maquina          SMALLINT UNSIGNED NOT NULL,
  id_unidad           TINYINT UNSIGNED  NOT NULL,
  id_ubicacion        SMALLINT UNSIGNED NULL,
  stock_actual        DECIMAL(10,2)     NOT NULL DEFAULT 0,
  stock_minimo        DECIMAL(10,2)     NOT NULL DEFAULT 0,
  activo              TINYINT(1)        NOT NULL DEFAULT 1,
  fecha_registro      DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario_registro INT UNSIGNED      NOT NULL,
  CONSTRAINT pk_repuesto PRIMARY KEY (id_repuesto),
  CONSTRAINT uq_repuesto_codigo UNIQUE (codigo),
  CONSTRAINT fk_repuesto_maquina FOREIGN KEY (id_maquina) REFERENCES maquina (id_maquina),
  CONSTRAINT fk_repuesto_unidad FOREIGN KEY (id_unidad) REFERENCES unidad_medida (id_unidad),
  CONSTRAINT fk_repuesto_ubicacion FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion),
  CONSTRAINT fk_repuesto_usuario FOREIGN KEY (id_usuario_registro) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_repuesto_codigo CHECK (TRIM(codigo) <> '' AND UPPER(TRIM(codigo)) <> 'NA'),
  CONSTRAINT ck_repuesto_stock CHECK (stock_actual >= 0),
  CONSTRAINT ck_repuesto_minimo CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

CREATE INDEX ix_repuesto_nombre  ON repuesto (nombre);
CREATE INDEX ix_repuesto_maquina ON repuesto (id_maquina);

-- ---------------------------------------------------------------------
-- Movimientos (HU-05, HU-06, HU-07, RNF-04, RNF-06)
-- Los movimientos no se modifican ni se eliminan (ver 02_logica.sql).
-- ---------------------------------------------------------------------
CREATE TABLE movimiento (
  id_movimiento         BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
  uuid_cliente          CHAR(36)          NOT NULL,
  tipo                  ENUM('entrada','salida','ajuste') NOT NULL,
  id_repuesto           INT UNSIGNED      NOT NULL,
  cantidad              DECIMAL(10,2)     NOT NULL,
  stock_resultante      DECIMAL(10,2)     NOT NULL DEFAULT 0,
  id_maquina_destino    SMALLINT UNSIGNED NULL,
  id_usuario_registra   INT UNSIGNED      NOT NULL,
  id_usuario_recibe     INT UNSIGNED      NULL,
  motivo                VARCHAR(255)      NULL,
  observacion           VARCHAR(255)      NULL,
  fecha_movimiento      DATETIME          NOT NULL,
  fecha_sincronizacion  DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_movimiento PRIMARY KEY (id_movimiento),
  CONSTRAINT uq_movimiento_uuid UNIQUE (uuid_cliente),
  CONSTRAINT fk_mov_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT fk_mov_maquina FOREIGN KEY (id_maquina_destino) REFERENCES maquina (id_maquina),
  CONSTRAINT fk_mov_registra FOREIGN KEY (id_usuario_registra) REFERENCES usuario (id_usuario),
  CONSTRAINT fk_mov_recibe FOREIGN KEY (id_usuario_recibe) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_mov_cantidad CHECK (
    (tipo IN ('entrada','salida') AND cantidad > 0) OR (tipo = 'ajuste' AND cantidad <> 0)),
  CONSTRAINT ck_mov_salida_destino CHECK (tipo <> 'salida' OR id_maquina_destino IS NOT NULL),
  CONSTRAINT ck_mov_ajuste_motivo CHECK (tipo <> 'ajuste' OR (motivo IS NOT NULL AND TRIM(motivo) <> ''))
) ENGINE=InnoDB;

CREATE INDEX ix_mov_repuesto_fecha ON movimiento (id_repuesto, fecha_movimiento);
CREATE INDEX ix_mov_tipo_fecha     ON movimiento (tipo, fecha_movimiento);

-- Salidas registradas sin conexión que no pudieron aplicarse al sincronizar
CREATE TABLE conflicto_sincronizacion (
  id_conflicto        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid_cliente        CHAR(36)        NOT NULL,
  id_usuario          INT UNSIGNED    NOT NULL,
  id_repuesto         INT UNSIGNED    NOT NULL,
  tipo                ENUM('entrada','salida','ajuste') NOT NULL,
  cantidad            DECIMAL(10,2)   NOT NULL,
  fecha_movimiento    DATETIME        NOT NULL,
  causa               VARCHAR(255)    NOT NULL,
  estado              ENUM('pendiente','resuelto') NOT NULL DEFAULT 'pendiente',
  fecha_registro      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_conflicto PRIMARY KEY (id_conflicto),
  CONSTRAINT uq_conflicto_uuid UNIQUE (uuid_cliente),
  CONSTRAINT fk_conflicto_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
  CONSTRAINT fk_conflicto_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Proveedores (HU-10). Sin precios ni condiciones comerciales (Tabla 15).
-- ---------------------------------------------------------------------
CREATE TABLE proveedor (
  id_proveedor    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(100)      NOT NULL,
  nombre_contacto VARCHAR(100)      NULL,
  telefono        VARCHAR(20)       NULL,
  correo          VARCHAR(100)      NULL,
  activo          TINYINT(1)        NOT NULL DEFAULT 1,
  CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
  CONSTRAINT uq_proveedor_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE repuesto_proveedor (
  id_repuesto            INT UNSIGNED      NOT NULL,
  id_proveedor           SMALLINT UNSIGNED NOT NULL,
  tiempo_reposicion_dias SMALLINT UNSIGNED NOT NULL,
  es_principal           TINYINT(1)        NOT NULL DEFAULT 0,
  -- Solo tiene valor cuando el proveedor es el principal: garantiza uno por repuesto
  principal_de           INT UNSIGNED AS (CASE WHEN es_principal = 1 THEN id_repuesto END) STORED,
  CONSTRAINT pk_repuesto_proveedor PRIMARY KEY (id_repuesto, id_proveedor),
  CONSTRAINT fk_rp_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT fk_rp_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor),
  CONSTRAINT uq_rp_principal UNIQUE (principal_de),
  CONSTRAINT ck_rp_tiempo CHECK (tiempo_reposicion_dias > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Alertas (HU-09, HU-14)
-- ---------------------------------------------------------------------
CREATE TABLE alerta (
  id_alerta         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  id_repuesto       INT UNSIGNED  NOT NULL,
  tipo              ENUM('stock_minimo','preventiva') NOT NULL,
  estado            ENUM('activa','atendida')         NOT NULL DEFAULT 'activa',
  stock_al_generar  DECIMAL(10,2) NOT NULL,
  cobertura_dias    DECIMAL(8,1)  NULL,
  cantidad_sugerida DECIMAL(10,2) NULL,
  fecha_generacion  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_atencion    DATETIME      NULL,
  -- Solo tiene valor mientras la alerta está activa: una activa por repuesto y tipo
  activa_de         INT UNSIGNED AS (CASE WHEN estado = 'activa' THEN id_repuesto END) STORED,
  CONSTRAINT pk_alerta PRIMARY KEY (id_alerta),
  CONSTRAINT fk_alerta_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT uq_alerta_activa UNIQUE (activa_de, tipo),
  CONSTRAINT ck_alerta_atencion CHECK (estado = 'activa' OR fecha_atencion IS NOT NULL)
) ENGINE=InnoDB;

CREATE INDEX ix_alerta_estado ON alerta (estado, tipo);

-- ---------------------------------------------------------------------
-- Solicitudes de repuestos (HU-11)
-- ---------------------------------------------------------------------
CREATE TABLE solicitud (
  id_solicitud        INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  id_repuesto         INT UNSIGNED      NOT NULL,
  id_proveedor        SMALLINT UNSIGNED NULL,
  cantidad            DECIMAL(10,2)     NOT NULL,
  estado              ENUM('pendiente','enviada','recibida','anulada') NOT NULL DEFAULT 'pendiente',
  id_usuario_solicita INT UNSIGNED      NOT NULL,
  fecha_solicitud     DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_envio         DATETIME          NULL,
  fecha_recepcion     DATETIME          NULL,
  observacion         VARCHAR(255)      NULL,
  -- Solo tiene valor mientras la solicitud está abierta: una abierta por repuesto
  abierta_de          INT UNSIGNED AS (CASE WHEN estado IN ('pendiente','enviada') THEN id_repuesto END) STORED,
  CONSTRAINT pk_solicitud PRIMARY KEY (id_solicitud),
  CONSTRAINT fk_sol_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT fk_sol_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor),
  CONSTRAINT fk_sol_usuario FOREIGN KEY (id_usuario_solicita) REFERENCES usuario (id_usuario),
  CONSTRAINT uq_sol_abierta UNIQUE (abierta_de),
  CONSTRAINT ck_sol_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Parámetros configurables (HU-13, HU-15, RNF-02)
-- ---------------------------------------------------------------------
CREATE TABLE parametro (
  clave       VARCHAR(40)   NOT NULL,
  valor       DECIMAL(10,2) NOT NULL,
  descripcion VARCHAR(200)  NOT NULL,
  CONSTRAINT pk_parametro PRIMARY KEY (clave),
  CONSTRAINT ck_parametro_valor CHECK (valor >= 0)
) ENGINE=InnoDB;
