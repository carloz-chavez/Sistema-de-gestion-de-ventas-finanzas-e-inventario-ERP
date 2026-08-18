-- ERP FRUTAS - Modelo físico PostgreSQL / Supabase V1
-- Flujo central: LOTE -> ENVIO -> RECEPCION -> VENTA
-- Fecha: 2026-08-18

begin;

set search_path = public;

-- =========================================================
-- 1. TIPOS
-- =========================================================

create type public.rol_usuario as enum ('ADMINISTRADOR', 'ENCARGADO');
create type public.estado_lote as enum (
  'RECIBIDO', 'EN_PRODUCCION', 'LISTO',
  'PARCIALMENTE_ENVIADO', 'ENVIADO', 'CERRADO'
);
create type public.estado_produccion as enum ('EN_PROCESO', 'TERMINADA');
create type public.estado_envio as enum ('PENDIENTE', 'ENVIADO', 'RECIBIDO', 'CERRADO');
create type public.estado_recepcion as enum ('BORRADOR', 'CONFIRMADA');
create type public.estado_venta as enum ('PENDIENTE', 'REGISTRADA', 'PAGADA', 'ANULADA');
create type public.tipo_venta as enum ('NORMAL', 'RECUPERACION');
create type public.estado_disposicion as enum ('PENDIENTE', 'PERDIDA', 'VENDIDA');
create type public.tipo_pago_mano_obra as enum ('JORNADA', 'JAVA', 'DIA', 'OTRO');
create type public.medio_pago as enum ('EFECTIVO', 'TRANSFERENCIA', 'YAPE', 'PLIN', 'OTRO');

-- Secuencias de códigos legibles. Los ID siguen siendo las PK reales.
create sequence public.seq_codigo_lote start 1;
create sequence public.seq_codigo_envio start 1;
create sequence public.seq_codigo_venta start 1;

-- =========================================================
-- 2. SEGURIDAD Y MAESTROS
-- =========================================================

create table public.perfil_usuario (
  id uuid primary key references auth.users(id) on delete restrict,
  nombre varchar(120) not null,
  rol public.rol_usuario not null default 'ENCARGADO',
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.producto (
  id bigint generated always as identity primary key,
  nombre varchar(80) not null,
  descripcion varchar(250),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create unique index uq_producto_nombre on public.producto (lower(nombre));

create table public.variedad (
  id bigint generated always as identity primary key,
  producto_id bigint not null references public.producto(id) on delete restrict,
  nombre varchar(80) not null,
  descripcion varchar(250),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create unique index uq_variedad_producto_nombre
  on public.variedad (producto_id, lower(nombre));

create table public.productor (
  id bigint generated always as identity primary key,
  nombre varchar(150) not null,
  tipo_documento varchar(10),
  numero_documento varchar(20),
  telefono varchar(20),
  direccion varchar(250),
  observaciones text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  constraint ck_productor_documento check (
    numero_documento is null or btrim(numero_documento) <> ''
  )
);
create unique index uq_productor_documento
  on public.productor (numero_documento) where numero_documento is not null;
create index ix_productor_nombre on public.productor (lower(nombre));

create table public.cliente (
  id bigint generated always as identity primary key,
  nombre varchar(150) not null,
  nombre_comercial varchar(150),
  tipo_documento varchar(10),
  numero_documento varchar(20),
  telefono varchar(20),
  direccion varchar(250),
  observaciones text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create unique index uq_cliente_documento
  on public.cliente (numero_documento) where numero_documento is not null;
create index ix_cliente_nombre on public.cliente (lower(nombre));

create table public.transportista (
  id bigint generated always as identity primary key,
  nombre varchar(150) not null,
  numero_documento varchar(20),
  telefono varchar(20),
  observaciones text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create unique index uq_transportista_documento
  on public.transportista (numero_documento) where numero_documento is not null;
create index ix_transportista_nombre on public.transportista (lower(nombre));

create table public.material (
  id bigint generated always as identity primary key,
  nombre varchar(100) not null,
  unidad_medida varchar(20) not null,
  costo_referencia numeric(12,4),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  constraint ck_material_costo check (costo_referencia is null or costo_referencia >= 0)
);
create unique index uq_material_nombre on public.material (lower(nombre));

create table public.trabajador (
  id bigint generated always as identity primary key,
  nombre varchar(150) not null,
  numero_documento varchar(20),
  telefono varchar(20),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create unique index uq_trabajador_documento
  on public.trabajador (numero_documento) where numero_documento is not null;
create index ix_trabajador_nombre on public.trabajador (lower(nombre));

create table public.motivo_rechazo (
  id bigint generated always as identity primary key,
  nombre varchar(100) not null,
  descripcion varchar(250),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create unique index uq_motivo_rechazo_nombre on public.motivo_rechazo (lower(nombre));

create table public.categoria_gasto (
  id bigint generated always as identity primary key,
  nombre varchar(80) not null,
  descripcion varchar(250),
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create unique index uq_categoria_gasto_nombre on public.categoria_gasto (lower(nombre));

-- =========================================================
-- 3. LOTE, PRODUCCIÓN Y COSTOS
-- =========================================================

create table public.lote (
  id bigint generated always as identity primary key,
  codigo varchar(20) not null unique default (
    'LOT-' || lpad(nextval('public.seq_codigo_lote')::text, 6, '0')
  ),
  productor_id bigint not null references public.productor(id) on delete restrict,
  variedad_id bigint not null references public.variedad(id) on delete restrict,
  fecha_registro date not null default current_date,
  cantidad_estimada_javas integer,
  estado public.estado_lote not null default 'RECIBIDO',
  cantidad_javas_acordadas integer,
  precio_productor_java numeric(12,4),
  monto_productor numeric(14,2) generated always as (
    case
      when cantidad_javas_acordadas is null or precio_productor_java is null then null
      else round(cantidad_javas_acordadas * precio_productor_java, 2)
    end
  ) stored,
  fecha_acuerdo_precio timestamptz,
  observaciones text,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  constraint ck_lote_cantidad_estimada check (
    cantidad_estimada_javas is null or cantidad_estimada_javas > 0
  ),
  constraint ck_lote_acuerdo_completo check (
    (cantidad_javas_acordadas is null and precio_productor_java is null and fecha_acuerdo_precio is null)
    or
    (cantidad_javas_acordadas > 0 and precio_productor_java >= 0 and fecha_acuerdo_precio is not null)
  )
);
create index ix_lote_productor_fecha on public.lote (productor_id, fecha_registro desc);
create index ix_lote_variedad on public.lote (variedad_id);
create index ix_lote_estado on public.lote (estado);

create table public.produccion (
  id bigint generated always as identity primary key,
  lote_id bigint not null unique references public.lote(id) on delete restrict,
  fecha_inicio timestamptz not null default now(),
  fecha_fin timestamptz,
  cantidad_enjavada integer,
  cantidad_javas_utilizadas integer,
  costo_java_unitario numeric(12,4),
  costo_total_javas numeric(14,2) generated always as (
    case
      when cantidad_javas_utilizadas is null or costo_java_unitario is null then null
      else round(cantidad_javas_utilizadas * costo_java_unitario, 2)
    end
  ) stored,
  estado public.estado_produccion not null default 'EN_PROCESO',
  observaciones text,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  constraint ck_produccion_cantidad check (
    (cantidad_enjavada is null or cantidad_enjavada > 0)
    and (cantidad_javas_utilizadas is null or cantidad_javas_utilizadas > 0)
    and (costo_java_unitario is null or costo_java_unitario >= 0)
  ),
  constraint ck_produccion_fechas check (fecha_fin is null or fecha_fin >= fecha_inicio),
  constraint ck_produccion_terminada check (
    estado <> 'TERMINADA'
    or (
      fecha_fin is not null
      and cantidad_enjavada > 0
      and cantidad_javas_utilizadas >= cantidad_enjavada
      and costo_java_unitario >= 0
    )
  )
);

create table public.detalle_produccion_material (
  produccion_id bigint not null references public.produccion(id) on delete restrict,
  material_id bigint not null references public.material(id) on delete restrict,
  cantidad numeric(14,3) not null check (cantidad > 0),
  costo_unitario numeric(12,4) not null check (costo_unitario >= 0),
  costo_total numeric(14,2) generated always as (round(cantidad * costo_unitario, 2)) stored,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  primary key (produccion_id, material_id)
);
create index ix_detalle_material_material on public.detalle_produccion_material (material_id);

create table public.detalle_mano_obra (
  produccion_id bigint not null references public.produccion(id) on delete restrict,
  trabajador_id bigint not null references public.trabajador(id) on delete restrict,
  tipo_pago public.tipo_pago_mano_obra not null,
  cantidad numeric(12,3) not null check (cantidad > 0),
  costo_unitario numeric(12,4) not null check (costo_unitario >= 0),
  costo_total numeric(14,2) generated always as (round(cantidad * costo_unitario, 2)) stored,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  primary key (produccion_id, trabajador_id)
);
create index ix_detalle_mano_obra_trabajador on public.detalle_mano_obra (trabajador_id);

create table public.pago_productor (
  id bigint generated always as identity primary key,
  lote_id bigint not null references public.lote(id) on delete restrict,
  fecha_pago timestamptz not null default now(),
  monto numeric(14,2) not null check (monto > 0),
  medio_pago public.medio_pago not null,
  numero_operacion varchar(80),
  observaciones text,
  anulado boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create index ix_pago_productor_lote_fecha on public.pago_productor (lote_id, fecha_pago);

-- =========================================================
-- 4. ENVÍO, RECEPCIÓN Y RECHAZOS
-- =========================================================

create table public.envio (
  id bigint generated always as identity primary key,
  codigo varchar(20) not null unique default (
    'ENV-' || lpad(nextval('public.seq_codigo_envio')::text, 6, '0')
  ),
  lote_id bigint not null references public.lote(id) on delete restrict,
  cliente_id bigint not null references public.cliente(id) on delete restrict,
  transportista_id bigint not null references public.transportista(id) on delete restrict,
  cantidad_javas integer not null check (cantidad_javas > 0),
  precio_flete_java numeric(12,4) not null check (precio_flete_java >= 0),
  costo_flete numeric(14,2) generated always as (
    round(cantidad_javas * precio_flete_java, 2)
  ) stored,
  placa_vehiculo varchar(15),
  fecha_programada date,
  fecha_envio timestamptz,
  estado public.estado_envio not null default 'PENDIENTE',
  anulado boolean not null default false,
  observaciones text,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  constraint ck_envio_fecha check (
    estado = 'PENDIENTE' or fecha_envio is not null
  )
);
create index ix_envio_lote_estado on public.envio (lote_id, estado) where not anulado;
create index ix_envio_cliente_fecha on public.envio (cliente_id, fecha_envio desc);
create index ix_envio_transportista_fecha on public.envio (transportista_id, fecha_envio desc);

create table public.recepcion (
  id bigint generated always as identity primary key,
  envio_id bigint not null unique references public.envio(id) on delete restrict,
  fecha_recepcion timestamptz not null default now(),
  cantidad_aceptada integer not null check (cantidad_aceptada >= 0),
  cantidad_rechazada integer not null check (cantidad_rechazada >= 0),
  estado public.estado_recepcion not null default 'BORRADOR',
  observaciones text,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);

create table public.rechazo (
  id bigint generated always as identity primary key,
  recepcion_id bigint not null references public.recepcion(id) on delete restrict,
  motivo_rechazo_id bigint not null references public.motivo_rechazo(id) on delete restrict,
  cantidad integer not null check (cantidad > 0),
  observaciones text,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create index ix_rechazo_recepcion on public.rechazo (recepcion_id);
create index ix_rechazo_motivo on public.rechazo (motivo_rechazo_id);

create table public.disposicion_rechazo (
  id bigint generated always as identity primary key,
  rechazo_id bigint not null references public.rechazo(id) on delete restrict,
  estado public.estado_disposicion not null default 'PENDIENTE',
  cantidad integer not null check (cantidad > 0),
  fecha_disposicion timestamptz,
  observaciones text,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  constraint ck_disposicion_fecha check (
    estado = 'PENDIENTE' or fecha_disposicion is not null
  )
);
create index ix_disposicion_rechazo_estado
  on public.disposicion_rechazo (rechazo_id, estado);

-- =========================================================
-- 5. VENTAS, COBROS Y GASTOS
-- =========================================================

create table public.venta (
  id bigint generated always as identity primary key,
  codigo varchar(20) not null unique default (
    'VTA-' || lpad(nextval('public.seq_codigo_venta')::text, 6, '0')
  ),
  recepcion_id bigint not null references public.recepcion(id) on delete restrict,
  disposicion_rechazo_id bigint unique references public.disposicion_rechazo(id) on delete restrict,
  cliente_id bigint not null references public.cliente(id) on delete restrict,
  tipo public.tipo_venta not null,
  fecha_venta timestamptz not null default now(),
  estado public.estado_venta not null default 'REGISTRADA',
  monto_total numeric(14,2) not null default 0 check (monto_total >= 0),
  observaciones text,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict,
  constraint ck_venta_origen check (
    (tipo = 'NORMAL' and disposicion_rechazo_id is null)
    or (tipo = 'RECUPERACION' and disposicion_rechazo_id is not null)
  )
);
create unique index uq_venta_normal_recepcion
  on public.venta (recepcion_id)
  where tipo = 'NORMAL' and estado <> 'ANULADA';
create index ix_venta_cliente_fecha on public.venta (cliente_id, fecha_venta desc);
create index ix_venta_recepcion_tipo on public.venta (recepcion_id, tipo);

create table public.detalle_venta (
  id bigint generated always as identity primary key,
  venta_id bigint not null references public.venta(id) on delete restrict,
  variedad_id bigint not null references public.variedad(id) on delete restrict,
  cantidad_javas integer not null check (cantidad_javas > 0),
  precio_java numeric(12,4) not null check (precio_java >= 0),
  subtotal numeric(14,2) generated always as (
    round(cantidad_javas * precio_java, 2)
  ) stored,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create index ix_detalle_venta_venta on public.detalle_venta (venta_id);
create index ix_detalle_venta_variedad on public.detalle_venta (variedad_id);

create table public.pago_venta (
  id bigint generated always as identity primary key,
  venta_id bigint not null references public.venta(id) on delete restrict,
  fecha_pago timestamptz not null default now(),
  monto numeric(14,2) not null check (monto > 0),
  medio_pago public.medio_pago not null,
  numero_operacion varchar(80),
  observaciones text,
  anulado boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create index ix_pago_venta_venta_fecha on public.pago_venta (venta_id, fecha_pago);

create table public.gasto (
  id bigint generated always as identity primary key,
  categoria_gasto_id bigint not null references public.categoria_gasto(id) on delete restrict,
  fecha_gasto date not null default current_date,
  concepto varchar(180) not null,
  monto numeric(14,2) not null check (monto > 0),
  medio_pago public.medio_pago,
  numero_comprobante varchar(50),
  observaciones text,
  anulado boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references public.perfil_usuario(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.perfil_usuario(id) on delete restrict
);
create index ix_gasto_fecha_categoria on public.gasto (fecha_gasto, categoria_gasto_id);

create table public.auditoria_evento (
  id bigint generated always as identity primary key,
  tabla varchar(80) not null,
  registro_id varchar(50) not null,
  accion varchar(20) not null check (accion in ('INSERT', 'UPDATE', 'DELETE')),
  datos_anteriores jsonb,
  datos_nuevos jsonb,
  usuario_id uuid references public.perfil_usuario(id) on delete restrict,
  fecha timestamptz not null default now()
);
create index ix_auditoria_registro on public.auditoria_evento (tabla, registro_id, fecha desc);
create index ix_auditoria_usuario_fecha on public.auditoria_evento (usuario_id, fecha desc);

-- =========================================================
-- 6. FUNCIONES DE SOPORTE Y AUDITORÍA
-- =========================================================

create or replace function public.es_usuario_activo()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfil_usuario p
    where p.id = auth.uid() and p.activo
  );
$$;

create or replace function public.es_administrador()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfil_usuario p
    where p.id = auth.uid() and p.activo and p.rol = 'ADMINISTRADOR'
  );
$$;

revoke all on function public.es_usuario_activo() from public;
revoke all on function public.es_administrador() from public;
grant execute on function public.es_usuario_activo() to authenticated;
grant execute on function public.es_administrador() to authenticated;

create or replace function public.fn_set_auditoria_campos()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  new.updated_by := coalesce(auth.uid(), new.updated_by);
  if tg_op = 'INSERT' then
    new.created_at := coalesce(new.created_at, now());
    new.created_by := coalesce(new.created_by, auth.uid());
  end if;
  return new;
end;
$$;

create or replace function public.fn_set_perfil_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.fn_auditar_operacion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_registro_id text;
begin
  if tg_op = 'DELETE' then
    v_registro_id := coalesce(to_jsonb(old)->>'id', 'COMPUESTO');
  else
    v_registro_id := coalesce(to_jsonb(new)->>'id', 'COMPUESTO');
  end if;
  insert into public.auditoria_evento (
    tabla, registro_id, accion, datos_anteriores, datos_nuevos, usuario_id
  ) values (
    tg_table_name,
    v_registro_id,
    tg_op,
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end,
    auth.uid()
  );
  return null;
end;
$$;

create trigger trg_perfil_updated_at
before update on public.perfil_usuario
for each row execute function public.fn_set_perfil_updated_at();

do $$
declare
  v_tabla text;
begin
  foreach v_tabla in array array[
    'producto','variedad','productor','cliente','transportista','material','trabajador',
    'motivo_rechazo','categoria_gasto','lote','produccion','detalle_produccion_material',
    'detalle_mano_obra','pago_productor','envio','recepcion','rechazo',
    'disposicion_rechazo','venta','detalle_venta','pago_venta','gasto'
  ] loop
    execute format(
      'create trigger %I before insert or update on public.%I '
      || 'for each row execute function public.fn_set_auditoria_campos()',
      'trg_' || v_tabla || '_auditoria_campos', v_tabla
    );
  end loop;
end $$;

do $$
declare
  v_tabla text;
begin
  foreach v_tabla in array array[
    'lote','produccion','detalle_produccion_material','detalle_mano_obra',
    'pago_productor','envio','recepcion','rechazo','disposicion_rechazo',
    'venta','detalle_venta','pago_venta','gasto'
  ] loop
    execute format(
      'create trigger %I after insert or update or delete on public.%I '
      || 'for each row execute function public.fn_auditar_operacion()',
      'trg_' || v_tabla || '_historial', v_tabla
    );
  end loop;
end $$;

-- =========================================================
-- 7. REGLAS TRANSACCIONALES
-- =========================================================

create or replace function public.fn_validar_acuerdo_lote()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_enjavadas integer;
begin
  if new.cantidad_javas_acordadas is not null then
    select p.cantidad_enjavada into v_enjavadas
    from public.produccion p
    where p.lote_id = new.id and p.estado = 'TERMINADA';

    if v_enjavadas is null then
      raise exception 'El precio al productor solo puede fijarse después de terminar la producción';
    end if;
    if new.cantidad_javas_acordadas <> v_enjavadas then
      raise exception 'La cantidad acordada (%) debe coincidir con las javas enjavadas (%)',
        new.cantidad_javas_acordadas, v_enjavadas;
    end if;
  end if;

  if tg_op = 'UPDATE'
     and (old.cantidad_javas_acordadas, old.precio_productor_java)
         is distinct from
         (new.cantidad_javas_acordadas, new.precio_productor_java)
     and exists (
       select 1 from public.pago_productor pp
       where pp.lote_id = old.id and not pp.anulado
     ) then
    raise exception 'No se puede modificar el acuerdo porque el productor ya tiene pagos registrados';
  end if;
  return new;
end;
$$;
create trigger trg_validar_acuerdo_lote
before update on public.lote
for each row execute function public.fn_validar_acuerdo_lote();

create or replace function public.fn_sincronizar_estado_produccion()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  update public.lote
  set estado = case when new.estado = 'TERMINADA' then 'LISTO'::public.estado_lote
                    else 'EN_PRODUCCION'::public.estado_lote end
  where id = new.lote_id
    and estado not in ('PARCIALMENTE_ENVIADO', 'ENVIADO', 'CERRADO');
  return new;
end;
$$;
create trigger trg_sincronizar_estado_produccion
after insert or update of estado on public.produccion
for each row execute function public.fn_sincronizar_estado_produccion();

create or replace function public.fn_validar_cupo_envio()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_producidas integer;
  v_enviadas integer;
begin
  if new.anulado then return new; end if;

  select p.cantidad_enjavada into v_producidas
  from public.produccion p
  where p.lote_id = new.lote_id and p.estado = 'TERMINADA'
  for update;

  if v_producidas is null then
    raise exception 'El lote no tiene una producción terminada';
  end if;

  select coalesce(sum(e.cantidad_javas), 0) into v_enviadas
  from public.envio e
  where e.lote_id = new.lote_id
    and not e.anulado
    and e.id <> coalesce(new.id, -1);

  if v_enviadas + new.cantidad_javas > v_producidas then
    raise exception 'Cantidad insuficiente: producidas %, ya enviadas %, solicitadas %',
      v_producidas, v_enviadas, new.cantidad_javas;
  end if;
  return new;
end;
$$;
create trigger trg_validar_cupo_envio
before insert or update of lote_id, cantidad_javas, anulado on public.envio
for each row execute function public.fn_validar_cupo_envio();

create or replace function public.fn_sincronizar_estado_lote_envio()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_producidas integer;
  v_enviadas integer;
  v_lote_id bigint;
begin
  v_lote_id := case when tg_op = 'DELETE' then old.lote_id else new.lote_id end;
  select p.cantidad_enjavada into v_producidas
  from public.produccion p where p.lote_id = v_lote_id;

  select coalesce(sum(e.cantidad_javas), 0) into v_enviadas
  from public.envio e where e.lote_id = v_lote_id and not e.anulado;

  update public.lote
  set estado = case
    when v_enviadas = 0 then 'LISTO'::public.estado_lote
    when v_enviadas < v_producidas then 'PARCIALMENTE_ENVIADO'::public.estado_lote
    else 'ENVIADO'::public.estado_lote
  end
  where id = v_lote_id and estado <> 'CERRADO';
  return null;
end;
$$;
create trigger trg_sincronizar_estado_lote_envio
after insert or update of cantidad_javas, anulado or delete on public.envio
for each row execute function public.fn_sincronizar_estado_lote_envio();

create or replace function public.fn_validar_recepcion()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_enviadas integer;
  v_rechazos_detallados integer;
begin
  select e.cantidad_javas into v_enviadas
  from public.envio e
  where e.id = new.envio_id and not e.anulado
  for update;

  if v_enviadas is null then raise exception 'El envío no existe o está anulado'; end if;
  if new.cantidad_aceptada + new.cantidad_rechazada <> v_enviadas then
    raise exception 'Aceptadas (%) + rechazadas (%) debe ser igual a enviadas (%)',
      new.cantidad_aceptada, new.cantidad_rechazada, v_enviadas;
  end if;

  if new.estado = 'CONFIRMADA' then
    select coalesce(sum(r.cantidad), 0) into v_rechazos_detallados
    from public.rechazo r
    where r.recepcion_id = new.id;
    if v_rechazos_detallados <> new.cantidad_rechazada then
      raise exception 'Los motivos de rechazo suman %, pero la recepción declara %',
        v_rechazos_detallados, new.cantidad_rechazada;
    end if;
  end if;
  return new;
end;
$$;
create trigger trg_validar_recepcion
before insert or update on public.recepcion
for each row execute function public.fn_validar_recepcion();

create or replace function public.fn_sincronizar_envio_recepcion()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.estado = 'CONFIRMADA' then
    update public.envio set estado = 'RECIBIDO' where id = new.envio_id;
  end if;
  return new;
end;
$$;
create trigger trg_sincronizar_envio_recepcion
after insert or update of estado on public.recepcion
for each row execute function public.fn_sincronizar_envio_recepcion();

create or replace function public.fn_validar_total_rechazos()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_declaradas integer;
  v_detalladas integer;
  v_recepcion_id bigint;
  v_rechazo_id bigint;
begin
  v_recepcion_id := case when tg_op = 'DELETE' then old.recepcion_id else new.recepcion_id end;
  v_rechazo_id := case when tg_op = 'INSERT' then -1 else old.id end;
  select cantidad_rechazada into v_declaradas
  from public.recepcion where id = v_recepcion_id for update;

  select coalesce(sum(cantidad), 0) into v_detalladas
  from public.rechazo
  where recepcion_id = v_recepcion_id
    and id <> v_rechazo_id;

  if tg_op <> 'DELETE' then v_detalladas := v_detalladas + new.cantidad; end if;
  if v_detalladas > v_declaradas then
    raise exception 'Los rechazos detallados (%) exceden los declarados (%)',
      v_detalladas, v_declaradas;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
create trigger trg_validar_total_rechazos
before insert or update of recepcion_id, cantidad or delete on public.rechazo
for each row execute function public.fn_validar_total_rechazos();

create or replace function public.fn_validar_disposicion()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_rechazadas integer;
  v_dispuestas integer;
begin
  if new.estado = 'PENDIENTE' then return new; end if;

  select cantidad into v_rechazadas
  from public.rechazo where id = new.rechazo_id for update;

  select coalesce(sum(cantidad), 0) into v_dispuestas
  from public.disposicion_rechazo
  where rechazo_id = new.rechazo_id
    and estado in ('PERDIDA', 'VENDIDA')
    and id <> coalesce(new.id, -1);

  if v_dispuestas + new.cantidad > v_rechazadas then
    raise exception 'Las javas dispuestas exceden las rechazadas';
  end if;
  return new;
end;
$$;
create trigger trg_validar_disposicion
before insert or update of rechazo_id, estado, cantidad on public.disposicion_rechazo
for each row execute function public.fn_validar_disposicion();

create or replace function public.fn_validar_venta()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_cliente_envio bigint;
  v_recepcion_disposicion bigint;
  v_estado_disposicion public.estado_disposicion;
begin
  if new.tipo = 'NORMAL' then
    select e.cliente_id into v_cliente_envio
    from public.recepcion r join public.envio e on e.id = r.envio_id
    where r.id = new.recepcion_id and r.estado = 'CONFIRMADA';
    if v_cliente_envio is null then raise exception 'La recepción debe estar confirmada'; end if;
    if new.cliente_id <> v_cliente_envio then
      raise exception 'El cliente de la venta normal debe coincidir con el cliente del envío';
    end if;
  else
    select r.recepcion_id, d.estado
      into v_recepcion_disposicion, v_estado_disposicion
    from public.disposicion_rechazo d
    join public.rechazo r on r.id = d.rechazo_id
    where d.id = new.disposicion_rechazo_id;
    if v_estado_disposicion <> 'VENDIDA' or v_recepcion_disposicion <> new.recepcion_id then
      raise exception 'La venta de recuperación no corresponde a una disposición VENDIDA de esta recepción';
    end if;
  end if;
  return new;
end;
$$;
create trigger trg_validar_venta
before insert or update of recepcion_id, disposicion_rechazo_id, cliente_id, tipo on public.venta
for each row execute function public.fn_validar_venta();

create or replace function public.fn_validar_detalle_venta()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_tipo public.tipo_venta;
  v_limite integer;
  v_vendidas integer;
  v_variedad bigint;
begin
  select v.tipo,
         case when v.tipo = 'NORMAL' then r.cantidad_aceptada else d.cantidad end,
         l.variedad_id
    into v_tipo, v_limite, v_variedad
  from public.venta v
  join public.recepcion r on r.id = v.recepcion_id
  join public.envio e on e.id = r.envio_id
  join public.lote l on l.id = e.lote_id
  left join public.disposicion_rechazo d on d.id = v.disposicion_rechazo_id
  where v.id = new.venta_id and v.estado <> 'ANULADA'
  for update of v;

  if v_limite is null then raise exception 'Venta inexistente, anulada o sin origen válido'; end if;
  if new.variedad_id <> v_variedad then raise exception 'La variedad no coincide con el lote de origen'; end if;

  select coalesce(sum(cantidad_javas), 0) into v_vendidas
  from public.detalle_venta
  where venta_id = new.venta_id and id <> coalesce(new.id, -1);

  if v_vendidas + new.cantidad_javas > v_limite then
    raise exception 'La venta excede las % javas disponibles', v_limite;
  end if;
  return new;
end;
$$;
create trigger trg_validar_detalle_venta
before insert or update of venta_id, variedad_id, cantidad_javas on public.detalle_venta
for each row execute function public.fn_validar_detalle_venta();

create or replace function public.fn_actualizar_total_venta()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_venta_id bigint;
begin
  v_venta_id := case when tg_op = 'DELETE' then old.venta_id else new.venta_id end;
  update public.venta
  set monto_total = (
    select coalesce(sum(dv.subtotal), 0)
    from public.detalle_venta dv where dv.venta_id = v_venta_id
  )
  where id = v_venta_id;
  return null;
end;
$$;
create trigger trg_actualizar_total_venta
after insert or update or delete on public.detalle_venta
for each row execute function public.fn_actualizar_total_venta();

create or replace function public.fn_validar_pago_productor()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_total numeric(14,2);
  v_pagado numeric(14,2);
begin
  if new.anulado then return new; end if;
  select monto_productor into v_total from public.lote where id = new.lote_id for update;
  if v_total is null then raise exception 'El lote todavía no tiene precio acordado'; end if;
  select coalesce(sum(monto), 0) into v_pagado
  from public.pago_productor
  where lote_id = new.lote_id and not anulado and id <> coalesce(new.id, -1);
  if v_pagado + new.monto > v_total then
    raise exception 'El pago excede el saldo pendiente de S/%', v_total - v_pagado;
  end if;
  return new;
end;
$$;
create trigger trg_validar_pago_productor
before insert or update of lote_id, monto, anulado on public.pago_productor
for each row execute function public.fn_validar_pago_productor();

create or replace function public.fn_validar_pago_venta()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_total numeric(14,2);
  v_pagado numeric(14,2);
begin
  if new.anulado then return new; end if;
  select monto_total into v_total
  from public.venta where id = new.venta_id and estado <> 'ANULADA' for update;
  if v_total is null then raise exception 'La venta no existe o está anulada'; end if;
  select coalesce(sum(monto), 0) into v_pagado
  from public.pago_venta
  where venta_id = new.venta_id and not anulado and id <> coalesce(new.id, -1);
  if v_pagado + new.monto > v_total then
    raise exception 'El cobro excede el saldo pendiente de S/%', v_total - v_pagado;
  end if;
  return new;
end;
$$;
create trigger trg_validar_pago_venta
before insert or update of venta_id, monto, anulado on public.pago_venta
for each row execute function public.fn_validar_pago_venta();

create or replace function public.fn_sincronizar_estado_pago_venta()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_venta_id bigint;
  v_total numeric(14,2);
  v_pagado numeric(14,2);
begin
  v_venta_id := case when tg_op = 'DELETE' then old.venta_id else new.venta_id end;
  select monto_total into v_total from public.venta where id = v_venta_id;
  select coalesce(sum(monto), 0) into v_pagado
  from public.pago_venta where venta_id = v_venta_id and not anulado;
  update public.venta
  set estado = case when v_total > 0 and v_pagado >= v_total
                    then 'PAGADA'::public.estado_venta
                    else 'REGISTRADA'::public.estado_venta end
  where id = v_venta_id and estado <> 'ANULADA';
  return null;
end;
$$;
create trigger trg_sincronizar_estado_pago_venta
after insert or update or delete on public.pago_venta
for each row execute function public.fn_sincronizar_estado_pago_venta();

-- =========================================================
-- 8. RPC: CASOS DE USO ATÓMICOS
-- =========================================================

create or replace function public.determinar_precio_productor(
  p_lote_id bigint,
  p_precio_java numeric
) returns public.lote
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_cantidad integer;
  v_resultado public.lote;
begin
  select cantidad_enjavada into v_cantidad
  from public.produccion
  where lote_id = p_lote_id and estado = 'TERMINADA'
  for update;
  if v_cantidad is null then raise exception 'La producción no está terminada'; end if;
  if p_precio_java < 0 then raise exception 'El precio no puede ser negativo'; end if;

  update public.lote
  set cantidad_javas_acordadas = v_cantidad,
      precio_productor_java = p_precio_java,
      fecha_acuerdo_precio = now()
  where id = p_lote_id
  returning * into v_resultado;
  return v_resultado;
end;
$$;

create or replace function public.crear_envio(
  p_lote_id bigint,
  p_cliente_id bigint,
  p_transportista_id bigint,
  p_cantidad_javas integer,
  p_precio_flete_java numeric,
  p_placa_vehiculo varchar default null,
  p_fecha_programada date default null
) returns public.envio
language plpgsql
security invoker
set search_path = public
as $$
declare v_resultado public.envio;
begin
  insert into public.envio (
    lote_id, cliente_id, transportista_id, cantidad_javas,
    precio_flete_java, placa_vehiculo, fecha_programada
  ) values (
    p_lote_id, p_cliente_id, p_transportista_id, p_cantidad_javas,
    p_precio_flete_java, p_placa_vehiculo, p_fecha_programada
  ) returning * into v_resultado;
  return v_resultado;
end;
$$;

create or replace function public.confirmar_recepcion(p_recepcion_id bigint)
returns public.recepcion
language plpgsql
security invoker
set search_path = public
as $$
declare v_resultado public.recepcion;
begin
  update public.recepcion set estado = 'CONFIRMADA'
  where id = p_recepcion_id and estado = 'BORRADOR'
  returning * into v_resultado;
  if v_resultado.id is null then raise exception 'Recepción inexistente o ya confirmada'; end if;
  return v_resultado;
end;
$$;

create or replace function public.generar_venta_normal(
  p_recepcion_id bigint,
  p_precio_java numeric
) returns public.venta
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_cliente_id bigint;
  v_variedad_id bigint;
  v_cantidad integer;
  v_venta public.venta;
begin
  select e.cliente_id, l.variedad_id, r.cantidad_aceptada
    into v_cliente_id, v_variedad_id, v_cantidad
  from public.recepcion r
  join public.envio e on e.id = r.envio_id
  join public.lote l on l.id = e.lote_id
  where r.id = p_recepcion_id and r.estado = 'CONFIRMADA'
  for update of r;

  if v_cliente_id is null then raise exception 'La recepción no está confirmada'; end if;
  if v_cantidad <= 0 then raise exception 'No existen javas aceptadas para vender'; end if;
  if p_precio_java < 0 then raise exception 'El precio no puede ser negativo'; end if;

  insert into public.venta (recepcion_id, cliente_id, tipo)
  values (p_recepcion_id, v_cliente_id, 'NORMAL')
  returning * into v_venta;

  insert into public.detalle_venta (venta_id, variedad_id, cantidad_javas, precio_java)
  values (v_venta.id, v_variedad_id, v_cantidad, p_precio_java);

  select * into v_venta from public.venta where id = v_venta.id;
  return v_venta;
end;
$$;

create or replace function public.registrar_perdida_rechazo(
  p_rechazo_id bigint,
  p_cantidad integer,
  p_observaciones text default null
) returns public.disposicion_rechazo
language plpgsql
security invoker
set search_path = public
as $$
declare v_resultado public.disposicion_rechazo;
begin
  insert into public.disposicion_rechazo (
    rechazo_id, estado, cantidad, fecha_disposicion, observaciones
  ) values (
    p_rechazo_id, 'PERDIDA', p_cantidad, now(), p_observaciones
  ) returning * into v_resultado;
  return v_resultado;
end;
$$;

create or replace function public.generar_venta_recuperacion(
  p_rechazo_id bigint,
  p_cliente_id bigint,
  p_cantidad integer,
  p_precio_java numeric,
  p_observaciones text default null
) returns public.venta
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_recepcion_id bigint;
  v_variedad_id bigint;
  v_disposicion_id bigint;
  v_venta public.venta;
begin
  select r.recepcion_id, l.variedad_id
    into v_recepcion_id, v_variedad_id
  from public.rechazo r
  join public.recepcion rc on rc.id = r.recepcion_id
  join public.envio e on e.id = rc.envio_id
  join public.lote l on l.id = e.lote_id
  where r.id = p_rechazo_id and rc.estado = 'CONFIRMADA'
  for update of r;

  if v_recepcion_id is null then raise exception 'Rechazo inexistente o recepción no confirmada'; end if;
  if p_precio_java < 0 then raise exception 'El precio no puede ser negativo'; end if;

  insert into public.disposicion_rechazo (
    rechazo_id, estado, cantidad, fecha_disposicion, observaciones
  ) values (
    p_rechazo_id, 'VENDIDA', p_cantidad, now(), p_observaciones
  ) returning id into v_disposicion_id;

  insert into public.venta (
    recepcion_id, disposicion_rechazo_id, cliente_id, tipo, observaciones
  ) values (
    v_recepcion_id, v_disposicion_id, p_cliente_id, 'RECUPERACION', p_observaciones
  ) returning * into v_venta;

  insert into public.detalle_venta (venta_id, variedad_id, cantidad_javas, precio_java)
  values (v_venta.id, v_variedad_id, p_cantidad, p_precio_java);

  select * into v_venta from public.venta where id = v_venta.id;
  return v_venta;
end;
$$;

grant execute on function public.determinar_precio_productor(bigint, numeric) to authenticated;
grant execute on function public.crear_envio(bigint, bigint, bigint, integer, numeric, varchar, date) to authenticated;
grant execute on function public.confirmar_recepcion(bigint) to authenticated;
grant execute on function public.generar_venta_normal(bigint, numeric) to authenticated;
grant execute on function public.registrar_perdida_rechazo(bigint, integer, text) to authenticated;
grant execute on function public.generar_venta_recuperacion(bigint, bigint, integer, numeric, text) to authenticated;

-- =========================================================
-- 9. VISTAS: PENDIENTES Y RENTABILIDAD
-- =========================================================

create or replace view public.v_saldo_productor
with (security_invoker = true)
as
select
  l.id as lote_id,
  l.codigo,
  l.monto_productor,
  coalesce(sum(pp.monto) filter (where not pp.anulado), 0)::numeric(14,2) as monto_pagado,
  (coalesce(l.monto_productor, 0)
   - coalesce(sum(pp.monto) filter (where not pp.anulado), 0))::numeric(14,2) as saldo_pendiente
from public.lote l
left join public.pago_productor pp on pp.lote_id = l.id
group by l.id, l.codigo, l.monto_productor;

create or replace view public.v_saldo_venta
with (security_invoker = true)
as
select
  v.id as venta_id,
  v.codigo,
  v.monto_total,
  coalesce(sum(pv.monto) filter (where not pv.anulado), 0)::numeric(14,2) as monto_pagado,
  (v.monto_total
   - coalesce(sum(pv.monto) filter (where not pv.anulado), 0))::numeric(14,2) as saldo_pendiente
from public.venta v
left join public.pago_venta pv on pv.venta_id = v.id
where v.estado <> 'ANULADA'
group by v.id, v.codigo, v.monto_total;

create or replace view public.v_operaciones_pendientes
with (security_invoker = true)
as
select 'LOTE_SIN_PRODUCCION'::text as tipo, l.id as entidad_id, l.codigo, l.fecha_registro as fecha
from public.lote l
left join public.produccion p on p.lote_id = l.id
where p.id is null
union all
select 'PRODUCCION_SIN_PRECIO', l.id, l.codigo, l.fecha_registro
from public.lote l
join public.produccion p on p.lote_id = l.id and p.estado = 'TERMINADA'
where l.precio_productor_java is null
union all
select 'PAGO_PRODUCTOR_PENDIENTE', l.id, l.codigo, l.fecha_registro
from public.lote l
join public.v_saldo_productor s on s.lote_id = l.id
where s.saldo_pendiente > 0
union all
select 'LOTE_PENDIENTE_ENVIO', l.id, l.codigo, l.fecha_registro
from public.lote l
join public.produccion p on p.lote_id = l.id and p.estado = 'TERMINADA'
where p.cantidad_enjavada > (
  select coalesce(sum(e.cantidad_javas), 0)
  from public.envio e where e.lote_id = l.id and not e.anulado
)
union all
select 'ENVIO_SIN_RECEPCION', e.id, e.codigo, coalesce(e.fecha_envio::date, e.fecha_programada)
from public.envio e
left join public.recepcion r on r.envio_id = e.id
where not e.anulado and r.id is null
union all
select 'RECEPCION_BORRADOR', r.id, e.codigo, r.fecha_recepcion::date
from public.recepcion r join public.envio e on e.id = r.envio_id
where r.estado = 'BORRADOR'
union all
select 'RECHAZO_SIN_DISPOSICION', r.id, e.codigo, rc.fecha_recepcion::date
from public.rechazo r
join public.recepcion rc on rc.id = r.recepcion_id
join public.envio e on e.id = rc.envio_id
where r.cantidad > (
  select coalesce(sum(d.cantidad), 0)
  from public.disposicion_rechazo d
  where d.rechazo_id = r.id and d.estado in ('PERDIDA', 'VENDIDA')
)
union all
select 'VENTA_PENDIENTE_COBRO', v.id, v.codigo, v.fecha_venta::date
from public.venta v
join public.v_saldo_venta s on s.venta_id = v.id
where s.saldo_pendiente > 0;

create or replace view public.v_rentabilidad_lote
with (security_invoker = true)
as
with materiales as (
  select p.lote_id, coalesce(sum(d.costo_total), 0) total
  from public.produccion p
  left join public.detalle_produccion_material d on d.produccion_id = p.id
  group by p.lote_id
), mano_obra as (
  select p.lote_id, coalesce(sum(d.costo_total), 0) total
  from public.produccion p
  left join public.detalle_mano_obra d on d.produccion_id = p.id
  group by p.lote_id
), fletes as (
  select e.lote_id, coalesce(sum(e.costo_flete), 0) total
  from public.envio e where not e.anulado group by e.lote_id
), ingresos as (
  select e.lote_id,
         coalesce(sum(v.monto_total) filter (where v.estado <> 'ANULADA'), 0) total
  from public.envio e
  join public.recepcion r on r.envio_id = e.id
  join public.venta v on v.recepcion_id = r.id
  where not e.anulado
  group by e.lote_id
), javas_ingreso as (
  select e.lote_id,
         coalesce(sum(dv.cantidad_javas) filter (where v.estado <> 'ANULADA'), 0) javas_con_ingreso
  from public.envio e
  join public.recepcion r on r.envio_id = e.id
  join public.venta v on v.recepcion_id = r.id
  join public.detalle_venta dv on dv.venta_id = v.id
  where not e.anulado
  group by e.lote_id
)
select
  l.id as lote_id,
  l.codigo,
  l.monto_productor as costo_productor,
  p.costo_total_javas,
  coalesce(m.total, 0)::numeric(14,2) as costo_materiales,
  coalesce(mo.total, 0)::numeric(14,2) as costo_mano_obra,
  coalesce(f.total, 0)::numeric(14,2) as costo_flete,
  (coalesce(l.monto_productor, 0) + coalesce(p.costo_total_javas, 0)
   + coalesce(m.total, 0) + coalesce(mo.total, 0) + coalesce(f.total, 0))::numeric(14,2)
    as costo_directo,
  coalesce(i.total, 0)::numeric(14,2) as ingresos_reales,
  (coalesce(i.total, 0) - coalesce(l.monto_productor, 0)
   - coalesce(p.costo_total_javas, 0) - coalesce(m.total, 0)
   - coalesce(mo.total, 0) - coalesce(f.total, 0))::numeric(14,2) as ganancia_bruta,
  p.cantidad_enjavada,
  coalesce(ji.javas_con_ingreso, 0)::bigint as javas_con_ingreso,
  case when p.cantidad_enjavada > 0 then
    round((coalesce(l.monto_productor, 0) + coalesce(p.costo_total_javas, 0)
      + coalesce(m.total, 0) + coalesce(mo.total, 0) + coalesce(f.total, 0))
      / p.cantidad_enjavada, 2)
  end as costo_por_java_producida,
  case when coalesce(ji.javas_con_ingreso, 0) > 0 then
    round((coalesce(l.monto_productor, 0) + coalesce(p.costo_total_javas, 0)
      + coalesce(m.total, 0) + coalesce(mo.total, 0) + coalesce(f.total, 0))
      / ji.javas_con_ingreso, 2)
  end as costo_por_java_con_ingreso
from public.lote l
left join public.produccion p on p.lote_id = l.id
left join materiales m on m.lote_id = l.id
left join mano_obra mo on mo.lote_id = l.id
left join fletes f on f.lote_id = l.id
left join ingresos i on i.lote_id = l.id
left join javas_ingreso ji on ji.lote_id = l.id;

-- =========================================================
-- 10. ROW LEVEL SECURITY
-- =========================================================

alter table public.perfil_usuario enable row level security;

create policy perfil_ver_propio_o_admin on public.perfil_usuario
for select to authenticated
using (id = auth.uid() or public.es_administrador());

create policy perfil_admin_insertar on public.perfil_usuario
for insert to authenticated
with check (public.es_administrador());

create policy perfil_admin_actualizar on public.perfil_usuario
for update to authenticated
using (public.es_administrador())
with check (public.es_administrador());

-- Los maestros sensibles solo pueden ser modificados por el administrador.
do $$
declare v_tabla text;
begin
  foreach v_tabla in array array['producto','variedad','motivo_rechazo','categoria_gasto'] loop
    execute format('alter table public.%I enable row level security', v_tabla);
    execute format(
      'create policy %I on public.%I for select to authenticated using (public.es_usuario_activo())',
      v_tabla || '_leer', v_tabla
    );
    execute format(
      'create policy %I on public.%I for all to authenticated '
      || 'using (public.es_administrador()) with check (public.es_administrador())',
      v_tabla || '_admin_escribir', v_tabla
    );
  end loop;
end $$;

-- Maestros operativos y transacciones: ambos roles activos trabajan con ellos.
do $$
declare v_tabla text;
begin
  foreach v_tabla in array array[
    'productor','cliente','transportista','material','trabajador','lote','produccion',
    'detalle_produccion_material','detalle_mano_obra','pago_productor','envio',
    'recepcion','rechazo','disposicion_rechazo','venta','detalle_venta','pago_venta','gasto'
  ] loop
    execute format('alter table public.%I enable row level security', v_tabla);
    execute format(
      'create policy %I on public.%I for select to authenticated using (public.es_usuario_activo())',
      v_tabla || '_leer', v_tabla
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated '
      || 'with check (public.es_usuario_activo())',
      v_tabla || '_insertar', v_tabla
    );
    execute format(
      'create policy %I on public.%I for update to authenticated '
      || 'using (public.es_usuario_activo()) with check (public.es_usuario_activo())',
      v_tabla || '_actualizar', v_tabla
    );
  end loop;
end $$;

alter table public.auditoria_evento enable row level security;
create policy auditoria_solo_admin_leer on public.auditoria_evento
for select to authenticated using (public.es_administrador());

grant usage on schema public to authenticated;
grant select, insert, update on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- No se concede DELETE: las operaciones se anulan o desactivan.
revoke delete on all tables in schema public from authenticated;

-- =========================================================
-- 11. DATOS INICIALES
-- =========================================================

insert into public.producto (nombre, descripcion) values
  ('Plátano', 'Fruta comercializada por javas'),
  ('Papaya', 'Fruta comercializada por javas');

insert into public.variedad (producto_id, nombre)
select p.id, v.nombre
from public.producto p
join (values
  ('Plátano', 'Bellaco'),
  ('Plátano', 'Manzano')
) as v(producto, nombre) on v.producto = p.nombre;

insert into public.motivo_rechazo (nombre) values
  ('Fruta dañada'),
  ('Mala presentación'),
  ('Maduración inadecuada'),
  ('Tamaño'),
  ('Incumplimiento de calidad'),
  ('Otro');

insert into public.categoria_gasto (nombre) values
  ('Administración'),
  ('Servicios'),
  ('Mantenimiento'),
  ('Otros');

commit;

-- =========================================================
-- CREACIÓN DEL PRIMER ADMINISTRADOR
-- =========================================================
-- 1. Crear el usuario en Supabase Authentication.
-- 2. Copiar su UUID y ejecutar con la service role o desde SQL Editor:
--
-- insert into public.perfil_usuario (id, nombre, rol)
-- values ('UUID-DEL-USUARIO', 'Administrador', 'ADMINISTRADOR');

