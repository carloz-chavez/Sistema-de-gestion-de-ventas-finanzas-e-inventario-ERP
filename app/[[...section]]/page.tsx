import Link from "next/link";
import { ArrowRight, Boxes, CircleDollarSign, ClipboardCheck, PackageOpen, Sprout, Truck, Users } from "lucide-react";
import { AppShell } from "@/components/app-shell";

const names:Record<string,string>={inicio:"Inicio",produccion:"Producción",envios:"Envíos",recepciones:"Recepciones",ventas:"Ventas",finanzas:"Finanzas",maestros:"Maestros",administracion:"Administración",productores:"Productores",clientes:"Clientes",trabajadores:"Trabajadores",transportistas:"Transportistas",materiales:"Materiales"};
const masters=[{n:"Productores",h:"/productores",i:Sprout},{n:"Clientes",h:"/clientes",i:Users},{n:"Trabajadores",h:"/trabajadores",i:Users},{n:"Transportistas",h:"/transportistas",i:Truck},{n:"Materiales",h:"/materiales",i:PackageOpen}];

export default async function Page({params}:{params:Promise<{section?:string[]}>}){
  const {section=["inicio"]}=await params; const slug=section[0]||"inicio"; const title=names[slug]||"Inicio";
  return <AppShell><header><div><p className="eyebrow">ERP Familia</p><h1>{title}</h1><p className="muted">Control simple y conectado de la operación frutícola.</p></div><button className="primary">+ Nuevo registro</button></header>{slug==="inicio"?<Dashboard/>:slug==="maestros"?<section className="masterGrid">{masters.map(({n,h,i:Icon})=><Link href={h} className="masterCard" key={h}><span><Icon/></span><div><h2>{n}</h2><p>Gestionar registros de {n.toLowerCase()}.</p></div><ArrowRight size={18}/></Link>)}</section>:<section className="panel"><div className="panelHead"><div><h2>{title}</h2><p>Conectado a la tabla correspondiente de Supabase.</p></div><input aria-label={`Buscar ${title}`} placeholder="Buscar..."/></div><div className="empty">Los registros aparecerán aquí después de iniciar sesión.</div></section>}</AppShell>;
}
function Dashboard(){const cards=[{l:"Lotes activos",v:"—",i:Sprout},{l:"Envíos en tránsito",v:"—",i:Truck},{l:"Recepciones pendientes",v:"—",i:ClipboardCheck},{l:"Ventas del mes",v:"—",i:CircleDollarSign}];return <><section className="stats">{cards.map(({l,v,i:Icon})=><article key={l}><span><Icon/></span><div><p>{l}</p><strong>{v}</strong></div></article>)}</section><section className="panel flow"><Boxes/><div><h2>LOTE → ENVÍO → RECEPCIÓN → VENTA</h2><p>La columna vertebral operativa ya está reflejada en el esquema.</p></div></section></>}

